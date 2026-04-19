# Closed-source модели для кодинга: обзор и сравнение

Обзор cloud-only моделей, которые недоступны для локального inference, но задают frontier качества в agentic coding. Сравнение с open-source альтернативами на платформе Strix Halo.

Локальные модели для кодинга -- в [coding.md](coding.md). Бенчмарки и методология -- в [llm-guide/benchmarks/swe-bench.md](../llm-guide/benchmarks/swe-bench.md). Агенты, использующие эти модели -- в [ai-agents/commercial.md](../ai-agents/commercial.md).

## Зачем это знать при работе на локальном стеке

На Strix Halo основной coding стек -- [Qwen3-Coder Next](families/qwen3-coder.md) (70.6% SWE-bench) и [Devstral 2](families/devstral.md) (72.2%). Closed-source frontier -- на 15-21 п.п. выше по SWE-bench. Зачем об этом знать:

1. **Benchmark-ориентир**: понимать куда движется индустрия и где потолок. Devstral 2 72.2% vs Claude Opus 4.7 87.6% -- gap **15.4 п.п.**, значительный для сложных задач
2. **Когда API дешевле**: типовой bugfix через Claude Sonnet = $2-5. Держать Strix Halo включённым 24/7 только ради inference -- тоже имеет стоимость ($50-80/мес электричество). При <50 запросов в день API может быть выгоднее
3. **Фичи которых нет у open**: cloud sandbox (Codex запускает тесты в облаке), 1M контекст (Claude Opus, Gemini), background agents (работают пока ты спишь), multi-modal coding (видит UI + пишет код)
4. **Fallback**: когда локальная модель не справляется со сложной задачей -- переключиться на API для единичного запроса

## Профили моделей

### GPT-5.3 Codex / codex-1 (OpenAI)

**Тип**: проприетарная (архитектура не раскрыта)
**Доступ**: API ($10/1M input, $30/1M output), ChatGPT Pro $200/мес
**SWE-bench Verified**: 85.0%
**Контекст**: 256K (стандартный), 128K для Spark

Самая производительная agentic coding модель OpenAI. GPT-5.3-Codex объединяет frontier coding от GPT-5.2-Codex и reasoning от GPT-5.2 в одной модели, на **25% быстрее** предшественника.

**Ключевые особенности**:
- **Reasoning effort settings**: low / medium / high / xhigh -- можно управлять глубиной reasoning per-task. Low для простых задач (быстро, дёшево), xhigh для сложных архитектурных (медленно, дорого)
- **Cloud sandbox**: Codex запускает код в изолированном облачном окружении, прогоняет тесты, видит результаты -- и итерирует автоматически. Локальные модели не имеют такого sandbox
- **Parallel agents**: несколько Codex-инстансов работают параллельно на разных задачах
- **PR generation**: от issue до ready-to-merge PR в одном workflow
- **Terminal-Bench**: установил новый industry-рекорд (Score Pro) наряду с SWE-Bench Pro
- **Unlimited access промо**: ChatGPT Pro ($200) даёт unlimited Codex -- агрессивное конкурирование с Claude Code

**GPT-5.3-Codex-Spark** -- облегчённый вариант:
- **1000+ tok/s** -- рекорд среди frontier моделей
- 128K контекст, text-only (без vision)
- Designed для low-latency autocomplete и быстрых правок
- Подходит для FIM-подобных задач через API

**Что НЕ раскрыто**: количество параметров, архитектура (MoE?), training data, точный reasoning mechanism. OpenAI не публикует technical reports для Codex-серии.

**Ограничения**:
- Только cloud -- нет self-hosted, нет open weights
- Backend-heavy (Faros 58.5% backend vs 80% frontend) -- Claude лучше для frontend
- Стоимость: при интенсивном использовании $10/1M input + $30/1M output быстро набирается

### Claude Opus 4.7 / Sonnet 4.5 / Opus 4.6 / Sonnet 4.6 (Anthropic)

