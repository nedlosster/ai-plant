# OpenCode: конфигурация

Конфигурация OpenCode: провайдеры, модели, агенты, приоритеты загрузки.

## Файл конфигурации

`opencode.json` (или JSONC с комментариями) в корне проекта. Поддерживает подстановку переменных:

```jsonc
{
  "model": "provider/model-id",         // основная модель
  "small_model": "provider/small-id",   // лёгкая модель (заголовки, быстрые задачи)

  "provider": { ... },                  // конфигурация LLM-провайдера
  "agent": { ... },                     // определение агентов
  "tools": { ... },                     // глобальные настройки инструментов
  "mcp": { ... },                       // MCP-серверы
  "permission": { ... },                // права доступа
  "instructions": "..."                 // кастомные инструкции
}
```

## Приоритет загрузки конфигов

Конфиги мержатся (deep merge), позднее перекрывает раннее:

1. Remote config (`.well-known/opencode`) -- организационный
2. Глобальный (`~/.config/opencode/opencode.json`) -- пользовательский
3. `OPENCODE_CONFIG` (env var, путь к файлу)
4. Проектный (`opencode.json` в текущей директории)
5. `OPENCODE_CONFIG_CONTENT` (env var, inline JSON)

Типичная схема: глобальный конфиг с провайдером, проектный с моделями и агентами.

## Подстановка переменных

```jsonc
{
  "options": {
    "baseURL": "{env:OPENAI_BASE_URL}",    // из переменной окружения
    "apiKey": "{file:~/.secrets/api-key}"   // из файла
  }
}
```

## Конфигурация провайдера

### llama.cpp (наш AI-сервер)

```json
{
  "provider": {
    "llama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama.cpp",
      "options": {
        "baseURL": "{env:OPENAI_BASE_URL}",
        "apiKey": "{env:OPENAI_API_KEY}"
      },
      "models": {
        "chat": {
          "name": "Chat model",
          "limit": { "context": 32768, "output": 8192 }
        },
        "coder": {
          "name": "Coder model",
          "limit": { "context": 32768, "output": 8192 }
        }
      }
    }
  }
}
```

llama.cpp игнорирует имя модели в запросе и использует загруженную. Имена в конфиге (`chat`, `coder`) -- для переключения между агентами с разными лимитами.

### Ollama

```json
{
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama",
      "options": {
        "baseURL": "http://localhost:11434/v1",
        "apiKey": "local"
      },
      "models": {
        "qwen3-coder": { "name": "Qwen3 Coder 30B", "limit": { "context": 32768 } }
      }
    }
  }
}
```

## Агенты

Два встроенных агента: **build** (полный доступ) и **plan** (read-only).

```json
{
  "default_agent": "build",
  "agent": {
    "build": {
      "model": "llama/chat",
      "tools": { "bash": true, "write": true, "edit": true, "read": true }
    },
    "plan": {
      "model": "llama/chat",
      "tools": { "bash": false, "write": false, "edit": false, "read": true }
    }
  }
}
```

Переключение между агентами: клавиша Tab в TUI.

### Кастомные агенты

Агенты можно определять в markdown-файлах:
- Глобально: `~/.config/opencode/agents/<name>.md`
- Проектно: `.opencode/agents/<name>.md`

Формат файла:

```markdown
---
name: reviewer
model: llama/chat
tools:
  bash: false
  write: false
  edit: false
  read: true
---

Ты -- code reviewer. Анализируй код на:
- Ошибки и баги
- Проблемы безопасности
- Нарушения стиля
- Возможные оптимизации

Не предлагай исправления -- только описывай проблемы.
```

Вызов кастомного агента: `@reviewer проверь файл src/main.go`

## Инструменты (tools)

| Инструмент | Описание |
|-----------|----------|
| `bash` | Выполнение shell-команд |
| `read` | Чтение файлов |
| `write` | Создание/перезапись файлов |
| `edit` | Частичное редактирование (patch) |

Глобальное ограничение:

```json
{
  "tools": {
    "bash": { "timeout": 30000 }
  }
}
```

## Лимиты моделей

```json
{
  "models": {
    "chat": {
      "name": "Qwen3.5 27B",
      "limit": {
        "context": 32768,     // макс. контекст (токены)
        "output": 8192        // макс. длина ответа
      }
    }
  }
}
```

Для llama.cpp контекст ограничен параметром `-c` при запуске сервера (DEFAULT_CTX_CHAT=32768).

## Связанные статьи

- [Быстрый старт](quickstart.md) -- установка и первый запуск
- [Кастомизация](customization.md) -- правила, permissions, MCP
- [Стратегии работы](strategies.md) -- приёмы и best practices
