# LLM общего назначения

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), llama-server + Vulkan.

Полные описания моделей -- в [`families/`](families/README.md). Эта страница: сравнительные таблицы и выбор под задачу.

## Скачано на платформе

| Модель | Семейство | Параметры | Пресет |
|--------|-----------|-----------|--------|
| Qwen3.5-27B | [qwen35](families/qwen35.md#27b) | 27B dense | `vulkan/preset/qwen3.5-27b.sh` |
| Qwen3.5-122B-A10B | [qwen35](families/qwen35.md#122b-a10b) | 122B MoE / 10B active | `vulkan/preset/qwen3.5-122b.sh` |
| Gemma 4 26B-A4B | [gemma4](families/gemma4.md) | 26B MoE / 3.8B active | `vulkan/preset/gemma4.sh` |

## Сравнительная таблица

| Модель | Семейство | Параметры | Active | Контекст | VRAM Q4 | Русский |
|--------|-----------|-----------|--------|----------|---------|---------|
| Qwen3.5-122B-A10B | [qwen35](families/qwen35.md#122b-a10b) | 122B MoE | 10B | 128K | ~71 GiB | отличный |
| Qwen3.5-35B-A3B | [qwen35](families/qwen35.md) | 35B MoE | 3B | 128K | ~22 GiB | отличный |
| Qwen3.5-27B | [qwen35](families/qwen35.md#27b) | 27B dense | 27B | 128K | ~17 GiB | отличный |
| Gemma 4 26B-A4B | [gemma4](families/gemma4.md) | 26B MoE | 3.8B | **256K** | ~17 GiB + mmproj | хороший |
| Mixtral 8x22B | [mixtral](families/mixtral.md) | 141B MoE | 39B | 64K | ~82 GiB | средний |
| Command A | [command-a](families/command-a.md) | 111B dense | 111B | 256K | ~65 GiB | средний |
| Llama-3.3-70B | [llama](families/llama.md#3-3-70b) | 70B dense | 70B | 128K | ~42 GiB / Q8 ~74 GiB | базовый |
| Llama 4 Scout | [llama](families/llama.md#4-scout) | 109B MoE | 17B | **10M** | ~67 GiB | средний |
| QwQ-32B | [qwq](families/qwq.md) | 32B dense | 32B | 32K | ~19 GiB | хороший |
| DeepSeek-R1-Distill-32B | [deepseek-distill](families/deepseek-distill.md) | 32B dense | 32B | 128K | ~19 GiB | средний |
| Phi-4 | [phi](families/phi.md) | 14B dense | 14B | 16K | ~9 GiB | слабый |
| Llama-3.1-8B | [llama](families/llama.md) | 8B dense | 8B | 128K | ~5 GiB | базовый |

## Что открывает 120 GiB (было недоступно при 96 GiB)

| Категория | При 96 GiB | При 120 GiB |
|-----------|-----------|-------------|
| 70B dense в Q8_0 + ctx 32K | ~90 GiB, нестабильно | ~94 GiB, запас 26 GiB |
| Mixtral 8x22B Q4_K_M | ~82 GiB, без контекста | + ctx 32K, запас ~20 GiB |
| Command A 111B Q5_K_M | не помещается (~78 GiB) | помещается |
| 122B MoE + параллельный FIM | ~73 GiB, мало запаса | ~73 GiB, запас 47 GiB |

## Выбор под задачу

### Универсальный русскоязычный chat

[Qwen3.5-27B](families/qwen35.md#27b) -- основная рабочая модель платформы. Лучший русский в среднем сегменте.

### Максимум качества для сложных задач

[Qwen3.5-122B-A10B](families/qwen35.md#122b-a10b) -- 10B active, multimodal, флагман на платформе.
[Llama-3.3-70B Q8](families/llama.md#3-3-70b) -- максимум dense, помещается с запасом 26 GiB.

### Multimodal (text + images)

[Gemma 4 26B-A4B](families/gemma4.md) -- function calling, 256K контекст, на платформе через пресет.
[Qwen3.5-27B](families/qwen35.md#27b) или [122B](families/qwen35.md#122b-a10b) -- мультимодальные из коробки.

### Длинный контекст

[Llama 4 Scout](families/llama.md#4-scout) -- 10M токенов (уникально для open-source).
[Gemma 4 26B-A4B](families/gemma4.md) -- 256K с native function calling.

### Reasoning (математика, логика)

[QwQ-32B](families/qwq.md) -- chain-of-thought, MATH-500 95.2, Apache 2.0.
[DeepSeek-R1-Distill-32B](families/deepseek-distill.md) -- MATH-500 94.3, MIT.
[Phi-4](families/phi.md) -- reasoning при минимальном VRAM (9 GiB Q4).

### RAG, function calling, tool use

[Command A 111B](families/command-a.md) -- специализирована (CC-BY-NC).
[Gemma 4 26B-A4B](families/gemma4.md) -- function calling из коробки, Apache.

### Английский (максимальное качество)

[Llama-3.3-70B Q8](families/llama.md#3-3-70b) -- эталон open-source dense.

## Что помещается в 120 GiB

| VRAM | Модели (Q4_K_M) |
|------|-----------------|
| <10 GiB | Qwen3.5-9B, Llama-3.1-8B, Phi-4, R1-Distill-14B |
| 10-25 GiB | Qwen3.5-27B, Qwen3.5-35B-A3B, QwQ-32B, R1-Distill-32B, Gemma 4 26B |
| 25-50 GiB | Llama-3.3-70B Q4 (~42), Qwen2.5-72B Q4 (~44) |
| 50-85 GiB | Qwen3.5-122B-A10B (~71), Llama 4 Scout (~67), Command A (~65), Mixtral 8x22B (~82) |
| 85-120 GiB | Llama-3.3-70B Q8 (~74) + ctx 32K, Qwen2.5-72B Q8 (~78) + ctx 16K |

Два сервера одновременно: Coder 1.5B Q8 (~2 GiB) + Qwen3.5-27B Q4 (~17 GiB) = ~19 GiB. Остаётся ~101 GiB.

## Русский язык (рейтинг)

1. [Qwen3.5-122B-A10B](families/qwen35.md#122b-a10b) -- лучший
2. [Qwen3.5-27B / 35B-A3B](families/qwen35.md) -- отличный
3. [QwQ-32B](families/qwq.md) -- хороший + reasoning
4. [Mixtral 8x22B](families/mixtral.md) -- средний, быстрый MoE
5. [DeepSeek-R1-Distill-32B](families/deepseek-distill.md) -- средний, отличный reasoning
6. [Llama-3.3-70B / Llama 4](families/llama.md) -- базовый
7. [Phi-4](families/phi.md) -- слабый

См. также [russian-llm.md](russian-llm.md) -- finetune'ы под русский.

## Ожидается open weights

[Qwen3.6-Plus](families/qwen36.md) -- свежий флагман Alibaba (апрель 2026). Контекст **1M токенов**, native function calling, multimodal, always-on chain-of-thought. Сейчас API-only через Alibaba Cloud Model Studio, open-варианты обещаны "в developer-friendly размерах". По аналогии с Qwen3.5 -- ждать 30-122B диапазон.

[Kimi K2.5](families/kimi-k25.md) -- open-weight 1T MoE / 32B active от Moonshot AI (январь 2026). Native multimodal, Agent Swarm, SWE-Bench Verified 76.8%, AIME 2025 96.1%. Веса открыты, но **не помещаются** на платформу даже в Dynamic 1.8-bit (240+ GiB). Используется через API ($0.45/1M input) после блокировки Anthropic Pro/Max в third-party tools апреля 2026.

## Не помещаются на платформе (для справки)

- GLM-5 / GLM-5.1 (744B) -- 440 GB Q4
- MiniMax M2.5 -- 150 GB Q4
- DeepSeek V3.2 (671B MoE) -- 390 GB Q4
- DeepSeek-Coder-V2 (236B MoE) -- 135 GB Q4
- Llama 4 Maverick (400B MoE) -- 240 GB Q4
- Qwen3.5-397B MoE -- 230 GB Q4
- Trinity-Large-Thinking (399B)

В каталог не включены, см. описание в README.md.

## Связанные направления

- [coding.md](coding.md) -- специализированные модели для кода
- [vision.md](vision.md) -- multimodal (text + images)
- [russian-llm.md](russian-llm.md) -- finetune'ы под русский

## Связанные статьи

- [Анатомия LLM](../llm-guide/model-anatomy.md)
- [Квантизация](../llm-guide/quantization.md)
- [HuggingFace](../llm-guide/huggingface.md)
- [Бенчмарки](../inference/benchmarking.md)
