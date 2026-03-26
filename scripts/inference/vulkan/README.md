# scripts/inference/vulkan/ -- Vulkan backend

Сборка и проверка Vulkan backend для llama.cpp на Radeon 8060S (gfx1151).

## Скрипты

| Скрипт | Назначение |
|--------|-----------|
| `check.sh` | Проверка окружения: Vulkan, GPU, группы, зависимости |
| `build.sh` | Сборка/пересборка llama.cpp с `GGML_VULKAN=ON` |
| `config.sh` | `export AI_BACKEND=vulkan` + source common/config.sh |

Обёртки (`start-server.sh`, `bench.sh` и др.) делегируют в `scripts/inference/` с `AI_BACKEND=vulkan`.

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
