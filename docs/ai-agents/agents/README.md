# Каталог AI-агентов

Один файл = один агент. **Единственный источник правды** для описания: возможности, сильные/слабые стороны, базовые и сложные сценарии, установка, конфиг, ссылки, последние новости.

Сводные таблицы и обзоры -- в [`../comparison.md`](../comparison.md), [`../commercial.md`](../commercial.md), [`../open-source.md`](../open-source.md).
Декларативный выбор -- в [`../selection.md`](../selection.md).
Анонсы -- в [`../news.md`](../news.md).

## Индекс

### Open source
- [opencode](opencode.md) -- CLI с TUI, OpenAI-compatible, MCP, поддерживает локальные LLM
- [cline](cline.md) -- VS Code extension, plan/act mode, browser use
- [qwen-code](qwen-code.md) -- CLI от Qwen team, multi-protocol, optimized для Qwen3-Coder
- [kilo-code](kilo-code.md) -- VS Code/JetBrains/CLI, fork Roo Code, Orchestrator mode
- [openclaw](openclaw.md) -- "Life OS" агент, model-agnostic
- [aider](aider.md) -- CLI с git-workflow, классика
- [continue-dev](continue-dev.md) -- VS Code/JetBrains, FIM-фокус, лучший для local llama-server
- [roo-code](roo-code.md) -- Cline fork с расширениями

### Commercial
- [claude-code](claude-code/README.md) -- Anthropic, эталон CLI агентов
- [claude-code-news](claude-code/news.md) -- детальная хроника фич Claude Code (Skills, Subagents, Hooks, MCP, Plugins, Agent Teams, Channels, Remote Control, анализ для разработчика)
- [cursor](cursor.md) -- IDE, лучший Composer

## Как читать страницу агента

Каждый файл следует единому шаблону:

1. **Заголовок** -- название, вендор, год
2. **Метаданные** -- тип, лицензия, backend, цена
3. **Обзор** -- что это и ключевая идея
4. **Возможности** -- список фич
5. **Сильные / слабые стороны** -- сравнительная оценка
6. **Базовые / сложные сценарии** -- как использовать
7. **Установка / запуск / конфиг** -- быстрый старт
8. **Бенчмарки** -- если есть
9. **Анонсы** -- последние релизы и события
10. **Ссылки** -- сайт, GitHub, документация
11. **Связано** -- альтернативы и связанные направления

## Шаблон для новых агентов

См. [`_template.md`](_template.md) -- копировать и заполнять.
