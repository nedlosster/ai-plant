# Qwen3.6 (Alibaba, апрель 2026)

> "First real agentic LLM" (Alibaba). Флагман нового поколения Qwen для агентного кодинга и multimodal reasoning. Open weights ожидаются.

**Тип**: смешанный -- API-only Plus / Max-Preview + open-weight 27B dense + open-weight 35B-A3B (MoE multimodal)
**Лицензия**: Plus/Max-Preview API-only; **27B dense -- Apache 2.0**; **35B-A3B -- Apache 2.0**
**Статус на сервере**: 35B-A3B -- **скачана** (Q4_K_M, 20.6 GiB, 25 апр 2026); 27B -- **скачана** (Q4_K_M, 15.7 GiB, 27 апр 2026), замер выполнен; Plus -- API
**Направления**: [coding](../coding.md), [llm](../llm.md), [vision](../vision.md)

## Обзор

Qwen3.6-Plus -- релиз от Alibaba / Tongyi Lab (2 апреля 2026). Позиционируется как "first real agentic LLM" -- флагман нового поколения, ориентированный на agentic coding и multimodal задачи. По заявлению Alibaba -- "в одном весовом классе с Claude 4.5 Opus" на agentic coding benchmarks.

Ключевое отличие от предшественников -- полный цикл автономной разработки: планирование, написание кода, тестирование и итеративная доработка без вмешательства пользователя. Модель способна работать на уровне репозитория (repository-level engineering) -- от декомпозиции задачи до финальной интеграции.

**На момент апреля 2026 модель API-only** -- весов на HuggingFace ещё нет. Alibaba обещает: *"продолжим поддерживать open-source community с отдельными Qwen3.6 моделями в developer-friendly размерах"*.

По аналогии с релизом Qwen3.5 (где сначала был большой 397B-MoE через API, потом открыли 27B / 35B-A3B / 122B-A10B варианты) -- через 1-3 месяца можно ожидать open-варианты в диапазоне 30-122B.

## Варианты

