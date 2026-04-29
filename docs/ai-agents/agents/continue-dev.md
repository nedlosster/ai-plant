# Continue.dev (Continue, 2023-2026)

> Open-source IDE расширение (VS Code/JetBrains) с FIM-фокусом, лучший выбор для local llama-server FIM autocomplete.

**Тип**: VS Code + JetBrains extension
**Лицензия**: Apache 2.0
**Backend**: Multi-provider (OpenAI / Anthropic / OpenAI-compatible / local)
**Совместим с локальным llama-server**: **да** -- основной use case для FIM
**Цена**: Free open-source

## Обзор

Continue.dev -- старейшее и самое популярное open-source IDE расширение для AI-кодинга. **Поддерживает VS Code и JetBrains** (один из немногих с обоими). Apache 2.0, активно развивается с 2023.

Главный фокус -- **inline FIM autocomplete** через локальные модели. На нашей платформе это идеальная пара с **Qwen2.5-Coder 1.5B** через FIM endpoint -- мгновенный отклик (120 tok/s) и хорошее качество автодополнения. Также поддерживает chat mode, agent mode и MCP.

В отличие от [Cursor](cursor.md) (закрытый, своё IDE), [Cline](cline.md) (только agent mode), [Kilo Code](kilo-code.md) (новый агент с Orchestrator), Continue.dev -- **универсальный**: FIM + chat + agent в одном расширении, для любой IDE.

## Возможности

- **Inline FIM autocomplete** -- самый быстрый при использовании с локальной 1.5B моделью
- **Chat mode** -- классический чат с моделью + контекст
- **Agent mode** -- multi-file edits и tool use
- **VS Code + JetBrains** -- поддержка обеих IDE
- **Multi-provider** -- OpenAI, Anthropic, OpenRouter, Ollama, llama.cpp, любой OpenAI-compatible
- **Custom commands** -- свои slash-команды через config
- **Context providers** -- @-references на файлы, папки, документы, GitHub PR
- **MCP support** -- подключение MCP-серверов
- **Local-first** -- хорошо документированный setup для локальных моделей

## Сильные стороны

- **Лучший FIM с локальными моделями** -- идеально с Qwen2.5-Coder 1.5B
- **VS Code + JetBrains** -- единственный из топа с обеими IDE
- **Apache 2.0** -- полная свобода
- **Local-first философия** -- не привязан к облачному провайдеру
- **Context providers** -- удобная система @-references
- **Конфигурация через JSON/YAML** -- легко версионировать
- **Активная разработка** -- регулярные релизы
- **Зрелая экосистема** -- много готовых конфигов и community-кастомизаций

## Слабые стороны / ограничения

- **Agent mode менее развит** чем у Cline или Kilo Code
- **UI в VS Code иногда неконсистентный** -- зависит от обновлений
- **Документация догоняет фичи**
- **Slower automatic context** -- иногда нужно явно указывать @-references
- **Меньше hype** чем Cursor / Cline -- хотя продукт зрелый и стабильный

## Базовые сценарии

- **Inline FIM** -- автодополнение во время написания (главный use case)
- Cmd+L (chat) → "объясни этот метод"
- @file references в chat
- Inline edit (Ctrl+I) -- "rename this variable to X"
- Custom slash commands -- `/test` для генерации тестов

## Сложные сценарии

- **Двойной setup на платформе**:
  - **FIM**: подключение к Qwen2.5-Coder 1.5B на порту 8080 -- мгновенный inline autocomplete
  - **Chat/Agent**: подключение к Qwen3-Coder Next на порту 8081 -- сложные задачи
  ```yaml
  models:
    - title: FIM
      provider: openai
      apiBase: http://192.168.1.77:8080/v1
      model: qwen2.5-coder-1.5b
      apiKey: local
    - title: Chat
      provider: openai
      apiBase: http://192.168.1.77:8081/v1
      model: qwen3-coder-next
      apiKey: local
  ```
- **JetBrains workflow** -- единственный нативный AI агент для IntelliJ/PyCharm с локальными моделями
- **Custom commands** для повторяющихся задач
- **Codebase Q&A** через embeddings (с локальной embeddings моделью)
- **MCP интеграция** -- расширение через серверы

## Установка / запуск

### VS Code

```
Extensions → искать "Continue" → Install (Continue - Codestral, Claude, and more)
```

### JetBrains

```
Plugins → искать "Continue" → Install
```

### Подключение к локальному llama-server

`~/.continue/config.yaml`:

```yaml
models:
  - title: Qwen3-Coder Next
    provider: openai
    apiBase: http://192.168.1.77:8081/v1
    model: qwen3-coder-next
    apiKey: local
    contextLength: 256000

tabAutocompleteModel:
  title: Qwen2.5-Coder 1.5B FIM
  provider: openai
  apiBase: http://192.168.1.77:8080/v1
  model: qwen2.5-coder-1.5b
  apiKey: local
```

## Конфигурация

`~/.continue/config.yaml` -- основная конфигурация:

```yaml
models:
  - title: ...
    provider: ...
tabAutocompleteModel:
  ...
contextProviders:
  - name: code
  - name: docs
  - name: diff
  - name: terminal
  - name: codebase
slashCommands:
  - name: test
    description: Generate tests
```

## Бенчмарки

Бенчмарков самого Continue нет -- зависит от модели. На платформе:
- FIM с Qwen2.5-Coder 1.5B Q8: 120 tok/s, мгновенный отклик
- Chat с Qwen3-Coder Next: 53 tok/s, 256K контекст

## Анонсы и открытия

- **2026-Q2** -- улучшения agent mode и MCP
- **2026-Q1** -- redesign config (YAML вместо JSON)
- **2025-Q4** -- расширенная JetBrains интеграция
- **2025-Q3** -- agent mode добавлен
- **2023** -- первый релиз, быстро стал стандартом для FIM с локальными моделями

## Ссылки

- [Официальный сайт](https://continue.dev/)
- [GitHub: continuedev/continue](https://github.com/continuedev/continue)
- [Документация](https://docs.continue.dev/)
- [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=Continue.continue)
- [JetBrains Plugin](https://plugins.jetbrains.com/plugin/22707-continue)

## Связано

- **Альтернативы (FIM)**: [qwen2.5-coder](../../models/families/qwen25-coder.md) -- лучшая модель для FIM на платформе
- **Альтернативы (agent IDE)**: [cline](cline.md), [kilo-code](kilo-code.md), [cursor](cursor.md)
- **Альтернативы (CLI)**: [aider](aider.md), [opencode](opencode/README.md)
- **Платформа**: [coding.md](../../models/coding.md)
- **Концепты**: [../README.md](../README.md)
