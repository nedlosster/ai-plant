# SWE-bench: анализ бенчмарка agentic-кодинга

Что это, как устроен, почему Original и Verified загрязнены, и что делает Pro.

## Что такое SWE-bench

SWE-bench -- бенчмарк от Princeton NLP (октябрь 2023, ICLR 2024) для оценки способности AI-систем решать **реальные задачи** из GitHub-репозиториев. В отличие от [HumanEval](humaneval.md) (164 изолированные функции), SWE-bench проверяет работу в контексте настоящей кодовой базы: понять issue, найти нужные файлы, написать patch, не сломать остальное.

Опубликован в статье ["SWE-bench: Can Language Models Resolve Real-World GitHub Issues?"](https://arxiv.org/abs/2310.06770) (Carlos E. Jimenez et al., Princeton).

**Формат**: модель получает текст GitHub Issue + доступ к репозиторию на конкретном коммите. Задача -- сгенерировать patch (diff), который решает описанную проблему. Результат проверяется через **fail-to-pass тесты**: тесты, которые падают без patch и проходят с ним.

## Формат задачи

Каждый экземпляр содержит:

| Поле | Описание |
|------|----------|
| `instance_id` | Уникальный ID (например `django__django-16379`) |
| `repo` | Репозиторий (например `django/django`) |
| `base_commit` | SHA коммита, на котором воспроизводится баг |
| `problem_statement` | Текст GitHub Issue |
| `patch` | Эталонное решение (gold patch) -- diff из PR |
| `test_patch` | Тесты, которые должны перейти из FAIL в PASS |
| `FAIL_TO_PASS` | Список тестов, которые падают на base_commit |
| `PASS_TO_PASS` | Тесты, которые не должны сломаться |

Пример problem_statement (упрощённый):

```
Title: QuerySet.only() after select_related() crashes on reverse OneToOneField

Description:
Given a model with a reverse OneToOneField relation:
  Book.objects.select_related('author').only('title')
raises TypeError: int() argument must be a string...
```

AI-система должна:
1. Прочитать issue
2. Найти в кодовой базе Django (200K+ строк) где ошибка
3. Написать patch (обычно 5-50 строк)
4. Не сломать 5000+ существующих тестов

## Методология оценки

### Процесс

```
Issue text + repository snapshot (base_commit)
                    |
                    v
          AI system generates patch
                    |
                    v
      Docker container: git checkout base_commit
                    |
                    v
              Apply patch (git apply)
                    |
                    v
         Run FAIL_TO_PASS tests → must PASS
         Run PASS_TO_PASS tests → must still PASS
                    |
                    v
         Resolved: all pass → score +1
         Failed: any fail → score 0
```

### Docker sandbox

Каждая задача выполняется в изолированном Docker-контейнере с:
- Установленным репозиторием на `base_commit`
- Зависимостями проекта (pip, apt)
- Полным тестовым окружением

Ресурсы: x86_64, 120 GB storage, 16 GB RAM, 8 CPU cores.

### Scaffolding (agent harness)

AI-система не просто вызывается один раз -- она работает в **agentic loop**:
- Читает файлы проекта
- Запускает grep/search
- Редактирует код
- Запускает тесты
- Итерирует по ошибкам

Качество scaffolding (agent framework) влияет на результат не меньше, чем качество модели. Одна и та же модель может дать 69% standalone и 81% с продвинутым agent harness.

### Репозитории в датасете

Original SWE-bench включает 12 Python-репозиториев:

```
django/django, scikit-learn/scikit-learn, matplotlib/matplotlib,
sympy/sympy, sphinx-doc/sphinx, astropy/astropy, pylint-dev/pylint,
pytest-dev/pytest, mwaskom/seaborn, pydata/xarray,
psf/requests, pallets/flask
```

Все -- крупные production-проекты с десятками тысяч строк и зрелой тестовой инфраструктурой.

## Варианты SWE-bench

| Вариант | Год | Задачи | Языки | Особенность |
|---------|-----|--------|-------|-------------|
| **Original** | 2023 | 2294 | Python | Полный набор, много шума |
| **Lite** | 2024 | 300 | Python | Подмножество для быстрого тестирования |
| **Verified** | 2024 | 500 | Python | Отфильтрован OpenAI (качественные тесты) |
| **Pro** | 2025 | 1865 | Python, Go, TypeScript, JS | Contamination-resistant, multi-language |
| **Multimodal** | 2025 | -- | + screenshots | Visual context к issues |

### SWE-bench Original (2294 задачи)

Первая версия. Проблемы:
- Много задач с **невоспроизводимыми** тестами или **нечёткими** issue descriptions
- Шум в данных: некоторые задачи нерешаемы по описанию
- 2294 задачи -- долго запускать полностью

### SWE-bench Lite (300 задач)

Подмножество Original -- 300 лучших задач для быстрого прогона. Де-факто замена Original для большинства оценок.

### SWE-bench Verified (500 задач)

Создан в сотрудничестве с OpenAI (июнь 2024). 500 задач, каждая проверена людьми на:
- Корректность тестов
- Однозначность issue description
- Решаемость по описанию (без скрытого контекста)

**Проблема**: к 2026 году датасет загрязнён (см. "Критика" ниже). OpenAI прекратила публиковать Verified-цифры в феврале 2026.

### SWE-bench Pro (1865 задач)

Создан Scale AI (2025) как ответ на загрязнение Verified:
- **1865 задач** из **41 репозитория**
- **4 языка**: Python, Go, TypeScript, JavaScript
- Задачи из реальных commit histories: consecutive commits (bug fix + test)
- **Не публично доступен** (дополнительная защита от contamination)
- Стандартизированный agent harness (SEAL) -- одинаковый scaffolding для всех моделей

Результат: **Claude Opus 4.5 набирает 80.9% на Verified и 45.9% на Pro**. Та же модель -- вдвое ниже score. Это иллюстрирует масштаб загрязнения Verified.

## Критика и ограничения

### 1. Contamination (загрязнение обучающих данных)

Главная проблема Verified (2026):
- 500 задач публичны с 2024 года. Gold patches из реальных PR -- тоже на GitHub
- **Аудит OpenAI** (февраль 2026): каждая протестированная frontier-модель (GPT-5.2, Claude Opus 4.5, Gemini 3 Flash) могла воспроизвести **verbatim gold patches** на части задач
- OpenAI проверила 138 задач (27.6% датасета) -- из нерешённых: **59.4% имели дефектные тесты**
- Любая модель, обученная на GitHub-данных после июня 2024, вероятно видела часть решений

OpenAI [прекратила публиковать Verified-цифры](https://openai.com/index/why-we-no-longer-evaluate-swe-bench-verified/) и рекомендует Pro.

### 2. Scaffolding dominance

Результат зависит не только от модели, но от **agent framework**:
- Та же модель: 69% standalone → 81% с продвинутым scaffolding
- Retry-стратегия, file exploration depth, test-driven iteration -- всё влияет
- Без стандартизации scaffolding нельзя сравнивать модели

SWE-bench Pro решает это через **SEAL harness** -- единый agent для всех подач.

### 3. Python-only (Original/Verified)

Original и Verified содержат только Python-задачи из 12 репозиториев. Модели, оптимизированные под Python-стек (Django, pytest), получают преимущество. Production-кодинг включает десятки языков.

Pro расширяет до Go/TypeScript/JavaScript, но всё ещё не покрывает C++/Java/Rust.

### 4. Масштаб задач

Типичная задача SWE-bench: 5-50 строк patch в одном файле. Реальные production-задачи часто требуют:
- Multi-file изменения
- Архитектурные решения
- Миграции и рефакторинг
- Работу с CI/CD, docker, deployment

SWE-bench оценивает **bug fixing**, не **feature development** или **architecture**.

### 5. Overfit на конкретные проекты

12 репозиториев (Original/Verified) -- все Django/scipy/pytest-экосистема. Модели, которые хорошо знают Django ORM, получают бонус. Это не отражает способность работать с произвольным проектом.

## Как интерпретировать SWE-bench score

### Verified (с оговоркой о contamination)

| Score | Что это значит |
|-------|---------------|
| <30% | Базовый уровень (standalone LLM без agent) |
| 30-50% | Простой agent с retry и file search |
| 50-70% | Хороший agentic coding (open-source модели 2025+) |
| 70-80% | Frontier open-source (Qwen3-Coder Next, Devstral 2) |
| 80%+ | Frontier closed (Claude Opus 4.5, GPT-5.3 Codex) -- **возможно загрязнено** |
| 90%+ | Preview-модели (Claude Mythos 93.9%) -- **вероятно загрязнено** |

### Pro (более чистый сигнал)

| Score | Что это значит |
|-------|---------------|
| <20% | Слабый agent или слабая модель |
| 20-35% | Средний уровень |
| 35-46% | Frontier (Claude Opus 4.5: 45.9%, GPT-5.3 Codex: ~57%) |
| 50%+ | Передовой edge |

Pro-цифры вдвое ниже Verified у тех же моделей -- это **нормально**, не деградация.

## SWE-bench score моделей на нашей платформе

| Модель | Параметры | SWE-V (Verified) | SWE-Pro | Скачана | Примечание |
|--------|-----------|-------------------|---------|---------|------------|
| [Qwen3-Coder Next 80B-A3B](../models/families/qwen3-coder.md#next-80b-a3b) | 80B MoE / 3B | **70.6%** | не публ. | **да** | Лидер open-source на платформе |
| [Devstral 2 24B](../models/families/devstral.md) | 24B dense | **72.2%** | не публ. | **да** | Лидер dense-сегмента |
| [Qwen3-Coder 30B-A3B](../models/families/qwen3-coder.md#30b-a3b) | 30B MoE / 3B | ~62% (est.) | не публ. | **да** | Младшая MoE, 86 tok/s |
| [Kimi K2.5 1T MoE](../models/families/kimi-k25.md) | 1T / 32B | **76.8%** | не публ. | API only | Не помещается (240+ GiB) |
| [Qwen2.5-Coder 32B](../models/families/qwen25-coder.md#32b) | 32B dense | не публ. | не публ. | нет (watch) | HumanEval 92.7%, SWE-bench не основной |
| [Qwen2.5-Coder 1.5B](../models/families/qwen25-coder.md#1-5b) | 1.5B dense | не применим | -- | **да** | FIM-сервер, не agentic |
| [Gemma 4 26B-A4B](../models/families/gemma4.md) | 26B MoE / 3.8B | не публ. | не публ. | **да** | Vision + FC, не coder-tuned |
| [Qwen3.5 122B-A10B](../models/families/qwen35.md#122b-a10b) | 122B MoE / 10B | не публ. | не публ. | **да** | Universal, не coder-tuned |

### Для сравнения: frontier closed-source

| Модель | SWE-V | SWE-Pro | Доступ | Стоимость |
|--------|-------|---------|--------|-----------|
| Claude Mythos Preview | **93.9%** | -- | preview | -- |
| GPT-5.3 Codex | 85.0% | ~57% | API | $10/1M |
| Claude Opus 4.5 | 80.9% | 45.9% | API | $15/1M |
| Gemini 3.1 Pro | 78.8% | -- | API | $1.25/1M |

**Вывод**: наш локальный стек (Qwen3-Coder Next 70.6%, Devstral 2 72.2%) отстаёт от frontier closed-source на 8-13 пунктов по Verified. На Pro разрыв может быть больше, но Pro-цифры для open-source моделей не публикуются. При нулевой стоимости inference и privacy это приемлемая разница для большинства задач.

## SWE-bench vs HumanEval

| Критерий | [HumanEval](humaneval.md) | SWE-bench |
|----------|--------------------------|-----------|
| Год | 2021 | 2023 |
| Что оценивает | Генерация одной функции | Решение реальной задачи в проекте |
| Размер | 164 задачи | 500-2294 задачи |
| Язык | Python only | Python (+ Go/TS/JS в Pro) |
| Контекст | Нет (изолированная функция) | Полная кодовая база (10K-200K строк) |
| Тесты | 3-8 на задачу | 1-50 fail-to-pass + pass-to-pass |
| Agentic | Нет (one-shot generation) | Да (read files, grep, edit, run tests) |
| Насыщение (2026) | Да (95%+) | Частично (Verified загрязнён, Pro -- нет) |
| Практическая ценность | Baseline / smoke test | Основной индустриальный бенчмарк для coding agents |

**Эволюция**: HumanEval → "может ли модель написать функцию?". SWE-bench → "может ли модель решить реальную задачу в реальном проекте?". Это разные уровни сложности, и SWE-bench ближе к реальному использованию в [AI-агентах](../../ai-agents/agents/).

## Рекомендация для нашей платформы

SWE-bench Verified -- **основной критерий** при выборе coding-моделей для платформы, с оговоркой о contamination. Практические рекомендации:

1. **Для оценки новых моделей**: смотреть SWE-bench Verified как primary, LiveCodeBench как contamination-free дополнение
2. **Для сравнения с closed-source**: SWE-bench Pro (когда публикуются цифры)
3. **Для daily work**: платформенные замеры (pp/tg tok/s) важнее score -- 70.6% SWE-V при 53 tok/s (Qwen3-Coder Next) практичнее чем 80.9% SWE-V через API за $15/1M
4. **Не полагаться на цифры выше 85% SWE-V** -- высока вероятность contamination

Полная таблица рейтинговых сайтов: [docs/models/coding.md](../models/coding.md#где-смотреть-актуальные-рейтинги).

## Ссылки

- [SWE-bench (официальный сайт)](https://www.swebench.com/) -- leaderboard, datasets, methodology
- [SWE-bench: Can Language Models Resolve Real-World GitHub Issues? (arXiv)](https://arxiv.org/abs/2310.06770) -- оригинальная статья 2023
- [GitHub: SWE-bench/SWE-bench](https://github.com/SWE-bench/SWE-bench) -- код evaluation harness
- [princeton-nlp/SWE-bench (HuggingFace)](https://huggingface.co/datasets/princeton-nlp/SWE-bench) -- датасет Original
- [princeton-nlp/SWE-bench_Verified (HuggingFace)](https://huggingface.co/datasets/princeton-nlp/SWE-bench_Verified) -- датасет Verified
- [OpenAI: Why we no longer evaluate SWE-bench Verified](https://openai.com/index/why-we-no-longer-evaluate-swe-bench-verified/) -- аудит contamination, февраль 2026
- [OpenAI: Introducing SWE-bench Verified](https://openai.com/index/introducing-swe-bench-verified/) -- создание Verified, 2024
- [SWE-Bench Pro Leaderboard (Scale AI)](https://labs.scale.com/leaderboard/swe_bench_pro_public) -- актуальный Pro рейтинг
- [SWE-Bench Pro Explained (Morph)](https://www.morphllm.com/swe-bench-pro) -- почему 46% лучше 81%
- [SWE-bench Verified (Epoch AI)](https://epoch.ai/benchmarks/swe-bench-verified/) -- исторические данные
- [Vals AI: SWE-bench](https://www.vals.ai/benchmarks/swebench) -- независимая верификация
- [Is SWE-bench Verified Contaminated? (CodeSOTA)](https://www.codesota.com/news/swe-bench-contamination-debate) -- разбор дебатов

## Связано

- [docs/llm-guide/humaneval.md](humaneval.md) -- HumanEval (изолированные функции, предшественник)
- [docs/models/coding.md](../models/coding.md) -- сравнительные таблицы моделей с SWE-bench score
- [docs/models/coding.md#где-смотреть-актуальные-рейтинги](../models/coding.md#где-смотреть-актуальные-рейтинги) -- все рейтинговые сайты
- [docs/ai-agents/agents/](../../ai-agents/agents/) -- AI-агенты, использующие SWE-bench-модели
- [docs/models/families/qwen3-coder.md](../models/families/qwen3-coder.md) -- основная coding-модель на платформе (70.6% SWE-V)
- [docs/models/families/devstral.md](../models/families/devstral.md) -- лидер dense (72.2% SWE-V)
