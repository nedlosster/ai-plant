# opencode -- продвинутые сценарии

Разбор простых и сложных workflow на opencode + локальный llama-server. Multi-agent orchestration, long-context refactoring, CI integration, cache-reuse оптимизация для платформы Strix Halo.

## Простые сценарии

### 1. Quick refactor одного файла

```bash
opencode run "rename function foo to bar in src/auth.ts and update all callers"
```

opencode сам найдёт callers через grep, сделает edits. **Когда подходит**: точечные изменения, переименования, мелкие feature flags.

**Совет**: для атомарных коммитов после refactor -- предварительно очистить рабочую директорию (`git stash` или `git commit -m "wip"`). Иначе сложно отделить opencode-changes от своих.

### 2. Bug fix через test reproduction

```bash
opencode "in tests/auth.test.ts I have a failing test for token expiration. Reproduce it locally, find the bug, fix it"
```

opencode:
1. Запускает тест (через bash tool) -- видит конкретную ошибку
2. Читает тестовый файл и production код
3. Локализует bug
4. Делает fix
5. Перезапускает тест -- если passes, готово; если нет, итерирует

**Когда подходит**: TDD workflow, regression fixes, debugging. Многие модели лучше работают именно с failing tests как entry-point (конкретный constraint vs абстрактный bug report).

### 3. Boilerplate generation

```bash
opencode --agent build "generate CRUD API for User model in Express + TypeScript with Zod validation"
```

Производит файлы routes/users.ts, schemas/user.ts, controllers/users.ts. Для repetitive structure (CRUD, REST endpoints, table migrations) opencode эффективнее чем ручное написание.

**Совет**: использовать `--agent build` явно, чтобы получить write/edit permissions без подтверждений на каждый файл (если permission set в `allow`).

### 4. Code review через reviewer-агента

См. [custom-agents-guide.md](custom-agents-guide.md) -- паттерн Reviewer agent.

```bash
opencode --agent reviewer "review changes since main branch"
```

Агент только читает (read-only), пишет structured отчёт в stdout. Подходит для:
- Pre-PR self-review (поймать issues до того как ревьюер заметит)
- Onboarding -- ассистент-ревьюер для junior разработчиков
- Security audit пассов

## Сложные сценарии

### 5. Long-context refactoring (whole-repo)

**Use case**: миграция framework по всему проекту, реорганизация архитектуры, перевод классов в hooks по всем компонентам React.

**Setup**:

```bash
# llama-server с Coder Next 256K контекста
./scripts/inference/vulkan/preset/qwen-coder-next.sh -d
```

opencode.json указывает context limit:

```json
"models": {
  "coder": { "name": "Qwen3-Coder Next", "limit": { "context": 256000, "output": 8192 } }
}
```

**Запуск**:

```bash
opencode "migrate all class components in src/ to functional with hooks. Preserve API"
```

opencode itself подгружает relevant файлы через grep/glob/read. Для **очень больших проектов** (1M+ tokens code) decompose на несколько подсессий по directory:

```bash
opencode "in src/auth/ migrate class to functional"
opencode --cont "now src/dashboard/"
opencode --cont "now src/profile/"
```

`--cont` сохраняет state -- модель помнит решения предыдущих sessions.

