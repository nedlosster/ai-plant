# Альтернативы для локального inference: анализ рынка (апрель 2026)

Сравнение платформ для запуска LLM локально. Наша платформа -- Strix Halo (Ryzen AI Max+ 395, 128 GiB, 256 GB/s). Здесь -- конкуренты, их плюсы/минусы, и почему мы выбрали то что выбрали.

## Сегменты рынка

Локальный inference в 2026 -- четыре отчётливых сегмента:

| Сегмент | VRAM/RAM | Bandwidth | Модели | Цена | Пример |
|---------|----------|-----------|--------|------|--------|
| **Consumer GPU** | 16-32 GiB | 0.5-1.8 TB/s | до 30B Q4 | $500-5000 | RTX 4090, RTX 5090 |
| **Unified memory APU** | 64-128 GiB | 256-800 GB/s | до 122B MoE / 70B dense | $1500-5000 | **Strix Halo**, Mac M4 Max |
| **Desktop AI** | 128-256 GiB | 273-546 GB/s | до 200B | $3000-10000 | DGX Spark, Mac M3 Ultra |
| **Enterprise** | 80-192 GiB | 2-3.4 TB/s | до 400B+ | $15000+ | A100, H100, MI300X |

Наша платформа -- **unified memory APU**, ниша "большие модели за разумные деньги" с компромиссом по bandwidth.

## Основные конкуренты

### 1. NVIDIA RTX 5090

| Параметр | RTX 5090 | Наша платформа |
|----------|----------|----------------|
| **VRAM** | 32 GiB GDDR7 | 96-120 GiB unified |
| **Bandwidth** | **1.79 TB/s** | 256 GB/s |
| **Макс модель** | 30B Q4 (32 GiB лимит) | **122B MoE** (120 GiB) |
| **tg 7B Q4** | ~180 tok/s | ~120 tok/s |
| **tg 30B MoE Q4** | не влезает (>32 GiB) | **86 tok/s** |
| **tg 70B Q4** | не влезает | ~5 tok/s (dense) |
| **Цена** | $3000-5000 (2026, дефицит) | ~$2000-3000 (mini PC) |
| **TDP** | 575W | 120W (APU) |
| **CUDA** | да | нет (Vulkan/ROCm) |
| **FP16 compute** | ~200 TFLOPS | ~30 TFLOPS |

**Плюсы RTX 5090**: в 7x больше bandwidth → на малых моделях (7-14B) в 1.5-2x быстрее. CUDA экосистема -- PyTorch, vLLM, TensorRT-LLM работают из коробки. Flash Attention нативно.

**Минусы**: 32 GiB VRAM -- жёсткий потолок. Модели >30B Q4 не влезают вообще. Для 70B+ нужен второй GPU или CPU offload (медленно). Дефицит и завышенные цены ($3000-5000 в 2026). TDP 575W -- требует мощный БП и охлаждение.

**Вердикт**: RTX 5090 лучше для **маленьких моделей с максимальной скоростью** (7-14B). Наша платформа лучше для **больших моделей** (30B+ MoE, 70B+) которые на 5090 не помещаются.

### 2. Apple Mac Studio M4 Max (128 GiB)

| Параметр | Mac M4 Max 128 GiB | Наша платформа |
|----------|---------------------|----------------|
| **RAM** | 128 GiB unified | 128 GiB unified |
| **Bandwidth** | **546 GB/s** | 256 GB/s |
| **GPU** | 40-core (Apple Silicon) | 40 CU RDNA 3.5 |
| **tg 27B dense Q4** | ~25-30 tok/s | ~12.6 tok/s |
| **tg 30B MoE Q4** | ~50-60 tok/s | **86 tok/s** |
| **Цена** | ~$3500-4000 | ~$2000-3000 |
| **TDP** | ~80W | ~120W |
| **OS** | macOS | Linux |
| **CUDA** | нет (MLX/Metal) | нет (Vulkan/ROCm) |

