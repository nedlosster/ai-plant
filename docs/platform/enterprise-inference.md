# Enterprise inference: обзор рынка (апрель 2026)

Как устроен inference в datacenter-масштабе: hardware, стоимость, self-hosted vs API, и зачем об этом знать при работе на consumer-платформе.

## Зачем это знать

При использовании локальной платформы (Strix Halo, 120 GiB, 256 GB/s) полезно понимать:
- Сколько стоит альтернатива через API (когда local не вытягивает)
- Какие GPU стоят за Claude Opus, GPT-5, Kimi K2.5 -- чтобы понимать разницу в качестве
- Когда self-hosted выгоднее API, а когда наоборот
- Какие технологии из enterprise попадут в consumer через 1-2 года

## Datacenter GPU: текущий landscape

### NVIDIA (доминирует ~80% рынка inference)

| GPU | VRAM | Bandwidth | FP16 TFLOPS | TDP | Цена (покупка) | Cloud $/hr (апр 2026) |
|-----|------|-----------|-------------|-----|-----------------|------------|
| **B200** | 192 GiB HBM3e | **8 TB/s** | 2250 | 1000W | ~$30-40K | **$5.62** (avg, +15% YoY) |
| **H200** | 141 GiB HBM3e | 4.8 TB/s | 990 | 700W | ~$25-30K | **$3.80** |
| **H100 SXM** | 80 GiB HBM3 | 3.35 TB/s | 990 | 700W | ~$25K | $2.49-3 |
| **A100 80G** | 80 GiB HBM2e | 2 TB/s | 312 | 400W | ~$10-15K | $1-1.5 |
| **L40S** | 48 GiB GDDR6 | 864 GB/s | 366 | 350W | ~$8-10K | $1-2 |

