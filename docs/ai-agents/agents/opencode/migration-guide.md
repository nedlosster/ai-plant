# Миграция с Claude Code на opencode

Practical guide для переезда с Claude Code на opencode. Покрывает: зачем мигрировать, mapping концепций (Skills/Hooks/Teams/Plugins/MCP/Routines), пошаговый чек-лист, что выигрывается / теряется при переходе.

## Зачем мигрировать

Три ключевые причины для перехода с Claude Code на opencode:

### 1. Privacy и compliance

Claude Code отправляет весь код в Anthropic API. Это блокер для:
- **Регулируемые отрасли** (финансы, медицина, defense)
- **GDPR/152-ФЗ** -- персональные данные не должны покидать инфраструктуру
- **Закрытые проекты** (NDA, government contracts)

opencode с локальным llama-server -- **полностью offline**, код никуда не уходит.

### 2. Cost

Claude Code:
- Pro: $20/мес
- Max: $200/мес
- Enterprise: pay-per-token (Opus 4.7 = $5/M input, $25/M output)

При активной разработке (Sub-agents Teams + heavy context use) -- $200-500/мес на пользователя.

opencode + локальный llama-server: **$0**. Аппаратные затраты (Strix Halo $2000-3000) окупаются за 6-12 месяцев vs Anthropic Pro.

### 3. Vendor lock-in

Claude Code привязан к Anthropic API. Если:
- Anthropic поменяет цены
- Anthropic заблокирует ваш аккаунт (4 апреля 2026 заблокировал OpenClaw users)
- Geopolitics ограничат доступ (РФ, Иран и т.д.)

-- ваш workflow ломается. opencode работает с любым OpenAI-compatible backend (cloud GPT/Gemini/Grok, local Qwen/Gemma/Llama). Vendor можно поменять за минуту.

## Сравнительная таблица фич

| Фича | Claude Code | opencode | Статус |
|------|-------------|----------|--------|
| **CLI режим** | да | да | паритет |
| **TUI** | да | да (Bubble Tea) | паритет |
| **IDE интеграция** | VS Code, JetBrains, web | нет | теряется |
| **Channels** (Telegram/Discord) | да (April 2026) | нет | теряется |
| **Computer Use** | да (через Anthropic API) | нет | теряется |
| **MCP support** | да | да | паритет |
| **Headless mode** | `claude run "..."` | `opencode run "..."` | паритет |
| **Sessions** | да (project-scoped) | да | паритет |
| **Tool use (bash, edit, read, etc)** | да | да | паритет |
| **Permissions model** | да | да (ask/allow/deny) | паритет |
| **Skills** | да (Anthropic-managed) | через custom agents | замена |
| **Hooks** | да (events) | нет | теряется |
| **Subagents** | да (parallel sub-agents) | через task tool + custom agents | замена |
| **Agent Teams** | да (Code Kit v5.0) | через multi-model orchestration | замена |
| **Plugins** | да (Anthropic marketplace) | через MCP | замена |
| **Routines** (cloud automation) | да (April 2026) | через cron + headless | workaround |
| **Models** | только Anthropic | любой OpenAI-compat | свобода |
| **Context** | до 1M (Opus 4.7) | зависит от модели (256K Coder Next, 1M YaRN на 122B) | паритет |
| **Стоимость** | $20-200/мес или per-token | **$0** | win opencode |
| **Privacy** | API → Anthropic | local | win opencode |
| **Open-source** | нет | MIT | win opencode |

## Mapping концепций

### Claude Code Skills → opencode custom agents

Claude Code Skills -- переиспользуемые "навыки" с собственным system prompt и tool permissions. Например, "code-reviewer" Skill анализирует PR и пишет отчёт.

**В opencode** аналог -- custom agent в `opencode.json`:

| Claude Code Skill | opencode custom agent |
|-------------------|------------------------|
| `~/.claude/skills/reviewer/SKILL.md` (markdown с metadata) | `opencode.json` agent + file `prompts/reviewer` (markdown в репо проекта) |
| Tool permissions в frontmatter | `tools` секция в opencode.json |
| Argument hint в metadata | inline в system prompt |
| User-invocable flag | `default_agent` в opencode.json |

**Пример переезда**:

Claude Code Skill `~/.claude/skills/reviewer/SKILL.md`:

```markdown
---
name: reviewer
description: Review code changes
allowed-tools: [Read, Grep, Glob]
---

You are a senior code reviewer. Find: bugs, security issues...
```

