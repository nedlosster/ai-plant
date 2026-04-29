# opencode Custom Agents: deep dive

Главный механизм расширения opencode -- **custom agents через `opencode.json`**. Это универсальный инструмент, заменяющий Skills + Hooks + Teams Claude Code через композицию.

В этом гайде: анатомия `opencode.json`, три канонических паттерна с готовыми примерами, multi-model orchestration, permission profiles, debugging, antipatterns.

## Анатомия `opencode.json`

`opencode.json` живёт в корне проекта. Все секции опциональны кроме `model` (default agent model).

### Полный пример с разбором

```json
{
  "$schema": "https://opencode.ai/config.json",

  "model": "llama-server/coder",

  "provider": {
    "llama-server": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Local llama.cpp",
      "options": {
        "baseURL": "{env:OPENAI_BASE_URL}",
        "apiKey": "{env:OPENAI_API_KEY}"
      },
      "models": {
        "coder": {
          "name": "Qwen3-Coder Next 80B-A3B",
          "limit": { "context": 256000, "output": 8192 }
        },
        "quality": {
          "name": "Qwen3.5-122B-A10B (planner)",
          "limit": { "context": 131072, "output": 8192 }
        }
      }
    }
  },

  "mcp_servers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  },

  "permission": {
    "edit": "ask",
    "write": "ask",
    "bash": "ask",
    "webfetch": "allow"
  },

  "default_agent": "build",

  "agent": {
    "build": {
      "model": "llama-server/coder",
      "tools": { "bash": true, "write": true, "edit": true, "read": true }
    },
    "plan": {
      "model": "llama-server/quality",
      "tools": { "bash": false, "write": false, "edit": false, "read": true }
    },
    "reviewer": {
      "model": "llama-server/coder",
      "tools": { "bash": false, "write": false, "edit": false, "read": true },
      "prompt": "{file:./prompts/reviewer.txt}"
    }
  }
}
```

### Поля по секциям

| Поле | Назначение | Обязательно |
|------|-----------|-------------|
| `$schema` | URL JSON schema для валидации в IDE | нет (рекомендуется) |
| `model` | Default model для default agent (формат `provider/model_id`) | да |
| `provider` | Регистрация OpenAI-compatible providers | минимум один |
| `provider.<name>.npm` | npm package implementing the SDK adapter | да |
| `provider.<name>.options.baseURL` | URL endpoint (поддерживает `{env:VAR_NAME}`) | да |
| `provider.<name>.options.apiKey` | API key (env-var template) | да |
| `provider.<name>.models.<id>.name` | Display name | нет |
| `provider.<name>.models.<id>.limit.context` | Max context tokens | да |
| `provider.<name>.models.<id>.limit.output` | Max output tokens | да |
| `mcp_servers` | MCP-серверы для подключения (см. [mcp-setup.md](mcp-setup.md)) | нет |
| `permission` | Default permissions для tools (`ask`/`allow`/`deny`) | нет |
| `default_agent` | Какой agent запускается по умолчанию (если есть несколько) | нет |
| `agent.<name>` | Custom agent definition | нет |
| `agent.<name>.model` | Override модели на уровне агента | нет |
| `agent.<name>.tools` | Per-agent tool permissions (boolean) | нет |
| `agent.<name>.prompt` | System prompt: inline string или `{file:relative_path}` template | нет |
| `agent.<name>.permission` | Override permissions из root | нет |

### Templates в строковых полях

opencode поддерживает специальные шаблоны:

| Шаблон | Значение |
|--------|----------|
| `{env:VAR_NAME}` | Подстановка переменной окружения |
| `{file:./path/to/file.txt}` | Подстановка содержимого файла |
| `{file:path#section}` | Подстановка секции markdown файла |

Особенно полезно для system prompts -- держать их в отдельных файлах:

```bash
mkdir -p prompts
cat > prompts/reviewer.txt <<'EOF'
You are a senior code reviewer. Find:
- Bugs, security issues, race conditions
- API inconsistencies
- Anti-patterns

Format: structured report. Do not modify files.
EOF
```

## Три канонических паттерна

### 1. Reviewer agent (read-only audit)

**Use case**: PR review, security audit, anti-pattern detection. Агент анализирует код, выдаёт structured отчёт, **не вносит изменений**.

```json
{
  "agent": {
    "reviewer": {
      "model": "llama-server/coder",
      "tools": {
        "read": true,
        "grep": true,
        "glob": true,
        "bash": false,
        "edit": false,
        "write": false,
        "webfetch": false
      },
      "permission": {
        "edit": "deny",
        "write": "deny",
        "bash": "deny"
      },
      "prompt": "{file:./prompts/reviewer.txt}"
    }
  }
}
```

`prompts/reviewer.txt`:

```
You are a senior code reviewer specializing in:
- Security: SQL injection, XSS, command injection, secrets in code
- Performance: N+1 queries, memory leaks, blocking I/O in async paths
- Correctness: race conditions, error handling, edge cases
- Style: project conventions (read CLAUDE.md / README.md if present)

Output format:
## Critical
- [file:line] description, suggested fix

## Important
- [file:line] description

## Style
- [file:line] description

If no issues found in a category, write "None found".
Do not modify any files. Only read and analyze.
```