**Тип**: проприетарная (архитектура не раскрыта)
**Доступ**: API (Opus $5/1M in, $25/1M out; Sonnet $3/$15), Claude Code $20-200/мес
**SWE-bench Verified**: Opus 4.7 87.6%, Opus 4.5 80.9%, Mythos Preview 93.9%
**SWE-bench Pro**: Opus 4.7 64.3%, Opus 4.5 45.9%
**Контекст**: 200K (standard), **1M** (Opus 4.7 / Opus 4.6 / Sonnet 4.6, Max plan)
**Vision**: 2,576px (3.75 MP) для Opus 4.7, 1,568px (1.15 MP) для Opus 4.6

Семейство Claude -- доминант в AI coding agents (41% профдевелоперов, 46% "most loved"). Несколько поколений одновременно:

**Claude Opus 4.7** (апрель 2026):
- SWE-bench Verified 87.6%, SWE-bench Pro 64.3% -- наивысшие среди production-моделей Anthropic
- 1M контекст, 128K max output
- Vision 2,576px (3.75 MP) -- 3x больше пикселей чем у Opus 4.6
- Новый xhigh effort level (между high и max)
- Task budgets (public beta) для контроля расхода токенов
- `/ultrareview` command в Claude Code
- Rebuilt tokenizer
- Доступен: Claude Platform, Amazon Bedrock, Google Vertex AI, Microsoft Foundry

**Claude Sonnet 4.5** (февраль 2026):
- Default в Claude Code -- это модель, которую видит большинство разработчиков
- **Hybrid reasoning**: быстрый default-mode + extended reasoning по запросу
- $3/1M input, $15/1M output -- доступнее чем Opus
- 200K контекст
- Быстрая, достаточно качественная для 80% daily tasks

**Claude Opus 4.5** (ноябрь 2025):
- SWE-bench 80.9% -- frontier на момент релиза
- **66% дешевле предшественника** ($5/1M input vs ~$15 ранее)
- Лучший frontend score в индустрии -- 95% в Faros benchmark
- Длинные, архитектурные задачи, complex multi-file refactoring

**Claude Opus 4.6 / Sonnet 4.6** (январь 2026):
- **1M токенов контекста** по стандартному pricing (без доплаты)
- Prompt caching -- повторные запросы по тому же документу/codebase дешевле
- Opus 4.6 -- предшественник Opus 4.7, по-прежнему доступен

**Claude Mythos Preview** (апрель 2026):
- 93.9% SWE-bench Verified -- **абсолютный рекорд**
- **Не production-модель**: research preview для "Project Glasswing" (defensive cybersecurity)
- Доступ: **invitation-only**, нет public API, нет pricing
- Для defensive security workflows: vulnerability analysis, exploit detection, incident response
- Не для общего coding -- узкая специализация

**Фишки экосистемы Claude**:
- **CLAUDE.md** -- проектные инструкции, загружаемые автоматически при каждом запуске
- **Sub-agents** -- параллельные рабочие агенты внутри Claude Code
- **Hooks** -- pre/post-action триггеры для enforce стандартов
- **MCP (Model Context Protocol)** -- расширяемость через 97M+ инсталляций MCP-серверов
- **Skills** -- переиспользуемые навыки
- **Claude Code Channels** -- интеграция с Telegram и Discord
- **Agent team mode** -- несколько Claude Code агентов на одном проекте

**Ограничения**:
- Привязан к Anthropic API (нет self-hosted, нет open weights)
- Mythos Preview -- недоступен большинству разработчиков
- OCR и vision coding -- хуже чем у [Gemma 4](families/gemma4.md) для screenshot-to-code (нет native bounding box)

### Gemini 3.1 Pro / Flash (Google)

**Тип**: проприетарная (архитектура не раскрыта, вероятно MoE)
**Доступ**: API (Pro $1.25/1M in, $5/1M out; Flash -- бесплатный tier)
**SWE-bench Verified**: Pro 78.8%
**Контекст**: **1M** (Pro), **1M** (Flash бесплатно)

Сильнейшая модель Google для coding. Уникальный контекст 1M доступен **даже в бесплатном Flash** (с quota).

**Gemini 3.1 Pro**:
- 78.8% SWE-bench -- не лидер, но **самый дешёвый frontier** ($1.25/1M input)
- 1M контекст -- весь monorepo за один запрос
- Grounding -- может проверять факты через Google Search inline
- Code execution -- встроенный Python sandbox
- Multimodal: text + images + audio + video

