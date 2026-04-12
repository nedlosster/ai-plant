# Анонсы и релизы моделей

Хроника релизов open-source и frontier-моделей по направлениям: LLM, coding, vision, image, video, audio. Дополняет [ai-agents/news.md](../ai-agents/news.md) (хроника AI-агентов) и [trends.md](../ai-agents/trends.md) (долгосрочные прогнозы).

Полные карточки моделей -- в [families/](families/). Сводные таблицы по направлениям -- в [llm.md](llm.md), [coding.md](coding.md), [vision.md](vision.md), [images.md](images.md), [video.md](video.md), [music.md](music.md), [russian-llm.md](russian-llm.md), [russian-vocals.md](russian-vocals.md), [tts.md](tts.md).

## 2026-Q2 (актуально)

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
- **Llama 4 Maverick** -- 400B total / 17B active, оптимизирован под качество

Llama 4 Scout помещается на платформу (~67 GiB Q4). См. [llama](families/llama.md#4-scout), [llm.md](llm.md).

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

### Q4 2025 -- DeepSeek V3.2 (DeepSeek)

Релиз **DeepSeek V3.2** -- 671B MoE под лицензией **MIT**. Consistently strong scores на всех бенчмарках, S-tier среди open-source. Не помещается на платформу (~390 GB Q4). См. [llm.md](llm.md#не-помещаются-на-платформе-для-справки).

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
