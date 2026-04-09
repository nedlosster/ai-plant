# opencode (Anomaly Co, 2024-2026)

> Open-source CLI агент с TUI на Go (Bubble Tea), MIT, любые OpenAI-совместимые модели включая локальные.

**Тип**: CLI с TUI (terminal UI)
**Лицензия**: MIT
**Backend**: OpenAI-compatible (любые провайдеры)
**Совместим с локальным llama-server**: **да** -- основной use case на платформе
**Цена**: Free open-source

## Обзор

opencode -- открытая альтернатива Claude Code с фокусом на работу с **любыми моделями** через OpenAI-compatible API. Написан на Go (TUI на Bubble Tea), что делает его быстрым и легковесным. **На нашей платформе используется как основной CLI-агент** -- работает в паре с локальным llama-server (Qwen3-Coder Next через `vulkan/preset/qwen-coder-next.sh`).

Главная философия -- **provider agnostic**: opencode не привязан к одному вендору. Любая модель с OpenAI-совместимым endpoint -- от ChatGPT до локального llama.cpp -- работает одинаково.

В отличие от [Claude Code](claude-code.md) (привязан к Anthropic) и [Cline](cline.md) (только VS Code), opencode -- **CLI-only**, что делает его отличным выбором для:
- Локальных моделей с приватностью
- Удалённой работы через SSH
- Скриптинга и автоматизации
- Минимальных setup'ов без IDE

## Возможности

- **TUI в терминале** -- chat интерфейс с подсветкой
- **Tool use** -- bash, read, write, edit, grep, glob, webfetch, task (sub-agents)
- **Agents** -- предопределённые агенты (build, plan) + кастомные через `opencode.json`
- **MCP** -- поддержка Model Context Protocol серверов
- **Permissions** -- ask/allow/deny per-tool, гранулярный контроль
- **OpenAI-compatible** -- любой провайдер через `OPENAI_BASE_URL`
- **Sessions** -- сохранение контекста между запусками
- **Cache reuse** -- эффективная работа с локальным llama-server (`--cache-reuse 256`)
- **Custom prompts** -- per-agent system prompts через файлы

## Сильные стороны

- **Provider agnostic** -- любые OpenAI-compatible модели
- **CLI-first** -- идеально для удалённой работы и скриптинга
- **Лёгкий** -- Go binary, быстрый старт
- **MIT** -- минимум ограничений
- **Хорошая поддержка локальных моделей** -- основной use case на нашей платформе
- **Custom agents** -- легко делать специализированные режимы
- **Permissions** -- безопасность по умолчанию
- **Минимальный setup** -- буквально `OPENAI_BASE_URL=... opencode`

## Слабые стороны / ограничения

- **Только CLI/TUI** -- нет IDE интеграции (для IDE -- [cline](cline.md), [continue-dev](continue-dev.md))
- **Нет multi-agent orchestration** уровня [kilo-code](kilo-code.md) Orchestrator или Claude Code multi-agent
- **Зависит от качества модели** -- на слабых моделях работает посредственно
- **Меньше готовых MCP серверов** чем у Claude Code
- **Нет computer use** -- только code-related операции

## Базовые сценарии

- `opencode "say hi"` -- быстрый чат с моделью
- `opencode` (interactive) → "напиши тесты для src/auth.ts"
- "Объясни архитектуру этого проекта"
- "Найди баг в логике обработки X"
- "Рефактор файла с применением паттерна Y"

## Сложные сценарии

- **Длинная агентная сессия для opencode на платформе**:
  - llama-server с Qwen3-Coder Next (256K контекст)
  - opencode подключён через `OPENAI_BASE_URL=http://192.168.1.77:8081/v1`
  - Plan agent → разработать архитектуру
  - Build agent → реализовать
  - Кастомные skills для повторяющихся операций
- **Custom agents** через `opencode.json`:
  ```json
  {
    "agent": {
      "reviewer": {
        "model": "llama-server/default",
        "tools": {"bash": false, "edit": false, "read": true},
        "prompt": "{file:./prompts/reviewer.txt}"
      }
    }
  }
  ```
- **MCP-driven workflows** -- Context7 для актуальной документации, GitHub MCP для PR
- **Long-context refactoring** -- репо целиком в 256K контекст Qwen3-Coder Next

## Установка / запуск

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

## Конфигурация

`opencode.json` в корне проекта:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "llama-server/default",
  "provider": {
    "llama-server": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama.cpp",
      "options": {
        "baseURL": "{env:OPENAI_BASE_URL}",
        "apiKey": "{env:OPENAI_API_KEY}"
      },
      "models": {
        "default": {
          "name": "llama-server default",
          "limit": { "context": 256000, "output": 8192 }
        }
      }
    }
  },
  "permission": {
    "edit": "ask",
    "write": "ask",
    "bash": "ask"
  },
  "default_agent": "build",
  "agent": {
    "build": {
      "model": "llama-server/default",
      "tools": { "bash": true, "write": true, "edit": true, "read": true }
    },
    "plan": {
      "model": "llama-server/default",
      "tools": { "bash": false, "write": false, "edit": false, "read": true }
    }
  }
}
```

Подробности про configuration, customization, MCP, strategies -- см. ранее существовавшие микро-доки в `docs/use-cases/coding/opencode/` (теперь консолидированы здесь).

## Бенчмарки

opencode сам по себе не бенчмаркируется -- зависит от модели. На платформе с Qwen3-Coder Next:
- Backend: llama-server Vulkan, 256K контекст
- Skорость: 53 tok/s
- SWE-bench (модели): 70.6%

## Анонсы и открытия

- **2026-Q2** -- интеграция с Qwen3.6-Plus через OpenAI-compatible endpoint
- **2026-Q1** -- улучшение MCP поддержки, токен parser для Gemma 4
- **2025-Q4** -- Custom agents через `opencode.json`
- **2025** -- первый публичный релиз, быстрый рост популярности

## Ссылки

- [Официальный сайт](https://opencode.ai/)
- [GitHub: anomalyco/opencode](https://github.com/anomalyco/opencode)
- [Документация](https://opencode.ai/docs)
- [Schema](https://opencode.ai/config.json)

## Связано

- **Альтернативы (CLI)**: [aider](aider.md), [qwen-code](qwen-code.md), [claude-code](claude-code.md) для commercial
- **Альтернативы (IDE)**: [cline](cline.md), [kilo-code](kilo-code.md), [continue-dev](continue-dev.md)
- **Лучшие модели для пары**: [qwen3-coder](../../models/families/qwen3-coder.md) (Next 80B-A3B на платформе), [qwen36](../../models/families/qwen36.md) когда выйдет
- **Платформа**: [coding.md](../../models/coding.md), пресеты `scripts/inference/vulkan/preset/qwen-coder-next.sh`
- **Концепты**: [../README.md](../README.md)
