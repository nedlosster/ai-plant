# Анонсы и релизы моделей

Хроника релизов open-source и frontier-моделей по направлениям: LLM, coding, vision, image, video, audio. Дополняет [ai-agents/news.md](../ai-agents/news.md) (хроника AI-агентов) и [trends.md](../ai-agents/trends.md) (долгосрочные прогнозы).

Полные карточки моделей -- в [families/](families/). Сводные таблицы по направлениям -- в [llm.md](llm.md), [coding.md](coding.md), [vision.md](vision.md), [images.md](images.md), [video.md](video.md), [music.md](music.md), [russian-llm.md](russian-llm.md), [russian-vocals.md](russian-vocals.md), [tts.md](tts.md).

## 2026-Q2 (актуально)

### Apr 16 -- Qwen 3.6-35B-A3B (Alibaba): MoE vision-language, новый default daily agent на платформе

**16 апреля 2026** -- Alibaba выпустила **Qwen 3.6-35B-A3B** -- sparse Mixture-of-Experts vision-language модель с встроенным vision encoder.

| Параметр | Значение |
|----------|----------|
| Архитектура | 35B total MoE, 3B active |
| Модальности | text + vision (multimodal) |
| Лицензия | Apache 2.0 |
| Контекст | ~128K (оценка) |
| **SWE-bench Verified** | **73.4%** |
| **Terminal-Bench 2.0** | **51.5%** |
| **QwenWebBench** | **1397** |
| Размер Q4_K_M | ~20 GiB |
| Помещается на платформу | да |