Источник цен: [getdeploying.com/gpus](https://getdeploying.com/gpus), [thundercompute.com](https://www.thundercompute.com/blog/nvidia-h200-pricing) (апрель 2026).

**B200** -- текущий флагман. 8 TB/s bandwidth = **31x больше** чем Strix Halo (256 GB/s). NVLink 5.0 (1.8 TB/s) связывает до 576 GPU в один cluster. FP4/FP6 native -- квантизация без потерь на уровне hardware.

**H100** -- рабочая лошадка inference 2024-2026. Cloud pricing упал с $12/hr (2023) до $1.5-3/hr (2026). На H100 крутятся большинство API-сервисов.

**A100** -- commodity ($1/hr). Всё ещё актуальна для inference малых/средних моделей. Нет FP8 Tensor Cores (только FP16/BF16).

### AMD (растущая доля)

| GPU | VRAM | Bandwidth | FP16 TFLOPS | TDP | Цена (покупка) | Cloud $/hr |
|-----|------|-----------|-------------|-----|-----------------|------------|
| **MI355X** | 288 GiB HBM3e | 8 TB/s | ~2500 | 1000W | ~$20-25K | $3-5 |
| **MI325X** | 256 GiB HBM3e | 6 TB/s | ~1300 | 1000W | ~$15-20K | $2.5-3 |
| **MI300X** | 192 GiB HBM3 | 5.3 TB/s | 1300 | 750W | ~$12-15K | $2-2.5 |

**MI300X** -- основной конкурент H100 для inference. 192 GiB VRAM > 80 GiB H100 -- помещаются большие модели без model parallelism. ROCm стек менее зрелый, чем CUDA, но для vLLM/TGI inference работает.

**MI355X** -- ответ на B200. При масштабировании до 4 нод дает 3.4x throughput vs MI300X.

### Другие вендоры

| Вендор | Чип | VRAM | Ниша | Статус 2026 |
|--------|-----|------|------|-------------|
| **Google** | TPU v6e (Trillium) | 32 GiB HBM | Cloud-only (GCP), Gemini inference | Production |
| **Intel** | Gaudi 3 | 128 GiB HBM2e | Cost-effective inference, AWS | Ограничен |
| **AWS** | Trainium 2 | 96 GiB HBM | AWS-only, дешёвый training | Раннее adoption |
| **Groq** | LPU (SRAM) | 230 MB SRAM | Ultra-low latency inference | Нишевый |

**Groq LPU** -- фундаментально другой подход: модель целиком в SRAM (не HBM), 0 memory latency. Рекорды по tok/s, но максимальный размер модели ограничен SRAM (~8B без шардинга).

## Стоимость API inference (апрель 2026)

### Frontier-модели

| Модель | $/1M input | $/1M output | Провайдер |
|--------|-----------|-------------|-----------|
| GPT-5 | $10 | $30 | OpenAI |
| Claude Opus 4.6 | $5 | $25 | Anthropic |
| Gemini 2.5 Pro | $1.25 | $5 | Google |
| GPT-4o | $2.50 | $10 | OpenAI |
| Claude Sonnet 4.5 | $3 | $15 | Anthropic |

### Бюджетные / open-source через API

| Модель | $/1M input | $/1M output | Провайдер |
|--------|-----------|-------------|-----------|
| Kimi K2.5 | **$0.45** | $1.35 | Moonshot |
| DeepSeek V3.2 | $0.14 | $0.28 | DeepSeek |
| GPT-4.1 Nano | $0.10 | $0.40 | OpenAI |
| Gemini 2.0 Flash | $0.10 | $0.40 | Google |
| Mistral Small | $0.10 | $0.30 | Mistral |

### Тренд: LLMflation

Стоимость inference падает экспоненциально. [a16z фиксирует](https://a16z.com/llmflation-llm-inference-cost/) снижение в ~10x за год для эквивалентного качества. GPT-4-уровень в 2023 стоил $30/1M tokens, в 2026 -- $0.10-0.50 через бюджетные модели.

## Self-hosted vs API: когда что выгоднее

### Break-even анализ

| Объём (tokens/день) | Self-hosted (H100 spot) | API (GPT-4o) | API (DeepSeek V3.2) | Выгоднее |
|---------------------|------------------------|--------------|----------------------|----------|
| 100K | $1.20/день | $0.25 | $0.01 | API |
| 1M | $1.20/день | $2.50 | $0.14 | API (DeepSeek) |
| 10M | $1.20/день | $25 | $1.40 | Self-hosted |
| 100M | $1.20/день | $250 | $14 | Self-hosted |

**Break-even**: ~10-50M tokens/день при использовании дешёвых API (DeepSeek). При дорогих API (GPT-5) break-even уже при ~1M tokens/день.

**Наша платформа**: $0/день (электричество ~$0.20/день при 120W 24/7). Break-even vs API -- при **любом** регулярном использовании. Но: модели ограничены тем, что помещается в 120 GiB.

### Когда API лучше локального

| Сценарий | Почему API |
|----------|-----------|
| Frontier-качество (Claude Opus, GPT-5) | Моделей нет в open-source |
| Редкое использование (<1K tokens/день) | Не окупает стоимость hardware |
| 200B+ модели | Не помещаются ни на одну consumer-платформу |
| Burst-нагрузка (100 параллельных запросов) | Consumer GPU не тянет параллелизм |
| Compliance / SLA / uptime 99.9% | Cloud infrastructure надёжнее домашнего сервера |

### Когда self-hosted лучше

| Сценарий | Почему self-hosted |
|----------|-------------------|
| Privacy (код, данные, документы) | Данные не покидают инфраструктуру |
| Объём >10M tokens/день | В 10-100x дешевле API |
| Нет интернета / air-gap | API недоступны |
| Кастомизация (fine-tune, special prompts) | Полный контроль |
| Эксперименты с моделями | Переключение между 10+ моделями бесплатно |
| Латентность (<100ms first token) | Локальный сервер быстрее round-trip через интернет |

## Сравнение с нашей платформой

| Метрика | Strix Halo (120 GiB) | 1x H100 (80 GiB) | 1x MI300X (192 GiB) | 8x H100 DGX |
|---------|----------------------|-------------------|----------------------|-------------|
| **VRAM** | 120 GiB | 80 GiB | **192 GiB** | **640 GiB** |
| **Bandwidth** | 256 GB/s | 3.35 TB/s | 5.3 TB/s | 26.8 TB/s |
| **tg 70B Q4** | ~5 tok/s | ~80 tok/s | ~100 tok/s | ~400 tok/s |
| **tg 30B MoE A3B** | **86 tok/s** | ~200 tok/s | ~250 tok/s | N/A |
| **Макс модель** | 122B MoE | 70B Q4 | **120B Q4** | **405B+** |
| **Цена** | **$2-3K** (разово) | $1.5-3/hr (cloud) | $2-2.5/hr (cloud) | $12-24/hr |
| **$/год** | **~$70** (электричество) | $13-26K | $18-22K | $105-210K |
| **TDP** | **120W** | 700W | 750W | 5600W |

### Скорости coding-моделей: наша платформа vs H100

| Модель | Strix Halo (Vulkan) | H100 (vLLM, est.) | Разница | Стоимость |
|--------|--------------------|--------------------|---------|-----------|
| Qwen2.5-Coder 1.5B Q8 | **121 tok/s** | ~300+ tok/s | 2.5x | $0 vs $1.5-3/hr |
| Qwen3-Coder 30B-A3B Q4 | **86 tok/s** | ~200 tok/s | 2.3x | $0 vs $1.5-3/hr |
| Qwen3-Coder Next 80B-A3B Q4 | **53 tok/s** | ~120 tok/s | 2.3x | $0 vs $1.5-3/hr |
| Devstral 2 24B Q4 (dense) | **~25 tok/s** | ~80 tok/s | 3.2x | $0 vs $1.5-3/hr |

MoE-модели (Qwen3-Coder) сглаживают разрыв: 13x разница в bandwidth (3.35 TB/s vs 256 GB/s), но только 2.3x разница в tg -- потому что MoE читает ~3 GiB активных весов, а не 45 GiB total. Dense-модели (Devstral 2) показывают разрыв ближе к bandwidth ratio.

**53 tok/s** на Qwen3-Coder Next (80B MoE, 70.6% SWE-V) -- **достаточно для интерактивного agent-loop** в [opencode](../ai-agents/agents/opencode.md)/[Cline](../ai-agents/agents/cline.md). На H100 было бы быстрее, но не качественнее -- модель та же, score тот же.

**Ключевой вывод**: Strix Halo -- это **$70/год** vs **$13-210K/год** для enterprise GPU. Разница в bandwidth (256 GB/s vs 3.35 TB/s) компенсируется MoE-архитектурой для daily-задач. Для frontier-качества (200B+, параллелизм) -- только enterprise или API.

## Архитектура enterprise inference

### Типичный production-стек

```
Load Balancer (nginx / Envoy)
        |
   +---------+---------+
   |         |         |
vLLM #1   vLLM #2   vLLM #3    (каждый на H100/MI300X)
   |         |         |
   Model sharding (tensor parallelism)
   |
   KV-cache (PagedAttention)
   |
   Speculative decoding (draft + verify)
```

### Ключевые технологии (enterprise → consumer pipeline)

| Технология | Enterprise (2024-2025) | Consumer (2026+) |
|-----------|------------------------|-------------------|
| **Speculative decoding** | TensorRT-LLM, vLLM | llama.cpp `--draft-model` (не тестировали) |
| **PagedAttention** | vLLM standard | llama.cpp partial support |
| **FP4/FP6 quantization** | B200 native | GGUF IQ4, Q4_K_M (аналог) |
| **KV-cache compression** | FlashInfer, vLLM | llama.cpp `--cache-type-k q4_0` |
| **Tensor parallelism** | NVLink / InfiniBand | Dual Strix Halo (Sapphire, ожидается) |
| **Continuous batching** | vLLM, TGI standard | llama.cpp `--parallel N` |

Технологии мигрируют из enterprise в consumer с задержкой 6-18 месяцев. Speculative decoding -- ближайший кандидат для нашей платформы.

## Провайдеры cloud GPU (апрель 2026)

### Tier 1: крупные облака

| Провайдер | GPU | $/hr | Минимум | SLA |
|-----------|-----|------|---------|-----|
| AWS (p5) | H100 | $12.30 | 1 hour | 99.99% |
| Azure (ND H100) | H100 | $10-14 | 1 hour | 99.9% |
| GCP (a3-highgpu) | H100 | $11.50 | 1 minute | 99.9% |

### Tier 2: специализированные

| Провайдер | GPU | $/hr | Минимум | Плюсы |
|-----------|-----|------|---------|-------|
| Lambda Labs | H100 | $2.49 | 1 hour | Простой UX, spot instances |
| Vast.ai | H100/A100 | $1.5-2.5 | 1 hour | Marketplace, дёшево |
| RunPod | H100/A100 | $2-3 | 1 minute | Serverless, community |
| Together AI | H100 | $2-3 | per token | API + dedicated |
| Voltage Park | H100 | $2.00 | 1 hour | Cheapest on-demand |

### Tier 3: AMD-специфичные

| Провайдер | GPU | $/hr | Примечание |
|-----------|-----|------|------------|
| AMD Cloud | MI300X | $2-2.5 | ROCm native |
| Vultr | MI300X | $2.4 | vLLM optimized |

## Когда масштабировать с consumer на enterprise

| Сигнал | Решение |
|--------|---------|
| tg <10 tok/s на нужной модели | Либо меньше модель, либо cloud GPU |
| >5 параллельных пользователей | Cloud с auto-scaling |
| Модель >120 GiB | Cloud GPU (MI300X 192 GiB) или API |
| Требуется fine-tune >14B | Cloud GPU (A100+ для training) |
| Uptime >99.5% критичен | Managed inference (Together, Replicate) |

**Для нашей платформы**: масштабирование = гибридный подход. Daily-задачи на local Strix Halo ($0), frontier-задачи через API (Kimi K2.5 $0.45/1M, DeepSeek $0.14/1M). Cloud GPU -- только для [training](../training/README.md)/fine-tune.

## Ссылки

- [GPU Comparison (llm-tracker.info)](https://llm-tracker.info/GPU-Comparison) -- актуальные бенчмарки
- [LLMflation: inference cost going down (a16z)](https://a16z.com/llmflation-llm-inference-cost/) -- тренд снижения стоимости
- [Cloud GPU Pricing (getdeploying.com)](https://getdeploying.com/gpus/nvidia-h100) -- сравнение H100 провайдеров
- [LLM API Pricing Comparison (pricepertoken.com)](https://pricepertoken.com/) -- актуальные цены на 300+ моделей
- [Self-Hosting vs API Break-Even (neuralrouting.io)](https://neuralrouting.io/blog/self-hosting-llm-vs-api-break-even-2026) -- анализ окупаемости
- [MLPerf Inference v5.1 Results (HPCwire)](https://www.hpcwire.com/2025/09/10/mlperf-inference-v5-1-results-land-with-new-benchmarks-and-record-participation/) -- официальные бенчмарки
- [Best GPU for AI (Northflank)](https://northflank.com/blog/best-gpu-for-ai) -- обзор 12 GPU для AI
- [AMD MI300X vs H100 (Clarifai)](https://www.clarifai.com/blog/mi300x-vs-h100) -- детальное сравнение

## Связано

- [hardware-alternatives.md](hardware-alternatives.md) -- consumer-альтернативы (RTX 5090, Mac, DGX Spark)
- [../inference/acceleration-outlook.md](../inference/acceleration-outlook.md) -- перспективы ускорения на нашей платформе
- [../inference/rocm-setup.md](../inference/rocm-setup.md) -- ROCm на Strix Halo (связь с enterprise MI300X стеком)
- [../models/coding.md](../models/coding.md#open-vs-облачные-лидеры-апрель-2026) -- сравнение open vs closed моделей
