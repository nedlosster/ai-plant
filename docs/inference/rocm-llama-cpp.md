# Inference через ROCm/HIP: llama.cpp

Платформа: Radeon 8060S (gfx1151), ROCm 7.2.1. Предварительно: [rocm-setup.md](rocm-setup.md).

## Зачем HIP если есть Vulkan

- Совместимость с PyTorch, vLLM, transformers
- Прямой контроль над GPU memory management
- Flash Attention через HIP (не доступен через Vulkan)

Оба бэкенда работают стабильно. Vulkan немного быстрее на маленьких моделях, HIP предпочтителен для PyTorch-совместимости.

## Предварительные требования

```bash
# ROCm установлен и работает
rocminfo | grep gfx

# HIP компилятор доступен
hipcc --version

# Переменная окружения
echo $HSA_OVERRIDE_GFX_VERSION
# 11.5.1
```

## Сборка llama.cpp с HIP

```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# gfx1151 -- нативный таргет для Strix Halo (ROCm 7.2.1)
cmake -B build \
    -DGGML_HIP=ON \
    -DAMDGPU_TARGETS="gfx1151" \
    -DCMAKE_PREFIX_PATH=/opt/rocm

cmake --build build -j$(nproc)
```

Если `hipcc` не найден:

```bash
export PATH=/opt/rocm/bin:$PATH
export CMAKE_PREFIX_PATH=/opt/rocm
```

## Запуск

```bash
./build/bin/llama-cli \
    -m ./models/model.gguf \
    -ngl 99 \
    -c 8192 \
    --temp 0.7
```

### Сервер

```bash
./build/bin/llama-server \
    -m ./models/model.gguf \
    -ngl 99 -c 8192 \
    --host 0.0.0.0 --port 8080
```

## Проверка что GPU используется

```bash
# Включить HIP-логирование
AMD_LOG_LEVEL=1 ./build/bin/llama-cli -m model.gguf -ngl 99 -p "test" -n 10

# В выводе должно быть:
# ggml_cuda_init: found 1 ROCm devices (Total VRAM: 122880 MiB)
# Device 0: AMD Radeon Graphics, gfx1151 (0x1151)

# Мониторинг
rocm-smi  # или watch -n1 rocm-smi
```

## Сравнение с Vulkan

Бенчмарк llama.cpp b8541, llama-bench pp512/tg128, 2026-04-06:

| Модель | Vulkan pp/tg | HIP pp/tg | HIP/Vulkan tg |
|--------|-------------|-----------|---------------|
| 1.5B Q8_0 (dense) | 5242 / 121 | 5140 / 105 | -13% |
| 27B Q4_K_M (dense) | 305 / 12.6 | 297 / 11.3 | -10% |
| 30B MoE Q4_K_M | 1029 / 86 | 899 / 59 | -31% |

Vulkan быстрее HIP во всех тестах. На dense-моделях разница -10-13%, на MoE -- -31%.

## Типичные ошибки

**`hipErrorNoBinaryForGpu`**
- AMDGPU_TARGETS при сборке не совпадает с GPU target
- Решение: пересобрать с `-DAMDGPU_TARGETS="gfx1151"`

**Segfault при генерации**
- Устарев версия ROCm (6.x). Обновить до ROCm 7.2.1+
- Проверить HSA_OVERRIDE_GFX_VERSION=11.5.1

**OOM (Out of Memory)**
- KFD VRAM heap = 120 GiB (после `ttm.pages_limit=31457280`), подробности: [vram-allocation.md](../platform/vram-allocation.md)
- Проверка: `cat /sys/class/kfd/kfd/topology/nodes/1/mem_banks/0/properties | grep size_in_bytes`
- Решение: явно ограничить -ngl или -c

**"Could not load ROCm library"**
- LD_LIBRARY_PATH не включает /opt/rocm/lib
- Решение: `export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH`

## Связанные статьи

- [Установка ROCm](rocm-setup.md)
- [llama.cpp + Vulkan](vulkan-llama-cpp.md)
- [Выбор моделей](model-selection.md)
- [Бенчмарки](benchmarking.md)