opencode эквивалент в `opencode.json`:

```json
"agent": {
  "reviewer": {
    "model": "llama-server/coder",
    "tools": { "read": true, "grep": true, "glob": true, "bash": false, "edit": false, "write": false },
    "prompt": "{file:./prompts/reviewer.md}"
  }
}
```

С file `prompts/reviewer` (markdown в репо проекта):

```
You are a senior code reviewer. Find: bugs, security issues, ...
```

Подробности -- в [custom-agents-guide.md](custom-agents-guide.md).

### Claude Code Hooks → нет (workaround)

Claude Code Hooks -- pre/post events (pre-tool-use, post-tool-use, user-prompt-submit) для guardrails: блокировать опасные операции, форматировать код после edit, audit log.

**В opencode** native hooks **не реализованы**. Workarounds:

1. **Wrapper script вокруг opencode**:

```bash
#!/bin/bash
# pre-flight: проверка что repo чистый
if ! git diff --quiet; then
    echo "ERROR: uncommitted changes. Commit or stash first."
    exit 1
fi

opencode "$@"

# post-flight: typecheck после агента
npm run typecheck
```

2. **Permissions = ask** для опасных операций (bash, write) -- user видит каждое действие

3. **MCP-сервер с custom правилами** -- кастомный сервер может проверять file paths перед write

4. **Git pre-commit hooks** -- срабатывают если agent попытается коммитить

**Что теряется**: атомарная связь "perform action → check rule → block если violation". Workarounds не такие плотные.

### Claude Code Subagents → task tool + custom agents

Claude Code subagents -- параллельные специализированные агенты внутри одной сессии. Например, основной агент делегирует "explore code" под-агенту, ждёт результат, продолжает.

**В opencode** есть `task` tool, который аналогично запускает sub-agent. Но для **multi-агентной координации** лучше использовать custom agents:

```json
"agent": {
  "explorer": {
    "model": "llama-server/fast",
    "tools": { "read": true, "grep": true, "glob": true, "bash": false, "edit": false }
  },
  "coder": {
    "model": "llama-server/coder",
    "tools": { "read": true, "write": true, "edit": true, "bash": true }
  }
}
```

Workflow в TUI:

```
[user]: explore the codebase, find all React components
[opencode/coder]: <calls task tool with agent=explorer>
[opencode/explorer]: ... ищет компоненты, возвращает список ...
[opencode/coder]: <получает результат, продолжает с найденными файлами>
```

См. [advanced-workflows.md](advanced-workflows.md) для multi-agent паттернов.

### Claude Code Agent Teams → multi-model orchestration

Claude Code Agent Teams (Code Kit v5.0, March 2026) -- декларативный YAML для оркестрации команды агентов параллельно. Например, planner + 3 coder'a одновременно работают на разных частях задачи.

**В opencode** native Teams **не реализованы**. Аналог:

1. **Multi-model orchestration через custom agents** (см. [custom-agents-guide.md](custom-agents-guide.md)):

```json
"agent": {
  "planner": { "model": "llama-server/quality", "prompt": "..." },
  "coder-1": { "model": "llama-server/coder", "prompt": "..." },
  "coder-2": { "model": "llama-server/coder", "prompt": "..." }
}
```

2. **Параллельные `opencode run` процессы** -- bash скрипт запускает несколько opencode параллельно, каждый со своим agent и task:

```bash
# decompose.sh
opencode run --agent coder-1 "implement frontend" &
opencode run --agent coder-2 "implement backend" &
opencode run --agent coder-3 "implement tests" &
wait
```

3. **Sequential pipeline через `--cont`**:

```bash
opencode --agent planner "design feature X" > plan.md
opencode --agent executor --cont "implement plan.md"
```

**Что теряется**: native Teams декларативный YAML, parallel coordination с shared context. Workarounds сложнее.

### Claude Code Plugins → MCP servers

Claude Code Plugins -- Anthropic marketplace расширений. opencode использует **MCP** для той же роли. Большинство Claude Code Plugins имеют MCP-эквиваленты:

| Claude Code Plugin | opencode MCP-сервер |
|--------------------|----------------------|
| Linear plugin | `mcp-server-linear` |
| Jira plugin | community MCP server |
| GitHub plugin | `mcp-server-github` |
| Postgres plugin | `@modelcontextprotocol/server-postgres` |
| Slack plugin | community MCP server |
| Notion plugin | community MCP |

