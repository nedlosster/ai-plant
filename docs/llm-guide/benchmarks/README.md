# Бенчмарки AI-моделей: методология

Описание самих бенчмарков -- что измеряют, как устроены, известные проблемы. Эта часть **не привязана к платформе** -- общая теория и анализ методов оценки моделей.

**Прогоны на нашей платформе Strix Halo** (наш leaderboard, отчёты по запускам, runbooks, история результатов) -- в [docs/coding/benchmarks/](../../coding/benchmarks/). Это разделение: здесь -- "что такое benchmark X", там -- "как мы тестировали модель Y на нашей платформе".

## Статьи раздела (методология)

| Статья | Тема |
|--------|------|
| [HumanEval](humaneval.md) | Методология, pass@k, критика, EvalPlus, таблица моделей платформы |
| [SWE-bench](swe-bench.md) | Методология, Verified vs Pro, contamination, scaffolding, таблица моделей |
| [LiveCodeBench](livecodebench.md) | Contamination-free coding, LeetCode/AtCoder/CodeForces, temporal segmentation |
| [MMMU / MMMU-Pro](mmmu.md) | Vision multimodal reasoning, 30 дисциплин, 11.5K задач, MMMU-Pro усложнения |

## Классификация бенчмарков

### Синтетические (изолированные задачи)

Модель получает описание функции и генерирует код. Проверка -- unit-тесты. Простые, быстрые, но насыщены: frontier-модели дают 90%+.