**Плюсы Mac M4 Max**: в 2x больше bandwidth → dense-модели быстрее. Зрелый MLX-стек для Apple Silicon. Тихий, компактный, энергоэффективный. macOS UX.

**Минусы**: дороже ($3500-4000 за 128 GiB). Закрытая экосистема -- нет ROCm, нет Vulkan compute shaders. На MoE-моделях **наша платформа быстрее** (86 vs ~60 tok/s на 30B MoE) из-за оптимизации llama.cpp Vulkan для RDNA. Linux даёт больше контроля (BIOS VRAM, kernel params). Нет NPU для LLM (Neural Engine слабее XDNA 2 для inference).

**Вердикт**: Mac -- лучший выбор для **dense-моделей** (27-70B) благодаря bandwidth. Наша платформа выигрывает на **MoE-моделях** и по цене. Для Linux-инфраструктуры и серверных задач -- наша платформа однозначно.

### 3. Apple Mac Studio M3 Ultra (192 GiB)

| Параметр | Mac M3 Ultra 192 GiB | Наша платформа |
|----------|----------------------|----------------|
| **RAM** | 192 GiB unified | 128 GiB unified |
| **Bandwidth** | **819 GB/s** | 256 GB/s |
| **Макс модель** | **235B MoE** | 122B MoE |
| **tg 27B dense Q4** | ~35-40 tok/s | ~12.6 tok/s |
| **tg 70B dense Q4** | ~18 tok/s | ~5 tok/s |
| **Цена** | **$5000-7000** | ~$2000-3000 |

**Плюсы**: 192 GiB → помещается Qwen3-VL 235B-A22B (Q4). 819 GB/s bandwidth -- в 3x быстрее на dense. Единственная consumer-платформа для 200B+ моделей.

**Минусы**: цена $5000-7000. macOS-only. M3 Ultra -- прошлое поколение (M4 Ultra ожидается). Тот же закрытый стек (MLX/Metal). 512 GiB вариант снят с продажи.

**Вердикт**: для тех, кому нужны **200B+ модели локально** -- единственный реалистичный вариант в consumer-сегменте. Для 30-122B наша платформа -- вдвое дешевле.

### 4. NVIDIA DGX Spark (GB10)

| Параметр | DGX Spark | Наша платформа |
|----------|-----------|----------------|
| **RAM** | 128 GiB unified (Grace Blackwell) | 128 GiB unified |
| **Bandwidth** | **273 GB/s** | 256 GB/s |
| **GPU** | Blackwell (CUDA) | RDNA 3.5 (Vulkan/ROCm) |
| **FP4 AI** | **1 PFLOP** | -- |
| **tg 70B dense Q4** | ~15-20 tok/s | ~5 tok/s |
| **Цена** | **$4700** | ~$2000-3000 |
| **TDP** | 125W | 120W |
| **CUDA** | **да** | нет |

**Плюсы DGX Spark**: CUDA из коробки -- PyTorch, TensorRT-LLM, vLLM без танцев с бубном. Blackwell GPU с native FP4 → лучше compute для prompt processing. Speculative decoding оптимизирован (2.5x в 2026 через SW update). ARM CPU (Grace) оптимизирован для inference.

**Минусы**: $4700 -- почти вдвое дороже Strix Halo mini PC. Bandwidth сопоставим (273 vs 256 GB/s) -- на tg разница минимальна. Нет десктопного GPU для gaming/rendering. ARM -- ограниченная совместимость x86 software. Закрытый NVIDIA-стек.

**Вердикт**: для тех, кому критичен **CUDA-стек** (PyTorch training, TensorRT, vLLM). Для inference через llama.cpp наша платформа -- аналогичная скорость за полцены.

### 5. Другие Strix Halo mini PC

