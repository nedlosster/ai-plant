# opencode (Anomaly Co, 2024-2026)

> Open-source CLI агент с TUI на Go (Bubble Tea), MIT, любые OpenAI-совместимые модели включая локальные. Первый use case на нашей платформе для agent-coding с Qwen3-Coder Next 80B-A3B через llama-server.

**Тип**: CLI с TUI (terminal UI)
**Лицензия**: MIT
**Backend**: OpenAI-compatible (любые провайдеры)
**Совместим с локальным llama-server**: **да** -- основной use case на платформе
**Цена**: Free open-source

## Файлы раздела

| Файл | О чём |
|------|-------|
| [news.md](news.md) | Хроника релизов 2024-2026, mental model "трёх механизмов": Provider-agnostic, Custom agents, MCP integration. Что отслеживать |
| [custom-agents-guide.md](custom-agents-guide.md) | Deep dive в `opencode.json`: 3 канонических паттерна (Reviewer, Architect, Plan-and-execute), multi-model orchestration, permission profiles, antipatterns |
| [mcp-setup.md](mcp-setup.md) | Настройка MCP-серверов (filesystem, github, postgres, context7, playwright), написание собственного, debug, performance |
| [migration-guide.md](migration-guide.md) | Миграция с Claude Code на opencode: mapping концепций (Skills/Hooks/Teams/Plugins/MCP/Routines), пошаговый чек-лист, что выигрывается/теряется |
| [advanced-workflows.md](advanced-workflows.md) | Простые и сложные сценарии: long-context refactoring, multi-agent через custom agents, multi-model, CI integration, cache-reuse оптимизация |

## Обзор

opencode -- открытая альтернатива Claude Code с фокусом на работу с **любыми моделями** через OpenAI-compatible API. Написан на Go (TUI на Bubble Tea), что делает его быстрым и легковесным. **На нашей платформе используется как основной CLI-агент** -- работает в паре с локальным llama-server (Qwen3-Coder Next через `vulkan/preset/qwen-coder-next.sh`).

Главная философия -- **provider agnostic**: opencode не привязан к одному вендору. Любая модель с OpenAI-совместимым endpoint -- от ChatGPT до локального llama.cpp -- работает одинаково.

В отличие от [Claude Code](../claude-code/README.md) (привязан к Anthropic) и [Cline](../cline.md) (только VS Code), opencode -- **CLI-only**, что делает его отличным выбором для:

- Локальных моделей с приватностью
- Удалённой работы через SSH
- Скриптинга и автоматизации
- Минимальных setup'ов без IDE

## Возможности

- **TUI в терминале** -- chat интерфейс с подсветкой
- **Tool use** -- bash, read, write, edit, grep, glob, webfetch, task (sub-agents)
- **Custom agents** -- предопределённые (build, plan) + кастомные через `opencode.json` -- см. [custom-agents-guide.md](custom-agents-guide.md)
- **MCP** -- поддержка Model Context Protocol серверов -- см. [mcp-setup.md](mcp-setup.md)
- **Permissions** -- ask/allow/deny per-tool, гранулярный контроль
- **OpenAI-compatible** -- любой провайдер через `OPENAI_BASE_URL`
- **Sessions** -- сохранение контекста между запусками
- **Multi-model orchestration** -- разные модели для разных агентов (planner на 122B-A10B, executor на Coder Next) -- см. [custom-agents-guide.md](custom-agents-guide.md)
- **Headless mode** -- `opencode run "..."` для CI/CD интеграции

## Сильные стороны

- **Provider agnostic** -- любые OpenAI-compatible модели, не привязан к вендору
- **CLI-first + Go binary** -- идеально для удалённой работы по SSH, минимальный overhead
- **Лучшая поддержка локальных моделей** -- основной use case на нашей платформе (Qwen3-Coder Next через llama-server Vulkan)
- **MIT** -- минимум ограничений, можно форкать и кастомизировать
- **Custom agents** -- легко делать специализированные режимы (reviewer, architect, plan-and-execute)
- **Permissions model по умолчанию** (ask/allow/deny) -- security без extra setup
- **Минимальный setup** -- буквально `OPENAI_BASE_URL=... opencode`
- **Multi-model оркестрация** -- разные модели для разных агентов через `opencode.json`

## Слабые стороны / ограничения

- **Только CLI/TUI** -- нет IDE интеграции (для IDE -- [cline](../cline.md), [continue-dev](../continue-dev.md))
- **Нет native multi-agent Teams** -- мульти-агент через custom agents с разными моделями (workaround, не из коробки как у Claude Code)
- **Нет Hooks** -- pre/post-action triggers нужно делать через wrapper-script
- **Зависит от качества модели** -- на слабых моделях работает посредственно
- **Нет Computer Use** -- только code-related операции
- **Меньше готовых MCP-серверов** чем у Claude Code (но протокол тот же)
- **Нет Cloud Routines** -- scheduled agent runs делаются через cron + headless mode

