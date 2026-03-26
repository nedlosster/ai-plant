# OpenCode: кастомизация

Правила проекта, инструкции, права доступа, MCP-серверы. Аналоги механизмов Claude Code.

## Сравнение механизмов кастомизации

| Механизм | Claude Code | OpenCode |
|----------|-------------|----------|
| Правила проекта | `CLAUDE.md` | `instructions` в opencode.json |
| Глобальные правила | `~/.claude/CLAUDE.md` | `~/.config/opencode/opencode.json` |
| Скилы (slash-команды) | `.claude/skills/` | кастомные агенты (`.opencode/agents/`) |
| Хуки (автоматизация) | `settings.json` hooks | нет прямого аналога |
| Права доступа | permissions в settings | `permission` в opencode.json |
| MCP-серверы | `settings.json` mcpServers | `mcp` в opencode.json |
| Memory | `.claude/memory/` | нет встроенного |

## Инструкции проекта (аналог CLAUDE.md)

В opencode.json:

```json
{
  "instructions": "Общайся по-русски. Комментарии в коде на русском. Не используй иконки в .md файлах."
}
```

Или из файла:

```json
{
  "instructions": "{file:.opencode/instructions.md}"
}
```

Файл `.opencode/instructions.md`:

```markdown
## Правила проекта

- Язык: русский (код, комментарии, документация)
- Не использовать иконки в .md файлах
- При изменении кода -- обновлять связанную документацию
- Коммиты: сухо и технично, без маркеров ИИ

## Архитектура

- Inference-сервер: scripts/inference/
- Веб-интерфейсы: scripts/webui/
- Документация: docs/

## Тестирование

- При исправлении багов -- добавлять тест
- Не править файлы на сервере напрямую, только через git
```

Инструкции добавляются в системный промпт каждого запроса. Это основной способ управления поведением агента.

## Права доступа (permissions)

Контроль, какие действия агент может выполнять без подтверждения:

```json
{
  "permission": {
    "allow": [
      "Read(*)",
      "Bash(git status)",
      "Bash(git diff*)",
      "Bash(git log*)",
      "Bash(ls *)",
      "Bash(cat *)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(git push*)",
      "Bash(git reset --hard*)",
      "Write(*.env)",
      "Write(*credentials*)"
    ]
  }
}
```

Три уровня:
- **allow** -- выполнять без запроса подтверждения
- **ask** (по умолчанию) -- спрашивать пользователя
- **deny** -- запретить полностью

Glob-паттерны для файлов: `Write(src/*.go)` -- разрешить запись только в src/.

## Кастомные агенты (аналог skills)

В Claude Code есть skills (slash-команды с инструкциями). В OpenCode аналог -- кастомные агенты в markdown-файлах.

### Структура

```
.opencode/agents/
  reviewer.md        # Code review агент
  documenter.md      # Документирование
  tester.md          # Генерация тестов
  refactorer.md      # Рефакторинг
```

### Пример: агент для code review

`.opencode/agents/reviewer.md`:

```markdown
---
name: reviewer
model: llama/chat
tools:
  bash: true
  write: false
  edit: false
  read: true
---

Ты -- code reviewer. Задача: найти проблемы в коде.

## Что проверять

1. Баги и логические ошибки
2. Проблемы безопасности (инъекции, XSS, утечки секретов)
3. Нарушения стиля проекта
4. Неэффективный код
5. Отсутствие обработки ошибок
6. Мёртвый код

## Формат вывода

Для каждой проблемы:
- Файл и строка
- Серьёзность (critical / warning / info)
- Описание проблемы
- Почему это проблема

НЕ предлагай исправления. Только описывай проблемы.
```

Вызов: `@reviewer проверь последний коммит`

### Пример: агент для документирования

`.opencode/agents/documenter.md`:

```markdown
---
name: documenter
model: llama/chat
tools:
  bash: true
  write: true
  edit: true
  read: true
---

Ты -- технический писатель. Задача: документировать код.

## Правила

- Язык: русский
- Без иконок в .md файлах
- Ссылки: относительные, кликабельные
- Каждый документ: заголовок, описание, примеры
- Стиль: сухо и технично

## Что делать

1. Прочитать указанный код
2. Написать или обновить документацию
3. Добавить ссылки на связанные статьи
4. Проверить ссылки
```

### Пример: агент-тестировщик

`.opencode/agents/tester.md`:

```markdown
---
name: tester
model: llama/chat
tools:
  bash: true
  write: true
  edit: true
  read: true
---

Ты -- QA-инженер. Задача: писать тесты.

## Стратегия

1. Прочитать код и понять логику
2. Определить edge cases
3. Написать тесты: позитивные, негативные, граничные
4. Запустить тесты, убедиться что проходят
5. Проверить покрытие

## Правила

- Фреймворк: определить из проекта (pytest, go test, jest)
- Моки: минимально, предпочитать реальные зависимости
- Имена тестов: описательные, на русском в комментариях
```

## MCP-серверы

Model Context Protocol -- расширение возможностей агента через внешние серверы:

```json
{
  "mcp": {
    "filesystem": {
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "/path/to/dir"],
      "env": {}
    },
    "github": {
      "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "{env:GITHUB_TOKEN}" }
    }
  }
}
```

MCP-серверы предоставляют дополнительные инструменты: работа с GitHub, файловая система, базы данных, API.

## Глобальная конфигурация

`~/.config/opencode/opencode.json` -- конфиг для всех проектов:

```json
{
  "provider": {
    "llama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama.cpp (AI-сервер)",
      "options": {
        "baseURL": "{env:OPENAI_BASE_URL}",
        "apiKey": "{env:OPENAI_API_KEY}"
      }
    }
  },
  "instructions": "Общайся по-русски. Комментарии на русском."
}
```

Проектный конфиг мержится поверх глобального. Провайдер задаётся один раз глобально, проектные конфиги определяют только модели и агентов.

## Связанные статьи

- [Конфигурация](configuration.md) -- основы конфигурации
- [Стратегии работы](strategies.md) -- приёмы и best practices
- [Сравнение с Claude Code](comparison.md) -- детальное сравнение
