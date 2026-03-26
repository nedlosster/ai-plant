# Inference через ROCm/HIP: llama.cpp

Платформа: Radeon 8060S (gfx1151), ROCm 6.x (требуется установка). Предварительно: [rocm-setup.md](rocm-setup.md).

## Зачем HIP если есть Vulkan

- Потенциально выше производительность: нативный доступ к GPU-памяти и compute
- Совместимость с PyTorch, vLLM, transformers (для будущего использования)
- Прямой контроль над GPU memory management
- Flash Attention через HIP (не доступен через Vulkan)

Vulkan -- стабильный рабочий вариант. HIP -- экспериментальный, для gfx1151 требует HSA_OVERRIDE_GFX_VERSION.

## Предварительные требования

```bash
# ROCm установлен и работает
rocminfo | grep gfx

# HIP компилятор доступен
hipcc --version

# Переменная окружения
echo $HSA_OVERRIDE_GFX_VERSION
# 11.5.0
```

## Сборка llama.cpp с HIP

```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# AMDGPU_TARGETS должен совпадать с HSA_OVERRIDE_GFX_VERSION
# Для HSA_OVERRIDE_GFX_VERSION=11.5.0 -> gfx1150
# Для HSA_OVERRIDE_GFX_VERSION=11.0.0 -> gfx1100
cmake -B build \
    -DGGML_HIP=ON \
    -DAMDGPU_TARGETS="gfx1150" \
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
HSA_OVERRIDE_GFX_VERSION=11.5.0 ./build/bin/llama-cli \
    -m ./models/model.gguf \
    -ngl 99 \
    -c 8192 \
    --temp 0.7
```

### Сервер

```bash
HSA_OVERRIDE_GFX_VERSION=11.5.0 ./build/bin/llama-server \
    -m ./models/model.gguf \
    -ngl 99 -c 8192 \
    --host 0.0.0.0 --port 8080
```

## Проверка что GPU используется

```bash
# Включить HIP-логирование
AMD_LOG_LEVEL=1 HSA_OVERRIDE_GFX_VERSION=11.5.0 \
    ./build/bin/llama-cli -m model.gguf -ngl 99 -p "test" -n 10

# В выводе должно быть:
# ggml_hip_init: found 1 ROCm devices
# Device 0: AMD Radeon ...

# Мониторинг
rocm-smi  # или watch -n1 rocm-smi
```

## Сравнение с Vulkan

Ожидаемые результаты (зависят от HSA_OVERRIDE_GFX_VERSION и модели):

| Метрика | Vulkan | HIP (gfx1150) | HIP (gfx1100) |
|---------|--------|---------------|---------------|
| pp tok/s | baseline | ~1.0-1.3x | ~0.8-1.0x |
| tg tok/s | baseline | ~1.0-1.2x | ~0.9-1.0x |
| Стабильность | высокая | средняя | низкая |

Примечание: реальные результаты для gfx1151 с HSA_OVERRIDE зависят от совместимости ISA. Провести собственные бенчмарки: [benchmarking.md](benchmarking.md).

## Типичные ошибки

**`hipErrorNoBinaryForGpu`**
- AMDGPU_TARGETS при сборке не совпадает с HSA_OVERRIDE_GFX_VERSION
- Решение: пересобрать с правильным AMDGPU_TARGETS

**Segfault при генерации**
- ISA несовместимость (gfx1100 слишком далек от gfx1151)
- Решение: попробовать gfx1150 вместо gfx1100

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