**Caveat**: hybrid Gated DeltaNet моделей (Qwen3-Coder Next, Qwen3.6) cache-reuse blocked между tasks (см. [optimization-backlog.md](../../../inference/optimization-backlog.md#u-001)). Каждый turn пересчитывает promt с нуля -- на 256K контексте это ~7 минут pp. **Полное использование 256K не оптимально для multi-turn**, лучше держать prompt в районе 50-100K.

### 6. Multi-agent через custom agents (orchestration без Teams)

opencode не имеет native Agent Teams. Multi-agent -- через композицию custom agents.

**Pattern: Plan-Decompose-Execute-Verify**

```json
"agent": {
  "planner": {
    "model": "llama-server/quality",
    "tools": { "read": true, "write": true, "edit": false, "bash": false },
    "prompt": "Decompose task into atomic steps. Output as plan.md with checkboxes."
  },
  "executor": {
    "model": "llama-server/coder",
    "tools": { "read": true, "write": true, "edit": true, "bash": true },
    "prompt": "Execute steps from plan.md. Mark [DONE] after each."
  },
  "verifier": {
    "model": "llama-server/coder",
    "tools": { "read": true, "bash": true, "edit": false, "write": false },
    "prompt": "Run tests, lints, typechecks. Report pass/fail per step."
  }
}
```

**Workflow** (sequential pipeline):

```bash
# Phase 1
opencode --agent planner "implement OAuth2 flow with refresh tokens"
# → plan.md с 8 steps

# Phase 2
opencode --agent executor --cont "execute plan.md"
# → код применён, plan.md с [DONE] marks

# Phase 3
opencode --agent verifier --cont "verify changes work"
# → отчёт по тестам, lint, typecheck
```

`--cont` сохраняет общую память между фазами.

### 7. Multi-model: planner на 122B, executor на Coder Next

**Idea**: использовать большую модель только для критических планировочных задач (короткий вывод), быструю -- для большого objem кода.

```json
"provider": {
  "llama-server-quality": {
    "options": { "baseURL": "http://localhost:8082/v1", "apiKey": "local" },
    "models": { "default": { "limit": { "context": 131072, "output": 4096 } } }
  },
  "llama-server-coder": {
    "options": { "baseURL": "http://localhost:8081/v1", "apiKey": "local" },
    "models": { "default": { "limit": { "context": 256000, "output": 8192 } } }
  }
},
"agent": {
  "planner": {
    "model": "llama-server-quality/default",
    "prompt": "Senior architect. Output: plan.md with atomic steps."
  },
  "coder": {
    "model": "llama-server-coder/default",
    "prompt": "Junior implementer. Read plan.md, execute step-by-step."
  }
}
```

**Setup на Strix Halo**:

```bash
# Запустить ОБА сервера параллельно
./scripts/inference/vulkan/preset/qwen3.5-122b.sh -d        # порт 8081 (default)
# Изменить порт в копии preset на 8082, или запустить через CLI override
./scripts/inference/vulkan/preset/qwen-coder-next.sh -d     # отдельный порт
```

Memory budget: 122B Q4 = 71 GiB + Coder Next Q4 = 45 GiB → 116 GiB из 120 GiB. Тонко, но помещается. Можно держать оба только если других тяжёлых сервисов нет.

**Когда полезно**:
- Сложные архитектурные изменения, где плохой план = много переделки
- Production-critical refactoring
- Когда есть бюджет 116 GiB на два сервера

### 8. Continuous integration (PR review через GitHub Actions)

opencode `--headless` mode идеально для CI/CD.

`.github/workflows/opencode-review.yml`:

```yaml
name: opencode PR review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: self-hosted  # нужен runner с доступом к llama-server
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Install opencode
        run: curl -fsSL https://opencode.ai/install | bash

      - name: Run reviewer
        env:
          OPENAI_BASE_URL: http://strix-halo.local:8081/v1
          OPENAI_API_KEY: local
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          opencode run --agent reviewer "review changes since origin/main" \
            > review.md

      - name: Post comment
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: review
            });
```

Self-hosted runner с прямым доступом к Strix Halo через LAN -- бесплатный automated PR review (vs GitHub Copilot Enterprise $39/user/мес).

### 9. Document → code (PDF spec через MCP filesystem + генерация)

**Use case**: техническое задание в PDF -- хочется автоматически сгенерировать starter code.

```json
"mcp_servers": {
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "./specs"]
  }
},
"agent": {
  "spec-implementer": {
    "model": "llama-server/coder",
    "tools": { "read": true, "write": true, "edit": true, "bash": false },
    "prompt": "{file:./prompts/spec-implementer.md}"
  }
}
```

file `prompts/spec-implementer` (markdown в репо проекта):

```
Read the technical spec from ./specs/<file>.txt (or .md/.json).
Generate implementation in src/ following project conventions:
1. Read existing code structure to match patterns
2. Generate types/interfaces first
3. Implement business logic
4. Add basic tests

Do not run shell commands. Only file ops.
```

**Caveat**: opencode сейчас не имеет vision -- PDF нужно конвертировать в text сначала (`pdftotext spec.pdf specs/spec.txt`). Для visual specs (Figma exports, wireframes) -- использовать [Cline](../cline.md) или [openclaw](../openclaw/README.md) с multimodal моделью.

### 10. Test-driven implementation (TDD)

**Workflow**:

```json
"agent": {
  "tdd-tests": {
    "model": "llama-server/coder",
    "tools": { "read": true, "write": true, "edit": false, "bash": false },
    "prompt": "Write tests for the requirement. Tests must FAIL initially. No implementation."
  },
  "tdd-impl": {
    "model": "llama-server/coder",
    "tools": { "read": true, "write": true, "edit": true, "bash": true },
    "prompt": "Make the failing tests pass. Run them after each change. Stop when all green."
  }
}
```

```bash
# Phase 1: failing tests
opencode --agent tdd-tests "write tests for User signup with email validation"

# Phase 2: implementation until green
opencode --agent tdd-impl --cont "implement to make tests pass"
```

Преимущество: модель не оптимизирует под "написал что-то правдоподобное", а **под прохождение тестов** -- более надёжный контракт.

### 11. Cross-language refactoring через translator agent

**Use case**: миграция Python скрипта на Rust для производительности.

```json
"agent": {
  "translator": {
    "model": "llama-server/quality",
    "tools": { "read": true, "write": true },
    "prompt": "{file:./prompts/translator.md}"
  }
}
```

file `prompts/translator` (markdown в репо проекта):

```
You are a code translator from Python to Rust. Process:
1. Read source.py
2. Identify dependencies, types, idioms
3. Map Python idioms to Rust:
   - dict → HashMap or BTreeMap
   - list → Vec
   - exceptions → Result<T, E>
   - asyncio → tokio
4. Write output as src/lib.rs (or src/<name>.rs)
5. Use idiomatic Rust (lifetimes, ownership)
6. Add Cargo.toml with deps

Do not implement business logic differently -- preserve behaviour.
Add comments where Python idiom doesn't translate cleanly.
```

```bash
opencode --agent translator "translate scripts/data-pipeline.py to Rust"
```

**Caveat**: open-weight модели слабы на Rust (см. [coding/benchmarks/](../../../coding/benchmarks/README.md) -- Rust исключён из aider polyglot потому что 0% pass у большинства моделей). Quality output -- only c quality моделью (122B-A10B) и аккуратной верификацией.

### 12. Sessions management для long-running агент-loops

opencode сохраняет sessions в `~/.opencode/sessions/`. Long-running проект:

```bash
# Создать sesion для feature
opencode --session feature-auth "let's implement OAuth from scratch"
# работа... отключение

# На следующий день -- продолжить тот же session
opencode --session feature-auth --cont
# модель помнит контекст всей задачи
```

**Когда полезно**:
- Multi-day проекты (контекст рабочего модуля сохраняется)
- Перерывы между working sessions
- Параллельные feature branches с разными context'ами

**Caveat**: для hybrid моделей (Qwen3-Coder Next и др.) cache reuse не работает -- session reload = full re-processing промпта. На 100K контекста это ~3 минуты на старт каждой возобновлённой сессии.

## Cache-reuse оптимизация для llama-server

opencode с локальным llama-server наиболее эффективен когда **cache reuse работает** между запросами. Из [optimization-backlog.md](../../../inference/optimization-backlog.md):

| Модель | Inter-task cache | Когда полезно |
|--------|------------------|---------------|
| **Qwen3-Coder 30B-A3B** | ✅ работает 100% | best speed для multi-turn agent loops |
| **Devstral 2 24B (dense)** | ✅ работает | dense alternative с cache |
| Qwen3-Coder Next 80B-A3B | ❌ blocked (hybrid) | high quality, но pause на каждый turn |
| Qwen3.6-35B-A3B (text/multi) | ❌ blocked (hybrid) | high quality |
| Qwen3.5-122B-A10B | ❌ blocked (hybrid) | top quality, но slow per turn |
| Gemma 4 26B-A4B | ❌ blocked (multi+SWA) | для vision tasks |

**Рекомендации для opencode**:

1. **Daily fast iteration** -- Qwen3-Coder 30B-A3B (cache works, 86 tok/s) -- хотя качество ниже
2. **Quality multi-turn** -- Qwen3-Coder Next 80B-A3B (68% pass_2, но pause на каждом turn -- держать prompt < 50K для приемлемой UX)
3. **Critical decisions** -- Qwen3.5-122B-A10B (75-78% pass_2, slowest but best)
4. **После merge llama.cpp PR #19670** (3-6 мес) -- inter-task cache откроется на hybrid моделях, переключиться на Coder Next/35B-text как daily

### `--keep N` для system prompt persistence

llama-server поддерживает `--keep 1500` -- сохранение первых 1500 токенов prompt от eviction в context shift. На multi-turn agent loops это критично для длинного system prompt:

```bash
# Уже включено в наших presets
./scripts/inference/vulkan/preset/qwen-coder-next.sh -d  # имеет --keep 1500
```

System prompt у custom agents (особенно reviewer/architect с подробными правилами) часто 1-2K токенов. С `--keep 1500` он не теряется при context shift -- агент всегда "помнит" свою роль.

### Multi-turn vs single-shot

| Mode | Когда |
|------|-------|
| **Multi-turn** (`opencode` interactive) | Сложные задачи требующие итераций, exploration |
| **Single-shot** (`opencode run "..."`) | Чёткая задача с предсказуемым output, CI integration |
| **Headless с --cont** | Pipeline-mode для multi-stage workflows |

Single-shot быстрее на cache-blocked моделях -- prompt пересчитывается **один раз**, не каждый turn.

## Performance tuning

### Memory budget на Strix Halo (120 GiB unified)

| Конфигурация | Memory | Use case |
|--------------|--------|----------|
| **Solo Coder Next** | 45 + 8 KV = ~53 GiB | Default daily |
| **Coder Next + FIM 1.5B** | 53 + 2 = 55 GiB | Coder + IDE autocomplete |
| **Coder Next + 30B-A3B** (multi-model) | 53 + 18 + KV = ~75 GiB | Quality vs speed split |
| **122B-A10B + Coder Next** | 78 + 53 = ~131 GiB ⚠️ | Не помещается! |
| **122B-A10B + 30B-A3B** | 78 + 18 + KV = ~100 GiB | Multi-model планер+executor |
| **Solo 122B-A10B** | 71 + 12 KV = ~83 GiB | Top quality, single model |

**Best practices**:

- Для daily multi-model -- 122B + 30B (помещается с запасом)
- Для max quality -- solo 122B
- Для max speed -- solo 30B-A3B (cache works!)
- Для balanced -- solo Coder Next 80B

### Параллельный запуск 2 моделей

```bash
# 122B planner на 8081
./scripts/inference/vulkan/preset/qwen3.5-122b.sh -d
# Coder Next executor на 8082 (нужен custom port)
PORT=8082 ./scripts/inference/vulkan/preset/qwen-coder-next.sh -d
```

opencode.json:

```json
"provider": {
  "planner": { "options": { "baseURL": "http://localhost:8081/v1" }, ... },
  "coder": { "options": { "baseURL": "http://localhost:8082/v1" }, ... }
}
```

### Какой preset запускать на 8081

Default рекомендация для opencode на платформе:

```bash
./scripts/inference/vulkan/preset/qwen-coder-next.sh -d
```

Aider Polyglot pass_2 = 68.0% на full (см. [coding/benchmarks/runs/2026-04-27-aider-full-qwen-coder-next.md](../../../coding/benchmarks/runs/2026-04-27-aider-full-qwen-coder-next.md)). Лучший balance качества и скорости на платформе.

После завершения теста Qwen3.5-122B-A10B (running 2026-04-29) если pass_2 ≥ 75% -- 122B становится альтернативный default для quality-critical workflows.

## Связано

- [README.md](README.md) -- обзор opencode
- [custom-agents-guide.md](custom-agents-guide.md) -- как делать custom agents для этих workflows
- [mcp-setup.md](mcp-setup.md) -- MCP-серверы для расширения функциональности
- [migration-guide.md](migration-guide.md) -- миграция Claude Code Teams в multi-agent через custom agents
- [../../../coding/benchmarks/](../../../coding/benchmarks/README.md) -- результаты на платформе
- [../../../inference/optimization-backlog.md](../../../inference/optimization-backlog.md) -- cache reuse status по моделям
- [../../../models/families/qwen3-coder.md](../../../models/families/qwen3-coder.md) -- Qwen3-Coder Next (default model)
- [../../../models/families/qwen35.md](../../../models/families/qwen35.md) -- Qwen3.5-122B-A10B (planner)
