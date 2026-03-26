# OpenCode: терминальный AI-агент для разработки

OpenCode -- open-source TUI-агент для работы с кодом, написанный на Go (Bubble Tea). Работает в терминале, подключается к любому OpenAI-совместимому API. В нашей инфраструктуре -- к llama.cpp на AI-сервере.

## Архитектура

```
Рабочая станция                    AI-сервер (<SERVER_IP>)
+------------------+               +----------------------+
|  OpenCode (TUI)  | --HTTP/API--> | llama-server :8080   |
|  терминал        |               | Vulkan + GPU         |
|  bash/read/write |               | модели (GGUF)        |
+------------------+               +----------------------+
```

OpenCode не запускает модели -- он только вызывает API. Вся тяжёлая работа на сервере.

## Зачем нужен (если есть Claude Code)

Claude Code -- коммерческий продукт Anthropic, привязан к их API и моделям. OpenCode -- open-source альтернатива, работающая с любыми моделями:

| Критерий | Claude Code | OpenCode |
|----------|-------------|----------|
| Модели | только Claude (Anthropic API) | любые OpenAI-совместимые |
| Стоимость | платная подписка | бесплатно (MIT) |
| Локальные модели | нет | да (llama.cpp, Ollama, vLLM) |
| Приватность | данные уходят в Anthropic | данные на локальном сервере |
| Tool use | bash, read, write, edit, grep, glob | bash, read, write, edit |
| Агенты | plan mode, subagents | build, plan, кастомные |
| Кастомизация | CLAUDE.md, skills, hooks, settings | opencode.json, agents, MCP, instructions |
| Качество | высокое (Claude Opus/Sonnet) | зависит от модели |
| Контекст | до 1M токенов | зависит от модели (8K-128K) |

**Когда OpenCode:** локальные модели, приватность, эксперименты, офлайн-работа, бюджет.
**Когда Claude Code:** сложные задачи, максимальное качество, большой контекст.

Подробное сравнение: [comparison.md](comparison.md)

## Документация

| N | Документ | Описание | Уровень |
|---|----------|----------|---------|
| 1 | [quickstart.md](quickstart.md) | Установка, подключение к серверу, первый запуск | базовый |
| 2 | [configuration.md](configuration.md) | Конфигурация: провайдеры, модели, агенты | базовый |
| 3 | [customization.md](customization.md) | Правила, инструкции, permissions, MCP | продвинутый |
| 4 | [strategies.md](strategies.md) | Приёмы работы, шаблоны, best practices | продвинутый |
| 5 | [comparison.md](comparison.md) | Детальное сравнение с Claude Code | справочный |
| 6 | [platform-analysis.md](platform-analysis.md) | Анализ моделей на платформе: бенчмарки, MoE vs dense, сравнение с Opus 4.6 | справочный |
| 7 | [mcp.md](mcp.md) | MCP-серверы: каталог, подключение, создание собственных | продвинутый |

Рекомендуемый порядок: 1 -> 2 -> 4 -> 3 -> 7 -> 5 -> 6.

## Связанные статьи

- [AI-агенты для кодинга](../agents.md) -- обзор всех агентов (Aider, SWE-agent, OpenHands)
- [Модели для кодинга](../../../models/coding.md) -- рейтинг, выбор модели
- [Inference-сервер](../../../inference/README.md) -- backend для OpenCode
- [Скрипты OpenCode](../../../../scripts/opencode/) -- установка и настройка
