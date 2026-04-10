# MMMU / MMMU-Pro: анализ бенчмарка multimodal reasoning

Что это, как устроен, зачем нужен MMMU-Pro и как использовать для выбора vision-моделей.

## Что такое MMMU

MMMU (Massive Multi-discipline Multimodal Understanding) -- бенчмарк для оценки multimodal reasoning у vision-language моделей. Опубликован в ноябре 2023, принят на CVPR 2024. Разработан командой из нескольких университетов.

Статья: ["MMMU: A Massive Multi-discipline Multimodal Understanding and Reasoning Benchmark for Expert AGI"](https://arxiv.org/abs/2311.16502).

**Ключевая идея**: задачи уровня колледжа/университета, требующие одновременно **восприятия** (распознать диаграмму, график, формулу), **знаний** (предметная область) и **рассуждения** (применить знания к визуальному входу).

## Формат задачи

Каждая задача включает:
- Изображение (или несколько) -- диаграмма, график, химическая структура, нотная запись, карта, таблица
- Текстовый вопрос на естественном языке
- 4 варианта ответа (multiple choice)
- Правильный ответ

Пример:

```
[Изображение: электрическая схема с резисторами и конденсатором]

Вопрос: Определите эквивалентное сопротивление цепи между точками A и B.
(A) 12 Ом  (B) 8 Ом  (C) 15 Ом  (D) 10 Ом
```

Модель должна: распознать элементы схемы на изображении, применить законы Кирхгофа, рассчитать ответ.

## Масштаб и покрытие

**11 550 задач** из 6 дисциплин, 30 предметов, 183 подполя:

| Дисциплина | Предметы | Примеры задач |
|-----------|----------|---------------|
| Art & Design | Музыка, дизайн, архитектура | Нотная запись, стили, конструкции |
| Business | Бухгалтерия, экономика, финансы | Графики рынков, отчётности |
| Science | Физика, химия, биология, математика | Диаграммы, молекулы, графики |
| Health & Medicine | Анатомия, фармакология | Медицинские снимки, схемы |
| Humanities & Social Science | История, география, психология | Карты, инфографика |
| Tech & Engineering | Электроника, CS, материаловедение | Схемы, диаграммы, чертежи |

**30 типов изображений**: графики, диаграммы, карты, таблицы, нотные записи, химические структуры, медицинские снимки, чертежи, фото, скриншоты и др.

## Методология оценки

### Процесс

1. Модель получает изображение(я) + текстовый вопрос + 4 варианта
2. Модель выбирает один вариант (A/B/C/D)
3. Сравнение с ground truth
4. Метрика: **accuracy** (% правильных ответов)

### Калибровка через людей

90 студентов-старшекурсников (3 на предмет) решали по 30 вопросов из своей дисциплины. Средний результат людей-экспертов: **88.6%**. Это ceiling бенчмарка -- выше этого числа модель "превосходит среднего студента".

### Random baseline

4 варианта → random = 25%. Всё что ниже 30% -- модель не понимает задачу.

## Историческая шкала

| Модель | Год | MMMU | Значение |
|--------|-----|------|----------|
| Random baseline | -- | 25% | Случайный выбор |
| LLaVA-1.5-13B | 2023 | 36.4% | Ранние VLM |
| GPT-4V | 2023 | 56.8% | Первый серьёзный результат |
| Gemini 1.5 Pro | 2024 | 62.2% | Google flagship |
| Claude 3.5 Sonnet | 2024 | 68.3% | Anthropic |
| InternVL3-78B | 2025 | 72.2% | Лидер open-source dense |
| Gemma 4 26B-A4B | 2026 | ~72% | Google, MoE |
| InternVL3.5-38B | 2026 | ~74% | Лидер dense GGUF (est.) |
| Qwen3-VL 30B-A3B | 2026 | ~70% | MoE, лучший OCR |
| GPT-5 / Gemini 3.1 Pro | 2026 | 80%+ | Frontier closed |
| Люди-эксперты | -- | 88.6% | Потолок |

За 3 года: 36% → 80%+. Бенчмарк ещё **не насыщен** (в отличие от HumanEval) -- gap до людей ~8 пунктов.

## MMMU-Pro: усложнённая версия

MMMU-Pro (сентябрь 2024, [arXiv](https://arxiv.org/abs/2409.02813)) -- ответ на рост score и обнаружение shortcuts в MMMU.

### Три усложнения

**1. Фильтрация text-only задач**

Убраны задачи, которые text-only модели (без vision) решают правильно. Если GPT-4-turbo (без картинки) отвечает верно -- задача не требует visual understanding и исключается.

**2. Расширение с 4 до 10 вариантов ответа**

Random baseline падает с 25% до 10%. Модели, которые "угадывали" через elimination, теряют score. GPT-4o потерял 10.7% только от этого изменения.

**3. Vision-only input**

Текст вопроса **внедряется в изображение** (скриншот). Модель должна одновременно "видеть" и "читать" -- чисто визуальная задача без текстовой подсказки.

### Результат

Score моделей на MMMU-Pro на **16-27 пунктов ниже** чем на MMMU. Это не деградация моделей, а более честная оценка.

| Модель | MMMU | MMMU-Pro | Падение |
|--------|------|----------|---------|
| GPT-4o | 69.1% | 54.1% | -15 |
| Claude 3.5 Sonnet | 68.3% | 51.5% | -16.8 |
| Gemini 1.5 Pro | 62.2% | 44.9% | -17.3 |
| Gemma 4 26B-A4B | ~72% | ~76.9% (MMMU-Pro) | -- |
| Kimi K2.5 | -- | 78.5% | лидер open-source |

**Вывод**: MMMU-Pro -- более строгий и менее насыщенный бенчмарк. Для frontier-моделей 2026 следует смотреть MMMU-Pro, не MMMU.

## Критика и ограничения

### 1. Сложность для open-source оценки

Запуск MMMU требует мультимодальной pipeline: загрузка изображений → encoding → inference → parsing ответа. Для GGUF-моделей через llama.cpp нет готового harness -- нужен свой скрипт.

### 2. Multiple choice bias

4 варианта (или 10 в Pro) -- это multiple choice, не свободная генерация. Модели могут использовать elimination strategy. Реальные задачи (OCR, описание фото) не имеют вариантов ответа.

### 3. English-only

Все задачи на английском. Способность работать с не-латинскими скриптами (русский OCR, японские документы) не оценивается.

### 4. Статичный датасет

В отличие от LiveCodeBench, MMMU не обновляется регулярно. Contamination со временем растёт.

## MMMU score моделей на нашей платформе

| Модель | Параметры | MMMU | MMMU-Pro | Скачана | Сильное место |
|--------|-----------|------|----------|---------|---------------|
| [InternVL3-38B](../../models/families/internvl.md#3-5-38b) | 38B dense | 72.2 | -- | **да** | Math, charts, reasoning |
| [Gemma 4 26B-A4B](../../models/families/gemma4.md) | 26B MoE / 3.8B | ~72 | **76.9** | **да** | FC + vision, screenshot-to-code |
| [Qwen3-VL 30B-A3B](../../models/families/qwen3-vl.md#30b-a3b) | 30B MoE / 3B | ~70 | -- | **да** | OCR, документы, structured JSON |
| [Mistral Small 3.1](../../models/families/mistral-small-31.md) | 24B dense | 64 | -- | нет | FC, balanced |
| [Qwen2.5-Omni 7B](../../models/families/qwen25-omni.md) | 7B dense | 59 | -- | нет | Vision + audio + text |
| [Pixtral 12B](../../models/families/pixtral.md) | 12B dense | 52 | -- | нет | Multi-image, Apache 2.0 |
| [SmolVLM2 2.2B](../../models/families/smolvlm2.md) | 2.2B dense | 42 | -- | нет | Edge, 150 tok/s |

**Замечание**: MMMU-Pro score опубликован не для всех моделей. Gemma 4 показывает 76.9% на MMMU-Pro -- это выше чем 72% на MMMU, потому что Google оптимизировал Gemma 4 специально под MMMU-Pro-стиль задач.

## Когда использовать MMMU vs MMMU-Pro

| Сценарий | Какой бенчмарк | Почему |
|----------|----------------|--------|
| Сравнение open-source моделей среднего размера (14-38B) | **MMMU** | Больше опубликованных score |
| Сравнение frontier-моделей (>70B или closed) | **MMMU-Pro** | Менее насыщен, строже |
| Выбор модели для OCR/документов | Ни тот ни другой -- **DocVQA** | MMMU -- reasoning, не OCR |
| Выбор модели для charts/graphs | **MMMU** или **ChartQA** | MMMU покрывает charts, но ChartQA специализированнее |
| Быстрый smoke test vision-модели | **MMMU** | Стандартный, все публикуют |

## Ссылки

- [MMMU (официальный сайт)](https://mmmu-benchmark.github.io/) -- leaderboard, dataset, methodology
- [MMMU paper (arXiv)](https://arxiv.org/abs/2311.16502) -- оригинальная статья 2023
- [MMMU-Pro paper (arXiv)](https://arxiv.org/abs/2409.02813) -- усложнённая версия 2024
- [MMMU dataset (HuggingFace)](https://huggingface.co/datasets/MMMU/MMMU) -- датасет
- [GitHub: MMMU-Benchmark/MMMU](https://github.com/MMMU-Benchmark/MMMU) -- evaluation code
- [MMMU-Pro Leaderboard (Artificial Analysis)](https://artificialanalysis.ai/evaluations/mmmu-pro) -- агрегированный leaderboard
- [MMMU-Pro Leaderboard (llm-stats)](https://llm-stats.com/benchmarks/mmmu-pro) -- альтернативный агрегатор

## Связано

- [docs/models/vision.md](../../models/vision.md) -- сравнительные таблицы с MMMU score
- [docs/models/families/internvl.md](../../models/families/internvl.md) -- лидер dense MMMU на платформе
- [docs/models/families/gemma4.md](../../models/families/gemma4.md) -- лидер MMMU-Pro на платформе
- [docs/models/families/qwen3-vl.md](../../models/families/qwen3-vl.md) -- OCR-лидер (MMMU -- не основная метрика)
- [docs/llm-guide/benchmarks/README.md](README.md) -- классификация всех бенчмарков
