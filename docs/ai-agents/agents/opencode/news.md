# opencode -- news и mental model

Хроника релизов и важных событий в opencode (sst/opencode + Anomaly Co), плюс ментальная модель работы для понимания, как продукт устроен на 2026 год.

## Mental model: три механизма opencode

Чтобы эффективно работать с opencode, нужно понимать три ключевых концепции, на которых построена вся архитектура. Они проще чем "6 механизмов Claude Code" (Skills, Subagents, Hooks, MCP, Plugins, Teams), но дают сопоставимую гибкость через композицию.

### 1. Provider-agnostic providers

В отличие от Claude Code (привязан к Anthropic API), opencode -- **OpenAI-compatible client**. Это даёт радикальную свободу выбора backend:

```json
"provider": {
  "llama-server": { ... baseURL: "http://localhost:8081/v1" ... },
  "anthropic": { ... },
  "openai": { ... },
  "groq": { ... }
}
```

Каждый provider реализует один и тот же interface (через `@ai-sdk/openai-compatible`). Модели одного provider'а делятся на logical "models" с разными лимитами контекста / output.

**Следствие**: миграция backend'а -- это правка одной секции в `opencode.json`. Можно тестировать модели side-by-side, не меняя всю инфраструктуру.

### 2. Custom agents через opencode.json

Любой "режим работы" в opencode -- это **custom agent** с фиксированным набором tool permissions, system prompt и моделью. По дефолту есть два встроенных агента:

- **build** -- полный доступ (write/edit/bash) для активной разработки
- **plan** -- read-only для проектирования без изменений

Кастомные агенты добавляются как top-level записи в `opencode.json`:

```json
"agent": {
  "reviewer": {
    "model": "llama-server/default",
    "tools": { "bash": false, "edit": false, "write": false, "read": true },
    "prompt": "{file:./prompts/reviewer.txt}"
  },
  "architect": {
    "model": "llama-server/quality",
    "tools": { "read": true, "write": false, "edit": false, "bash": false },
    "prompt": "{file:./prompts/architect.txt}"
  }
}
```

**Следствие**: специализированные агенты, multi-model orchestration, plan-and-execute паттерн -- всё через композицию custom agents. Это **универсальный механизм** заменяющий Skills + Hooks + Teams Claude Code.

Подробности -- в [custom-agents-guide.md](custom-agents-guide.md).

### 3. MCP integration

opencode реализует **Model Context Protocol** (Anthropic-стандарт, открыт ноябрь 2024). Любой MCP-сервер (filesystem, github, postgres, context7, playwright) подключается секцией `mcp_servers` в `opencode.json`:

```json
"mcp_servers": {
  "context7": {
    "command": "npx",
    "args": ["-y", "@upstash/context7-mcp@latest"]
  },
  "github": { "command": "uvx", "args": ["mcp-server-github"] }
}
```

**Следствие**: вся MCP экосистема (97 миллионов установок MCP-серверов на март 2026) доступна opencode без переделки. Это closes gap с Claude Code Plugins.

Подробности -- в [mcp-setup.md](mcp-setup.md).

## Хроника релизов

Свежие сверху.

### 2026-Q2

#### Apr 2026 -- интеграция с Qwen3.6-Plus / OpenClaw v2026.4.15 ставит стандарт