**Gemini 3.1 Flash**:
- Бесплатный tier (с rate limits: 15 req/min, 1M tokens/min)
- **Flash Thinking** -- reasoning mode аналогичный Claude extended thinking
- 1M контекст в бесплатном tier
- Для daily coding -- **$0 вообще** при умеренном использовании

**Доступ через агенты**:
- **Gemini CLI** -- терминальный агент от Google, OpenAI-compat API
- **Gemini Code Assist** -- IDE-расширение (VS Code, JetBrains)
- Через BYOK в [Aider](../ai-agents/agents/aider.md), [opencode](../ai-agents/agents/opencode.md), [Cline](../ai-agents/agents/cline.md)

**Ограничения**:
- Latency выше чем у OpenAI/Anthropic (cold start на Flash ~2-3 сек)
- Code quality на backend-задачах ниже чем Codex/Claude
- Grounding иногда вмешивается когда не нужно

### GPT-6 (OpenAI)

**Тип**: проприетарная (архитектура не раскрыта)
**Доступ**: API only ($2.50/1M input, $12/1M output)
**Контекст**: **2M токенов** -- рекорд среди proprietary моделей
**Дата релиза**: 14 апреля 2026

Новое поколение OpenAI general-purpose модели. Позиционируется как преемник GPT-5 series, не как специализированный coding (GPT-5.3 Codex остаётся флагманом именно для coding).

**Ключевые особенности**:
- **2M контекст** -- больше чем у Claude 4.6 и Gemini Pro (обе 1M)
- **В 4x дешевле по input** чем GPT-5.3 Codex ($2.50 vs $10) -- агрессивное ценообразование против конкурентов
- **General-purpose**: хорошие результаты на всех категориях (reasoning, coding, knowledge) без узкой специализации
- **Не Codex-замена**: OpenAI продолжает развивать Codex-серию (GPT-5.3 Codex, Spark) как отдельную линейку для agentic coding

**Для coding** GPT-6 может использоваться в general-purpose агентах (ChatGPT plugins, кастомные интеграции), но для профессионального coding лучше GPT-5.3 Codex.

**Что НЕ раскрыто**: размер, архитектура, training data, есть ли reasoning-модификация.

### GLM-5.1 (Z.ai / Zhipu AI)

Подробная карточка семейства -- [families/glm.md](families/glm.md).

**Тип**: 744B MoE / 44B active, **open weights** (MIT лицензия)
**Доступ**: API Z.ai; open weights доступны, но **не помещаются** (~440 GB Q4)
**Контекст**: 128K
**Дата релиза**: 7 апреля 2026

Z.ai (ex-Zhipu AI) выпустила **первый open-weight модель, обогнавшую proprietary frontier** на SWE-Bench Pro:

| Модель | SWE-Bench Pro |
|--------|---------------|
| **GLM-5.1 (MIT)** | **58.4%** |
| GPT-5.4 | 57.7% |
| Claude Opus 4.6 | 57.3% |

**Ключевые особенности**:
- **MIT лицензия** -- самая свободная в индустрии, включая коммерческое использование
- **Iterative strategy refinement**: модель может "переосмысливать" coding-стратегию через сотни итераций -- уникальная способность для agentic engineering
- **Long-horizon software development**: специализирована под задачи, требующие многочасовой работы (refactors, архитектурные изменения)
- **GLM-5V-Turbo**: отдельный vision-language вариант (релиз 1 апреля), оптимизирован под screenshot-to-code

**Для нашей платформы**: 744B MoE не помещается (требуется ~440 GB). Доступ через Z.ai API или HuggingFace Spaces.

### Kimi K2.5 (Moonshot AI)

**Тип**: 1T MoE / 32B active, **open weights** (Apache 2.0)
**Доступ**: API $0.45/1M input, $1.35/1M output; open weights доступны, но **не помещаются** (240+ GiB Q4)
**SWE-bench Verified**: 76.8%
**Контекст**: 128K

Уникальный случай: веса открыты, лицензия свободная, но **физически не помещается** на consumer hardware (1T MoE в Q4 ~240 GiB, Strix Halo max 120 GiB). Для нашей платформы -- фактически cloud-only через API.

