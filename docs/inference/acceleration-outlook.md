# Перспективы ускорения inference на Strix Halo

Платформа: Ryzen AI Max+ 395 (Zen 5 + RDNA 3.5 + XDNA 2), 128 GiB LPDDR5X-8000, 256 GB/s bandwidth.

Три вычислителя на одном чипе, каждый с разными характеристиками и зрелостью software-стека. Здесь -- текущее состояние, нерешённые вопросы и что отслеживать.

## Текущая производительность (апрель 2026)

### GPU (RDNA 3.5, 40 CU, Vulkan)

Основной backend для inference. Лучшее соотношение throughput / зрелость стека.

| Модель | Параметры | Active | tg tok/s | pp tok/s | Backend |
|--------|-----------|--------|----------|----------|---------|
| Qwen2.5-Coder 1.5B Q8 | 1.5B dense | 1.5B | **121** | 5245 | Vulkan |
| Qwen3-Coder 30B-A3B | 30B MoE | 3B | **86** | 1036 | Vulkan |
| Qwen3-Coder Next 80B-A3B | 80B MoE | 3B | **53** | 590 | Vulkan |
| Qwen3.5-122B-A10B | 122B MoE | 10B | **22** | -- | Vulkan |
| Qwen3.5-27B dense | 27B | 27B | 12.6 | 305 | Vulkan |

MoE-модели дают 3-7x ускорение по tg за счёт малой активации -- основное преимущество платформы.

### GPU (RDNA 3.5, HIP/ROCm 7.2.1)

Работает, но медленнее Vulkan на 26-57%. Ограничение: `hipMalloc` не может выделить >30-35 GiB единым блоком при carved-out 96 GiB VRAM (модели >35 GiB не загружаются).

| Модель | tg tok/s (HIP) | tg tok/s (Vulkan) | Разница |
|--------|----------------|-------------------|---------|
| Qwen3-Coder 30B-A3B | 63.5 | 86 | -26% |
| Qwen3-Coder Next 80B-A3B | **OOM** | 53 | не загружается |