Trade-off vs dense [Qwen 3.6-27B](families/qwen36.md#27b) (77.2% SWE-V, ~15 tok/s): -3.8 п.п. SWE-V в обмен на ~5× скорость генерации (оценка ~80 tok/s tg на платформе при 3B active, 256 GB/s ÷ ~1.7 GiB Q4 active с overhead). Prefill -- оценка ~700-1000 tok/s.

**Позиционирование на платформе** -- новый рекомендуемый default daily agent между 27B dense (лидер качества SWE-V) и [Qwen3-Coder 30B-A3B](families/qwen3-coder.md#30b-a3b) (86 tok/s, без vision). Vision encoder из коробки позволяет работать со скриншотами/UI/диаграммами в agent loop без отдельного mmproj-сервера. Контекст ~128K уступает [Qwen3-Coder Next](families/qwen3-coder.md#next-80b-a3b) (256K), но достаточен для большинства agentic-задач.

Источник: [HuggingFace: Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B). Карточка семейства: [families/qwen36.md](families/qwen36.md#35b-a3b).

### Apr 23 -- Qwen 3.6-27B (Alibaba): dense coding LLM, новый лидер open-source local SWE-V

**23 апреля 2026** -- Alibaba выпустила **Qwen 3.6-27B** -- dense 27B coding LLM с hybrid Gated DeltaNet архитектурой и vision encoder.

| Параметр | Значение |
|----------|----------|
| Архитектура | 27B dense, hybrid Gated DeltaNet |
| Модальности | text + vision (multimodal screenshots) |
| Лицензия | Apache 2.0 |
| **SWE-bench Verified** | **77.2%** -- #1 open-source local |
| Размер Q4_K_M | ~17 GiB |
| Помещается на платформу | да |

Превосходит [Devstral 2 24B](families/devstral.md) (72.2%) и [Qwen3-Coder Next 80B-A3B](families/qwen3-coder.md) (70.6%) на SWE-V среди моделей, влезающих в платформу. Trade-off: dense-архитектура memory-bound, оценка скорости ~15 tok/s (256 GB/s ÷ 17 GiB) -- ниже MoE-вариантов на платформе (Coder Next 53 tok/s, Coder 30B-A3B 86 tok/s).

GGUF выпущен одновременно с релизом (типичный паттерн -- unsloth/Qwen3.6-27B-GGUF, bartowski, mradermacher), llama.cpp интеграция через 48 часов после релиза. Источники: [explore.n1n.ai](https://explore.n1n.ai/blog/qwen-3-6-27b-gguf-llama-cpp-local-multimodal-2026-04-23), [aimadetools](https://www.aimadetools.com/blog/best-ollama-models-coding-2026/). Карточка семейства: [families/qwen36.md](families/qwen36.md#27b).

### Apr 24 -- DeepSeek V4 (DeepSeek): 1.6T / 284B MoE, 1M контекст, open-source MIT

**24 апреля 2026** -- [DeepSeek](https://api-docs.deepseek.com/news/news260424) выпустила preview семейства **DeepSeek V4** под MIT-лицензией. Два варианта:

| Вариант | Параметры | Активных | Контекст | Pricing (input / output) |
|---------|-----------|----------|----------|---------------------------|
| **V4-Pro** | 1.6T MoE | 49B | **1M** | $1.74 / $3.48 за 1M |
| **V4-Flash** | 284B MoE | 13B | **1M** | $0.14 / $0.28 за 1M |

Архитектура -- гибридное внимание Compressed Sparse Attention (CSA) + Heavily Compressed Attention (HCA): на 1M контексте V4-Pro требует ~27% FLOPs и 10% KV-кеша от V3.2. Pre-train в FP4 + FP8 mixed precision (32T токенов). Hybrid reasoning / non-reasoning режимы, hybrid-режим V4-Pro-Max -- максимум reasoning effort.

Бенчмарки:
- **SWE-bench Verified: 80.6%** -- топ open-source, на уровне Claude Opus 4.6 (80.8%)
- **Terminal-Bench 2.0: 67.9%** (vs Claude 65.4%)
- **LiveCodeBench: 93.5%** (vs 88.8%)
- **SWE-Bench Pro: 55.4%** (уступает Kimi K2.6 58.6%, GLM-5.1 58.4%)

Веса опубликованы на [HuggingFace](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro) и [V4-Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash). Не помещаются на платформу (V4-Pro ~960 GB Q4, V4-Flash ~165 GB Q4). Покрытие в обзорах: [Simon Willison](https://simonwillison.net/2026/Apr/24/deepseek-v4/), [VentureBeat](https://venturebeat.com/technology/deepseek-v4-arrives-with-near-state-of-the-art-intelligence-at-1-6th-the-cost-of-opus-4-7-gpt-5-5), [CNBC](https://www.cnbc.com/2026/04/24/deepseek-v4-llm-preview-open-source-ai-competition-china.html).

### Apr 22 -- Xiaomi MiMo V2.5-Pro и V2.5: 1T MoE, agentic + multimodal

**22 апреля 2026** -- Xiaomi выпустила **MiMo V2.5-Pro** и **MiMo V2.5** ([анонс](https://www.marktechpost.com/2026/04/22/xiaomi-releases-mimo-v2-5-pro-and-mimo-v2-5-matching-frontier-model-benchmarks-at-significantly-lower-token-cost/), [страница модели](https://mimo.xiaomi.com/mimo-v2-5-pro)).

| Параметр | MiMo V2.5-Pro |
|----------|---------------|
| Архитектура | 1T MoE, **42B активных** |
| Контекст | **1M токенов** |
| Модальности | text + vision + audio (native) |
| Лицензия | open-source "soon" (V2-Flash был MIT) |

Бенчмарки:
- **SWE-Bench Pro: 57.2%** -- выше Claude Opus 4.6 (53.4%), в 0.5 п.п. от GPT-5.4 (57.7%)
- **Terminal-Bench 2.0: 86.7%** -- лидер на этом бенчмарке
- **ClawEval Pass^3: 64%** при ~70K токенов на trajectory (на 40-60% меньше токенов чем у Opus 4.6 / Gemini 3.1 Pro / GPT-5.4 при сопоставимом качестве)
- Реальная задача: SysY-компилятор на Rust за 4.3 часа / 672 tool calls, 233/233 hidden tests

Веса не помещаются на платформу (1T MoE). Предшественник [MiMo-V2-Flash](https://github.com/xiaomimimo/MiMo-V2-Flash) (309B, MIT, декабрь 2025) -- ориентир по open-варианту.

### Apr 20-22 -- Kimi K2.6 (Moonshot AI): 1T MoE, open-source, 4 варианта

Moonshot AI выпустила **Kimi K2.6** -- open-source 1T MoE под Modified MIT License. Линейка из четырёх вариантов:

| Вариант | Назначение |
|---------|------------|
| **Instant** | Низкая латентность, быстрые ответы |
| **Thinking** | Extended reasoning с цепочкой рассуждений |
| **Agent** | Single-agent workflow с tool use |
| **Agent Swarm** | Native multi-agent orchestration (до 300 агентов) |

Бенчмарки:
- **SWE-bench Verified: 80.2%** -- в пределах 0.6 п.п. от Claude Opus 4.6 (80.8%) и Gemini 3.1 Pro (80.6%)
- **SWE-Bench Pro: 58.6%** -- лидер open-weight (опережает GLM-5.1 58.4%)
- **HLE (Humanity's Last Exam): 54.0%**
- **SWE-bench Multilingual: 76.7%**
- **Artificial Analysis Intelligence Index: 54** (#1 open-source)

Веса не помещаются на платформу (1T MoE, 240+ GiB Q4). Используется через API или cloud-провайдеров. Карточка семейства: [families/kimi-k25.md](families/kimi-k25.md). Источники: [llm-stats](https://llm-stats.com/models/kimi-k2.6), [Artificial Analysis](https://artificialanalysis.ai/models/kimi-k2-6), [HuggingFace](https://huggingface.co/moonshotai/Kimi-K2.6).

### Apr 2026 -- Qwen3.6-Max-Preview (Alibaba): early preview следующего флагмана

Alibaba выпустила **Qwen3.6-Max-Preview** -- ранний preview следующего flagship семейства Qwen. Улучшенный agentic coding (tool use, multi-step reasoning, long-horizon задачи). API-only через Alibaba Cloud Model Studio. Полноценный релиз ожидается в Q2-Q3 2026. См. [families/qwen36.md](families/qwen36.md).

### Apr 2026 -- GPT-6 (OpenAI): 2M context, новая frontier

**14 апреля 2026** -- релиз [GPT-6](https://openai.com/) от OpenAI:
- **Контекст 2M токенов** -- рекорд среди proprietary моделей
- **Proprietary license**, API-only
- **Pricing**: $2.50/1M input, $12/1M output (в 4x дешевле GPT-5.3 Codex по input)
- Позиционируется как новое поколение general-purpose frontier

См. [closed-source-coding.md](closed-source-coding.md) для роли в coding.

### Apr 2026 -- GLM-5.1 (Z.ai): open-weight #1 на SWE-Bench Pro

**7 апреля 2026** -- [Z.ai](https://z.ai) (ex-Zhipu AI) выпустила **GLM-5.1** под MIT лицензией:

| Модель | SWE-Bench Pro |
|--------|---------------|
| **GLM-5.1 (open-weight, MIT)** | **58.4%** |
| GPT-5.4 | 57.7% |
| Claude Opus 4.6 | 57.3% |

Это **первая open-weight модель**, обогнавшая proprietary frontier на SWE-Bench Pro. Специализация -- agentic engineering и long-horizon software development. Может "переосмысливать" стратегию кодирования через сотни итераций.

Не помещается на платформу (744B total / 44B active, ~440 GB Q4). Используется через API Z.ai или cloud-провайдеров. Полный профиль семейства: [families/glm.md](families/glm.md). См. также [llm.md](llm.md), [coding.md](coding.md).

### Apr 2026 -- GLM-5V-Turbo (Z.ai): multimodal vision

**1 апреля 2026** -- релиз **GLM-5V-Turbo** -- vision-language вариант GLM-5 семейства, оптимизирован под coding-задачи (screenshot-to-code, diagram understanding). Multimodal coding conversion, на уровне Claude Opus / Gemini Pro на vision-coding бенчмарках. Open-weight. См. [vision.md](vision.md).

### Apr 2026 -- Microsoft MAI Models: speech, voice, image generation

Первая неделя апреля 2026 -- Microsoft выпустила **MAI (Microsoft AI) Models** семейство. Включает модели для:
- Генерации речи (TTS)
- Voice cloning
- Image generation

Детали и лицензия пока ограничены. Watching: интеграция в Azure AI Foundry и Copilot Studio.

### Apr 2026 -- MiniMax M2.7 open-sourced (SWE-Pro 56.2%, Terminal-Bench 57.0%)

MiniMax выпустил open-source модель **M2.7**: state-of-the-art на двух coding-бенчмарках:
- **SWE-Pro**: 56.22% (рекорд среди open-source)
- **Terminal-Bench 2**: 57.0%

Веса на [HuggingFace](https://huggingface.co/MiniMaxAI), API через MiniMax Platform. Позиционируется как серьёзный конкурент Devstral 2 и Qwen3-Coder в open coding-сегменте.

### Apr 2026 -- HappyHorse-1.0 (Alibaba) -- open-source видео #1 на Artificial Analysis

Alibaba выпустила **HappyHorse-1.0** -- open-source видео-генерацию, занявшую **первое место** на лидерборде [Artificial Analysis](https://artificialanalysis.ai). Тихий релиз без промо -- модель обнаружена community на HuggingFace. Конкурент [Wan 2.7](families/wan.md) и [LTX-2](families/ltx-2.md). См. [video.md](video.md).

### Apr 2026 -- VoxCPM2 (OpenBMB) -- tokenizer-free TTS

**VoxCPM2** от OpenBMB -- TTS-модель нового подхода: **без токенизатора** в pipeline. Вместо text → tokens → speech, VoxCPM2 работает напрямую text → speech через continuous representation. Multilingual, voice cloning, creative sound design. См. [tts.md](tts.md).

### Apr 2026 -- Claude Mythos Preview лидирует на SWE-bench Verified

**10 апреля 2026** -- лидерборд [SWE-bench Verified](../llm-guide/benchmarks/swe-bench.md):

| Модель | Score | Доступ |
|--------|-------|--------|
| Claude Mythos Preview (Anthropic) | **93.9%** | preview |
| GPT-5.3 Codex (OpenAI) | 85.0% | API |
| Claude Opus 4.5 (Anthropic) | 80.9% | API |
| Gemini 3.1 Pro Preview (Google) | 78.8% | API |

Прирост за квартал: с ~76% (Q1 2026) до 93.9% (+18 п.п.). Бенчмарк приближается к насыщению, обсуждается переход на SWE-bench Pro и SWE-rebench. Источник: [llm-stats.com](https://llm-stats.com/benchmarks/swe-bench-verified).

### Apr 2026 -- Qwen3.6-Plus (Alibaba)

**2 апреля 2026** -- релиз [Qwen3.6-Plus](families/qwen36.md):
- Контекст 1M токенов
- Always-on chain-of-thought
- Native function calling
- Multimodal (vision + audio)
- Поддержка Anthropic API protocol
- API-only через Alibaba Cloud Model Studio, open-варианты обещаны "в developer-friendly размерах"

### Mar 2026 -- LTX-Video 2.3, Wan 2.7

Прорыв в **видеогенерации**:
- **LTX-Video 2.3** -- 4K 50fps в реалтайме (single-stream, отдельная ветка от [LTX-2](families/ltx-2.md))
- **Wan 2.7** -- 1080p с native audio sync, multi-shot, cinematic

См. [video.md](video.md).

### Apr 2026 -- Gemma 4: четыре размера, 256K context, Apache 2.0 (Google)

**2 апреля 2026** -- Google DeepMind выпустил [Gemma 4](families/gemma4.md) в четырёх вариантах:

| Вариант | Параметры | Контекст | Особенности |
|---------|-----------|----------|-------------|
| **E2B** | 2B | 32K | Edge/mobile inference |
| **E4B** | 4B | 32K | Edge, энергоэффективность |
| **26B-A4B** | 26B MoE / 3.8B active | 256K | Multimodal, function calling, Apache 2.0 |
| **31B** | 31B dense | **256K** | Flagship, function calling, agentic workflows |

31B -- максимальный по качеству вариант, 85 tok/s на consumer hardware, встроенный function calling для agentic-задач. Скачан на платформу (26B-A4B через `vulkan/preset/gemma4.sh`). См. [llm.md](llm.md), [vision.md](vision.md).

### Mar 2026 -- Cursor Composer 2 (Kimi K2.5 base)

Cursor выпустил проприетарную coding-модель **Composer 2**, построенную поверх **Moonshot AI Kimi K2.5** (1T MoE / 32B active). Continued pretraining + large-scale RL. Это первый крупный продакт-тейкап Kimi K2.5 как foundation. См. [kimi-k25](families/kimi-k25.md), [coding.md](coding.md).

## 2026-Q1

### Jan 2026 -- LTX-2: первая truly open audio-video foundation-модель (Lightricks)

**6 января 2026** -- [Lightricks](https://www.globenewswire.com/news-release/2026/01/06/3213304/0/en/Lightricks-Open-Sources-LTX-2-the-First-Production-Ready-Audio-and-Video-Generation-Model-With-Truly-Open-Weights.html) выпустили [LTX-2](families/ltx-2.md) -- новую foundation-модель с революционной архитектурой:
- **19B параметров** в асимметричной dual-stream архитектуре: 14B video + 5B audio
- **Синхронизированные audio+video в одном forward pass** через cross-attention между потоками -- первая open-source модель с этим
- **4K 50fps native**, **до 20 секунд клипа** с sync audio (рекорд среди open-source)
- **Truly open-source**: веса + training code + benchmarks (первая в сегменте)
- Community-квантизации GGUF Q3_K_S...Q8_0 появились в день релиза

Soft-launch был в октябре 2025 (limited access), полный open-source с весами -- 6 января 2026. NVFP4/NVFP8 quantizations для NVIDIA Blackwell доступны отдельно (на AMD бесполезны). См. [families/ltx-2.md](families/ltx-2.md).

### Q1 2026 -- Qwen3.5-397B-A17B (Alibaba)

Релиз флагмана семейства Qwen3.5: **397B total / 17B active MoE**, multimodal reasoning, ultra-long context. По сравнению с Qwen3-Max -- 8.6×-19× higher decoding throughput. Не помещается на платформу (~230 GiB Q4). См. [qwen35](families/qwen35.md), [llm.md](llm.md).

### Q1 2026 -- GLM-5 / GLM-5.1 (Zhipu AI)

Релиз **GLM-5** -- флагман от Zhipu AI:
- Масштаб: от 355B (32B active) до 744B (40B active)
- Long-horizon agentic tasks, complex systems engineering
- BenchLM open-weight leaderboard: GLM-5 Reasoning 85, GLM-5.1 84

Не помещается на платформу (~440 GB Q4). См. [llm.md](llm.md#не-помещаются-на-платформе-для-справки).

### Q1 2026 -- Mistral Large 3

Mistral AI вернулась в MoE-сегмент после Mixtral: **675B total / 41B active**, обучена на 3000 NVIDIA H200. Не помещается на платформу. См. [llm.md](llm.md).

### Q1 2026 -- Llama 4 Scout и Maverick (Meta)

Релиз семейства Llama 4 -- первый Mixture-of-Experts от Meta:
- **Llama 4 Scout** -- 109B total / 17B active, контекст **10M токенов** (уникально для open-source)
- **Llama 4 Maverick** -- 400B total / 17B active, 128 экспертов, контекст 1M, **MMLU 85.5%** (рекорд среди open-моделей), HumanEval 86.4%

Llama 4 Scout помещается на платформу (~67 GiB Q4). См. [llama](families/llama.md#4-scout), [llm.md](llm.md).

### Mar 2026 -- Nemotron Cascade 2 30B-A3B (NVIDIA)

**20 марта 2026** -- NVIDIA выпустила [Nemotron Cascade 2](https://research.nvidia.com/labs/nemotron/nemotron-cascade-2/) -- 30B MoE / 3B active, гибридная архитектура (Mamba-2 + Transformer), контекст 1M токенов. Обучена через Cascade RL + Multi-Domain On-Policy Distillation (MOPD). Вторая open-weight модель с gold-level на IMO, IOI, ICPC World Finals 2025. Превосходит Nemotron-3-Super 120B на coding и instruction-following при 20x меньше параметров. ~18 GiB Q4, помещается на одном RTX 4090. NVIDIA Open Model License. SWE-bench Verified ~50% -- слабо для agent-кодинга, но сильна на reasoning/math. См. [llm.md](llm.md).

### Jan 2026 -- Qwen3-VL 30B-A3B и 235B-A22B

Релиз [Qwen3-VL](families/qwen3-vl.md) -- лидер open-source vision LLM:
- **30B-A3B** -- помещается на платформу (`vulkan/preset/qwen3-vl.sh`), 18 GiB + 1 mmproj
- **235B-A22B** -- на multimodal-бенчмарках сравним с Gemini-2.5-Pro и GPT-5

Лучший OCR, document understanding, video understanding в open-source. См. [vision.md](vision.md).

### Jan 2026 -- Kimi K2.5 (Moonshot AI)

Релиз **Kimi K2.5** -- 1T MoE / 32B active. Native multimodal, Agent Swarm, **SWE-Bench Verified 76.8%**, AIME 2025 96.1%. Веса открыты под Apache 2.0, но **не помещаются** на платформу даже в Dynamic 1.8-bit (240+ GiB). Используется через API ($0.45 / 1M input). См. [kimi-k25](families/kimi-k25.md).

## 2025-Q4

### Dec 2025 -- HunyuanVideo 1.5 (Tencent)

Эффективная foundation video-модель -- **8.3B параметров** (вместо 13B в 1.0). Уменьшение размера без потери качества. См. [hunyuanvideo](families/hunyuanvideo.md), [video.md](video.md).

### Dec 2025 -- Devstral 2 24B (Mistral)

[Devstral 2](families/devstral.md) -- лидер dense-сегмента по [SWE-bench Verified](../llm-guide/benchmarks/swe-bench.md): **72.2% при 24B параметров**. FIM + agent в одной модели. Помещается на одном RTX 4090 или Mac 32GB. На платформе используется без отдельного пресета, через `vulkan/preset/...`. См. [coding.md](coding.md).

### Q4 2025 -- DeepSeek V3.2 и V3.2-Speciale (DeepSeek)

**1 декабря 2025** -- релиз **DeepSeek V3.2** -- 671B MoE / 37B active под лицензией **MIT**. Consistently strong scores на всех бенчмарках, S-tier среди open-source. Не помещается на платформу (~390 GB Q4).

Одновременно выпущен **DeepSeek-V3.2-Speciale** -- reasoning-вариант V3.2, усиленный DeepSeek-Math-V2. Результаты: AIME **96.0%** (vs GPT-5-High 94.6%, Gemini-3.0-Pro 95.0%), HMMT **99.2%** (vs Gemini 97.5%). Gold-level на IMO, CMO, ICPC World Finals, IOI 2025. Контекст 164K. Не поддерживает tool-calling, предназначен для deep reasoning. API-only, MIT. См. [llm.md](llm.md#не-помещаются-на-платформе-для-справки).

## 2025-Q3

### Sep 2025 -- Qwen3-Coder Next 80B-A3B (Alibaba)

Релиз [Qwen3-Coder Next](families/qwen3-coder.md#next-80b-a3b) -- MoE с 3B активных параметров, **SWE-bench Verified 70.6%**, контекст 256K. Эталон efficiency-сегмента: качество как у 24B dense, скорость почти как у 3B. Основной выбор для daily agentic-кодинга на платформе. См. [coding.md](coding.md).

### Q3 2025 -- Qwen3-Coder 480B-A35B-Instruct (Alibaba)

Флагман семейства: **480B total / 35B active**, контекст 256K-1M. Не помещается на платформу (~270 GB Q4). См. [families/qwen3-coder.md](families/qwen3-coder.md).

## Что отслеживать

| Категория | Источники |
|-----------|-----------|
| LLM-релизы | [llm-stats.com](https://llm-stats.com/llm-updates), [HuggingFace daily papers](https://huggingface.co/papers), [Reddit r/LocalLLaMA](https://reddit.com/r/LocalLLaMA) |
| Бенчмарки | [SWE-bench leaderboard](https://www.swebench.com/), [BenchLM.ai](https://benchlm.ai/), [llm-stats.com benchmarks](https://llm-stats.com/benchmarks/swe-bench-verified) |
| Coding | [LMSYS Copilot Arena](https://lmsys.org/blog/), [SWE-rebench](https://swe-rebench.com/) |
| Vision | [MMMU leaderboard](https://mmmu-benchmark.github.io/) |
| Image/video | [civitai.com](https://civitai.com/), [comfyui-news](https://www.reddit.com/r/comfyui/) |

## Связанные статьи

- [ai-agents/news.md](../ai-agents/news.md) -- новости AI-агентов (Cursor, Claude Code, Devin)
- [ai-agents/trends.md](../ai-agents/trends.md) -- долгосрочные тренды
- [llm.md](llm.md), [coding.md](coding.md), [vision.md](vision.md), [images.md](images.md), [video.md](video.md), [music.md](music.md) -- актуальные сравнения по направлениям
- [families/](families/README.md) -- per-model карточки
- [../llm-guide/benchmarks/](../llm-guide/benchmarks/README.md) -- описание бенчмарков