| Модель | CPU | RAM | Цена (2026) | Особенность |
|--------|-----|-----|-------------|-------------|
| **Beelink GTR9 Pro** | Ryzen AI Max+ 395 | 128 GiB | $2000-3000 | Dual 10GbE, USB4, компактный |
| **Framework Desktop** | Ryzen AI Max+ 395 | 128 GiB | $2000 (base) | Модульный, ремонтопригодный |
| **GMKtec EVO-X2** | Ryzen AI Max+ 395 | 128 GiB | $1700-3000 | Бюджетный |
| **Sapphire Linked Dual** | 2x Max+ 395 | **256 GiB** | ~$5000+ | Для 235B+ моделей |
| **Meigao MS-S1 MAX** ⭐ | Ryzen AI Max+ 395 | 128 GiB | ~$2000 | Наша платформа |

Все используют один и тот же чип -- различия в корпусе, портах, охлаждении, цене.

### 6. RTX 4090 (прошлое поколение)

| Параметр | RTX 4090 | Наша платформа |
|----------|----------|----------------|
| **VRAM** | 24 GiB GDDR6X | 96-120 GiB unified |
| **Bandwidth** | **1.01 TB/s** | 256 GB/s |
| **Макс модель** | 14B Q4 (24 GiB) | **122B MoE** |
| **tg 7B Q4** | ~130 tok/s | ~120 tok/s |
| **Цена** | $1500-2000 (б/у) | ~$2000-3000 |

**Вердикт**: в 2026 RTX 4090 -- только для моделей до 14B. Наша платформа объективно лучше на крупных моделях, сопоставима на мелких.

## Сводная таблица

| Платформа | VRAM/RAM | BW (GB/s) | Макс модель | tg 30B MoE | tg 70B dense | Цена | CUDA |
|-----------|----------|-----------|-------------|------------|--------------|------|------|
| **Strix Halo** ⭐ | 120 GiB | 256 | 122B MoE | **86** | 5 | $2-3K | нет |
| RTX 5090 | 32 GiB | 1790 | 30B Q4 max | -- | -- | $3-5K | да |
| Mac M4 Max 128G | 128 GiB | 546 | 70B dense | ~60 | ~14 | $3.5-4K | нет |
| Mac M3 Ultra 192G | 192 GiB | 819 | 235B MoE | ~80 | **18** | $5-7K | нет |
| DGX Spark | 128 GiB | 273 | 200B | ~65 | ~15 | $4.7K | **да** |
| RTX 4090 | 24 GiB | 1010 | 14B Q4 max | -- | -- | $1.5-2K | да |

## Какие модели на какой платформе

| Модель | Strix Halo | RTX 5090 | Mac M4 Max | DGX Spark | Mac M3 Ultra |
|--------|------------|----------|------------|-----------|--------------|
| Qwen2.5-Coder 1.5B Q8 | 121 tok/s | ~200+ | ~150 | ~130 | ~170 |
| Qwen3-Coder 30B-A3B Q4 | **86** | не влезает | ~60 | ~65 | ~80 |
| Qwen3-Coder Next 80B-A3B Q4 | **53** | не влезает | ~35 | ~40 | ~50 |
| Qwen3.5-122B-A10B Q4 | **22** | не влезает | не влезает | ~18 | ~25 |
| Qwen3-VL 235B-A22B Q4 | не влезает | не влезает | не влезает | не влезает | **~15** |

## Зачем Strix Halo: обоснование выбора

1. **120 GiB -- sweet spot** для MoE-моделей 2025-2026. Qwen3-Coder Next (80B, 45 GiB) и 122B-A10B (71 GiB) помещаются с запасом. На RTX 5090 (32 GiB) не помещаются вообще.

2. **MoE-ускорение** через малую активацию. На MoE-моделях bandwidth ceiling рассчитывается по active parameters, не total. 80B MoE с 3B active даёт 53-86 tok/s -- сравнимо с Mac M4 Max при вдвое меньшей цене.

3. **Цена/VRAM** -- лучшее в индустрии. $2000-3000 за 128 GiB unified -- вдвое дешевле Mac M4 Max 128G ($3500-4000), втрое дешевле Mac M3 Ultra ($5000-7000).

