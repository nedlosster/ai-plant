# HumanEval: анализ бенчмарка кодогенерации

Что это, как устроен, почему насыщен и что пришло ему на смену.

## Что такое HumanEval

HumanEval -- бенчмарк от OpenAI (июль 2021), созданный для оценки способности LLM генерировать корректный код по описанию на естественном языке. Опубликован в статье ["Evaluating Large Language Models Trained on Code"](https://arxiv.org/abs/2107.03374) (Mark Chen et al.) вместе с моделью Codex.

**164 задачи** на Python. Каждая включает:
- Сигнатуру функции
- Docstring с описанием задачи
- Набор unit-тестов для проверки
- Референсное решение (для верификации тестов)

Задачи написаны вручную командой OpenAI, не взяты из публичных наборов данных -- что на момент выпуска гарантировало отсутствие в обучающих выборках моделей.

## Формат задачи

```python
def has_close_elements(numbers: List[float], threshold: float) -> bool:
    """Check if in given list of numbers, are any two numbers
    closer to each other than given threshold.
    >>> has_close_elements([1.0, 2.0, 3.0], 0.5)
    False
    >>> has_close_elements([1.0, 2.8, 3.0, 4.0, 5.0, 2.0], 0.3)
    True
    """
```

Модель получает сигнатуру + docstring и должна дописать тело функции. Затем код запускается с unit-тестами -- прошли все → задача решена.

## Метрика pass@k

Главная инновация HumanEval -- метрика **pass@k**:

- **pass@1** -- вероятность, что единственное сгенерированное решение пройдёт все тесты
- **pass@10** -- вероятность, что хотя бы одно из 10 решений пройдёт
- **pass@100** -- хотя бы одно из 100

Формула:

```
pass@k = 1 - C(n-c, k) / C(n, k)
```

где `n` -- число сгенерированных решений, `c` -- число корректных среди них.

Зачем несколько попыток: на момент 2021 года Codex решал 28.8% задач с одной попытки (pass@1), но 70.2% с 100 попыток (pass@100). Это показало, что модели "знают" решение, но не всегда выдают его с первого раза -- стохастичность sampling играет роль.

Сейчас (2026) pass@1 -- основная метрика: frontier-модели дают 90%+ с первой попытки, и pass@100 потерял практический смысл.

## Историческая шкала

| Модель | Год | pass@1 | Значение для индустрии |
|--------|-----|--------|------------------------|
| GPT-3 | 2021 | 0% | Не умела кодировать |
| Codex (GPT-3 + code finetune) | 2021 | 28.8% | Первый "программирующий" LLM |
| GPT-3.5 | 2023 | 48.1% | ChatGPT эпоха |
| GPT-4 | 2023 | 67.0% | Прорыв в coding quality |
| Claude 3 Opus | 2024 | 84.9% | Anthropic вошла в гонку |
| DeepSeek-V3 | 2025 | ~90% | Open-source догнал |
| Qwen2.5-Coder 32B | 2025 | **92.7%** | Лидер open-source dense |
| GPT-5 / Claude Opus 4.5 | 2026 | 95%+ | Бенчмарк насыщен |

За 5 лет: 0% → 95%+. Бенчмарк перестал различать frontier-модели.

## Методология: как проводится оценка

### Процесс

1. Модель получает prompt: сигнатуру функции + docstring (без тела)
2. Модель генерирует тело функции (одно или k решений)
3. Каждое решение помещается в sandbox и запускается с unit-тестами
4. Результат: pass (все тесты прошли) или fail

### Параметры генерации

- temperature: обычно 0.2 для pass@1, 0.8 для pass@100
- max_tokens: ограничен (~256-512 токенов)
- top_p: 0.95
- Нет доступа к интернету, библиотекам, файлам -- чистая генерация

### Sandbox

Код запускается в изолированной среде. Нет `import os`, `subprocess`, сетевых вызовов. Только стандартная библиотека Python + math/typing/collections.

## Критика и ограничения

### 1. Насыщение (saturation)

Frontier-модели 2026 года дают 95%+ pass@1. Бенчмарк **не различает** лучшие модели -- все "сдали на отлично". Это как IQ-тест, где все набирают 149-151 баллов -- потолок теста, не испытуемых.

### 2. Простота задач

164 задачи покрывают узкий спектр:
- **70% задач** -- 5 концепций: строки, массивы, математика, условия, циклы
- Нет работы с файлами, сетью, базами данных, фреймворками
- Нет multi-file задач
- Нет зависимостей (только stdlib)
- Средняя длина решения: 8-15 строк

Это уровень "LeetCode Easy/Medium", не "production-код".

### 3. Мало тестов (недостаточное покрытие)

Каждая задача проверяется **менее чем 10 тестами**. Это позволяет:
- Off-by-one ошибкам проходить
- Corner cases не обнаруживаться
- Хардкод конкретных ответов формально "проходить"

Исследование EvalPlus показало: расширение тестов в **80x** (HumanEval+) снижает pass@1 у моделей с 94.2% до 79.9%. То есть **15% "правильных" решений содержали баги**, не замеченные оригинальными тестами.

### 4. Contamination (утечка в обучающие данные)

164 задачи опубликованы на GitHub с 2021 года. К 2026 году они есть в training data практически всех LLM. Модели могут "вспоминать" решения, а не генерировать их.

Доказательство: модели, обученные на коде после 2021, показывают аномально высокие результаты на HumanEval даже при слабых результатах на свежих задачах.

### 5. Только Python

Бенчмарк покрывает только Python. Нет Java, TypeScript, C++, Go, Rust. Модели, оптимизированные под Python, получают преимущество.

### 6. Нет контекста проекта

Реальное программирование -- это работа в контексте кодовой базы: import-ы, зависимости, conventions, тесты, CI. HumanEval оценивает **изолированную** генерацию функций, не agentic-работу.

## EvalPlus: исправление ограничений тестирования

[EvalPlus](https://evalplus.github.io/) (NeurIPS 2023) -- прямой ответ на проблему #3:

- **HumanEval+**: те же 164 задачи, но тестов в **80x больше** (автоматическая генерация + ручная верификация)
- **MBPP+**: 378 задач из MBPP с тестами в **35x больше**

Результат: pass@1 у моделей **падает на 10-15%** по сравнению с оригинальным HumanEval. Это показывает, что модели генерируют код, проходящий простые тесты, но содержащий corner-case баги.

**Леderboard**: [evalplus.github.io/leaderboard.html](https://evalplus.github.io/leaderboard.html)

EvalPlus не решает проблемы #1 (насыщение), #2 (простота), #4 (contamination) и #6 (нет контекста). Только делает тестирование строже.

## Что пришло на смену

| Бенчмарк | Год | Задачи | Что оценивает | Contamination-free | Ссылка |
|----------|-----|--------|---------------|--------------------|----|
| HumanEval | 2021 | 164 | Изолированная генерация функций Python | нет (все знают задачи) | [github.com/openai/human-eval](https://github.com/openai/human-eval) |
| MBPP | 2021 | 974 | Простые задачи (уровень intro CS) | нет | [google-research/mbpp](https://github.com/google-research/google-research/tree/master/mbpp) |
| EvalPlus (HumanEval+/MBPP+) | 2023 | 164+378 | Те же задачи, строже тесты | нет (те же задачи) | [evalplus.github.io](https://evalplus.github.io/) |
| BigCodeBench | 2024 | 1140 | Реальные библиотеки и API (pandas, numpy, sklearn) | частично | [bigcode-bench.github.io](https://bigcode-bench.github.io/) |
| LiveCodeBench | 2024-now | 1055+ | Свежие задачи с LeetCode/AtCoder/CodeForces | **да** (обновляется) | [livecodebench.github.io](https://livecodebench.github.io/) |
| SWE-bench (Verified/Pro) | 2023-now | 500+ | Реальные GitHub issues → PR | частично | [swebench.com](https://www.swebench.com/) |
| Aider Polyglot | 2024 | ~130 | Multi-language editing через Aider | частично | [aider.chat/docs/leaderboards](https://aider.chat/docs/leaderboards/) |

### Эволюция фокуса

```
2021  HumanEval        "Может ли модель написать функцию?"
2023  EvalPlus          "Без багов ли эта функция?"
2024  BigCodeBench      "Может ли использовать реальные библиотеки?"
2024  LiveCodeBench     "На свежих задачах, без заучивания?"
2023  SWE-bench         "Может ли решить реальный баг в реальном проекте?"
2026  SWE-bench Pro     "Без contamination?"
```

Индустрия движется от "сгенерируй функцию" к "реши реальную задачу в реальном проекте". HumanEval остался как **исторический маркер** и **baseline** для новых моделей, но для оценки frontier-моделей 2026 года бесполезен.

## Когда HumanEval ещё полезен

Несмотря на ограничения, HumanEval имеет практическое применение:

1. **Smoke test новой модели** -- если модель не может набрать 70%+ на HumanEval, нет смысла тестировать на SWE-bench
2. **Сравнение квантизаций** -- Q4 vs Q8 одной модели: деградация на HumanEval покажет потерю "базовой" способности кодировать
3. **Обучение и fine-tune** -- быстрый feedback loop при дообучении (164 задачи прогоняются за минуты)
4. **FIM-модели** -- HumanEval можно адаптировать для infill-задач (дописать середину функции)
5. **Baseline для нового семейства** -- первый опубликованный score для позиционирования модели

## Как интерпретировать HumanEval score

| Score | Что это значит | На практике |
|-------|---------------|-------------|
| <50% | Модель слабо кодирует | Не использовать для coding agents |
| 50-70% | Базовые задачи решает | Подходит для простых скриптов, объяснений |
| 70-85% | Хороший кодировщик | Конкурентоспособна для daily use |
| 85-92% | Сильная модель | Подходит для production agent-style |
| 92%+ | Потолок бенчмарка | Не различает -- смотреть SWE-bench, BigCodeBench |

## HumanEval score моделей на нашей платформе

| Модель | Параметры | Тип | HumanEval pass@1 | Скачана | Примечание |
|--------|-----------|-----|-------------------|---------|------------|
| [Qwen2.5-Coder 32B](../models/families/qwen25-coder.md#32b) | 32B dense | Coder | **92.7%** | нет (watch) | Лидер open-source dense |
| [Qwen2.5-Coder 7B](../models/families/qwen25-coder.md#7b) | 7B dense | Coder | 88.4% | нет (watch) | FIM + chat, хороший баланс |
| [Codestral 25.08](../models/families/codestral.md) | 22B dense | Coder/FIM | 86.6% | нет (watch) | Лидер LMsys FIM arena |
| [Gemma 4 26B-A4B](../models/families/gemma4.md) | 26B MoE / 3.8B | Universal+VLM | ~85% (est.) | **да** | LiveCodeBench 77.1%, AIME 88.3% |
| [Qwen3-Coder Next 80B-A3B](../models/families/qwen3-coder.md#next-80b-a3b) | 80B MoE / 3B | Coder | не публикуется | **да** | SWE-bench 70.6% (agentic > synthetic) |
| [Qwen3-Coder 30B-A3B](../models/families/qwen3-coder.md#30b-a3b) | 30B MoE / 3B | Coder | не публикуется | **да** | 86 tok/s, fокус на SWE-bench |
| [Devstral 2 24B](../models/families/devstral.md) | 24B dense | Coder | не публикуется | **да** | SWE-bench 72.2%, FIM+agent |
| [Qwen2.5-Coder 1.5B](../models/families/qwen25-coder.md#1-5b) | 1.5B dense | FIM | ~75% | **да** | FIM-сервер, 120 tok/s |
| [Qwen3.5 122B-A10B](../models/families/qwen35.md#122b-a10b) | 122B MoE / 10B | Universal | не публикуется | **да** | Не coder-tuned, для chat |
| [Qwen3.5 35B-A3B](../models/families/qwen35.md#35b-a3b) | 35B MoE / 3B | Universal | не публикуется | **да** | Не coder-tuned, для chat |
| [InternVL3-38B](../models/families/internvl.md#3-5-38b) | 38B dense | VLM | не применим | **да** | Vision-модель, MMMU 72.2 |

**Замечание**: Qwen3-Coder и Devstral 2 не публикуют HumanEval — они оптимизированы под **SWE-bench** (agentic multi-step задачи), а не под синтетические функции. HumanEval-score для них не показателен: 70.6% SWE-bench у Qwen3-Coder Next практически важнее, чем 92.7% HumanEval у Qwen2.5-Coder 32B.

## Рекомендация для нашей платформы

Для оценки моделей на платформе HumanEval **не является основным критерием**. Используем:

1. **SWE-bench Verified** -- основной agentic-бенчмарк (70.6% Qwen3-Coder Next, 72.2% Devstral 2)
2. **Платформенные замеры** (pp/tg tok/s через llama-bench) -- практическая скорость
3. **LiveCodeBench** -- contamination-free, для верификации свежих моделей
4. **BigCodeBench** -- реальные библиотеки, ближе к production

HumanEval оставляем как **исторический baseline** и **smoke test** при добавлении новой модели в каталог.

Полная таблица рейтинговых сайтов: [docs/models/coding.md](../models/coding.md#где-смотреть-актуальные-рейтинги).

## Ссылки

- [OpenAI HumanEval (GitHub)](https://github.com/openai/human-eval) -- исходный датасет
- [Evaluating Large Language Models Trained on Code (arXiv)](https://arxiv.org/abs/2107.03374) -- оригинальная статья 2021
- [openai/openai_humaneval (HuggingFace)](https://huggingface.co/datasets/openai/openai_humaneval) -- датасет на HF
- [EvalPlus (HumanEval+ / MBPP+)](https://evalplus.github.io/) -- расширенное тестирование
- [EvalPlus Leaderboard](https://evalplus.github.io/leaderboard.html) -- актуальный рейтинг
- [BigCodeBench](https://bigcode-bench.github.io/) -- реальные библиотеки и API
- [LiveCodeBench](https://livecodebench.github.io/) -- contamination-free
- [AI Coding Benchmarks 2026 (Morph)](https://www.morphllm.com/ai-coding-benchmarks-2026) -- обзор всех бенчмарков
- [Where Do LLMs Still Struggle? (arXiv)](https://arxiv.org/html/2511.04355v1) -- глубокий анализ ограничений

## Связано

- [docs/models/coding.md](../models/coding.md) -- сравнительные таблицы моделей с HumanEval-score
- [docs/models/coding.md#где-смотреть-актуальные-рейтинги](../models/coding.md#где-смотреть-актуальные-рейтинги) -- все рейтинговые сайты
- [docs/llm-guide/function-calling.md](function-calling.md) -- function calling (agentic-бенчмарки оценивают это)
- [docs/models/families/qwen25-coder.md](../models/families/qwen25-coder.md) -- лидер HumanEval (92.7%)
