# scripts/inference/ -- llama.cpp inference-серверы

Скрипты управления llama.cpp inference-серверами на AMD Radeon 8060S (gfx1151, 96 GiB VRAM).

## Структура

```
inference/
  common/config.sh        # Общая конфигурация, функции, выбор backend'а
  start-server.sh         # Запуск chat API (порт 8080)
  start-fim.sh            # Запуск FIM-сервера (порт 8081)
  stop-servers.sh         # Остановка всех серверов
  download-model.sh       # Загрузка моделей из HuggingFace
  bench.sh                # Бенчмарк модели (pp + tg)
  status.sh               # Статус: backend, GPU, серверы, модели
  monitor.sh              # Мониторинг GPU в реальном времени
  vulkan/                 # Vulkan backend: сборка, проверка
  rocm/                   # ROCm/HIP backend: установка, сборка, проверка
```

## Быстрый старт

```bash
# Проверка окружения
./scripts/inference/vulkan/check.sh

# Загрузка модели
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF --include "*Q8_0*"

# Запуск (backend определяется автоматически)
./scripts/inference/start-server.sh Qwen2.5-Coder-1.5B-Instruct-Q8_0.gguf --daemon

# Проверка
curl http://localhost:8080/health
```

## Выбор backend'а

Приоритет:
1. `AI_BACKEND=vulkan|rocm` -- переменная окружения
2. `~/.config/ai-plant/backend` -- файл (одна строка)
3. Автодетект: build-hip/ + /opt/rocm -> rocm, иначе vulkan

```bash
# Явный выбор
AI_BACKEND=rocm ./scripts/inference/start-server.sh model.gguf

# Через обёртку
./scripts/inference/vulkan/start-server.sh model.gguf   # Vulkan
./scripts/inference/rocm/start-server.sh model.gguf     # ROCm
```

## Скрипты

| Скрипт | Использование |
|--------|--------------|
| `start-server.sh` | `./scripts/inference/start-server.sh <model.gguf> [port] [ctx] [--daemon]` |
| `start-fim.sh` | `./scripts/inference/start-fim.sh <model.gguf> [port] [ctx] [--daemon]` |
| `stop-servers.sh` | `./scripts/inference/stop-servers.sh` |
| `download-model.sh` | `./scripts/inference/download-model.sh <hf-repo> [--include <pattern>]` |
| `bench.sh` | `./scripts/inference/bench.sh <model.gguf> [pp_tokens] [tg_tokens]` |
| `status.sh` | `./scripts/inference/status.sh` |
| `monitor.sh` | `./scripts/inference/monitor.sh [interval]` |

## Два сервера одновременно

```bash
# FIM (автодополнение, 1.5B, ~2 GiB VRAM)
./scripts/inference/start-fim.sh Qwen2.5-Coder-1.5B-Instruct-Q8_0.gguf --daemon

# Chat (30B MoE, ~18 GiB VRAM)
./scripts/inference/start-server.sh Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf --daemon

# Мониторинг
./scripts/inference/monitor.sh
```

## Конфигурация

| Переменная | Значение | Описание |
|-----------|---------|----------|
| LLAMA_DIR | ~/projects/llama.cpp | Путь к llama.cpp |
| MODELS_DIR | ~/models | Путь к моделям |
| DEFAULT_PORT_CHAT | 8080 | Порт chat-сервера |
| DEFAULT_PORT_FIM | 8081 | Порт FIM-сервера |
| DEFAULT_NGL | 99 | Слои на GPU (все) |
| DEFAULT_CTX_CHAT | 32768 | Контекст chat |
| DEFAULT_CTX_FIM | 4096 | Контекст FIM |

Переопределение:
```bash
MODELS_DIR=/data/models ./scripts/inference/start-server.sh model.gguf
```

## Замеры (2026-03-27, llama.cpp b8541, Vulkan)

| Модель | pp tok/s | tg tok/s | VRAM |
|--------|----------|----------|------|
| Qwen2.5-Coder-1.5B Q8_0 | 5232 | 120 | 1.5 GiB |
| Qwen3.5-27B Q4_K_M | 292 | 12.5 | 15.6 GiB |