| Бенчмарк | Год | Задачи | Язык | Contamination-free | Статус 2026 |
|----------|-----|--------|------|--------------------|----|
| [HumanEval](humaneval.md) | 2021 | 164 | Python | нет | насыщен (95%+) |
| MBPP | 2021 | 974 | Python | нет | насыщен |
| [EvalPlus](https://evalplus.github.io/) (HumanEval+ / MBPP+) | 2023 | 164+378 | Python | нет (те же задачи) | актуален (строже тесты) |
| [HumanEval Pro / MBPP Pro](https://arxiv.org/html/2412.21199v2) | 2024 | 164+378 | Python | частично | self-invoking code |

### Agentic (реальные задачи в кодовой базе)

Модель работает в контексте реального проекта: читает файлы, ищет баги, пишет patch. Основной критерий для coding agents.

| Бенчмарк | Год | Задачи | Языки | Contamination-free | Статус 2026 |
|----------|-----|--------|-------|--------------------|----|
| [SWE-bench Original](swe-bench.md) | 2023 | 2294 | Python | нет | шумный, заменён Verified/Pro |
| [SWE-bench Verified](swe-bench.md) | 2024 | 500 | Python | **нет** (OpenAI audit) | загрязнён, но широко используется |
| [SWE-bench Pro](https://labs.scale.com/leaderboard/swe_bench_pro_public) | 2025 | 1865 | Python, Go, TS, JS | **да** | рекомендован OpenAI вместо Verified |
| [SWE-bench Multimodal](https://www.swebench.com/) | 2025 | -- | + screenshots | да | vision-расширение |

### Contamination-free (свежие задачи)

Задачи обновляются регулярно, не попадают в training data. Лучший сигнал "реальной" способности модели.

| Бенчмарк | Год | Задачи | Источник | Обновление |
|----------|-----|--------|----------|------------|
| [LiveCodeBench](https://livecodebench.github.io/) | 2024 | 1055+ | LeetCode, AtCoder, CodeForces | ежемесячно |
| [BigCodeBench](https://bigcode-bench.github.io/) | 2024 | 1140 | Реальные библиотеки (pandas, numpy, sklearn) | периодически |

### Human preference (голосование людей)

Пользователи выбирают лучший ответ из двух анонимных моделей. Нет "правильного" ответа -- субъективная оценка качества.

| Бенчмарк | Фокус | Формат |
|----------|-------|--------|
| [LMSYS Chatbot Arena](https://lmarena.ai/) | Общий chat | Pairwise voting |
| [LMSYS WebDev Arena](https://web.lmarena.ai/leaderboard) | Frontend / UI генерация | Pairwise voting |
| [LMSYS Copilot Arena](https://lmarena.ai/) | FIM / IDE autocomplete | Pairwise voting |

### Vision / multimodal

Задачи с изображениями: OCR, графики, диаграммы, math reasoning по фото.

| Бенчмарк | Фокус | Примечание |
|----------|-------|------------|
| [MMMU](https://mmmu-benchmark.github.io/) | College-level multimodal reasoning | 30 дисциплин |
| MMMU-Pro | Усложнённый MMMU (10 вариантов ответа) | Строже, менее насыщен |
| [ChartQA](https://github.com/vis-nlp/ChartQA) | Графики и диаграммы | Для InternVL-класса моделей |
| [DocVQA](https://www.docvqa.org/) | Документы, OCR, таблицы | Для Qwen3-VL-класса моделей |

### Общие / агрегаторы

| Бенчмарк | Что даёт | Ссылка |
|----------|----------|--------|
| [HuggingFace Open LLM Leaderboard](https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard) | Общий рейтинг open-source моделей | Multi-benchmark |
| [Artificial Analysis](https://artificialanalysis.ai/) | Скорость + цена + качество в одной таблице | Для API-моделей |
| [llm-stats](https://llm-stats.com/) | Агрегация SWE-bench, HumanEval, MMLU | Удобные фильтры |
| [Vals AI](https://www.vals.ai/benchmarks/) | Независимая верификация бенчмарков | Доверенный источник |
| [Epoch AI](https://epoch.ai/benchmarks/) | Исторические данные, тренды | Для анализа прогресса |

### Coding-specific

| Бенчмарк | Фокус | Ссылка |
|----------|-------|--------|
| [Aider Polyglot](https://aider.chat/docs/leaderboards/) | Multi-language code editing через Aider | Python, JS, TS, Java, C++, Go. Runbook: [coding/benchmarks/runbooks/aider-polyglot.md](../../coding/benchmarks/runbooks/aider-polyglot.md) |
| [Terminal-Bench 2.0](https://www.terminal-bench.com) | Agent tool use в shell-окружении | 56 задач: bash, git, debugging. Runbook: [coding/benchmarks/runbooks/terminal-bench.md](../../coding/benchmarks/runbooks/terminal-bench.md) |
| [Faros.ai](https://faros.ai/) | Frontend vs backend по отдельности | Используется для сравнения AI-агентов |
| [Codeforces ELO](https://codeforces.com/) | Competitive programming | Оценка алгоритмического мышления |

## Какой бенчмарк смотреть

| Задача | Первый бенчмарк | Дополнительный | Почему |
|--------|-----------------|----------------|--------|
| Выбор coding-модели для agent loop | **SWE-bench Verified** | LiveCodeBench | Agentic + contamination-free |
| Выбор FIM-модели для IDE | **LMSYS Copilot Arena** | Aider Polyglot | Human preference + multi-lang |
| Сравнение квантизаций (Q4 vs Q8) | **HumanEval** | EvalPlus | Быстрый smoke test |
| Выбор vision-модели | **MMMU / MMMU-Pro** | DocVQA, ChartQA | Multi-discipline + документы |
| Оценка frontier closed-source | **SWE-bench Pro** | Artificial Analysis | Чистый сигнал + цена |
| Оценка speed/quality trade-off | **Artificial Analysis** | Платформенные замеры | Скорость + цена + качество |
| Frontend-специфичный выбор | **Faros.ai** | LMSYS WebDev Arena | Отдельно front vs back |

## Проблемы бенчмарков

| Проблема | Затронутые | Следствие |
|----------|-----------|-----------|
| **Contamination** (утечка задач в training data) | HumanEval, MBPP, SWE-bench Verified | Score завышен, не отражает реальную способность |
| **Насыщение** (все модели 90%+) | HumanEval, MBPP | Не различает frontier-модели |
| **Scaffolding dominance** | SWE-bench | Результат зависит от agent framework, не только от модели |
| **Субъективность** | LMSYS Arena | Зависит от пула голосующих |
| **Python-bias** | HumanEval, MBPP, SWE-bench Original | Модели оптимизированные под Python получают бонус |
| **Simplicity** | HumanEval (70% -- 5 концепций) | Не отражает production-задачи |

## Рейтинговые сайты: классификация

### Официальные leaderboards (авторы бенчмарка)

Первоисточник score. Все подачи верифицированы авторами или стандартизированным harness.

| Сайт | Бенчмарк | Кто ведёт | Обновление |
|------|----------|-----------|------------|
| [swebench.com](https://www.swebench.com/) | SWE-bench (Verified, Pro, Multimodal) | Princeton NLP | при подаче |
| [evalplus.github.io](https://evalplus.github.io/leaderboard.html) | HumanEval+ / MBPP+ | EvalPlus team | при подаче |
| [livecodebench.github.io](https://livecodebench.github.io/leaderboard.html) | LiveCodeBench | LiveCodeBench team | ежемесячно |
| [bigcode-bench.github.io](https://bigcode-bench.github.io/) | BigCodeBench | HuggingFace BigCode | периодически |
| [lmarena.ai](https://lmarena.ai/) | LMSYS Chatbot Arena / Copilot Arena | UC Berkeley LMSYS | в реальном времени |
| [web.lmarena.ai](https://web.lmarena.ai/leaderboard) | WebDev Arena | LMSYS | в реальном времени |
| [mmmu-benchmark.github.io](https://mmmu-benchmark.github.io/) | MMMU | MMMU team | при подаче |
| [labs.scale.com](https://labs.scale.com/leaderboard/swe_bench_pro_public) | SWE-bench Pro (SEAL) | Scale AI | при подаче |

### Агрегаторы (собирают данные из нескольких бенчмарков)

Удобны для быстрого сравнения. Не проводят собственных оценок -- компилируют чужие.

| Сайт | Что агрегирует | Фишка |
|------|----------------|-------|
| [artificialanalysis.ai](https://artificialanalysis.ai/) | Скорость, цена, качество API-моделей | Единая таблица speed/cost/quality |
| [llm-stats.com](https://llm-stats.com/) | SWE-bench, HumanEval, MMLU и др. | Фильтры по бенчмарку, модели |
| [huggingface.co/open-llm-leaderboard](https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard) | Multi-benchmark для open-source | Стандарт индустрии для open-моделей |
| [benchlm.ai](https://benchlm.ai/) | SWE-bench + LiveCodeBench | Weighted coding score |
| [epoch.ai](https://epoch.ai/benchmarks/) | Исторические данные по бенчмаркам | Тренды и прогнозы |

### Независимые верификаторы

Перепроверяют заявленные score на собственной инфраструктуре. Ценны когда вендор публикует подозрительно высокие цифры.

| Сайт | Фокус |
|------|-------|
| [vals.ai](https://www.vals.ai/benchmarks/) | SWE-bench, HumanEval -- независимая верификация |
| [hal.cs.princeton.edu](https://hal.cs.princeton.edu/) | SWE-bench Verified Mini -- академическая верификация |
| [swe-rebench.com](https://swe-rebench.com/) | Re-evaluation SWE-bench -- независимый harness |

### Специализированные coding-рейтинги

| Сайт | Фокус | Кому полезен |
|------|-------|--------------|
| [aider.chat/docs/leaderboards](https://aider.chat/docs/leaderboards/) | Aider Polyglot -- multi-language editing | Выбор модели для Aider |
| [faros.ai](https://faros.ai/) | Frontend vs backend, стоимость за задачу | Выбор AI-агента |
| [morphllm.com](https://www.morphllm.com/ai-coding-benchmarks-2026) | Обзорные статьи по всем coding-бенчмаркам | Контекст и объяснения |
| [codesota.com](https://www.codesota.com/) | Code SOTA tracker | Отслеживание новых рекордов |

### Vendor-рейтинги (с конфликтом интересов)

Публикуются самими вендорами моделей. Полезны как data point, но не как единственный источник.

| Источник | Что публикует | Caveat |
|----------|---------------|--------|
| [openai.com/research](https://openai.com/research/) | Score GPT-5, Codex на бенчмарках | Выбирают выгодные бенчмарки |
| [anthropic.com/research](https://www.anthropic.com/research) | Score Claude на бенчмарках | Аналогично |
| [qwenlm.github.io](https://qwenlm.github.io/) | Qwen model cards с бенчмарками | Open-source, но тоже self-reported |
| [mistral.ai/news](https://mistral.ai/news/) | Score Mistral/Codestral/Devstral | Аналогично |

**Правило**: если score опубликован только вендором и не подтверждён ни одним независимым leaderboard -- относиться скептически.

## Связано

- [docs/coding/benchmarks/](../../coding/benchmarks/) -- **прогоны на нашей платформе** Strix Halo, leaderboard, runbooks, отчёты по запускам
- [docs/models/coding.md](../../models/coding.md#где-смотреть-актуальные-рейтинги) -- ссылки на все рейтинговые сайты
- [docs/models/vision.md](../../models/vision.md) -- MMMU score в таблицах vision-моделей
- [docs/ai-agents/comparison.md](../../ai-agents/comparison.md) -- бенчмарки Faros.ai для AI-агентов
- [docs/models/coding.md](../../models/coding.md#open-vs-облачные-лидеры-апрель-2026) -- сравнение open vs closed SWE-bench
