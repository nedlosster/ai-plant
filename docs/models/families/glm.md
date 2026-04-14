# GLM (Z.ai / Zhipu AI, 2019-2026)

> Семейство LLM от Z.ai (ex-Zhipu AI), обученное полностью на Huawei Ascend. GLM-5.1 -- первая open-weight модель, обогнавшая proprietary frontier на SWE-Bench Pro.

**Тип**: MoE (GLM-4.5/4.7/5 series), dense (старые GLM-4)
**Лицензия**: **MIT** (GLM-5.x) -- одна из самых свободных в индустрии
**Статус на сервере**: не помещается (744B MoE ~440 GB Q4)
**Направления**: [llm](../llm.md), [coding](../coding.md), [vision](../vision.md) (5V-Turbo)
**Function calling**: native (особенно сильная в 5.1 для agentic-задач)
**Vision**: да (GLM-5V-Turbo -- vision-coding foundation)
**Доступ на платформе**: через API Z.ai (не локальный inference)

## Обзор

**Z.ai** (официально переименована из Zhipu AI в 2025 году) -- ведущая китайская AI-компания, spun out из Tsinghua University в 2019. Hong Kong IPO в январе 2026. Серия GLM (General Language Model) -- их флагманская линейка LLM, конкурент Claude/GPT/DeepSeek в open-source сегменте.

Ключевые вехи:
- **2019** -- основание Zhipu AI на базе Tsinghua University
- **2023** -- первые GLM open-weight модели (ChatGLM-6B, GLM-4)
- **Конец 2024** -- GLM-4.5 (355B MoE, 32B active) -- первая серьёзная MoE в семействе
- **2025** -- GLM-4.7, специализация на agentic coding. Переименование Zhipu → Z.ai
- **Февраль 2026** -- GLM-5 (744B MoE / 44B active), полностью обучена на Huawei Ascend
- **1 апреля 2026** -- GLM-5V-Turbo (vision-language variant)
- **7 апреля 2026** -- **GLM-5.1** -- первая open-weight модель, обогнавшая proprietary frontier на SWE-Bench Pro (58.4% vs GPT-5.4 57.7% vs Claude Opus 4.6 57.3%)
- **Январь 2026** -- Hong Kong IPO

## Варианты