- **Apr 2026** -- opencode добавил первоклассную интеграцию с Qwen3.6-Plus (Alibaba) через OpenAI-compatible endpoint. На платформе пока недоступно (Plus -- API-only), но опции для cloud users готовы
- **Apr 15** -- [OpenClaw v2026.4.15 "Dreaming"](../../news.md#apr-15--openclaw-v202641?5-dreaming-release-347k-github-stars-native-opus-47) ставит новый стандарт security: 347K GitHub stars (most starred ever), native Claude Opus 4.7, advanced memory management. opencode остаётся быстрее и легче, но OpenClaw перетягивает enterprise сегмент
- **Apr 2026** -- партнёрство с llama-server community: bug fix серия для Vulkan backend integration на Strix Halo

#### Apr 2026 -- ответы на блокировку Claude Pro

После [4 апреля 2026 -- Anthropic заблокировал Claude Pro/Max в third-party tools](../../news.md), миграция пользователей в opencode дала рост:

- Stargazers +30% за месяц
- Активных Discord/Slack каналов -- удвоилось
- Новые providers contributed (xAI Grok, DeepSeek, MiniMax M2.5)

### 2026-Q1

#### Jan-Mar 2026 -- улучшение MCP поддержки

- **Jan 2026** -- стабилизация MCP client'а (фиксы для длинных tool calls, timeouts)
- **Feb 2026** -- token parser для Gemma 4 (специфичный JSON формат tool calls)
- **Mar 2026** -- поддержка `--stream` для real-time agent output

#### Mar 2026 -- Headless mode для CI/CD

`opencode run "..."` теперь полностью non-interactive: exit code = success/failure, stdout = agent output. Открыло возможности CI integration (PR review через GitHub Actions).

### 2025-Q4

#### Q4 2025 -- Custom agents через opencode.json

Главный релиз 2025: возможность определять кастомные агенты через декларативный JSON. До этого opencode имел только два режима (interactive + headless) и одну модель в env-vars.

- Per-agent permissions
- Per-agent system prompts (inline или через `{file:...}` template)
- Per-agent model selection
- Готовые шаблоны (build, plan, reviewer)

Это превратило opencode из "просто CLI" в **расширяемый agent platform**.

### 2025-Q3

#### Q3 2025 -- MCP support из коробки

opencode стал одним из первых open-source CLI с native MCP. До этого все non-Anthropic клиенты требовали отдельный MCP-bridge.

#### Q3 2025 -- Sessions persistence

Сохранение state между запусками (`opencode resume <session-id>`). Раньше каждый запуск был tabula rasa.

### 2025

#### Mid 2025 -- первый публичный релиз

Первая stable версия. Установка через `curl ... | bash`, работа через TUI Bubble Tea. Сразу поддержка OpenAI, Anthropic (через прокси), локальный llama.cpp.

Быстрый рост популярности благодаря community: ChatGPT/Claude Code альтернатива в одном binary.

## Текущее состояние (актуально на 2026-04-29)

| Метрика | Значение |
|---------|----------|
| Версия | определяется через `opencode --version` |
| Repo | [github.com/anomalyco/opencode](https://github.com/anomalyco/opencode) |
| Stargazers | растёт после блокировки Claude Pro в third-party tools (апрель 2026) |
| Активные contributors | широкий круг open-source разработчиков |
| Лицензия | MIT |
| Стек | Go (Bubble Tea TUI) + AI SDK (TypeScript) |

## Что отслеживать

| Источник | Что проверять | Периодичность |
|----------|---------------|---------------|
| [GitHub releases](https://github.com/anomalyco/opencode/releases) | Новые providers, MCP fixes, custom agents features | Раз в 2 недели |
| [opencode Pull Requests](https://github.com/anomalyco/opencode/pulls) | Идеи в community до релиза | Раз в месяц |
| [opencode.ai/docs](https://opencode.ai/docs) | Изменения в schema (`opencode.json`) | При обновлении |
| MCP ecosystem ([modelcontextprotocol.io](https://modelcontextprotocol.io)) | Новые MCP-серверы для подключения | Раз в месяц |
| [Reddit r/LocalLLaMA](https://reddit.com/r/LocalLLaMA) | Community workflows с opencode + локальные модели | Раз в 2 недели |

## Связано

- [README.md](README.md) -- обзор opencode
- [custom-agents-guide.md](custom-agents-guide.md) -- deep dive в opencode.json
- [mcp-setup.md](mcp-setup.md) -- MCP-серверы
- [migration-guide.md](migration-guide.md) -- переход с Claude Code
- [advanced-workflows.md](advanced-workflows.md) -- продвинутые сценарии
- [../../news.md](../../news.md) -- общая хроника AI-агентов
- [../claude-code/news.md](../claude-code/news.md) -- хроника Claude Code для контекста