**Ключевые особенности**:
- **Самый дешёвый frontier**: $0.45/1M input -- в 10x дешевле GPT-5.3, в 7x дешевле Claude Opus
- **AIME 2025: 96.1%** -- один из лучших reasoning scores
- **Agent Swarm** -- native multi-agent orchestration
- **Native multimodal** -- text + vision в одном
- **Cursor Composer 2 base** -- Cursor выбрал K2.5 как foundation для своей проприетарной модели (continued pretraining + large-scale RL)

Альтернатива: использовать через [Cursor](../ai-agents/agents/cursor.md) (включён в подписку $20/мес) или через API напрямую.

**Карточка семейства**: [families/kimi-k25.md](families/kimi-k25.md).

### Cursor Composer 2 (Anysphere)

**Тип**: проприетарная (Kimi K2.5 base + continued pretraining + RL)
**Доступ**: **только через Cursor IDE** ($20 Pro / $40 Team)
**SWE-bench Verified**: не публикуется
**Контекст**: 128K

Третье поколение проприетарной coding-модели Cursor. Построена поверх Kimi K2.5 от Moonshot AI:
1. **Foundation**: Kimi K2.5 1T MoE / 32B active (open weights от Moonshot AI)
2. **Continued pretraining**: обширная до-обучение на coding-данных Cursor
3. **Large-scale RL**: reinforcement learning на real user feedback из Cursor IDE
4. **Composer-specific training**: оптимизация под multi-file edit workflow (Composer UI)

Результат: модель, которая понимает Cursor-specific workflow'ы (Composer multi-tab, @-references, .cursorrules) лучше чем generic Claude/GPT.

**Доступна только через Cursor IDE** -- нет API, нет BYOK, нет open weights. Анysphere не публикует модель отдельно.

## Сводная таблица

| Модель | SWE-bench V | SWE-Pro | Faros Overall | $/1M in | $/1M out | Context | Self-hosted | Agent |
|--------|-------------|---------|---------------|---------|----------|---------|-------------|-------|
| **Claude Mythos Preview** | **93.9%** | -- | -- | invitation | -- | -- | нет | -- |
| **Claude Opus 4.7** | **87.6%** | **64.3%** | -- | $5 | $25 | **1M** | нет | Claude Code |
| **GPT-6** | -- | -- | -- | $2.50 | $12 | **2M** | нет | -- (new Apr 14) |
| **GPT-5.3 Codex** | 85.0% | ~57% | 67.7% | $10 | $30 | 256K | нет | Codex |
| **Gemini 3.1 Pro** | 78.8% | 54.2% | -- | **$1.25** | $5 | **1M** | нет | Gemini CLI |
| **GLM-5.1** (open MIT) | -- | **58.4%** | -- | via Z.ai API | -- | 128K | не помещается (440 GB) | -- |
| **GPT-5.4** | -- | 57.7% | -- | -- | -- | -- | нет | -- |
| **Claude Opus 4.6** | 80.8% | 53.4% | -- | $5 | $25 | **1M** | нет | Claude Code |
| **Claude Opus 4.5** | 80.9% | 45.9% | 55.5% | $5 | $25 | 200K-1M | нет | Claude Code (устарел) |
| **Kimi K2.5** | 76.8% | -- | -- | **$0.45** | $1.35 | 128K | нет (240+ GB) | Cursor |
| **Claude Sonnet 4.5** | ~75% est. | -- | -- | $3 | $15 | 200K-1M | нет | Claude Code |
| **Gemini 3.1 Flash** | ~65% est. | -- | -- | **$0** (free tier) | $0 | **1M** | нет | Gemini CLI |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Devstral 2 24B (open) | **72.2%** | -- | -- | $0 | $0 | 256K | **да** | Aider, opencode |
| Qwen3-Coder Next (open) | 70.6% | -- | -- | $0 | $0 | 256K | **да** | opencode, Cline |
| Gemma 4 26B (open) | -- | -- | -- | $0 | $0 | 256K | **да** | opencode |

## Open vs Closed: gap analysis

### Количественный gap