См. [mcp-setup.md](mcp-setup.md) для подробностей.

### Claude Code MCP → opencode MCP (тот же протокол)

opencode реализует **тот же MCP протокол** что Claude Code (Anthropic это создатели стандарта, ноябрь 2024).

Конфигурация немного отличается:

**Claude Code** (`.claude/settings.json`):
```json
"mcpServers": {
  "context7": { "command": "npx", "args": ["-y", "@upstash/context7-mcp@latest"] }
}
```

**opencode** (`opencode.json`):
```json
"mcp_servers": {
  "context7": { "command": "npx", "args": ["-y", "@upstash/context7-mcp@latest"] }
}
```

Различия: snake_case vs camelCase, и одна секция в `opencode.json` vs возможно несколько мест в Claude Code (project + global). MCP-серверы **сами не меняются** -- они одинаковые.

### Claude Code Routines → cron + opencode --headless

Claude Code Routines (April 2026) -- scheduled agent runs в Anthropic cloud. Например, "каждый день в 9 утра проверить новые PR и оставить review-комментарии".

**В opencode** аналог через локальный cron:

```bash
# crontab -e
0 9 * * * cd /path/to/repo && OPENAI_BASE_URL=http://localhost:8081/v1 \
  opencode run --agent reviewer "review new PRs since yesterday" \
  >> /var/log/opencode-routine.log 2>&1
```

С MCP github-сервером агент может реально оставить комментарии:

```json
"agent": {
  "pr-reviewer": {
    "model": "llama-server/coder",
    "tools": { "read": true },
    "prompt": "Review new PRs. Add comments via github MCP. Format: ..."
  }
}
```

**Что выигрывается**: всё локально, никаких cloud затрат, контроль над расписанием.

**Что теряется**: cloud reliability (компьютер должен быть включён), нет встроенной queue/retry логики (нужно делать в bash).

## Пошаговый чек-лист миграции

### Phase 1: подготовка (1 час)

- [ ] Установить opencode: `curl -fsSL https://opencode.ai/install | bash`
- [ ] Запустить llama-server с подходящей моделью (Qwen3-Coder Next через `vulkan/preset/qwen-coder-next.sh -d`)
- [ ] Проверить healthcheck: `curl http://localhost:8081/v1/models`
- [ ] Создать `opencode.json` в корне основного проекта (минимальный, см. [README.md](README.md))
- [ ] Тест: `opencode run "hello"` -- должен ответить через локальную модель

### Phase 2: миграция Skills → custom agents (2-4 часа)

- [ ] Сделать `mkdir -p prompts/`
- [ ] Скопировать каждый Skill (`~/.claude/skills/<name>/SKILL.md`) в `prompts/<name>.md`
- [ ] Очистить от Claude Code-specific frontmatter (`name`, `description`, `allowed-tools`, `argument-hint`)
- [ ] Для каждого Skill добавить запись в `opencode.json` agent секцию с tool permissions из `allowed-tools`
- [ ] Протестировать каждый агент: `opencode run --agent <name> "<typical task>"`
- [ ] Сравнить вывод с Claude Code Skill -- если результат значимо хуже, использовать большую модель в этом агенте

### Phase 3: миграция MCP servers (1-2 часа)

- [ ] Перенести `mcpServers` из Claude Code config в `mcp_servers` в `opencode.json` (snake_case!)
- [ ] Убедиться что env-vars экспортированы (GITHUB_TOKEN, DATABASE_URL и т.д.)
- [ ] Запустить opencode с verbose: `opencode --verbose` -- должен показать "Loaded MCP server: ..."
- [ ] Протестировать каждый MCP-сервер: задать модели вопрос, требующий конкретного tool

### Phase 4: workarounds для отсутствующих фич (variable)

- [ ] **Hooks** -- если использовали git-guardrails hooks: переписать как git pre-commit
- [ ] **Hooks для format-after-edit** -- запустить prettier/black/rustfmt в bash после opencode сессии
- [ ] **Hooks для secret-scanning** -- использовать gitleaks как git pre-commit
- [ ] **Routines** -- переписать на crontab с `opencode run --headless`
- [ ] **Agent Teams playbooks** -- переписать как bash-скрипт с параллельными `opencode run`

### Phase 5: тестирование (1 неделя)

