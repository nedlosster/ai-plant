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
     (RADV)     + ROCm 7.2.1   Linux      драйвер
        |            |            |          |
        +-----+------+-----+-----+          |
              |             |                |
           Radeon       Ryzen AI          NPU block
           8060S        MAX+ 395
```

## Сводная таблица

| | Vulkan | ROCm/HIP | CPU (AVX-512) | NPU (XDNA 2) |
|-|--------|----------|---------------|---------------|
| **Статус** | работает | работает (ROCm 7.2.1) | работает | экспериментальный |
| **Runtime** | llama.cpp | llama.cpp, PyTorch, vLLM | llama.cpp | ONNX Runtime |
| **Драйвер** | Mesa (RADV) | amdgpu + ROCm 7.2.1 | ядро Linux | amdxdna |
| **VRAM видимый** | 96 GiB | 120 GiB (ttm.pages_limit) | -- (RAM) | -- |
| **Зависимости** | mesa-vulkan-drivers, glslc | ROCm 7.2.1, HSA_OVERRIDE 11.5.1 | cmake, build-essential | xdna-driver, onnxruntime |
| **Модели до** | 122B MoE (120 GiB) | 122B MoE (120 GiB) | 70B Q4 (RAM) | ограничено |

## Замеры производительности

llama-bench pp512/tg128, llama.cpp b8541, ngl=99. Дата: 2026-04-06.

### Vulkan vs HIP (ROCm 7.2.1)

| Модель | Тип | Размер | Vulkan pp | Vulkan tg | HIP pp | HIP tg | HIP/Vulkan tg |
|--------|-----|--------|-----------|-----------|--------|--------|---------------|
| Qwen2.5-Coder-1.5B Q8_0 | dense | 1.5 GiB | 5242 | 121 | 5140 | 105 | -13% |
| Qwen3.5-27B Q4_K_M | dense | 15.6 GiB | 305 | 12.6 | 297 | 11.3 | -10% |
| Qwen3-Coder-30B-A3B Q4_K_M | MoE | 17.3 GiB | 1029 | 86 | 899 | 59 | -31% |

Vulkan быстрее HIP во всех тестах. На MoE-моделях разрыв наибольший (-31% tg).

### Vulkan: крупные модели (2026-03-27)

| Модель | Тип | Размер | pp tok/s | tg tok/s |
|--------|-----|--------|----------|----------|
| Qwen3-Coder-Next-80B-A3B Q4_K_M | MoE | 45.1 GiB | 590 | 53.2 |
| Qwen3.5-122B-A10B Q4_K_M | MoE | 71.3 GiB | 300 | 22.2 |

CPU (AVX-512) -- 10-30x медленнее Vulkan.

### Теоретический потолок (bandwidth-limited)

Token generation ограничен пропускной способностью памяти (256 GB/s):

```
tok/s (tg) ~ bandwidth / model_size_bytes
```

| Модель | Размер | Теория | Vulkan | HIP | Эфф. Vulkan | Эфф. HIP |
|--------|--------|--------|--------|-----|-------------|----------|
| 1.5B Q8_0 | 1.5 GiB | ~163 | 121 | 105 | 74% | 64% |
| 27B Q4_K_M | 15.6 GiB | ~15.6 | 12.6 | 11.3 | 81% | 72% |

Dense-модели: Vulkan 74-81%, HIP 64-72% от теоретического потолка. MoE-модели эффективнее за счёт активации части экспертов при генерации.

## Vulkan: рекомендуемый backend для llama.cpp

**Почему Vulkan:**
- Быстрее HIP на 10-31% в тестах token generation
- 120 GiB GPU-доступной памяти (96 GiB carved-out + GTT через ttm.pages_limit)
- Стабильная работа на gfx1151 через Mesa RADV
- Не зависит от ROCm и его матрицы поддержки
- Cooperative matrix extensions (KHR_coopmat) для матричных операций

**Ограничения:**
- Только llama.cpp (нет поддержки PyTorch/vLLM через Vulkan)
- Нет аналога CUDA/ROCm для произвольных GPGPU-вычислений
- Compute shaders менее гибкие, чем HIP/CUDA kernels

Документация: [vulkan-llama-cpp.md](vulkan-llama-cpp.md)
Скрипты: `scripts/inference/vulkan/`

## ROCm/HIP: работает, медленнее Vulkan

**Статус (ROCm 7.2.1, 2026-04-06):**
- HIP-инференс работает стабильно, segfault устранён
- GPU определяется нативно как gfx1151
- VRAM: 120 GiB через `ttm.pages_limit=31457280` ([подробности](../platform/vram-allocation.md))
- gfx1151 отсутствует в официальной матрице, но де-факто поддерживается

**Производительность:** HIP на 10-31% медленнее Vulkan в llama.cpp (tg). На MoE-моделях разрыв наибольший.

**Зачем нужен ROCm:**
- PyTorch, vLLM, transformers -- требуют ROCm для GPU
- Необходим для training/fine-tuning на GPU
- Ollama: нативная поддержка gfx1151, ~40 tok/s на 30B Q8_0

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
| Бенчмарк, сравнение | Vulkan + HIP + CPU |
| PyTorch, training, fine-tuning | ROCm/HIP |
| Ollama | ROCm/HIP (нативная поддержка gfx1151) |
| Модель не помещается целиком | CPU + partial GPU offload |

## Связанные статьи

- [Inference-стек](README.md) -- архитектура, ограничения платформы
- [Vulkan + llama.cpp](vulkan-llama-cpp.md) -- установка и запуск
- [ROCm setup](rocm-setup.md) -- установка ROCm
- [CPU inference](cpu-inference.md) -- AVX-512 backend
- [Бенчмарки](benchmarking.md) -- методика замеров
