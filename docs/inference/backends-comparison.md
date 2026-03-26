# Сравнение GPU backend'ов для Strix Halo

Платформа: AMD Ryzen AI MAX+ 395, Radeon 8060S (gfx1151, RDNA 3.5, 40 CU), 120 GiB GPU-доступной памяти (LPDDR5 256 GB/s).

## Обзор

На платформе Strix Halo доступны четыре backend'а для inference LLM. Каждый использует разный путь от модели к GPU/CPU, с разными зависимостями и ограничениями.

```
                  llama.cpp
                     |
        +------------+------------+----------+
        |            |            |          |
     Vulkan      ROCm/HIP      CPU       NPU
    (SPIR-V)    (HIP kernels)  (AVX-512)  (XDNA 2)
        |            |            |          |
      Mesa        amdgpu        ядро      amdxdna
     (RADV)     + ROCm 6.4+    Linux      драйвер
        |            |            |          |
        +-----+------+-----+-----+          |
              |             |                |
           Radeon       Ryzen AI          NPU block
           8060S        MAX+ 395
```

## Сводная таблица

| | Vulkan | ROCm/HIP | CPU (AVX-512) | NPU (XDNA 2) |
|-|--------|----------|---------------|---------------|
| **Статус** | работает | segfault на gfx1151 | работает | экспериментальный |
| **Runtime** | llama.cpp | llama.cpp, PyTorch, vLLM | llama.cpp | ONNX Runtime |
| **Драйвер** | Mesa (RADV) | amdgpu + ROCm 6.4+ | ядро Linux | amdxdna |
| **VRAM видимый** | 96 GiB | 120 GiB (ttm.pages_limit) | -- (RAM) | -- |
| **Зависимости** | mesa-vulkan-drivers, glslc | ROCm 6.4, HSA_OVERRIDE | cmake, build-essential | xdna-driver, onnxruntime |
| **Модели до** | 122B MoE (120 GiB) | segfault (gfx1151) | 70B Q4 (RAM) | ограничено |

## Замеры производительности

Все замеры на одной модели, llama-bench pp512/tg128, llama.cpp b8541, 2026-03-27.

### Vulkan (llama-bench pp512/tg128, b8541, 2026-03-27)

| Модель | Тип | Размер | pp tok/s | tg tok/s |
|--------|-----|--------|----------|----------|
| Qwen2.5-Coder-1.5B Q8_0 | dense | 1.5 GiB | 5245 | 120.6 |
| Qwen3-Coder-30B-A3B Q4_K_M | MoE | 17.3 GiB | 1036 | 86.1 |
| Qwen3.5-27B Q4_K_M | dense | 15.6 GiB | 309 | 12.6 |
| Qwen3-Coder-Next-80B-A3B Q4_K_M | MoE | 45.1 GiB | 590 | 53.2 |
| Qwen3.5-122B-A10B Q4_K_M | MoE | 71.3 GiB | 300 | 22.2 |

ROCm/HIP -- segfault на всех моделях (gfx1151). CPU (AVX-512) -- 10-30x медленнее Vulkan.

### Теоретический потолок (bandwidth-limited)

Token generation ограничен пропускной способностью памяти (256 GB/s):

```
tok/s (tg) ~ bandwidth / model_size_bytes
```

| Модель | Размер | Теория | Vulkan (реально) | Эффективность |
|--------|--------|--------|------------------|---------------|
| 1.5B Q8_0 | 1.5 GiB | ~163 | 120.6 | 74% |
| 27B Q4_K_M | 15.6 GiB | ~15.6 | 12.6 | 81% |
| 122B-A10B MoE | 71.3 GiB | ~3.4 | 22.2 | -- (MoE) |

Dense-модели: 74-81% от теоретического потолка. MoE-модели эффективнее за счёт активации части экспертов при генерации.

## Vulkan: рекомендуемый backend

**Почему Vulkan:**
- 120 GiB GPU-доступной памяти (96 GiB carved-out + GTT через ttm.pages_limit)
- Стабильная работа на gfx1151 через Mesa RADV
- Не зависит от ROCm и его матрицы поддержки
- Cooperative matrix extensions (KHR_coopmat) для матричных операций
- Поддержка новых GPU появляется в Mesa раньше, чем в ROCm

**Ограничения:**
- Только llama.cpp (нет поддержки PyTorch/vLLM через Vulkan)
- Нет аналога CUDA/ROCm для произвольных GPGPU-вычислений
- Compute shaders менее гибкие, чем HIP/CUDA kernels

Документация: [vulkan-llama-cpp.md](vulkan-llama-cpp.md)
Скрипты: `scripts/inference/vulkan/`

## ROCm/HIP: потенциально быстрее, не работает на gfx1151

**Проблемы на текущей платформе (ROCm 6.4.0-47):**
1. **Segfault** -- HIP-ядра падают при инференсе. HSA_OVERRIDE_GFX_VERSION=11.5.0 маскирует gfx1151 под gfx1150, но ядра несовместимы
2. **VRAM** -- решено: KFD видит 120 GiB через `ttm.pages_limit=31457280` ([подробности](../platform/vram-allocation.md))
3. **Матрица поддержки** -- gfx1151 отсутствует в официальном списке

**Когда будет работать:**
- Ожидается поддержка gfx1151 в будущих версиях ROCm
- Мониторинг: https://repo.radeon.com/amdgpu-install/ и https://rocm.docs.amd.com/en/latest/release/versions.html

**Зачем нужен ROCm (когда заработает):**
- PyTorch, vLLM, transformers -- требуют ROCm для GPU
- Потенциально быстрее Vulkan для compute-heavy задач
- Необходим для training/fine-tuning на GPU

Документация: [rocm-setup.md](rocm-setup.md), [rocm-llama-cpp.md](rocm-llama-cpp.md)
Скрипты: `scripts/inference/rocm/`

## CPU (AVX-512 BF16): надёжный fallback

**Характеристики:**
- Zen 5, 16C/32T, AVX-512 BF16/VNNI
- 64 MiB L3, 256 GB/s bandwidth (shared с GPU)
- Работает всегда, без GPU-зависимостей

**Когда использовать:**
- Baseline для сравнения с GPU
- GPU-backend недоступен
- Partial offload: часть слоёв на GPU, часть на CPU (`-ngl N` где N < total layers)
- Отладка без GPU-зависимостей

**Производительность:** 10-30x медленнее Vulkan для token generation. Для prompt processing разрыв меньше (2-5x).

Документация: [cpu-inference.md](cpu-inference.md)

## NPU (XDNA 2): экспериментальный

**Характеристики:**
- 50 TOPS INT8
- Доступен через amdxdna драйвер + ONNX Runtime

**Статус:**
- Ограниченная экосистема: только ONNX-модели
- Нет интеграции с llama.cpp
- Потенциально полезен для offload мелких задач (embedding, VAD)

## Рекомендации

| Задача | Backend |
|--------|---------|
| Интерактивный чат, API-сервер | Vulkan |
| Автодополнение кода (FIM) | Vulkan |
| Бенчмарк, сравнение | Vulkan + CPU |
| PyTorch, training, fine-tuning | ROCm (когда заработает) |
| Модель не помещается целиком | CPU + partial GPU offload |

## Связанные статьи

- [Inference-стек](README.md) -- архитектура, ограничения платформы
- [Vulkan + llama.cpp](vulkan-llama-cpp.md) -- установка и запуск
- [ROCm setup](rocm-setup.md) -- установка ROCm
- [CPU inference](cpu-inference.md) -- AVX-512 backend
- [Бенчмарки](benchmarking.md) -- методика замеров
