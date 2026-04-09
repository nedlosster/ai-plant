# Roo Code (community, 2024-2026)

> Cline fork с расширенными настройками, custom modes, и улучшенным developer experience.

**Тип**: VS Code extension
**Лицензия**: Apache 2.0
**Backend**: Multi-provider (OpenAI / Anthropic / OpenAI-compatible / local)
**Совместим с локальным llama-server**: **да** (как Cline)
**Цена**: Free open-source

## Обзор

Roo Code -- наиболее заметный fork [Cline](cline.md). Появился в конце 2024 как community-fork с целью **более быстрой итерации** и расширенной кастомизации, чем хотел поддерживать оригинальный Cline.

Главная фишка -- **Custom Modes**: пользователь может определять свои режимы агента под конкретные задачи (например "Architect", "Reviewer", "Debugger") с разными промптами, инструментами и моделями. Это подход который потом скопировали [Kilo Code](kilo-code.md) (который сам fork Roo Code) и opencode.

Roo Code позиционируется как **"Cline для power users"** -- больше настроек, кастомизации, экспериментальных фич.

## Возможности

- **Custom Modes** -- свои режимы агента с per-mode настройками
- **Plan / Act mode** (унаследовано от Cline)
- **Multi-provider** -- любые OpenAI/Anthropic/local
- **Browser use** (с Claude моделями)
- **MCP support** -- расширение через MCP-серверы
- **Auto-approve settings** -- гранулярный контроль
- **Custom instructions** -- per-mode и global
- **Sticky models** -- запоминание выбора модели по режиму
- **Cost tracking** -- учёт стоимости по моделям

## Сильные стороны

- **Custom Modes** -- лучшая кастомизация среди VS Code agents
- **Power user features** -- больше тонких настроек чем Cline
- **Active community** -- быстрые релизы, эксперименты
- **Cline compatibility** -- настройки/привычки Cline переносятся
- **Apache 2.0** -- свобода
- **Cost tracking** -- видно сколько потрачено

## Слабые стороны / ограничения

- **Только VS Code** -- нет CLI, нет JetBrains
- **Конкуренция от Kilo Code** -- многие пользователи мигрируют на более крупный fork с Orchestrator
- **Сложнее в освоении** чем Cline -- больше настроек = больше кривой обучения
- **Меньше mainstream visibility** чем Cline или Cursor

## Базовые сценарии

- "Создай файл X с реализацией Y" -- стандартные agent задачи
- Plan mode → Act mode для контролируемых изменений
- Inline edits через chat
- Browser testing UI

## Сложные сценарии

- **Custom Modes** для специализации:
  - **Mode "Architect"**: только read tools + промпт "design system architecture"
  - **Mode "Coder"**: read/write/edit + промпт "implement following the plan"
  - **Mode "Reviewer"**: только read + промпт "find bugs and code smells"
  - **Mode "Debugger"**: bash + edit + специальный промпт для отладки
- **Sticky model per mode** -- использовать Claude Opus для Architect, Qwen3-Coder Next для Coder
- **Cost optimization** -- отслеживать какой режим/модель сколько стоит
- **MCP-driven workflows** -- интеграция с GitHub, Linear через MCP

## Установка / запуск

### VS Code

```
Extensions → искать "Roo Code" → Install
```

### Подключение к локальному llama-server

```
Settings → Provider → OpenAI Compatible
Base URL: http://192.168.1.77:8081/v1
API Key: local
Model: qwen3-coder-next
```

## Конфигурация

В Settings panel:
- **Modes**: создать/редактировать custom modes
- **Provider per mode**: разные модели для разных режимов
- **Auto-approve**: read / edit / bash / browser actions per mode
- **Cost tracking**: enable/disable
- **MCP servers**: подключённые расширения

## Бенчмарки

Бенчмарков отдельно не публикуется -- зависит от модели и режима. С Claude Sonnet 4.5 в Architect+Coder paired mode -- сравним с Cline и Kilo Code.

## Анонсы и открытия

- **2026-Q1** -- стабилизация Custom Modes
- **2025-Q4** -- расширение Cost tracking
- **2025-Q3** -- быстрый рост благодаря Custom Modes
- **2024** -- fork Cline, начало разработки

## Ссылки

- [GitHub: RooCodeInc/Roo-Code](https://github.com/RooCodeInc/Roo-Code)
- [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=RooVeterinaryInc.roo-cline)
- [Документация](https://docs.roocode.com/)

## Связано

- **Прародитель**: [cline](cline.md) -- Roo Code это fork
- **Дальнейший fork**: [kilo-code](kilo-code.md) -- более крупный community-fork с Orchestrator
- **Альтернативы (VS Code)**: [continue-dev](continue-dev.md), [cursor](cursor.md)
- **Альтернативы (CLI)**: [opencode](opencode.md), [aider](aider.md), [qwen-code](qwen-code.md)
- **Лучшие модели для пары**: [qwen3-coder](../../models/families/qwen3-coder.md)
- **Платформа**: [coding.md](../../models/coding.md)
- **Концепты**: [../README.md](../README.md)
