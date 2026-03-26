# OpenCode: быстрый старт

Установка OpenCode на рабочую станцию и подключение к AI-серверу.

## Предварительные требования

- bash 4.0+, curl, git
- AI-сервер запущен: `./scripts/inference/start-server.sh model.gguf --daemon`
- Сетевой доступ к серверу (<SERVER_IP>:8080)

## Установка

```bash
# Рекомендуемый способ (бинарник в ~/.opencode/bin/)
curl -fsSL https://opencode.ai/install | bash

# Проверка (перелогиниться или source ~/.bashrc)
opencode --version
```

Установщик добавляет `~/.opencode/bin` в PATH через `~/.bashrc`.

Альтернативы: `brew install opencode-ai/tap/opencode`, `go install github.com/opencode-ai/opencode@latest`, `npm install -g @opencode-ai/opencode`.

## Настройка окружения

Создать файл `~/.opencode-env`:

```bash
# На AI-сервере (локально)
export OPENAI_API_KEY="local"
export OPENAI_BASE_URL="http://localhost:8080/v1"

# На рабочей станции (удалённо)
# export OPENAI_BASE_URL="http://<SERVER_IP>:8080/v1"
```

Добавить в `~/.bashrc` (или `~/.zshrc`):

```bash
[ -f ~/.opencode-env ] && source ~/.opencode-env
```

Применить: `source ~/.bashrc`

## Проверка подключения

```bash
# Список моделей на сервере
curl -s "$OPENAI_BASE_URL/models" | python3 -m json.tool

# Тестовый запрос
curl -s "$OPENAI_BASE_URL/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{"model":"any","messages":[{"role":"user","content":"test"}],"max_tokens":10}'
```

## Конфигурация проекта

Создать `opencode.json` в корне проекта:

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
          "limit": { "context": 32768, "output": 8192 }
        }
      }
    }
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

llama.cpp автоматически использует загруженную модель -- имя модели в конфиге может быть любым.

## Запуск

```bash
cd /path/to/project
opencode
```

Или через скрипт (подгружает окружение):

```bash
#!/usr/bin/env bash
[ -f ~/.opencode-env ] && source ~/.opencode-env
exec opencode "$@"
```

## Переключение моделей

Для смены модели -- перезапустить inference-сервер на AI-сервере:

```bash
# На AI-сервере (ssh)
./scripts/inference/stop-servers.sh
./scripts/inference/start-server.sh Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf --daemon
```

OpenCode автоматически начнёт использовать новую модель при следующем запросе.

## Два сервера: chat + FIM

Для автодополнения в IDE параллельно с OpenCode:

```bash
# На AI-сервере
./scripts/inference/start-server.sh Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf --daemon   # :8080 chat
./scripts/inference/start-fim.sh Qwen2.5-Coder-1.5B-Instruct-Q8_0.gguf --daemon          # :8081 FIM
```

OpenCode подключается к :8080, IDE (Continue.dev) -- к :8081.

## Проблемы и решения

| Симптом | Причина | Решение |
|---------|---------|---------|
| Connection refused | Inference не запущен | `./scripts/inference/start-server.sh` |
| Пустой ответ | Модель не загружена | Проверить `curl localhost:8080/health` |
| Tool calling не работает | Модель не поддерживает | Использовать Qwen3-Coder или Qwen3.5 |
| Медленный ответ | Большая модель | Уменьшить контекст или использовать меньшую модель |

## Связанные статьи

- [Конфигурация](configuration.md) -- провайдеры, модели, агенты
- [Кастомизация](customization.md) -- правила, инструкции, MCP
- [Inference-сервер](../../../inference/README.md) -- управление backend'ом