4. **Linux + open-source стек** -- полный контроль: BIOS VRAM tuning, kernel params, llama.cpp source, ROCm, Vulkan. На Mac -- закрытый MLX, на DGX Spark -- NVIDIA-зависимость.

5. **Три вычислителя** (CPU + GPU + NPU) на одном чипе. NPU-стек пока незрелый, но перспективен для draft model / FIM. См. [acceleration-outlook.md](../inference/acceleration-outlook.md).

6. **120W TDP** -- можно питать от обычной розетки, работает тихо. RTX 5090 = 575W.

## Когда Strix Halo -- не лучший выбор

| Сценарий | Лучше взять | Почему |
|----------|-------------|--------|
| Максимальная скорость на 7-14B моделях | **RTX 5090** | 1.79 TB/s bandwidth, 180+ tok/s |
| Модели 200B+ локально | **Mac M3 Ultra 192G** | 192 GiB + 819 GB/s |
| CUDA-зависимые workflow (PyTorch training, TensorRT) | **DGX Spark** | Нативный CUDA + Blackwell |
| Dense-модели 70B+ с высокой скоростью | **Mac M4 Max 128G** | 546 GB/s vs 256 GB/s |
| Бюджет < $1000 | **RTX 4090 б/у** | 24 GiB за $1500 |
| Cloud inference (нет hardware) | **API** (Claude, GPT, Kimi) | $0 upfront |

## Что отслеживать

| Событие | Влияние на рынок | Ожидание |
|---------|-----------------|----------|
| **Mac Studio M5 Ultra** | 256+ GiB, ~1 TB/s bandwidth | Q3-Q4 2026 |
| **RTX 5090 Ti / PRO** | 48 GiB VRAM (если выйдет) | 2026-2027 |
| **Sapphire Linked Dual Strix Halo** | 256 GiB unified для 235B+ | Q2-Q3 2026 |
| **Strix Point (RDNA 4 APU)** | Следующее поколение, ~300 GB/s | 2027 |
| **DGX Spark SW updates** | Speculative decoding, TensorRT improvements | постоянно |

## Ссылки

- [llm-tracker.info: GPU Comparison](https://llm-tracker.info/GPU-Comparison) -- актуальные бенчмарки разных GPU
- [llm-tracker.info: Strix Halo](https://llm-tracker.info/AMD-Strix-Halo-(Ryzen-AI-Max+-395)-GPU-Performance) -- community benchmarks
- [What to Buy for Local LLMs (April 2026)](https://julsimon.medium.com/what-to-buy-for-local-llms-april-2026-a4946a381a6a) -- обзорная статья
- [Best Hardware for Local LLMs 2026 (ToolHalla)](https://toolhalla.ai/blog/best-hardware-for-local-llms-2026) -- сравнение 5 платформ
- [hogeheer499/strix-halo-guide](https://github.com/hogeheer499-commits/strix-halo-guide) -- community guide
- [NVIDIA DGX Spark](https://www.nvidia.com/en-us/products/workstations/dgx-spark/) -- официальная страница
- [Apple Mac Studio](https://www.apple.com/mac-studio/) -- текущая конфигурация
- [Framework Desktop](https://frame.work/) -- модульный Strix Halo
- [Beelink GTR9 Pro Review (ServeTheHome)](https://www.servethehome.com/beelink-gtr9-pro-review-amd-ryzen-ai-max-395-system-with-128gb-and-dual-10gbe/) -- обзор

## Связано

- [acceleration-outlook.md](../inference/acceleration-outlook.md) -- перспективы ускорения на нашей платформе
- [processor.md](processor.md) -- спецификация процессора
- [../inference/benchmarking.md](../inference/benchmarking.md) -- методология замеров
- [../models/coding.md](../models/coding.md#open-vs-облачные-лидеры-апрель-2026) -- open vs closed модели