Подробнее: [rocm-setup.md](rocm-setup.md#hip-inference-ограничение-по-vram-аллокации-2026-04-09).

### CPU (Zen 5, 16 cores, AVX-512)

Fallback для задач, когда GPU занят. AVX-512 BF16 + VNNI для INT8.

| Модель | tg tok/s (CPU) | vs GPU |
|--------|----------------|--------|
| 7B Q4_K_M | 8-12 | 10x медленнее |
| 13B Q4_K_M | 5-8 | 5x медленнее |
| 27B Q4_K_M | 3-5 | 3x медленнее |
| 70B Q4_K_M | 1-2 | 3x медленнее |

Подробнее: [cpu-inference.md](cpu-inference.md).

### NPU (XDNA 2, 50 INT8 TOPS)

**Статус: экспериментальный**. Драйвер `amdxdna` в mainline с ядра 6.14+. Устройство: `/dev/accel0`. 32 AI Engine tiles, 2x MAC/tile vs XDNA 1.

На апрель 2026:
- **[Lemonade Server](lemonade.md)** ([AMD](https://www.amd.com/en/developer/resources/technical-articles/2026/lemonade-for-local-ai.html)) -- unified API для GPU + NPU через ONNX RT GenAI + VitisAI EP, hybrid prefill/decode split
- **FastFlowLM** -- NPU-оптимизированный backend, Linux support с v0.9.35 (март 2026)
- **Поддерживаемые модели на NPU**: только малые (Gemma 4 E2B/E4B, Phi-4-mini, Llama 3.2 3B)
- **Крупные модели (14B+)**: NPU не тянет -- 50 TOPS INT8 < GPU throughput на порядок
- **llama.cpp**: прямой XDNA-backend **не существует**. Только через Lemonade/FastFlowLM/ONNX Runtime

## Фундаментальные ограничения

### 1. Bandwidth ceiling

Token generation (tg) на inference ограничена **пропускной способностью памяти**, не compute. Каждый сгенерированный токен требует прочитать все веса модели из памяти (memory-bound).

```
tg_max (tok/s) = bandwidth / model_size

Примеры (256 GB/s theoretical):
  1.5B Q8 (1.5 GiB):  256 / 1.5  = 171 tok/s (реально 121 = 71%)
  30B MoE A3B (~17 GiB active): 256 / ~3 GiB active = 85 tok/s (реально 86 = ~100%)
  80B MoE A3B (~45 GiB, 3B active): 256 / ~3 GiB active = 85 tok/s (реально 53 = 62%)
  27B dense (17 GiB): 256 / 17 = 15 tok/s (реально 12.6 = 84%)
```

**MoE-модели обходят bandwidth ceiling** -- читаются только активные эксперты (~3B из 80B), поэтому 80B MoE даёт 53 tok/s vs 12.6 для 27B dense.

**Потолок не сдвигается** без смены памяти. LPDDR5X-8000 = 256 GB/s -- это аппаратный лимит чипа. Ни оптимизация software, ни NPU его не обойдут.

### 2. GPU VRAM vs HIP allocation

96 GiB carved-out VRAM. Vulkan использует полностью (через TTM расширение до 120 GiB). HIP/ROCm ограничен ~30-35 GiB на одну аллокацию.

[AMD рекомендует](https://rocm.docs.amd.com/en/latest/how-to/system-optimization/strixhalo.html) уменьшить carved-out до 0.5-4 GiB и использовать shared TTM/GTT. Это решит HIP-проблему, но требует перенастройки BIOS + проверки что Vulkan не деградирует.

### 3. Flash Attention на Vulkan

Flash attention в llama.cpp **падает на CPU** для AMD GPU через Vulkan backend ([issue #9572](https://github.com/ggml-org/llama.cpp/issues/9572)). Coopmat2 extension поддерживается только на NVIDIA. На AMD Vulkan FA фактически не работает -- prompt processing не ускоряется.

Через ROCm/HIP flash attention работает (ROCWMMA), но ROCm в целом медленнее Vulkan для inference.

**Текущее решение**: использовать `-fa on` в пресетах (llama.cpp корректно fallback'ит на non-FA path для Vulkan), ждать Vulkan FA-реализацию для AMD.

## Нерешённые вопросы на платформе

| # | Вопрос | Статус | Где отслеживать |
|---|--------|--------|-----------------|
| 1 | **HIP allocation limit 30-35 GiB** -- Qwen3-Coder Next (45 GiB) не загружается через ROCm | открыт | [rocm-setup.md](rocm-setup.md), [AMD Strix Halo docs](https://rocm.docs.amd.com/en/latest/how-to/system-optimization/strixhalo.html) |
| 2 | **Vulkan Flash Attention** -- FA падает на CPU для AMD, prompt processing не ускорен | открыт | [llama.cpp #9572](https://github.com/ggml-org/llama.cpp/issues/9572), [#12526](https://github.com/ggml-org/llama.cpp/issues/12526) |
| 3 | **NPU для LLM inference** -- только малые модели (<4B) через Lemonade/FastFlowLM | в разработке AMD | [Lemonade Server](https://github.com/lemonade-sdk/lemonade), [Ryzen AI SW](https://www.amd.com/en/developer/resources/ryzen-ai-software.html) |
| 4 | **KV-cache reuse у Gemma 4** -- sliding window cache не переиспользуется | ограничение архитектуры | [families/gemma4.md](../models/families/gemma4.md) |
| 5 | **BIOS VRAM tuning** -- не тестировали переход с 96 GiB carved-out на 4 GiB + shared | не начат | [AMD рекомендация](https://rocm.docs.amd.com/en/latest/how-to/system-optimization/strixhalo.html) |
| 6 | **Speculative decoding** -- не тестировали на платформе (draft 1.5B + target 80B MoE) | не начат | [llama.cpp wiki](https://github.com/ggml-org/llama.cpp/wiki/Feature-matrix) |

## Перспективы ускорения

### Краткосрочные (Q2-Q3 2026)

**1. Speculative decoding (draft + verify)**

Самый перспективный метод ускорения tg без смены hardware. Малая "draft" модель (Qwen2.5-Coder 1.5B, 121 tok/s) генерирует N кандидат-токенов, большая "target" модель (Qwen3-Coder Next, 53 tok/s) верифицирует их за один forward pass.

Ожидаемый прирост: **1.5-2.5x** tg при acceptance rate 60-80%.

llama.cpp поддерживает через `--draft-model`. На платформе: 1.5B + Next оба помещаются (2 + 45 = 47 GiB).

```bash
# Не тестировали, но формально поддерживается
llama-server -m coder-next.gguf --draft-model coder-1.5b.gguf \
    --draft-n 8 --draft-p-min 0.5 -ngl 99 --port 8081
```

**Статус**: не тестировали на платформе. Приоритетный эксперимент.

**2. Vulkan Flash Attention для AMD**

Если llama.cpp реализует FA через Vulkan без coopmat2 (через compute shaders), prompt processing ускорится в 2-4x. Это уменьшит time-to-first-token на длинных промптах (32K+ контекст).

**Где отслеживать**: [ggml-org/llama.cpp discussions](https://github.com/ggml-org/llama.cpp/discussions), PR с тегом `vulkan`.

**3. NPU+GPU hybrid через Lemonade**

AMD Lemonade Server позволяет запускать маленькую модель (speculative draft или FIM 1.5B) на NPU, освобождая GPU для основной модели. Теоретически: FIM на NPU (50 TOPS INT8 достаточно для 1.5B) + chat на GPU параллельно без конфликта по bandwidth.

FastFlowLM v0.9.35 поддерживает Linux + контекст до 256K. Но:
- Только ONNX-формат (не GGUF) -- требуется конвертация
- Пока только E2B/E4B (2B/4B) модели на NPU
- OpenAI-compatible API через Lemonade -- можно подключить к [opencode](../ai-agents/agents/opencode/README.md)

**Статус**: экспериментальный. Тестировать после установки Lemonade Server.

**4. BIOS: переход на shared memory model**

AMD [рекомендует](https://rocm.docs.amd.com/en/latest/how-to/system-optimization/strixhalo.html) carved-out VRAM 0.5-4 GiB вместо 96 GiB, с увеличением shared TTM/GTT:
- Решит HIP allocation limit (модели >35 GiB через ROCm)
- Потенциально: Vulkan и HIP используют одну и ту же физическую память, нет разницы в скорости
- Риск: не тестировали, Vulkan может деградировать на некоторых workloads

### Среднесрочные (Q3-Q4 2026)

**5. KV-cache compression (Q4/Q8 KV)**

llama.cpp поддерживает `--cache-type-k q4_0 --cache-type-v q4_0` -- квантизация KV-cache. Уменьшает memory footprint KV-cache в 4-8x, позволяя:
- Больший контекст при том же VRAM (256K → 512K+)
- Больше параллельных слотов (--parallel 4 → 8)
- Незначительная деградация качества (~1-2% на downstream задачах)

**6. Tensor parallelism (dual Strix Halo)**

[Sapphire анонсировала](https://www.starryhope.com/minipcs/sapphire-linked-strix-halo-mini-pc-cluster-llm-inference/) linked dual-unit Strix Halo cluster для 235B+ моделей. Два чипа с 256 GiB unified memory через высокоскоростной interconnect. Потенциально: Qwen3-VL 235B-A22B локально.

**Статус**: hardware не доступен, отслеживать.

**7. AMD ROCm improvements для gfx1151**

ROCm 7.2.1 -- текущая стабильная. Ожидаются:
- Улучшение hipMalloc для APU (решение allocation limit)
- Оптимизация ROCWMMA для RDNA 3.5
- Нативная поддержка gfx1151 без HSA_OVERRIDE (уже частично)

### Долгосрочные (2027+)

**8. RDNA 4 / XDNA 3**

Следующее поколение APU (Strix Point successor): RDNA 4 CU + XDNA 3 NPU. Ожидается:
- Увеличение compute density (больше CU)
- Быстрее memory (LPDDR5X-9600 → ~300 GB/s)
- Зрелый NPU-стек (XDNA 3 с увеличенным on-chip memory)

**9. Прямой XDNA-backend в llama.cpp**

Пока существует только через Lemonade/ONNX Runtime. Прямой ggml-backend для XDNA потенциально даст лучшую производительность на малых моделях (draft model, FIM, embeddings).

[Feature request #14377](https://github.com/ggml-org/llama.cpp/issues/14377) открыт в llama.cpp.

## Сводка: что даёт каждый вычислитель

| Вычислитель | Текущее использование | Теоретическая роль | Зрелость стека |
|-------------|----------------------|---------------------|----------------|
| **GPU (RDNA 3.5)** | Основной inference (Vulkan) | Основной inference | Высокая (Vulkan), средняя (ROCm) |
| **CPU (Zen 5)** | Fallback, CPU-only задачи | Speculative verification, preprocessing | Высокая |
| **NPU (XDNA 2)** | Не используется для LLM | Draft model, FIM, embeddings, small inference | Низкая (только Lemonade/FastFlowLM) |

**Оптимальная конфигурация (цель)**:
- GPU: основная модель (Qwen3-Coder Next 80B-A3B)
- NPU: draft model (Qwen2.5-Coder 1.5B) для speculative decoding
- CPU: preprocessing, tokenization, I/O

Это даст потенциальный прирост от speculative decoding без конкуренции за GPU bandwidth.

## Что отслеживать

| Источник | Зачем |
|----------|-------|
| [ggml-org/llama.cpp releases](https://github.com/ggml-org/llama.cpp/releases) | Vulkan FA, speculative decoding improvements, NPU backend |
| [AMD ROCm releases](https://repo.radeon.com/amdgpu-install/) | hipMalloc fix для APU, ROCWMMA improvements |
| [AMD Lemonade Server](https://github.com/lemonade-sdk/lemonade) | NPU+GPU hybrid, FastFlowLM updates |
| [AMD Ryzen AI SW](https://www.amd.com/en/developer/resources/ryzen-ai-software.html) | NPU driver updates, ONNX Runtime GenAI |
| [AMD Strix Halo optimization docs](https://rocm.docs.amd.com/en/latest/how-to/system-optimization/strixhalo.html) | BIOS/memory tuning guidelines |
| [llm-tracker.info Strix Halo](https://llm-tracker.info/AMD-Strix-Halo-(Ryzen-AI-Max+-395)-GPU-Performance) | Community benchmarks |
| [hogeheer499/strix-halo-guide](https://github.com/hogeheer499-commits/strix-halo-guide) | Community optimizations |
| [Framework Community: ROCm](https://community.frame.work/t/linux-rocm-january-2026-stable-configurations-update/79876) | Linux + ROCm stability reports |
| [r/LocalLLaMA](https://www.reddit.com/r/LocalLLaMA/) | Community benchmarks, новые оптимизации |

## Связано

- [rocm-setup.md](rocm-setup.md) -- текущий статус ROCm на платформе
- [cpu-inference.md](cpu-inference.md) -- CPU-инференс
- [benchmarking.md](benchmarking.md) -- методология замеров
- [../platform/processor.md](../platform/processor.md) -- спецификация процессора (NPU, bandwidth)
- [../models/coding.md](../models/coding.md) -- бенчмарки coding-моделей
- [vulkan-llama-cpp.md](vulkan-llama-cpp.md) -- Vulkan backend setup