```
SWE-bench Verified (апрель 2026):

93.9%  Claude Mythos Preview  ----+
                                  |  21.7 п.п. gap
87.6%  Claude Opus 4.7        -+  |
85.0%  GPT-5.3 Codex          |  |
78.8%  Gemini 3.1 Pro         |  |
76.8%  Kimi K2.5              |  |  <- "frontier closed"
-------------------------------+  |
72.2%  Devstral 2 24B (open)  ----+  <- "frontier open"
70.6%  Qwen3-Coder Next (open)
~65%   Gemini Flash (free)
```

**Gap между best open (72.2%) и best closed non-preview (87.6%)**: 15.4 п.п.
**Gap между best open и Mythos**: 21.7 п.п. -- но Mythos invitation-only, не для общего использования.

### Что даёт closed, чего нет у open

| Возможность | Closed | Open (на Strix Halo) |
|-------------|--------|---------------------|
| Cloud sandbox (запуск тестов в облаке) | Codex, Claude Code (через GitHub Actions) | нужен свой CI/CD |
| 1M+ контекст | Claude 4.6, Gemini | максимум 256K |
| Background agents (работают автономно часами) | Codex, Claude Code | нужна своя инфра |
| Multi-modal coding (UI screenshot → код) | Claude, Gemini | [Gemma 4](families/gemma4.md) -- но слабее |
| Reasoning effort tuning (low/high) | GPT-5.3 Codex | нет аналога |
| Prompt caching (дешёвые повторные запросы) | Claude, Gemini | llama.cpp KV-cache (другой механизм) |
| Rate limits и quota management | встроено в API | нет ограничений (свой сервер) |

### Когда closed-source gap не важен

1. **Privacy-sensitive код**: банковский, медицинский, military -- код не должен покидать периметр. Локальный inference = данные не уходят в cloud
2. **Высокая частота**: >200 запросов/день по 300K токенов → $600+/мес через Claude API. Strix Halo = $50-80/мес электричество, после чего inference бесплатный
3. **Offline / air-gapped среда**: на submarine, в бункере, в офисе без интернета -- cloud не работает
4. **Fine-tuning / LoRA**: open модели можно до-обучить на корпоративном коде. Closed -- никак
5. **Предсказуемость**: cloud API может измениться завтра (pricing, rate limits, ToS). Локальный стек стабилен
6. **Юрисдикция**: API-запросы уходят на серверы в США. Для EU GDPR / российского ФЗ-152 это может быть проблемой

## Decision matrix: когда API оправдан

| Фактор | API (cloud) | Локально (Strix Halo) |
|--------|-------------|----------------------|
| **Качество на сложных задачах** | 87-94% SWE-bench | 70-72% SWE-bench |
| **Скорость generation** | 50-100 tok/s (server-side) | 53-86 tok/s (MoE Vulkan) |
| **Latency TTFT** | 0.5-2 сек (network + queue) | 0.1-0.5 сек (local) |
| **Стоимость per-task** | $2-8 (bugfix), $5-15 (feature) | $0 (электричество ~$2/день) |
| **Privacy** | код уходит в cloud | код остаётся локально |
| **Контекст** | до 1M (Claude, Gemini) | до 256K (llama.cpp) |
| **Availability** | 99.9% SLA, но downtime бывает | 100% (свой сервер, своё железо) |
| **Fine-tuning** | нет (кроме limited OpenAI fine-tune) | LoRA, QLoRA, full FT |
| **Multi-modal** | Claude, Gemini: screenshot → код | [Gemma 4](families/gemma4.md): screenshot → код |

**Рекомендация для нашей платформы**: использовать **локальный стек по умолчанию** (Qwen3-Coder Next / Devstral 2) для 80% задач. **Переключаться на API** для:
- Архитектурных задач с 500K+ контекстом (весь monorepo)
- Задач где SWE-bench gap критичен (сложные multi-file рефакторинги)
- Одноразовых сложных задач (дешевле $5 через API, чем час отладки локально)

## API pricing per-task

Ориентировочная стоимость типовых coding-задач (input + output, один запрос):