**Запуск**:

```bash
opencode --agent reviewer "review changes since main branch"
```

### 2. Architect agent (design proposal без implementation)

**Use case**: проектирование новой фичи, миграционный план, рефакторинг архитектуры. Агент пишет дизайн-документ в Markdown, не трогает код.

```json
{
  "agent": {
    "architect": {
      "model": "llama-server/quality",
      "tools": {
        "read": true,
        "grep": true,
        "glob": true,
        "webfetch": true,
        "write": true,
        "edit": false,
        "bash": false
      },
      "permission": {
        "edit": "deny",
        "bash": "deny",
        "write": "ask"
      },
      "prompt": "{file:./prompts/architect.txt}"
    }
  }
}
```

`prompts/architect.txt`:

```
You are a system architect. Your job: design proposals, NOT implementation.

When asked to design a feature:
1. Read relevant existing code (use grep/read tools)
2. Identify patterns, conventions, dependencies
3. Propose 2-3 alternative approaches with trade-offs
4. Recommend one with justification
5. Write the design as docs/design/<feature>.md

Constraints:
- Do not modify production code (edit tool denied)
- Only write design documents (write tool ask-mode)
- Cite specific files/line numbers in proposals
- Estimate effort (S/M/L) and risks
```

**Запуск**:

```bash
opencode --agent architect "design migration from REST to GraphQL"
```

Использует **более качественную модель** (Qwen3.5-122B-A10B через `quality`) для деликатной работы планирования.

### 3. Plan-and-execute (two-phase workflow)

**Use case**: сложная задача требует separation планирования и выполнения. Planner проектирует с большой моделью, executor выполняет с быстрой -- multi-model orchestration.

```json
{
  "provider": {
    "llama-server": {
      "models": {
        "fast": { "name": "Qwen3-Coder 30B-A3B", "limit": { "context": 131072, "output": 8192 } },
        "balanced": { "name": "Qwen3-Coder Next 80B-A3B", "limit": { "context": 256000, "output": 8192 } },
        "quality": { "name": "Qwen3.5-122B-A10B", "limit": { "context": 131072, "output": 8192 } }
      }
    }
  },
  "agent": {
    "planner": {
      "model": "llama-server/quality",
      "tools": { "read": true, "grep": true, "glob": true, "write": true, "edit": false, "bash": false },
      "prompt": "Create a detailed implementation plan as plan.md. Steps must be atomic and testable. No code changes."
    },
    "executor": {
      "model": "llama-server/balanced",
      "tools": { "read": true, "write": true, "edit": true, "bash": true },
      "prompt": "{file:./prompts/executor.txt}"
    }
  }
}
```

`prompts/executor.txt`:

```
You execute steps from plan.md. For each step:
1. Read the step from plan.md
2. Implement it (write/edit/bash as needed)
3. Run tests if relevant
4. Mark step as [DONE] in plan.md if successful
5. If step fails, mark [FAILED] with error description and stop

Read plan.md at start. Do not deviate from the plan -- if plan looks wrong,
write a comment in plan.md and stop. Do not improvise.
```

**Workflow**:

```bash
# Phase 1: planning
opencode --agent planner "design implementing user authentication with JWT"
# Result: plan.md with atomic steps

# Phase 2: execution
opencode --agent executor "implement plan.md"
# Result: code applied, plan.md marked with [DONE]/[FAILED]
```

**Преимущество**: planner использует большую модель **только на проектирование** (короткий вывод), executor использует быструю модель **для большого вывода** (код). Экономия по compute и качество.

## Multi-model orchestration

`opencode.json` поддерживает **разные провайдеры одновременно**. Это позволяет mix cloud и local моделей:

```json
{
  "provider": {
    "anthropic": {
      "npm": "@ai-sdk/anthropic",
      "options": { "apiKey": "{env:ANTHROPIC_API_KEY}" },
      "models": {
        "opus": { "name": "Claude Opus 4.7", "limit": { "context": 1000000, "output": 128000 } }
      }
    },
    "llama-server": {
      "npm": "@ai-sdk/openai-compatible",
      "options": { "baseURL": "http://localhost:8081/v1", "apiKey": "local" },
      "models": {
        "coder": { "name": "Qwen3-Coder Next", "limit": { "context": 256000, "output": 8192 } }
      }
    }
  },
  "agent": {
    "design-review": {
      "model": "anthropic/opus",
      "tools": { "read": true },
      "prompt": "Senior architect, review only. No edits."
    },
    "implement": {
      "model": "llama-server/coder",
      "tools": { "read": true, "write": true, "edit": true, "bash": true }
    }
  }
}
```

**Когда полезно**:

- **Sensitive design** -- privacy critical projects используют local модель для implementation, но проверяют дизайн через cloud для качества
- **Cost optimization** -- использовать Opus только для редких задач планирования, executor -- local
- **Fallback** -- если local недоступен, переключиться на cloud
- **A/B testing** моделей на одинаковых задачах

