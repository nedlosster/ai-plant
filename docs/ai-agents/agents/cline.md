# Cline (community, 2024-2026)

> Open-source VS Code extension с plan/act mode и MCP. 36K+ stars, 5M+ installs.

**Тип**: VS Code extension
**Лицензия**: Apache 2.0
**Backend**: Multi-provider (OpenAI / Anthropic / Google / OpenAI-compatible)
**Совместим с локальным llama-server**: **да** (через OpenAI Compatible)
**Цена**: Free open-source + bring-your-own API key (zero markup)

## Обзор

Cline -- один из самых популярных open-source AI agents для VS Code. **36K+ stars на GitHub, 5M+ установок**. Стартовал как простой агент с возможностью multi-file edits, вырос в полноценную платформу с plan/act режимами, MCP, computer use.

Главная философия -- **zero markup**: пользователь платит провайдеру за токены напрямую (Anthropic, OpenAI, OpenRouter, локальный сервер), Cline ничего не берёт сверху. Это привлекает разработчиков, которые хотят максимальную прозрачность стоимости.

Cline стал базой для **Roo Code** и **Kilo Code** -- два самых известных fork'а с расширенной функциональностью. Сам Cline продолжает развиваться как минималистичная "core" версия.

## Возможности

- **VS Code extension** -- agentic режим прямо в редакторе
- **Plan / Act mode** -- сначала план, потом действия (с подтверждениями)
- **Multi-file edits** -- одновременные изменения в нескольких файлах
- **Browser use** -- управление браузером для тестирования
- **MCP support** -- подключение MCP-серверов
- **Multi-provider** -- OpenAI, Anthropic, Google, OpenRouter, любой OpenAI-compatible (включая локальный llama-server)
- **Auto-approve settings** -- какие действия выполнять без подтверждения
- **Computer Use** (для Claude моделей) -- управление мышью/клавиатурой
- **Custom instructions** -- проектные правила
- **Memory bank** -- персистентный контекст

## Сильные стороны

- **Зрелая большая экосистема** -- 5M installs, активная community
- **Zero markup** -- только стоимость модели
- **Plan/Act mode** -- хороший контроль над агентом
- **Multi-provider из коробки** -- легко переключаться между API
- **Поддержка локальных моделей** через OpenAI-compatible
- **MCP support** -- расширяемость
- **Apache 2.0** -- свобода форков (Roo Code, Kilo Code -- доказательство)
- **Стабильность** -- уже несколько лет в production

## Слабые стороны / ограничения

- **Только VS Code** -- нет CLI-режима, нет JetBrains
- **Нет встроенного multi-agent** (в отличие от [kilo-code](kilo-code.md) с Orchestrator)
- **Менее автономен** чем Cursor / Claude Code -- больше human-in-the-loop
- **UI может быть перегружен** при большом количестве настроек
- **Forked экосистема** -- многие лучшие фичи появляются сначала в Roo Code или Kilo Code, а потом портируются обратно

## Базовые сценарии

- "Создай React компонент с TypeScript" -- multi-file генерация
- Inline edits через chat
- "Объясни этот код"
- "Найди и исправь TypeScript ошибки в файле"
- Quick refactoring

## Сложные сценарии

- **Plan mode для больших задач**: 
  1. Cline выдаёт детальный план
  2. Пользователь корректирует
  3. Act mode выполняет шаг за шагом с подтверждениями
- **Browser use тестирование**: agent открывает сайт, проверяет UX, исправляет CSS
- **MCP-driven workflows** -- интеграция с Linear, GitHub, Slack
- **Multi-file refactoring** с сохранением совместимости
- **Computer Use** для автоматизации UI задач (с Claude моделями)

## Установка / запуск

### VS Code

```
1. Open VS Code
2. Extensions → search "Cline"
3. Install
4. Click Cline icon in sidebar
5. Settings → Provider → choose
```

### Подключение к локальному llama-server

```
Provider: OpenAI Compatible
Base URL: http://192.168.1.77:8081/v1
API Key: local
Model: qwen3-coder-next
```

## Конфигурация

В Settings panel:
- **API Provider** + credentials
- **Auto-approve**: read / edit / bash / browser actions
- **Custom Instructions**: проектные правила (~CLAUDE.md аналог)
- **MCP Servers**: подключённые MCP
- **Computer Use**: enable/disable (только для Claude)

`.clinerules` файл в корне проекта -- проектные правила.

## Бенчмарки

Бенчмарки самого Cline отдельно не публикуются -- зависят от модели:
- С Claude Sonnet 4.5: ~ уровень Cursor
- С Qwen3-Coder Next: SWE-bench 70.6% (модель)
- С GPT-5: топ результаты на сложных задачах

## Анонсы и открытия

- **2026-Q2** -- 5M+ installs milestone
- **2026-Q1** -- Computer Use интеграция
- **2025-Q4** -- расширение MCP поддержки
- **2025-Q3** -- Plan/Act mode стал основным
- **2024** -- первый релиз, быстрый рост
- **Continuous** -- регулярные релизы каждые 1-2 недели

## Ссылки

- [Официальный сайт](https://cline.bot/)
- [GitHub: cline/cline](https://github.com/cline/cline)
- [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev)
- [Документация](https://docs.cline.bot/)

## Связано

- **Forks**: [roo-code](roo-code.md), [kilo-code](kilo-code.md)
- **Альтернативы (VS Code)**: [continue-dev](continue-dev.md), [kilo-code](kilo-code.md)
- **Альтернативы (CLI)**: [opencode](opencode/README.md), [aider](aider.md), [qwen-code](qwen-code.md)
- **Лучшие модели для пары**: [qwen3-coder](../../models/families/qwen3-coder.md), [claude-code](claude-code/README.md) для платных
- **Платформа**: [coding.md](../../models/coding.md)
- **Концепты**: [../README.md](../README.md)