## Когда брать opencode

| Use case | Почему |
|----------|--------|
| **Локальный agent-coding с приватностью** ⭐ | Любая модель через llama-server, всё локально, $0 |
| **Удалённая работа через SSH** | Go binary, минимальный overhead, отлично работает в headless TTY |
| **CI/CD автоматизация** | `opencode run "..."` headless mode для PR review, automated refactoring |
| **Multi-model оркестрация** | Разные модели для planner и executor через custom agents |
| **Open-source compliance** | MIT, аудит исходников, можно форкать |
| **Миграция с Claude Code из-за cost/privacy** | См. [migration-guide.md](migration-guide.md) |

## Установка / минимальный config

```bash
# Установка (Linux/Mac)
curl -fsSL https://opencode.ai/install | bash

# Подключение к локальному llama-server
export OPENAI_BASE_URL=http://192.168.1.77:8081/v1
export OPENAI_API_KEY=local

cd /path/to/project
opencode

# Один shot
opencode run "fix the bug in auth.ts"
```

Минимальный `opencode.json` в корне проекта:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "llama-server/default",
  "provider": {
    "llama-server": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "{env:OPENAI_BASE_URL}",
        "apiKey": "{env:OPENAI_API_KEY}"
      },
      "models": {
        "default": { "name": "llama-server", "limit": { "context": 256000, "output": 8192 } }
      }
    }
  },
  "permission": { "edit": "ask", "write": "ask", "bash": "ask" }
}
```

Полная анатомия конфигурации -- в [custom-agents-guide.md](custom-agents-guide.md).

## Бенчмарки

opencode сам по себе не бенчмаркируется -- зависит от модели. На платформе Strix Halo с Qwen3-Coder Next через `vulkan/preset/qwen-coder-next.sh` (порт 8081):

| Метрика | Значение |
|---------|----------|
| Backend | llama-server Vulkan |
| Модель | Qwen3-Coder Next 80B-A3B Q4_K_M (~45 GiB) |
| Контекст | 256K native |
| **Tg на платформе** | 53 tok/s |
| **Aider Polyglot pass_2** | **68.0%** на 178/195 (наш full прогон 2026-04-27, см. [coding/benchmarks/runs/2026-04-27-aider-full-qwen-coder-next.md](../../../coding/benchmarks/runs/2026-04-27-aider-full-qwen-coder-next.md)) |
| **SWE-bench Verified** (модель) | 70.6% (Qwen-reported) |

Для сравнения с frontier closed-weight (Opus 4.6/4.7 ~85-90% pass_2) -- разрыв ~17-22pp при цене $0 vs $200+/мес.

## Анонсы и открытия

См. [news.md](news.md) -- полная хроника релизов 2024-2026.

Краткий summary последних событий:

- **2026-Q2** -- интеграция с Qwen3.6-Plus через OpenAI-compatible endpoint, OpenClaw v2026.4.15 ставит новый стандарт security
- **2026-Q1** -- улучшение MCP поддержки, токен parser для Gemma 4
- **2025-Q4** -- Custom agents через `opencode.json`
- **2025** -- первый публичный релиз, быстрый рост популярности

## Ссылки

- [Официальный сайт](https://opencode.ai/)
- [GitHub: anomalyco/opencode](https://github.com/anomalyco/opencode)
- [Документация](https://opencode.ai/docs)
- [Schema](https://opencode.ai/config.json)

## Связано

- **Альтернативы (CLI)**: [aider](../aider.md), [qwen-code](../qwen-code.md), [claude-code](../claude-code/README.md) commercial, [openclaw](../openclaw/README.md) open-source heavy
- **Альтернативы (IDE)**: [cline](../cline.md), [kilo-code](../kilo-code.md), [continue-dev](../continue-dev.md)
- **Лучшие модели для пары**: [qwen3-coder](../../../models/families/qwen3-coder.md) (Next 80B-A3B), [qwen35](../../../models/families/qwen35.md) (122B-A10B как planner), [qwen36](../../../models/families/qwen36.md) (35B-A3B как daily)
- **Платформа**: [coding.md](../../../models/coding.md), preset [`scripts/inference/vulkan/preset/qwen-coder-next.sh`](../../../../scripts/inference/vulkan/preset/qwen-coder-next.sh)
- **Бенчмарки**: [coding/benchmarks/](../../../coding/benchmarks/README.md), [optimization-backlog.md](../../../inference/optimization-backlog.md) (cache reuse status)
- **Концепты**: [../../README.md](../../README.md), [../../trends.md](../../trends.md), [../../news.md](../../news.md)