## Permission profiles

opencode имеет три уровня permission:

| Profile | edit | write | bash | webfetch | Use case |
|---------|------|-------|------|----------|----------|
| **production** | ask | ask | ask | allow | Default рекомендация: подтверждать каждое изменение |
| **experimental** | allow | allow | ask | allow | Активная разработка, частые изменения, но bash требует confirm |
| **sandbox** | allow | allow | allow | allow | Изолированный VM/container, всё разрешено |
| **read-only** | deny | deny | deny | allow | Reviewer/auditor агенты |

Готовые JSON-снимки в `~/.opencode/profiles/`:

```bash
# production
{ "permission": { "edit": "ask", "write": "ask", "bash": "ask", "webfetch": "allow" } }

# experimental
{ "permission": { "edit": "allow", "write": "allow", "bash": "ask", "webfetch": "allow" } }

# sandbox (для Docker контейнеров)
{ "permission": { "edit": "allow", "write": "allow", "bash": "allow", "webfetch": "allow" } }

# read-only
{ "permission": { "edit": "deny", "write": "deny", "bash": "deny", "webfetch": "allow" } }
```

Применение через extends:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "extends": "~/.opencode/profiles/production.json"
}
```

(Если opencode поддерживает `extends` -- проверить в текущей версии. Иначе copy-paste.)

## Debugging custom agents

### Включить verbose

```bash
opencode --verbose --agent reviewer "review src/auth.ts"
```

Покажет:
- Какой провайдер и модель используются
- Какие tools доступны для агента
- Каждый tool call с аргументами
- Permission decisions

### Логи

opencode пишет логи в `~/.opencode/logs/<session-id>.log`. Полезно при долгих сессиях, чтобы понять "что агент сделал на 50-м step".

### Симптом: agent игнорирует system prompt

**Причина 1**: prompt слишком длинный и обрезается context window. Проверить `limit.context` модели.

**Причина 2**: модель плохо следует system prompt (слабые модели типа 7B). Решение: использовать большую модель в этом агенте, или упростить prompt.

**Причина 3**: prompt противоречит instructions от пользователя. Проверить иерархию: opencode user message > system prompt > defaults.

### Симптом: agent не видит файл

**Причина**: tools.read = false, или permission read = deny. Проверить через `opencode --verbose`.

**Причина**: файл за пределами current working directory (если опен-cwd ограничен).

### Симптом: agent не вызывает MCP-сервер

См. [mcp-setup.md](mcp-setup.md) -- секция Debug.

## Antipatterns (5 типичных ошибок)

### 1. Over-permissive default agent

```json
"agent": {
  "build": {
    "tools": { "bash": true, "write": true, "edit": true, "read": true },
    "permission": { "bash": "allow" }
  }
}
```

`bash: "allow"` -- значит **любая bash-команда** идёт без confirm. Один промпт-injection и `rm -rf` уйдёт.

**Лучше**: `bash: "ask"`, плюс whitelisting через `permission.bash.commands` (если поддерживается).

### 2. Conflicting prompts на разных уровнях

User говорит "fix the bug, don't touch tests", agent prompt говорит "always update tests after fixing bugs". Result: модель путается, поведение непредсказуемое.

**Лучше**: prompt agent'а -- это **persistent правила** ("you are a code reviewer"), user message -- **конкретная задача**. Не дублировать в обоих местах.

### 3. Model mismatch с capacity

```json
"agent": {
  "reviewer": {
    "model": "llama-server/fast",  // 30B-A3B
    "prompt": "очень длинный prompt с 20 правилами и примерами на 5K токенов"
  }
}
```

Маленькая модель не может удержать длинный prompt + большой код в context. Reviewer-агенту лучше использовать качественную модель (122B-A10B), executor -- быструю.

### 4. Слишком много custom agents

Если `opencode.json` содержит 10+ агентов, **никто не помнит когда использовать какой**. Реальная цена: cognitive overhead + ошибки выбора.

**Лучше**: 3-5 агентов с чёткими разными ролями. Если нужно больше -- делать project templates с разными `opencode.json`.

### 5. system prompts inline в JSON

```json
"prompt": "You are a senior reviewer. Find: \n- Bugs\n- ...\n[5K символов]"
```

JSON-escaping ломается, изменения вне VCS, нет syntax highlighting.

**Лучше**: `"prompt": "{file:relative_prompt_path}"` template. Markdown в отдельных файлах под git.

## Связано

- [README.md](README.md) -- обзор opencode
- [mcp-setup.md](mcp-setup.md) -- расширение через MCP-серверы
- [migration-guide.md](migration-guide.md) -- migrate Claude Code skills/hooks/teams в custom agents
- [advanced-workflows.md](advanced-workflows.md) -- использование custom agents в сложных сценариях
- [../claude-code/skills-guide.md](../claude-code/skills-guide.md) -- аналогичный механизм Claude Code (Skills) для сравнения
- [../claude-code/agent-teams.md](../claude-code/agent-teams.md) -- Anthropic Teams для контекста (не доступны в opencode)