| Задача | ~Tokens | GPT-5.3 | Claude Opus | Claude Sonnet | Gemini Pro | Kimi K2.5 | Gemini Flash | Локально |
|--------|---------|---------|-------------|---------------|------------|-----------|--------------|----------|
| Bugfix (файл + описание) | 50K in, 5K out | $0.65 | $0.38 | $0.23 | $0.09 | $0.03 | **$0** | **$0** |
| Feature (10 файлов) | 200K in, 20K out | $2.60 | $1.50 | $0.90 | $0.35 | $0.12 | **$0** | **$0** |
| Refactor monorepo | 500K in, 50K out | $6.50 | $3.75 | $2.25 | $0.88 | $0.29 | **$0** | **$0** |
| Code review (full PR) | 100K in, 10K out | $1.30 | $0.75 | $0.45 | $0.18 | $0.06 | **$0** | **$0** |
| Daily usage (50 задач) | ~5M in, 500K out | **$65** | **$37** | **$22** | **$8.75** | **$2.93** | **$0** | **$0** |

**Вывод**: при 50 задач/день Claude Sonnet обходится в ~$22/день (~$660/мес). Strix Halo: ~$60/мес электричество. **Локальный стек окупается за 3 дня** при такой нагрузке (при чуть меньшем quality).

При 5 задач/день: API = ~$2.20/день ($66/мес) -- сопоставимо со стоимостью электричества. В этом режиме **API оправдан**, если quality gap критичен.

## Интеграция с агентами: какой agent какую модель использует

| Agent | Default модель | Альтернативы | API / Local |
|-------|----------------|--------------|-------------|
| [Claude Code](../ai-agents/agents/claude-code/README.md) | Sonnet 4.5 / Opus 4.7 (Max) | -- | API only |
| [Cursor](../ai-agents/agents/cursor.md) | **Composer 2** (Kimi K2.5 base) | Claude/GPT через BYOK | API (built-in) + BYOK |
| Codex | **codex-1** (GPT-5.3 Codex) | -- | Cloud sandbox |
| Copilot | GPT-4o | -- | API only |
| Devin 2.0 | проприетарная | -- | Cloud sandbox |
| Junie | Multi (JetBrains selection) | -- | API |
| Gemini CLI | Flash (free) / Pro | -- | API |
| Amazon Q | Claude 3.7 | -- | API + CLI |
| [Aider](../ai-agents/agents/aider.md) | Claude API / OpenAI API | **Qwen3-Coder Next (local)** | Both |
| [opencode](../ai-agents/agents/opencode.md) | Claude API / OpenAI API | **Qwen3-Coder Next (local)** | Both |
| [Cline](../ai-agents/agents/cline.md) / [Roo Code](../ai-agents/agents/roo-code.md) | Claude API / OpenAI API | **Local через llama-server** | Both |
| [Kilo Code](../ai-agents/agents/kilo-code.md) | Multi (500+ providers) | **Local через llama-server** | Both |
| [Continue.dev](../ai-agents/agents/continue-dev.md) | Multi (any provider) | **Local через llama-server** | Both |

**Стратегия на Strix Halo**: open-source агенты ([Aider](../ai-agents/agents/aider.md), [opencode](../ai-agents/agents/opencode.md), [Cline](../ai-agents/agents/cline.md)) переключаются между local и API через смену base_url. Для daily work -- local Qwen3-Coder Next. Для сложной задачи -- `OPENAI_API_KEY=... opencode` с Claude Opus через API.

## Связанные статьи

- [coding.md](coding.md) -- open-source coding модели на платформе
- [families/qwen3-coder.md](families/qwen3-coder.md) -- основная local coding модель
- [families/devstral.md](families/devstral.md) -- лидер dense local coding
- [families/kimi-k25.md](families/kimi-k25.md) -- Kimi K2.5 (open weights, API-only для нас)
- [../ai-agents/commercial.md](../ai-agents/commercial.md) -- платные агенты с бенчмарками
- [../ai-agents/comparison.md](../ai-agents/comparison.md) -- сводная таблица агентов
- [../llm-guide/benchmarks/swe-bench.md](../llm-guide/benchmarks/swe-bench.md) -- методология SWE-bench
- [../llm-guide/local-vs-api.md](../llm-guide/local-vs-api.md) -- теоретический обзор
- [../inference/llama-cpp.md](../inference/llama-cpp.md) -- backend для local inference
