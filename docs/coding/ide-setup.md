# IDE-интеграция с локальным AI

Платформа: llama-server на портах 8081 (FIM) и 8080 (Chat). Предварительно: [server-setup.md](server-setup.md).

## Сравнение расширений

| Расширение | IDE | Autocomplete | Chat | Agent | FIM | Лицензия |
|-----------|-----|-------------|------|-------|-----|----------|
| **Continue.dev** | VS Code, JetBrains | да | да | нет | да | Apache 2.0 |
| **llama.vscode** | VS Code | да | нет | нет | да | MIT |
| **Cline** | VS Code | нет | да | да | нет | Apache 2.0 |
| **Roo Code** | VS Code | нет | да | да | нет | Apache 2.0 |
| **avante.nvim** | Neovim | нет | да | да | нет | Apache 2.0 |

Для полного покрытия: **Continue.dev** (autocomplete + chat) + **Cline** (agent).

## Continue.dev

Расширение для VS Code и JetBrains. Поддерживает раздельные модели для автодополнения и чата.

### Установка

VS Code: Extensions -> поиск "Continue" -> Install.

### Конфигурация

Файл `~/.continue/config.yaml`:

```yaml
models:
  # Большая модель для чата и редактирования
  - name: qwen2.5-coder-32b
    provider: openai
    model: qwen2.5-coder-32b
    apiBase: http://<SERVER_IP>:8080/v1
    apiKey: not-needed
    roles:
      - chat
      - edit
      - apply

  # Маленькая модель для автодополнения (FIM)
  - name: qwen2.5-coder-1.5b
    provider: llama.cpp
    model: qwen2.5-coder-1.5b
    apiBase: http://<SERVER_IP>:8081
    roles:
      - autocomplete
    autocompleteOptions:
      debounceDelay: 250
      maxPromptTokens: 1024
      modelTimeout: 2000
```

**Провайдеры:**
- `provider: llama.cpp` -- для FIM (использует эндпоинт `/infill`)
- `provider: openai` -- для чата (использует `/v1/chat/completions`)

### Использование

- **Tab** -- принять автодополнение
- **Ctrl+L** -- открыть чат
- **Ctrl+I** -- inline-редактирование (выделить код, описать изменение)
- **Ctrl+Shift+L** -- добавить выделенный код в контекст чата

## llama.vscode

Минималистичное расширение от создателей llama.cpp. Только FIM-автодополнение.

### Установка

VS Code: Extensions -> поиск "llama.vscode" -> Install.

### Конфигурация

Settings -> llama.vscode:
- **Endpoint**: `http://<SERVER_IP>:8081/infill`
- **Temperature**: 0.1
- **N Predict**: 128

Или в `settings.json`:

```json
{
    "llama.endpoint": "http://<SERVER_IP>:8081/infill",
    "llama.temperature": 0.1,
    "llama.n_predict": 128
}
```

### Рекомендуемые модели

- Qwen2.5-Coder-1.5B -- быстрый отклик
- Qwen2.5-Coder-7B -- лучшее качество
- Codestral 25.01 -- SOTA FIM

## Cline

Автономный AI-агент в VS Code. Создает/редактирует файлы, выполняет команды в терминале, работает с браузером.

### Установка

VS Code: Extensions -> поиск "Cline" -> Install.

### Настройка

Settings -> Cline:
- **API Provider**: OpenAI Compatible
- **Base URL**: `http://<SERVER_IP>:8080/v1`
- **API Key**: `not-needed`
- **Model**: `qwen2.5-coder-32b`

### Режимы

- **Plan** -- планирование перед выполнением (анализ задачи)
- **Act** -- непосредственное выполнение (создание/редактирование файлов)
- **MCP** -- интеграция с внешними инструментами

## Roo Code (ex-Roo Cline)

Форк Cline с расширенными возможностями. 22k+ GitHub stars.

### Уникальные фичи

- **Custom Modes** -- настраиваемые роли:
  - Security Reviewer -- поиск уязвимостей
  - Test Writer -- генерация тестов
  - Architect -- проектирование архитектуры
- **Sticky models** -- разные модели для разных режимов
- Plan/Act режимы
- MCP-интеграция

### Настройка

Аналогична Cline: OpenAI Compatible -> `http://<SERVER_IP>:8080/v1`.

## avante.nvim (Neovim)

Cursor-подобный опыт в Neovim.

### Установка (lazy.nvim)

```lua
{
    "yetone/avante.nvim",
    event = "VeryLazy",
    build = "make",
    opts = {
        provider = "openai",
        openai = {
            endpoint = "http://<SERVER_IP>:8080/v1",
            model = "qwen2.5-coder-32b",
            api_key_name = "",
        },
    },
}
```

### Альтернатива: через Ollama

```lua
opts = {
    provider = "ollama",
    ollama = {
        endpoint = "http://<SERVER_IP>:8080/v1",
        model = "qwen2.5-coder-32b",
    },
}
```

## OpenCode (терминальный AI-агент)

Open-source терминальный агент для кодинга. TUI-интерфейс, поддержка локальных моделей.

### Установка

```bash
# Go
go install github.com/opencode-ai/opencode@latest

# Или бинарник
curl -fsSL https://opencode.ai/install | bash
```

### Конфигурация

Файл `opencode.json` в корне проекта:

```json
{
    "provider": {
        "openai-compatible": {
            "apiKey": "not-needed",
            "baseURL": "http://<SERVER_IP>:8080/v1"
        }
    },
    "agents": {
        "coder": {
            "model": "openai-compatible/qwen2.5-coder-32b",
            "maxTokens": 8192
        },
        "task": {
            "model": "openai-compatible/qwen2.5-coder-32b",
            "maxTokens": 8192
        }
    }
}
```

### Использование

```bash
cd /path/to/project
opencode
```

TUI-интерфейс: chat, просмотр файлов, diff, терминал. Поддерживает LSP, git, MCP.

## Общие рекомендации

1. **FIM-модель отдельно от Chat** -- маленькая модель для автодополнения не блокирует большую для чата
2. **IP-адрес сервера** -- если IDE на другой машине, использовать `<SERVER_IP>` вместо `localhost`
3. **Задержка автодополнения** -- настроить debounce 200-300ms для комфортной работы
4. **Контекст** -- для чата включать минимально необходимые файлы, не весь проект
5. **Температура** -- для кода 0.0-0.3 (детерминированный), для рефакторинга 0.3-0.5

## Связанные статьи

- [Настройка сервера](server-setup.md)
- [Модели для кодинга](../models/coding.md)
- [Промпт-инжиниринг](prompts.md)
- [AI-агенты](../ai-agents/README.md)
