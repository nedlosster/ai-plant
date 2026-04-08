# scripts/inference/vulkan/ -- Vulkan backend

Сборка и проверка Vulkan backend для llama.cpp на Radeon 8060S (gfx1151).

## Скрипты

| Скрипт | Назначение |
|--------|-----------|
| `check.sh` | Проверка окружения: Vulkan, GPU, группы, зависимости |
| `build.sh` | Сборка/пересборка llama.cpp с `GGML_VULKAN=ON` |
| `config.sh` | `export AI_BACKEND=vulkan` + source common/config.sh |
| `qwen-coder-next.sh` | Пресет: Qwen3-Coder-Next 80B-A3B, порт 8081, контекст 256K |
| `gemma4.sh` | Пресет: Gemma 4 26B-A4B, порт 8081, контекст 64K, `--parallel 1 --no-mmap --jinja` |

Обёртки (`start-server.sh`, `bench.sh` и др.) делегируют в `scripts/inference/` с `AI_BACKEND=vulkan`.

## Пресеты запуска моделей

Готовые скрипты с подобранными параметрами для конкретных моделей. Все запускают `llama-server` на порту **8081** через Vulkan-бэкенд.

```bash
# Стабильный 256K-контекст для Qwen3-Coder-Next
./scripts/inference/vulkan/qwen-coder-next.sh -d

# Безопасные параметры для Gemma 4 (защита от OOM)
./scripts/inference/vulkan/gemma4.sh -d
```

### Почему Gemma 4 нужны спец. параметры

Со стандартными параметрами (`-c 256000 --parallel 4`) Gemma 4 уходит в **OOM-kill**:

- **Sliding window attention** -- llama-server создаёт context checkpoints (~765 MiB каждый, до 32 = 24 GiB)
- **`cache reuse is not supported`** -- KV-shifting не работает, чекпоинты разрастаются
- **4 параллельных слота** мультиплицируют KV cache
- **mmap** добавляет ~22 GiB виртуальной памяти под GGUF поверх анонимной RSS

Пресет `gemma4.sh` ограничивает: `-c 65536`, `--parallel 1`, `--no-mmap`, `--jinja`.

## Быстрый старт

```bash
cd ~/projects/ai-plant

# Проверка окружения (7 компонентов)
./scripts/inference/vulkan/check.sh

# Сборка (инкрементальная или --clean)
./scripts/inference/vulkan/build.sh

# Запуск сервера (общий скрипт, backend по автодетекту)
./scripts/inference/start-server.sh model.gguf --daemon
```

## check.sh

Проверяет: группы video/render, /dev/dri, vulkaninfo, cmake/g++/glslc, llama-server, модели, GPU sysfs.

```
=== Проверка окружения для llama.cpp + Vulkan ===

[1/7] Группы video/render: OK
[2/7] Устройства /dev/dri/: OK (card1, renderD128)
[3/7] Vulkan: OK (AMD Radeon Graphics (RADV GFX1151), API 1.4.318)
[4/7] Зависимости (cmake, g++, glslc): OK
[5/7] llama.cpp: OK (version: 8541)
[6/7] Модели: OK (4 моделей)
[7/7] GPU: OK (загрузка 0%, VRAM 4181/98304 MiB, 31C)
```

## build.sh

```bash
./scripts/inference/vulkan/build.sh          # инкрементальная
./scripts/inference/vulkan/build.sh --clean   # полная пересборка
```

Клонирует llama.cpp (если отсутствует), `git pull`, cmake с `GGML_VULKAN=ON`. Бинарники в `build/bin/`.

## Замеры (2026-03-27, llama.cpp b8541)

| Модель | pp tok/s | tg tok/s | VRAM |
|--------|----------|----------|------|
| Qwen2.5-Coder-1.5B Q8_0 | 5232 | 120 | 1.5 GiB |
| Qwen3.5-27B Q4_K_M | 292 | 12.5 | 15.6 GiB |
