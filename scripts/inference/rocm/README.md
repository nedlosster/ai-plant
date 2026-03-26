# scripts/inference/rocm/ -- ROCm/HIP backend

Установка, проверка и сборка ROCm/HIP backend для llama.cpp на Radeon 8060S (gfx1151).

## Скрипты

| Скрипт | Назначение |
|--------|-----------|
| `install.sh` | Установка ROCm 6.4 (запускать с sudo) |
| `check.sh` | Проверка: ROCm, GPU, HIP, rocm-smi |
| `build.sh` | Сборка llama.cpp с `GGML_HIP=ON` |
| `config.sh` | `export AI_BACKEND=rocm` + source common/config.sh + check_rocm/check_gpu |

Обёртки (`start-server.sh`, `bench.sh` и др.) делегируют в `scripts/inference/` с `AI_BACKEND=rocm`.

## Быстрый старт

```bash
cd ~/projects/ai-plant

# Установка ROCm 6.4 (с sudo)
sudo ./scripts/inference/rocm/install.sh

# Проверка (5 компонентов)
./scripts/inference/rocm/check.sh

# Сборка (в build-hip/)
./scripts/inference/rocm/build.sh

# Запуск через общий скрипт
AI_BACKEND=rocm ./scripts/inference/start-server.sh model.gguf --daemon

# Или через обёртку
./scripts/inference/rocm/start-server.sh model.gguf --daemon
```

## check.sh

```
=== Проверка ROCm ===

[1/5] ROCm: OK (6.4.0-47)
[2/5] HSA_OVERRIDE_GFX_VERSION: 11.5.0
[3/5] GPU: OK (gfx1150 -- AMD Radeon Graphics)
[4/5] HIP: OK (HIP version: 6.4.43482)
[5/5] rocm-smi: OK (temp: 33.0C, power: 11.1W)
```

## Статус: не работает на gfx1151

Две проблемы:

1. **Segfault** -- маленькие модели (1.5B Q8_0) помещаются в VRAM, но HIP-ядра падают
2. **VRAM 15.8 GiB вместо 96 GiB** -- ROCm видит только GPU-сегмент unified memory, модели >15 GiB не грузятся (`failed to load model`)

| Параметр | Vulkan | HIP |
|----------|--------|-----|
| ROCm | не нужен | ROCm 6.4+ |
| HSA_OVERRIDE | не нужен | обязателен |
| VRAM видимый | 96 GiB | 15.8 GiB |
| Стабильность | работает | segfault / failed to load |
| pp (1.5B Q8_0) | 5232 tok/s | -- |
| tg (1.5B Q8_0) | 120 tok/s | -- |

Бенчмарк 2026-03-27, ROCm 6.4.0-47, llama.cpp b8541.

Для повседневной работы -- Vulkan. HIP -- экспериментальный, ожидает поддержки gfx1151 в ROCm.

## Конфигурация

| Переменная | Значение |
|-----------|---------|
| ROCM_PATH | /opt/rocm |
| HSA_OVERRIDE_GFX_VERSION | 11.5.0 |
| Окружение | /etc/profile.d/rocm.sh |

Документация: [docs/inference/rocm-setup.md](../../../docs/inference/rocm-setup.md)