| Вариант | Параметры | Контекст | Output | Лицензия | Статус | Доступ |
|---------|-----------|----------|--------|----------|--------|--------|
| Qwen3.6-Plus | не раскрыто | **1M токенов** | 65K | proprietary | API-only | [Alibaba Cloud Model Studio](https://www.alibabacloud.com/product/modelstudio), [OpenRouter](https://openrouter.ai/) (бесплатно в preview) |
| Qwen3.6-Max-Preview | не раскрыто | -- | -- | proprietary | API-only preview | Alibaba Cloud Model Studio |
| **Qwen 3.6-27B** | **27B dense, hybrid Gated DeltaNet** | 1M (предв.) | -- | **Apache 2.0** | open-weight, 23 апр 2026 | [HuggingFace](https://huggingface.co/Qwen) (unsloth/bartowski/mradermacher GGUF) |
| **Qwen 3.6-35B-A3B** | **35B MoE / 3B active, multimodal (vision)** | ~128K (оценка) | -- | **Apache 2.0** | open-weight, 16 апр 2026 | [HuggingFace](https://huggingface.co/Qwen/Qwen3.6-35B-A3B) |

## 27B

<a id="27b"></a>

**Qwen 3.6-27B** (релиз 23 апреля 2026) -- первый open-weight вариант семейства Qwen3.6 под Apache 2.0. Dense 27B coding LLM на гибридной архитектуре **Gated DeltaNet** + multimodal (vision encoder).

| Параметр | Значение |
|----------|----------|
| Параметры | 27B dense |
| Архитектура | dense (по llama.cpp metadata: `qwen35` family, без recurrent state) |
| Модальности | text + vision (mmproj-BF16 889 MB) |
| Контекст | 1M токенов (предварительно) |
| Лицензия | Apache 2.0 |
| **SWE-bench Verified** | **77.2%** -- #1 open-source local |
| Q4_K_M | **15.7 GiB** (замер на платформе) |
| **pp2048** на платформе | **286.7 tok/s** (замер 2026-04-28, Vulkan b8717) |
| **tg256** на платформе | **12.4 tok/s** (замер 2026-04-28) ⚠️ |

**Позиционирование**: лидер локального SWE-bench Verified -- превосходит [Devstral 2 24B](devstral.md) (72.2%) и [Qwen3-Coder Next 80B-A3B](qwen3-coder.md) (70.6%) среди моделей, помещающихся в 120 GiB unified memory платформы.

**КРИТИЧНО для платформы Strix Halo**: dense-архитектура memory-bound. Реальный замер **tg256 = 12.4 tok/s** (близко к теоретическому потолку 256 GB/s ÷ 15.7 GiB ≈ 16 tok/s). Это **в 4.7× медленнее** [Qwen3.6-35B-A3B MoE](#35b-a3b) (58.7 tok/s) и **в 7× медленнее** [Qwen3-Coder 30B-A3B](qwen3-coder.md#30b-a3b) (86 tok/s).

**Практический вывод**: 27B dense **непрактична** как daily agent на Strix Halo. Pilot smoke `bench-aider.sh --tries 2` 2026-04-28 был остановлен после 45 минут без единой закрытой задачи -- multi-turn с retry на 12.4 tok/s растягивает простую задачу на 7-15 мин, smoke 20 × --tries 2 = >5 часов. Замер записан в [runs/2026-04-28-bench-qwen3.6-27b.md](../../coding/benchmarks/runs/2026-04-28-bench-qwen3.6-27b.md).

**Когда всё-таки имеет смысл**:
- Batch-задачи с длинным prompt и коротким output (где pp 286 tok/s окупается)
- Сравнение качества: точечная сверка ответов 27B vs 35B-A3B на конкретной задаче -- запросить 1-2 раза, не loop
- Выход обновлений llama.cpp с GATED_DELTA_NET ускорением (ожидание PR #20376) может изменить картину

Daily agent default остаётся [35B-A3B MoE](#35b-a3b).

**Multimodal**: vision encoder позволяет работать со скриншотами интерфейсов и диаграммами прямо в agent loop -- типичный сценарий для Cursor/Cline/opencode при отладке UI или чтении дизайн-макетов.

**GGUF и интеграция**:
- GGUF выпущен одновременно с релизом весов (типичный паттерн -- `unsloth/Qwen3.6-27B-GGUF`, также bartowski, mradermacher на HuggingFace)
- llama.cpp интеграция через 48 часов после релиза
- Для платформы рекомендуется Q4_K_M (~17 GiB) или Q5_K_M (~20 GiB)

**Источники**:
- [explore.n1n.ai: Qwen 3.6-27B GGUF llama.cpp local multimodal](https://explore.n1n.ai/blog/qwen-3-6-27b-gguf-llama-cpp-local-multimodal-2026-04-23)
- [aimadetools: Best Ollama Models Coding 2026](https://www.aimadetools.com/blog/best-ollama-models-coding-2026/)

## 35B-A3B

<a id="35b-a3b"></a>

**Qwen 3.6-35B-A3B** (релиз 16 апреля 2026) -- первый MoE-вариант семейства Qwen3.6 под Apache 2.0. Sparse Mixture-of-Experts vision-language модель: 35B total параметров, 3B активных на токен, встроенный vision encoder.

| Параметр | Значение |
|----------|----------|
| Параметры | 35B total MoE, 3B active |
| Архитектура | Sparse MoE + vision encoder |
| Модальности | text + vision (multimodal) |
| Контекст | ~128K (оценка, точные данные не раскрыты) |
| Лицензия | Apache 2.0 |
| **SWE-bench Verified** | **73.4%** |
| **Terminal-Bench 2.0** | **51.5%** |
| **QwenWebBench** | **1397** |
| Q4_K_M | ~20 GiB total -- помещается на платформу |
| Скорость на платформе | 58.7 tok/s (замер) tg (256 GB/s ÷ ~1.7 GiB активных Q4, с overhead) |
| Prefill | оценка ~700-1000 tok/s |

**Позиционирование**: новый рекомендуемый default для daily agentic-loop на платформе. MoE-архитектура с 3B active даёт скорость, близкую к [Qwen3-Coder 30B-A3B](qwen3-coder.md#30b-a3b) (86 tok/s) при качестве SWE-V между Devstral 2 (72.2%) и Qwen 3.6-27B dense (77.2%).

**Сравнение с 27B dense**:

| Метрика | 35B-A3B (MoE) | 27B (dense) | Δ |
|---------|---------------|-------------|---|
| SWE-bench Verified | 73.4% | 77.2% | -3.8 п.п. |
| **tg на платформе** (замер) | **58.7 tok/s** | **12.4 tok/s** | **+4.7×** |
| **pp2048** (замер) | -- | **286.7 tok/s** | -- |
| Контекст | ~128K | 1M (предв.) | -8× |
| Q4_K_M | ~20 GiB | 15.7 GiB | +4.3 GiB |
| Modality | text + vision | text + vision | -- |

Trade-off: -3.8 п.п. SWE-V в обмен на **в 4.7× быстрее** генерацию -- решающее для agent loop, где итераций десятки. 27B dense непрактична как daily agent на Strix Halo (см. секцию [27B](#27b)). Aider Polyglot smoke на 27B не закрылся после 45 минут (0 задач) и был остановлен. MoE-вариант 35B-A3B остаётся новым default daily.

**Multimodal**: vision encoder работает со скриншотами интерфейсов, диаграммами, дизайн-макетами -- стандартный сценарий для [opencode](../../ai-agents/agents/opencode.md), [Cline](../../ai-agents/agents/cline.md), [Aider](../../ai-agents/agents/aider.md) при отладке UI или чтении wireframes.

**Когда брать MoE 35B-A3B** (новый default daily agent):
- Daily agentic-loop ([opencode](../../ai-agents/agents/opencode.md), [Aider](../../ai-agents/agents/aider.md), [Cline](../../ai-agents/agents/cline.md))
- Vision-задачи: скриншоты, UI-отладка, дизайн → код
- Multi-file orchestration со многими итерациями
- Quick code review

**Когда переключаться на 27B dense**:
- Сложный single-file refactor с приоритетом качества
- Архитектурный дизайн алгоритма
- Когда +3.8% SWE-V критичны для конкретной задачи
- Время не критично, важно качество одного прохода

**Когда оставаться на [Qwen3-Coder Next 80B-A3B](qwen3-coder.md#next-80b-a3b)**:
- Нужен 256K контекст (35B-A3B оценочно ~128K)
- Уже настроенные пресеты и привычные workflow

**GGUF и интеграция**:
- GGUF выпускается типичным паттерном через unsloth / bartowski / mradermacher на HuggingFace
- llama.cpp: MoE-архитектура поддерживается, multimodal через mmproj-файл
- Для платформы рекомендуется Q4_K_M (~20 GiB)

**Замеры на платформе (Aider Polyglot, text-only вариант)**:

| Прогон | Tasks | pass_1 | pass_2 | sec/case | Дата |
|--------|-------|--------|--------|----------|------|
| smoke 20 + --tries 2 | 20/20 | 30.0% | **70.0%** ⭐ | 248.8 | 2026-04-27 |
| **full** + --tries 2 | **195/195** ✅ | **29.2%** | **65.6%** | ~407 | **2026-04-29** |

Регрессия к среднему -4.4pp от smoke. Лидер C++ (73.1%) на платформе. **0 watchdog kills и 0 manual resumes за 22 часа full** -- best-in-class production-stability. Coder Next 80B-A3B на 2.4pp впереди по pass_2, но 35B-text меньше (20.6 vs 45 GiB) и достиг 100% покрытия. Полная статья: [runs/2026-04-29-aider-full-qwen3.6-35b-text.md](../../coding/benchmarks/runs/2026-04-29-aider-full-qwen3.6-35b-text.md).

**Источники**:
- [HuggingFace: Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B)

## Архитектура и особенности

- **Контекст 1M токенов** по умолчанию (Qwen3.5 был 256K)
- **Output до 65K токенов** -- длинные ответы без обрезаний
- **Always-on chain-of-thought** -- thinking-режим включён по умолчанию
- **Reasoning preservation** -- сохранение thinking context между сообщениями (reasoning chain не теряется при multi-turn)
- **Native function calling**
- **Multimodal** -- text + vision
- **Screenshot-to-code** -- генерация фронтенда из скриншотов и дизайн-макетов
- **Anthropic API protocol** -- работает с [Claude Code](../../ai-agents/agents/claude-code/README.md) и совместимыми клиентами

## Сильные кейсы

- **Agentic coding** -- автономное планирование, написание, тестирование и итеративная доработка кода; production-ready решения
- **Repository-level engineering** -- полный цикл от декомпозиции задачи до финальной интеграции
- **Контекст 1M** -- весь репозиторий + история обсуждений + документация в одном запросе
- **Frontend development** -- интерпретация скриншотов UI, wireframes, прототипов и генерация функционального frontend-кода
- **Document understanding** + multimodal reasoning
- **Сложные workflow** в agent-инструментах ([Claude Code](../../ai-agents/agents/claude-code/README.md), [opencode](../../ai-agents/agents/opencode.md), [Aider](../../ai-agents/agents/aider.md), [Cline](../../ai-agents/agents/cline.md))

## Слабые стороны / ограничения

- **Сейчас нет open weights** -- только API
- **Параметры/архитектура не раскрыты** -- закрытый флагман
- **Конкретных бенчмарков нет** -- Alibaba делает акцент на "workflow performance", не на синтетических метриках
- **Зависимость от облака** -- privacy и стоимость

## Идеальные сценарии применения (когда появятся open weights)

- **[opencode](../../ai-agents/agents/opencode.md) / [Claude Code](../../ai-agents/agents/claude-code/README.md) / [Aider](../../ai-agents/agents/aider.md) / [Cline](../../ai-agents/agents/cline.md)** -- бэкенд для agent-style кодинга
- **Long-context RAG** на больших корпусах документов
- **Screenshot-to-code** -- генерация UI компонентов из дизайнов
- **Multimodal agents** -- задачи с visual вводом + tool use

## Доступ сейчас (API)

```bash
# Через Alibaba Cloud Model Studio
# Документация: https://www.alibabacloud.com/product/modelstudio

# Через OpenRouter (бесплатно в preview-период)
# https://openrouter.ai/

# Совместимые клиенты:
# - Claude Code (через Anthropic API protocol) -- ../../ai-agents/agents/claude-code/README.md
# - opencode (через OpenAI-compatible endpoint) -- ../../ai-agents/agents/opencode.md
# - Qwen Code, Kilo Code, Cline, OpenClaw -- см. ../../ai-agents/agents/
```

## Загрузка (когда появятся open weights)

Когда Alibaba опубликует open-варианты на HuggingFace Qwen org -- проверять:

- [https://huggingface.co/Qwen](https://huggingface.co/Qwen) -- основной канал релизов
- [https://github.com/QwenLM](https://github.com/QwenLM) -- анонсы
- [https://qwen.ai/](https://qwen.ai/) -- официальный сайт

После релиза создать пресет в [`scripts/inference/vulkan/preset/`](../../../scripts/inference/vulkan/preset/) (файл `qwen3.6-<variant>.sh`) и обновить этот файл (заполнить таблицу вариантов, переключить статус на "не скачана").

## Бенчмарки

| Бенч | Значение |
|------|----------|
| Agentic coding (Alibaba claim) | "в одном классе с Claude 4.5 Opus" |
| SWE-bench Verified | не публикуется |
| HumanEval | не публикуется |

## Что отслеживать

1. **Qwen org на HuggingFace** -- появление файлов с "Qwen3.6" в названии
2. **GitHub QwenLM** -- анонсы релизов
3. **Размер open-вариантов** -- по аналогии с Qwen3.5 ожидать 27B / 35B-A3B / 122B-A10B диапазон
4. **GGUF-квантизации** -- bartowski, unsloth, mradermacher обычно публикуют в течение недели после релиза

После релиза:
- Создать пресет в [`scripts/inference/vulkan/preset/`](../../../scripts/inference/vulkan/preset/) (файл `qwen3.6-*.sh`)
- Заполнить таблицу вариантов в этом файле
- Запустить `/models-catalog sync-status`
- Перенести запись в README из "Ожидается open weights" в "Стоит обратить внимание" или "Скачано"

## Roadmap семейства Qwen3.6 на платформе

### Уже выпущенные open-weight (апрель 2026)

| Вариант | Релиз | Размер | Q4 | Скачана? |
|---------|-------|--------|----|---------:|
| Qwen3.6-35B-A3B (multimodal MoE) | 16 апр 2026 | 35B/3B active | 21 GiB | ✅ |
| **Qwen3.6-27B (dense, лидер SWE-V)** | 23 апр 2026 | 27B dense | 15.7 GiB | ✅ скачана + замер (12.4 tok/s, нерентабельна для loop) |

### Ожидается / предполагаемый roadmap

**Qwen3.6-Coder (приоритет ⭐)** -- coder-specific вариант на той же hybrid Gated DeltaNet архитектуре. По паттерну Qwen3 → Qwen3-Coder выпускается через 1-2 месяца после base release. Ожидаемое окно: **июнь-июль 2026**.

Вероятные параметры:
- Размер: 80B-A3B (как [Qwen3-Coder Next](qwen3-coder.md)) -- идеальный sweet spot для платформы (~45 GiB)
- Прогноз SWE-V: **~75-80%** (vs 70.6% у Coder Next текущего, vs 77.2% у 3.6-27B dense)
- Function calling, Agentic coding, FIM -- усиленные

**Qwen3.6-Plus open weights** -- Alibaba обещала "продолжать поддерживать open-source community с отдельными Qwen3.6 моделями в developer-friendly размерах". Plus-уровень (флагман) ожидается в больших размерах (122B+/A10B), не для нашей платформы. Но возможен компактный вариант 35-50B.

**Qwen3.6-Max-Preview** ([релиз 20 апреля 2026](https://qwen.ai/blog?id=qwen3.6-max-preview)) -- proprietary, hosted. **Не для open-weight деплоя**, отслеживаем только для контекста (#1 на 6 coding бенчмарках включая SWE-bench Pro и Terminal-Bench 2.0).

### План для платформы

1. **Выполнено 2026-04-28** -- 27B dense:
   - Qwen3.6-27B Q4_K_M скачана (15.7 GiB, прямой curl с huggingface.co)
   - Пресет [`qwen3.6-27b.sh`](../../../scripts/inference/vulkan/preset/qwen3.6-27b.sh) создан (порт 8086, `-c 131072`, `--keep 1500`, --batch-size/--ubatch-size 4096)
   - Замер: pp2048=286.7, **tg256=12.4 tok/s** -- в 4.7× медленнее MoE 35B-A3B
   - Полный smoke не делался: на 12.4 tok/s aider-loop с --tries 2 = >5 часов на 20 задач, нерентабельно. См. [runs/2026-04-28-bench-qwen3.6-27b.md](../../coding/benchmarks/runs/2026-04-28-bench-qwen3.6-27b.md)
   - Вывод: 27B dense **не daily option** на платформе. Для SWE-V лидерства лучше ждать 35B-A3B Coder fine-tune или 80B-A3B Coder Next refresh
2. **Май-июнь 2026**: следить за анонсами в [Qwen blog](https://qwen.ai/blog) и [GitHub](https://github.com/QwenLM/Qwen3.6)
3. **При релизе Qwen3.6-Coder**:
   - Скачать в день релиза
   - Скопировать преcет от `qwen-coder-next.sh` (с оптимизациями) → `qwen3.6-coder.sh`
   - Запустить full + --tries 2 для прямого сравнения с Coder Next
4. **Тренинг внимания**: все Qwen3.6 на hybrid Gated DeltaNet -- cache-reuse blocked в текущем llama.cpp. Ждать [PR #20376](https://github.com/ggml-org/llama.cpp/pull/20376) merge для PP speedup на всём семействе

## Источники

- [Qwen Blog: Qwen 3.6-Plus](https://qwen.ai/blog?id=qwen3.6)
- [Qwen 3.6-Plus Review (BuildFastWithAI)](https://www.buildfastwithai.com/blogs/qwen-3-6-plus-preview-review)
- [Constellation Research](https://www.constellationr.com/insights/news/alibabas-qwen-launches-new-flagship-llm-qwen-36-plus)
- [Alibaba Cloud blog: Qwen3.6-Plus Towards Real World Agents](https://www.alibabacloud.com/blog/qwen3-6-plus-towards-real-world-agents_603005)
- [Caixin Global: Enhanced Coding Capabilities](https://www.caixinglobal.com/2026-04-02/alibaba-releases-qwen-36-plus-ai-model-with-enhanced-coding-capabilities-102430395.html)

## Связано

- Направления: [coding](../coding.md), [llm](../llm.md), [vision](../vision.md)
- Предыдущее поколение: [qwen35](qwen35.md) (текущий лучший локальный general-purpose Qwen)
- Альтернатива для agent-coding локально: [qwen3-coder](qwen3-coder.md) (Next 80B-A3B, 70.6% SWE-V)
- Внутри семейства: [27B dense](#27b) (лидер качества SWE-V, ~15 tok/s) vs [35B-A3B MoE](#35b-a3b) (рекомендуемый default daily agent, **58.7 tok/s** замер)
