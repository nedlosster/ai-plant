# scripts/inference/rocm/ -- ROCm/HIP backend

Установка, проверка и сборка ROCm/HIP backend для llama.cpp на Radeon 8060S (gfx1151).

## Скрипты

| Скрипт | Назначение |
|--------|-----------|
| `install.sh` | Установка ROCm 7.2.1 (запускать с sudo) |
| `check.sh` | Проверка: ROCm, GPU, HIP, rocm-smi |
| `build.sh` | Сборка llama.cpp с `GGML_HIP=ON` |
| `config.sh` | `export AI_BACKEND=rocm` + source common/config.sh + check_rocm/check_gpu |
| `qwen-coder-next.sh` | Пресет: Qwen3-Coder-Next 80B-A3B (см. предупреждение об OOM) |
| `gemma4.sh` | Пресет: Gemma 4 26B-A4B, безопасные параметры |

Пресеты -- тонкие обёртки над `common/presets/{qwen-coder-next,gemma4}.sh`,
устанавливают `AI_BACKEND=rocm` и делегируют логику в общий пресет.

ВНИМАНИЕ для Qwen3-Coder-Next: HIP-аллокация ограничена ~30 GiB GPU-памяти
(см. KFD pool size в `rocminfo`), модель занимает ~45 GiB -- возможен OOM
на загрузке. Для этой модели предпочтителен Vulkan-бекенд.

Обёртки (`start-server.sh`, `bench.sh` и др.) делегируют в `scripts/inference/` с `AI_BACKEND=rocm`.

## Быстрый старт

```bash
cd ~/projects/ai-plant

# Установка ROCm 7.2.1 (с sudo)
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

[1/5] ROCm: OK (7.2.1)
[2/5] HSA_OVERRIDE_GFX_VERSION: 11.5.1
[3/5] GPU: OK (gfx1151 -- AMD Radeon Graphics)
[4/5] HIP: OK (HIP version: 7.2.53211)
[5/5] rocm-smi: OK (temp: 40.0C, power: 37.0W)
```

## Статус: работает на gfx1151 (ROCm 7.2.1)

HIP-инференс работает стабильно. GPU определяется нативно как gfx1151. VRAM 120 GiB (после ttm.pages_limit).

| Модель | Vulkan pp/tg | HIP pp/tg | HIP/Vulkan tg |
|--------|-------------|-----------|---------------|
| 1.5B Q8_0 (dense) | 5242 / 121 | 5140 / 105 | -13% |
| 27B Q4_K_M (dense) | 305 / 12.6 | 297 / 11.3 | -10% |
| 30B MoE Q4_K_M | 1029 / 86 | 899 / 59 | -31% |

Бенчмарк 2026-04-06, ROCm 7.2.1, llama.cpp b8541, llama-bench pp512/tg128.

## Конфигурация

| Переменная | Значение |
|-----------|---------|
| ROCM_PATH | /opt/rocm |
| HSA_OVERRIDE_GFX_VERSION | 11.5.1 |
| AMDGPU_TARGETS | gfx1151 |
| Окружение | /etc/profile.d/rocm.sh |

Документация: [docs/inference/rocm-setup.md](../../../docs/inference/rocm-setup.md)