- [ ] Прожить рабочую неделю с opencode на основных задачах
- [ ] Записать кейсы где результат значимо хуже Claude Code -- они выявят что нужно адаптировать
- [ ] Сравнить time-to-completion на типичных задачах
- [ ] Если нашли проблемные кейсы -- скорректировать system prompts или модель
- [ ] При необходимости -- использовать Claude Code как fallback для самых сложных задач

### Phase 6: финализация

- [ ] Удалить Claude Code config (если не нужен fallback)
- [ ] Закоммитить `opencode.json` + `prompts/` в git проекта
- [ ] Документировать team-specific patterns в `CLAUDE.md` -> `OPENCODE.md` (или просто README)
- [ ] Отписаться от Claude Pro/Max если не нужен

## Что выигрывается

| Аспект | Win |
|--------|-----|
| **Стоимость** | $0 vs $20-500/мес |
| **Privacy** | Всё локально, нет API-зависимости |
| **Vendor freedom** | Любая OpenAI-compatible модель -- cloud или local |
| **Open-source** | MIT, можно форкать/модифицировать |
| **Latency** | Local -- нет network round-trip (минус response time generation) |
| **Compliance** | GDPR/152-ФЗ-friendly из коробки |
| **No rate limits** | Сколько хватает железа -- столько генерируешь |
| **Headless friendly** | Go binary, отличная работа в SSH/CI |

## Что теряется

| Аспект | Loss | Workaround |
|--------|------|------------|
| **IDE интеграция** | Нет VS Code/JetBrains plugin | [cline](../cline.md) или [continue-dev](../continue-dev.md) для IDE |
| **Computer Use** | Нет | [Cline](../cline.md) с Anthropic API |
| **Channels** (Telegram/Discord) | Нет | [openclaw](../openclaw/README.md) с native messengers |
| **Native Hooks** | Нет events API | git hooks + wrapper scripts |
| **Native Teams** | Нет parallel orchestration | bash скрипт с параллельными `opencode run` |
| **Routines (cloud)** | Нет | crontab + headless |
| **Plugins marketplace** | Только MCP | большинство есть в MCP-форме |
| **Качество** (Opus 4.7 90%+ pass) | Local Qwen3-Coder Next ~70% | Использовать Claude Code как fallback для критичных задач |

## Кому НЕ подходит миграция

| Сценарий | Почему |
|----------|--------|
| **Computer Use критичен** | opencode не имеет, [Cline](../cline.md) или [openclaw](../openclaw/README.md) |
| **Сильная зависимость от Anthropic Plugins** | Не все имеют MCP-эквиваленты |
| **Качество > всё**, бюджет неограничен | Opus 4.7 на 17-22pp лучше open-weight на платформе |
| **Нет hardware для local inference** | Нужен Strix Halo / Mac M3 Ultra / Datacenter GPU |
| **Critical path workflows** где сбои недопустимы | Local stack менее надёжен чем Anthropic uptime |
| **Enterprise support важен** | Anthropic имеет SLA, opencode -- community-only |

## Hybrid стратегия

Не обязательно мигрировать **полностью**. Можно использовать **оба клиента параллельно**:

- **opencode + Qwen3-Coder Next** -- daily routine, privacy-sensitive, large refactors
- **Claude Code + Opus 4.7** -- сложные дизайн-вопросы, frontend (95% Faros), production-critical fixes

Конфигурация: `~/.claude/settings.json` для Claude Code остаётся, `opencode.json` per-project для opencode. Используешь нужный CLI в зависимости от задачи.

## Связано

- [README.md](README.md) -- обзор opencode
- [custom-agents-guide.md](custom-agents-guide.md) -- замена Skills через custom agents
- [mcp-setup.md](mcp-setup.md) -- замена Plugins через MCP
- [advanced-workflows.md](advanced-workflows.md) -- замена Teams через multi-model orchestration
- [../claude-code/README.md](../claude-code/README.md) -- Claude Code обзор
- [../claude-code/skills-guide.md](../claude-code/skills-guide.md) -- что такое Skills (для миграции)
- [../claude-code/hooks-guide.md](../claude-code/hooks-guide.md) -- что такое Hooks (что теряется)
- [../claude-code/agent-teams.md](../claude-code/agent-teams.md) -- что такое Teams
- [../claude-code/mcp-setup.md](../claude-code/mcp-setup.md) -- mcp в Claude Code (тот же протокол)