| Вариант | Параметры | Active | Контекст | VRAM Q4 | Статус | Hub |
|---------|-----------|--------|----------|---------|--------|-----|
| **GLM-5.1** ⭐ | 744B MoE | 44B | 203K | ~440 GB (не помещается) | open MIT | [zai-org/GLM-5](https://huggingface.co/zai-org/GLM-5) (base), 5.1 post-training upgrade |
| **GLM-5** | 744B MoE | 44B | 200K | ~440 GB | open MIT | [zai-org/GLM-5](https://huggingface.co/zai-org/GLM-5) |
| **GLM-5V-Turbo** | -- | -- | -- | не помещается | open | [Z.ai docs](https://docs.z.ai/guides/vlm/glm-5v-turbo) |
| **GLM-5-Turbo** | lighter | -- | -- | API-only | proprietary | Z.ai API |
| **GLM-Image** | -- | -- | -- | -- | part of GLM-5 family | -- |
| **GLM-4.7** | -- | -- | -- | -- | open | -- |
| **GLM-4.5** | 355B MoE | 32B | 128K | ~210 GB | open | [zai-org/GLM-4.5](https://huggingface.co/zai-org/GLM-4.5) |
| **GLM-4.5-Air** | 106B MoE | 12B | 128K | ~63 GB | open | -- |

### GLM-5.1 (текущий флагман)

Post-training upgrade GLM-5 базы: та же архитектура 744B/44B, но значительно улучшенные coding, tool use и autonomous execution. **Первый open-weight модель в топе SWE-Bench Pro**.

**Специализация**: agentic engineering, long-horizon software development. Модель может "переосмысливать" стратегию кодирования через **сотни итераций** -- уникальная способность.

**API pricing**: $1.40 / 1M input, $4.40 / 1M output. Cache discount: $0.26 / 1M для повторного input.

### GLM-5V-Turbo (vision-coding foundation)

**Первая multimodal coding foundation модель Z.ai**. Ключевая способность -- **воспроизведение UI designs как working frontend code** (mockup, Figma export, hand-drawn sketch → HTML/CSS/JavaScript).

**Design2Code benchmark**: GLM-5V-Turbo **94.8** vs Claude Opus 4.6 77.3 -- **+17.5 п.п.** на специализированной задаче.

**Architecture**: CogViT vision encoder + MTP (Multi-Token Prediction) для inference-efficiency + native multimodal fusion.

**API pricing**: $1.20 / 1M input, $4.00 / 1M output -- дешевле GLM-5.1 на vision-нагрузках.

### GLM-4.5 и GLM-4.5-Air (предыдущее поколение)

Первая серьёзная MoE в GLM семействе. 4.5-Air (106B / 12B active) -- помещается локально в Q2/Q3 но с потерей качества. Уступает GLM-5 во всём, производится для контекста.

## Архитектура и особенности

### MoE: 256 experts, 8 активны per token

GLM-5 / 5.1 использует **256 experts**, из которых только **8 активируются** на токен (5.9% sparsity rate) -- один из самых разреженных MoE в open-source. Для сравнения:
- DeepSeek V3: 256/8 (5.9% sparsity) -- аналогично
- Qwen3.5-122B-A10B: более плотный MoE
- Mixtral 8x22B: 8/2 (25% sparsity) -- менее разреженный

Результат: **744B параметров total, 44B active** на inference. Стоимость вычисления ~ 44B модели, но качество ближе к 744B dense.

### DSA (Dynamically Sparse Attention)

GLM-5 / 5.1 интегрирует **DSA механизм**, разработанный DeepSeek для DeepSeek V3.2. Это эффективный long-context attention, который активирует subset heads для разных токенов:
- **Context**: до 200K (GLM-5), **203K** (GLM-5.1)
- Снижает cost long-context inference на ~40% vs naive full attention
- Позволяет обрабатывать длинные кодовые базы и документы без квадратной стоимости

### Huawei Ascend: независимость от NVIDIA

**Ключевой факт**: GLM-5 была **полностью обучена на Huawei Ascend** через **MindSpore** framework -- без единого NVIDIA GPU. Это первая серьёзная frontier-модель, достигшая такой независимости.

Значение:
- Геополитический: демонстрация что китайская AI может обойтись без US-semiconductor ecosystem (в контексте export controls)
- Техническое: MindSpore и Ascend-стек способны обучать 744B MoE модели
- Экономическое: Ascend чипы потенциально дешевле H100/H200 для китайских компаний

### CogViT vision encoder (5V-Turbo)

В GLM-5V-Turbo используется новый **CogViT** vision encoder вместо стандартных SigLIP/CLIP. Особенности:
- Native multimodal fusion (как в Kimi K2.5 MoonViT) -- интегрирован в pretrain, не post-hoc adapter
- **MTP architecture** (Multi-Token Prediction) -- inference-friendly, выдаёт несколько токенов за шаг
- Оптимизирован под coding-задачи: понимание UI-элементов, layout, связей между компонентами

### Iterative strategy refinement (5.1)

Уникальная способность GLM-5.1 -- **rethinking coding strategy across hundreds of iterations**. В отличие от обычных моделей (которые следуют одному плану), GLM-5.1 может:
1. Начать писать код по одной стратегии
2. Обнаружить проблему через тесты или чтение output
3. **Переосмыслить подход** -- изменить архитектуру, выбрать другой алгоритм
4. Продолжить с новой стратегией
5. Повторить до 100+ раз в одном agentic-loop

Это ключ к рекорду на SWE-Bench Pro (сложные multi-step задачи) и Terminal-Bench.

## Бенчмарки

| Бенчмарк | GLM-5.1 | Claude Opus 4.6 | GPT-5.4 | Devstral 2 24B (open local) |
|----------|---------|------------------|---------|------------------------------|
| **SWE-Bench Pro** | **58.4%** ⭐ | 57.3% | 57.7% | -- |
| SWE-Bench Verified | -- | -- | -- | 72.2% |
| Terminal-Bench 2.0 | высокий | 57.5 (compositе) | -- | -- |
| NL2Repo | высокий | 57.5 (composite) | -- | -- |
| **Design2Code (5V-Turbo)** | -- | 77.3 | -- | -- |

**GLM-5V-Turbo Design2Code**: **94.8** -- рекорд на специализированном vision-coding бенчмарке.

**Композитный coding score** (Terminal-Bench 2.0 + NL2Repo + SWE-Bench Pro):
- Claude Opus 4.6: 57.5
- GLM-5.1: 54.9 -- на общем композите Claude Opus 4.6 всё ещё лидер, но на SWE-Bench Pro изолированно GLM-5.1 впереди

## Сильные кейсы

- **Open-weight lead на SWE-Bench Pro** -- единственная open модель, которая обходит proprietary frontier на этом бенчмарке
- **MIT лицензия** -- свободное коммерческое использование без royalty, без ограничений по MAU
- **Iterative refinement** -- для задач где план может меняться по ходу работы (прототипирование, exploration)
- **Long-horizon agentic** -- 8-часовые автономные сессии разработки
- **Vision-coding (5V-Turbo)** -- design-to-code на уровне gold standard
- **Independence from NVIDIA** -- обучена на Ascend, демонстрация альтернативного стека
- **Cheap API** -- $1.40/1M input (в 3x дешевле Claude Opus)

## Слабые стороны

- **Не помещается локально** -- 744B MoE требует ~440 GB Q4, на Strix Halo (120 GiB) не загружается. Даже Q2 не помещается
- **Композитный coding score** ниже Claude Opus 4.6 (54.9 vs 57.5)
- **Китайская компания** -- потенциальные geopolitical concerns для US/EU enterprise (data residency, compliance)
- **Экосистема меньше** чем у Claude/GPT -- меньше интеграций, меньше cookbook'ов
- **Русский язык** -- не специализирован, хуже Qwen3.5 для русскоязычных задач
- **GLM-4.5-Air** (106B/12B) помещается локально, но качество уступает Qwen3.5-122B-A10B на тех же задачах

## Идеальные сценарии

- **Agentic engineering через API**: autonomous multi-hour coding sessions где iterative refinement критичен. Альтернатива Claude Code с Opus 4.6, но дешевле
- **Design-to-code pipelines**: GLM-5V-Turbo для автоматизации front-end development из Figma/mockup'ов
- **Long-horizon refactoring**: многофайловый рефакторинг, где каждый шаг меняет контекст для следующего
- **MIT-compliant production**: когда нужна open модель с максимально свободной лицензией (MIT > Apache 2.0 > Llama CL)
- **Cost-sensitive API**: $1.40/1M input -- на 65% дешевле Claude Opus ($5), при сопоставимом quality на SWE-Pro

## Загрузка

На Strix Halo 120 GiB модель **не помещается** в основной 744B варианте. Варианты:

### Через API Z.ai

```bash
# Настроить провайдера Z.ai в Aider / opencode / Cline
export OPENAI_API_BASE="https://api.z.ai/v1"
export OPENAI_API_KEY="<your-zai-key>"

# Использовать model name
opencode --model "glm-5.1"
```

API-ключ получить на [z.ai](https://z.ai). Pricing: $1.40/$4.40 per 1M tokens.

### Через OpenRouter / Puter / OpenRouter-compat провайдеры

GLM-5.1 и GLM-5V-Turbo доступны через OpenRouter, Puter Developer, ZenMux. Удобно если уже настроен OpenRouter workflow.

### GLM-4.5-Air (если всё-таки хочется локально)

Единственный вариант, который помещается на Strix Halo (но уже заметно устарел):

```bash
# GLM-4.5-Air Q4 (~63 GB) -- помещается, но Qwen3.5-122B-A10B обычно лучше
./scripts/inference/download-model.sh zai-org/GLM-4.5-Air-GGUF --include '*Q4_K_M*'
```

Рекомендация: **использовать GLM-5.1 через API**, локально выбирать [Qwen3.5-122B-A10B](qwen35.md#122b-a10b) или [Devstral 2](devstral.md) в зависимости от задачи.

## Ссылки

**Официально**:
- [Z.ai](https://z.ai) -- сайт компании
- [docs.z.ai](https://docs.z.ai/) -- официальная документация API
- [zai-org на HuggingFace](https://huggingface.co/zai-org) -- организация на HF
- [zai-org/GLM-5](https://huggingface.co/zai-org/GLM-5) -- основные веса GLM-5
- [zai-org/GLM-4.5](https://huggingface.co/zai-org/GLM-4.5) -- GLM-4.5 семейство

**Документация моделей**:
- [GLM-5.1 overview](https://docs.z.ai/guides/llm/glm-5.1)
- [GLM-5V-Turbo overview](https://docs.z.ai/guides/vlm/glm-5v-turbo)

**Анализ**:
- [GLM-5 release analysis (DigitalApplied)](https://www.digitalapplied.com/blog/zhipu-ai-glm-5-release-744b-moe-model-analysis)
- [GLM-5.1 review (BuildFastWithAI)](https://www.buildfastwithai.com/blogs/glm-5-1-open-source-review-2026)
- [GLM-5V-Turbo vs Opus 4.6 (Medium)](https://agentnativedev.medium.com/glm-5v-turbo-beats-opus-4-6-on-multimodal-benchmarks-f6376822eb32)
- [VentureBeat: GLM-5.1 ships](https://venturebeat.com/technology/ai-joins-the-8-hour-work-day-as-glm-ships-5-1-open-source-llm-beating-opus-4)
- [The Decoder: GLM-5.1 iterative coding](https://the-decoder.com/zhipu-ais-glm-5-1-can-rethink-its-own-coding-strategy-across-hundreds-of-iterations/)

## Связано

- Направления: [llm](../llm.md), [coding](../coding.md), [vision](../vision.md)
- Обзор closed-source (где GLM-5.1 присутствует несмотря на open weights из-за невозможности self-host): [closed-source-coding.md](../closed-source-coding.md)
- Хроника релизов: [news.md](../news.md)
- Альтернативы (помещаются локально): [qwen35](qwen35.md) (122B MoE -- альтернатива GLM-5), [devstral](devstral.md) (лидер dense coding на платформе)
- Родственные large-MoE не помещающиеся модели: [kimi-k25](kimi-k25.md), DeepSeek V3.2 (не имеет карточки), MiniMax M2.7 (не имеет карточки)
