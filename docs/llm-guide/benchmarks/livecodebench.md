# LiveCodeBench: contamination-free бенчмарк кодинга

Что это, как работает непрерывное обновление, и почему это лучший индикатор реальной способности модели писать код.

## Что такое LiveCodeBench

LiveCodeBench -- бенчмарк кодинга, который **непрерывно собирает свежие задачи** с competitive programming платформ. Опубликован в марте 2024. Главное отличие от [HumanEval](humaneval.md) и [SWE-bench](swe-bench.md): задачи обновляются ежемесячно, что делает contamination (утечку в training data) практически невозможной.

Статья: ["LiveCodeBench: Holistic and Contamination Free Evaluation of Large Language Models for Code"](https://arxiv.org/abs/2403.07974).

**Ключевая идея**: если модель обучалась до марта 2025, а задача появилась в апреле 2025 -- модель не могла её "заучить". Привязка задач к датам позволяет отфильтровать contamination для любой модели с известным training cutoff.

## Источники задач

| Платформа | Тип задач | Частота контестов |
|-----------|-----------|-------------------|
| [LeetCode](https://leetcode.com/) | Weekly/Biweekly contests | 2-3 раза в неделю |
| [AtCoder](https://atcoder.jp/) | ABC/ARC/AGC rated contests | еженедельно |
| [CodeForces](https://codeforces.com/) | Div 1-4 rated contests | 2-3 раза в неделю |

Каждая задача снабжена:
- Условие на естественном языке
- Набор тестов (public + hidden)
- Точная дата публикации (timestamp контеста)
- Уровень сложности (Easy / Medium / Hard)

## Масштаб

| Версия | Период | Задачи |
|--------|--------|--------|
| v1 | май 2023 - сентябрь 2023 | ~400 |
| v4 | май 2023 - сентябрь 2024 | 713 |
| v5 | май 2023 - январь 2025 | 880 |
| v6 | май 2023 - апрель 2025 | 1055+ |

Датасет только растёт -- старые задачи не удаляются, новые добавляются каждый месяц.

## Формат задачи

```
Условие:
  Дана строка s, состоящая из строчных латинских букв.
  Определите минимальное количество операций удаления подстрок
  для преобразования строки в палиндром.

Входные данные:
  Первая строка содержит целое число t (1 <= t <= 100) --
  количество тестовых случаев. Далее t строк с s (1 <= |s| <= 2*10^5).

Выходные данные:
  Для каждого тестового случая выведите одно число -- ответ.

Примеры:
  Вход: 3
         abc
         aaa
         abacaba
  Выход: 2
         0
         1
```

Модель генерирует полное решение (не одну функцию, как в HumanEval), которое запускается с hidden тестами.

## Четыре сценария оценки

LiveCodeBench оценивает не только генерацию кода, но и смежные навыки:

| Сценарий | Что оценивает | Формат |
|----------|---------------|--------|
| **Code Generation** | Написание решения с нуля | Условие → полное решение |
| **Self-Repair** | Исправление ошибки после неудачной попытки | Условие + ошибочный код + traceback → исправленный код |
| **Code Execution** | Предсказание вывода программы | Код + входные данные → предсказанный вывод |
| **Test Output Prediction** | Предсказание результата тестов | Код + тесты → pass/fail |

Основная метрика: **pass@1** на Code Generation (как в [HumanEval](humaneval.md)).

## Методология: contamination detection

Главная инновация -- **временная сегментация**:

```
Training cutoff модели: август 2024
                              |
задачи до августа 2024        |  задачи после августа 2024
(могут быть в training data)  |  (гарантированно чистые)
                              |
Score на "до": 75%            |  Score на "после": 58%
                              |
Разница = contamination signal
```

Если score резко падает после training cutoff -- модель "помнила" старые задачи.

**Реальные примеры contamination**:
- DeepSeek-Instruct-33B: score падает на LeetCode-задачах после августа 2023 (совпадает с release date)
- GPT-4o: падение на задачах после ноября 2023 (training cutoff)
- AtCoder-задачи менее подвержены contamination (реже попадают в training data)

## Критика и ограничения

### 1. Competitive programming != production coding

Задачи LiveCodeBench -- алгоритмические (sorting, graphs, DP, number theory). Production-кодинг включает:
- Работу с библиотеками и фреймворками (покрывает [BigCodeBench](https://bigcode-bench.github.io/))
- Multi-file архитектуру (покрывает [SWE-bench](swe-bench.md))
- Debugging и refactoring
- Code review и documentation

### 2. Только Python (преимущественно)

Хотя задачи допускают решение на нескольких языках, все evaluation pipeline ориентированы на Python/C++. Нет оценки TypeScript, Go, Rust.

### 3. Latency vs quality trade-off не измеряется

LiveCodeBench не учитывает время генерации. Модель, которая думает 60 секунд и даёт правильный ответ, получает тот же score, что и модель за 2 секунды. Для real-time agent loop это критично.

### 4. Нет agentic-компонента

Модель генерирует one-shot решение. Нет итеративного цикла (написал → запустил → увидел ошибку → исправил), как в реальных agent-инструментах ([opencode](../../ai-agents/agents/opencode.md), [Aider](../../ai-agents/agents/aider.md)).

## LiveCodeBench vs HumanEval vs SWE-bench

| Критерий | [HumanEval](humaneval.md) | LiveCodeBench | [SWE-bench](swe-bench.md) |
|----------|--------------------------|---------------|---------------------------|
| Год | 2021 | 2024 | 2023 |
| Задачи | 164 (фиксированные) | 1055+ (растут) | 500-2294 |
| Contamination-free | **нет** | **да** | частично (Pro -- да) |
| Тип задач | Простые функции | Competitive programming | Реальные GitHub issues |
| Agentic | нет | нет | **да** |
| Обновление | никогда | ежемесячно | при подаче |
| Насыщение (2026) | **да** (95%+) | частично (~80% frontier) | частично (Verified загрязнён) |
| Языки | Python | Python, C++ | Python (+ Go/TS/JS в Pro) |

**Оптимальная стратегия**: использовать все три как комплементарные сигналы:
- HumanEval -- baseline / smoke test
- LiveCodeBench -- чистый coding signal
- SWE-bench -- agentic capabilities

## Как интерпретировать LiveCodeBench score

| Score (pass@1, Easy+Medium+Hard) | Что это значит |
|----------------------------------|---------------|
| <30% | Слабая модель для кодинга |
| 30-50% | Средний уровень (open-source 7-14B) |
| 50-65% | Хорошая модель (open-source 30-80B) |
| 65-80% | Frontier open-source / mid-tier closed |
| 80%+ | Frontier closed (GPT-5, Claude Opus) |

## LiveCodeBench и наша платформа

LiveCodeBench score не публикуется для большинства open-source моделей в стандартных model cards. Его нужно проверять на [livecodebench.github.io/leaderboard.html](https://livecodebench.github.io/leaderboard.html) или [artificialanalysis.ai](https://artificialanalysis.ai/evaluations/livecodebench).

Для наших моделей:

| Модель | LiveCodeBench (est.) | Основание |
|--------|----------------------|-----------|
| [Gemma 4 26B-A4B](../../models/families/gemma4.md) | **77.1%** (LiveCodeBench v6) | Опубликован Google |
| [Qwen3-Coder Next 80B-A3B](../../models/families/qwen3-coder.md#next-80b-a3b) | ~65-70% (est.) | По SWE-bench 70.6% и Aider polyglot |
| [Devstral 2 24B](../../models/families/devstral.md) | ~55-60% (est.) | Dense 24B, SWE-bench 72.2% но competitive < agentic |
| [Qwen2.5-Coder 32B](../../models/families/qwen25-coder.md#32b) | ~55% (est.) | HumanEval 92.7%, но competitive coding слабее |

**Gemma 4** показывает 77.1% -- лучший score среди наших моделей на LiveCodeBench. Это подтверждает, что Gemma сильна не только в vision, но и в pure coding (LiveCodeBench v6 score, Codeforces ELO 1718).

## Практическое использование

### Как запустить самостоятельно

```bash
git clone https://github.com/LiveCodeBench/LiveCodeBench.git
cd LiveCodeBench
pip install -e .

# Генерация решений через OpenAI-compatible API
python -m lcb_runner.runner.main \
    --model "openai/qwen3-coder-next" \
    --api_base "http://192.168.1.77:8081/v1" \
    --scenario codegeneration \
    --start_date 2025-01-01 \
    --end_date 2025-04-01 \
    --n 1 --temperature 0.2

# Оценка
python -m lcb_runner.evaluation.compute_scores \
    --scenario codegeneration \
    --model "openai/qwen3-coder-next"
```

Это даст contamination-free score на задачах после training cutoff модели.

### Когда запускать на платформе

- При добавлении новой coding-модели -- для сравнения с Qwen3-Coder Next (базовый score)
- При смене кванта (Q4 → Q8) -- чтобы оценить деградацию
- После обновления llama.cpp -- верификация что performance не деградировал

## Ссылки

- [LiveCodeBench (официальный сайт)](https://livecodebench.github.io/) -- leaderboard, methodology
- [LiveCodeBench paper (arXiv)](https://arxiv.org/abs/2403.07974) -- оригинальная статья 2024
- [GitHub: LiveCodeBench/LiveCodeBench](https://github.com/LiveCodeBench/LiveCodeBench) -- код и данные
- [LiveCodeBench Leaderboard (Artificial Analysis)](https://artificialanalysis.ai/evaluations/livecodebench)
- [LiveCodeBench Leaderboard (llm-stats)](https://llm-stats.com/benchmarks/livecodebench)

## Связано

- [docs/llm-guide/benchmarks/README.md](README.md) -- классификация всех бенчмарков
- [docs/llm-guide/benchmarks/humaneval.md](humaneval.md) -- HumanEval (синтетический, насыщен)
- [docs/llm-guide/benchmarks/swe-bench.md](swe-bench.md) -- SWE-bench (agentic)
- [docs/models/coding.md](../../models/coding.md) -- сравнительные таблицы coding-моделей
- [docs/models/families/gemma4.md](../../models/families/gemma4.md) -- лидер LiveCodeBench на платформе (77.1%)
