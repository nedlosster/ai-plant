# <Имя агента> (<вендор>, <год релиза>)

> Однострочная характеристика.

**Тип**: CLI / IDE / Cloud / Self-hosted
**Лицензия**: Apache 2.0 / MIT / Proprietary / ...
**Backend**: API-only / OpenAI-compatible / Anthropic-compatible / Self-hosted
**Совместим с локальным llama-server**: да / нет / частично
**Цена**: $X/мес или Free

## Обзор

2-3 абзаца: что это, ключевая идея, чем отличается.

## Возможности

- Bullet-list ключевых фич: tool use, multi-file edits, agentic loop, MCP, ...

## Сильные стороны

- Где блестит уникально

## Слабые стороны / ограничения

- Где не подходит, известные баги

## Базовые сценарии использования

- Quick fix bug
- Refactor file
- Generate tests

## Сложные сценарии

- Multi-repo refactoring
- Migration framework version
- Architecture review
- ...

## Установка / запуск

```bash
# Установка
...

# Подключение к локальному llama-server (если поддерживается)
export OPENAI_BASE_URL=http://192.168.1.77:8081/v1
agent run "..."
```

## Конфигурация

Краткий пример конфига или ссылка на полный.

## Бенчмарки

| Бенч | Значение |
|------|----------|
| SWE-bench Verified | XX% |

## Анонсы и открытия (последние)

- **YYYY-MM-DD** -- релиз vX.Y, что нового
- **YYYY-MM-DD** -- интеграция с X

## Ссылки

- [Официальный сайт](URL)
- [GitHub](https://github.com/...)
- [Документация](URL)

## Связано

- Альтернативы: ссылки на альтернативные агенты в этом же разделе (`agent-name.md`)
- Платформа: [coding.md](../../models/coding.md)
- Концепты: [README.md](../README.md)
