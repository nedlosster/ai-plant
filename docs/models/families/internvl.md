# InternVL3 / InternVL3.5 (OpenGVLab, 2025-2026)

> Vision-серия с большим vision encoder (6B), сильна на математике, диаграммах, reasoning. InternVL3.5 -- свежее поколение 2026 с лучшим MMMU в open-source dense сегменте.

**Тип**: dense (2B / 14B / 38B / 78B) + MoE (3.5-30B-A3B, 3.5-241B-A28B)
**Лицензия**: Open (MIT-like)
**Статус на сервере**: частично (3.5-38B на скачивании)
**Направления**: [vision](../vision.md)

## Обзор

InternVL3 / InternVL3.5 от OpenGVLab -- серия с фокусом на reasoning и сложные задачи. Использует **InternViT-6B-448px-V2_5** -- большой vision encoder (6B параметров, в 6 раз больше типового). Отсюда сила на сложных визуальных задачах: математика, диаграммы, графики.

InternVL3.5 (релиз август 2025, продолжение в 2026) -- новое поколение. 38B dense -- лучший баланс качество/VRAM в категории: MMMU ~74 при ~24 GiB Q4 на платформе. 241B-A28B MoE -- frontier (MMMU 77.7), но не помещается локально.

## Варианты

| Вариант | Параметры | VRAM Q4 | mmproj | MMMU | Статус | Hub |
|---------|-----------|---------|--------|------|--------|-----|
| InternVL3-2B | 2B dense | ~2 GiB | ~3 GiB | -- | не скачана | [bartowski/InternVL3-2B-GGUF](https://huggingface.co/bartowski/InternVL3-2B-GGUF) |
| InternVL3-14B | 14B dense | ~8 GiB | ~3 GiB | -- | не скачана | [bartowski/InternVL3-14B-GGUF](https://huggingface.co/bartowski/InternVL3-14B-GGUF) |
| InternVL3-78B | 78B dense | ~50 GiB | ~3 GiB | 72.2 | не скачана | [bartowski/InternVL3-78B-GGUF](https://huggingface.co/bartowski/InternVL3-78B-GGUF) |
| **InternVL3.5-38B** | 38B dense | ~24 GiB | ~3 GiB | **~74** | **на скачивании** | [QuantStack/InternVL3_5-38B-gguf](https://huggingface.co/QuantStack/InternVL3_5-38B-gguf) |
| InternVL3.5-30B-A3B | 30B MoE / 3B | ~18 GiB | ~3 GiB | ~73 | не скачана | [bartowski/OpenGVLab_InternVL3_5-30B-A3B-GGUF](https://huggingface.co/bartowski/OpenGVLab_InternVL3_5-30B-A3B-GGUF) |
| InternVL3.5-14B | 14B dense | ~9 GiB | ~3 GiB | ~70 | не скачана | [bartowski/OpenGVLab_InternVL3_5-14B-GGUF](https://huggingface.co/bartowski/OpenGVLab_InternVL3_5-14B-GGUF) |
| InternVL3.5-241B-A28B | 241B MoE / 28B | ~145 GiB | ~3 GiB | **77.7** | не помещается | [HF: OpenGVLab](https://huggingface.co/OpenGVLab) |

### InternVL3.5-38B {#3-5-38b}

Топ dense-сегмента для нашей платформы по MMMU. ~24 GiB Q4_K_M + 3 GiB mmproj = 27 GiB -- комфортно помещается с большим запасом на контекст и параллельные сервера.

- **MMMU ~74** -- лидер dense open-source среднего сегмента (выше Qwen3-VL 30B-A3B Instruct)
- **Скорость**: ~15 tok/s (dense 38B на bandwidth-limited платформе)
- **Контекст**: 32-64K (зависит от конфига сервера)
- **Сильные стороны**: reasoning, математика, научные диаграммы, multi-image сравнение
- **Слабые**: медленнее MoE-вариантов того же качества, уступает Qwen3-VL на чистом OCR

## Сильные кейсы

- **Математика по картинке** -- решение задач из учебников, уравнения с переменными, геометрия
- **Научные диаграммы** -- графики из статей, диаграммы рассеяния, контурные карты
- **Chart QA** -- одна из лучших на ChartQA benchmark
- **Reasoning по схемам** -- блок-схемы алгоритмов, UML, ER-диаграммы
- **Tables** -- извлечение таблиц из научных статей
- **Лидер на MMMU** -- 78B = 72.2 (комплексный multimodal reasoning)

## Слабые стороны

- mmproj большой (3 GB) -- занимает заметно VRAM
- OCR на текстах не лучше [qwen3-vl](qwen3-vl.md)
- Function calling слабее
- Не поддерживает видео нативно

## Базовые сценарии (простые)

- **"Опиши что на графике"** -- bar/line/scatter, ключевые тренды, выбросы
- **OCR таблицы из PDF** → структурированный JSON или CSV
- **Решение школьной задачи по фото** -- алгебра, геометрия, физика с диаграммой
- **Распознавание формул** из учебника или научной статьи (LaTeX-вывод)
- **"Что не так с этим chart?"** -- обнаружение визуальных несоответствий, неверных осей, отсутствующих легенд
- **Описание блок-схемы / UML / ER-диаграммы** в текстовом виде
- **Извлечение данных из квартального отчёта** -- цифры из графиков, таблиц, выноски

## Сложные сценарии

### 1. Воспроизведение цифр из научной статьи

Загрузить PDF научной публикации с графиками и таблицами. InternVL3.5-38B (или 78B) может:
- Извлечь точные значения из bar/line charts (не "примерно", а конкретные числа с error bars)
- Сопоставить цифры в таблице с упоминаниями в тексте, найти расхождения
- Пересчитать derivations и проверить, согласуются ли выводы с данными
- Указать на статистические проблемы (малая выборка, отсутствие confidence intervals, p-hacking признаки)

Это уровень peer-review junior researcher.

### 2. Multi-page document understanding

PDF с десятками страниц диаграмм + текста (например квартальный отчёт компании или научный обзор). InternVL3.5:
- Восстанавливает **связи** между диаграммами на разных страницах (что зависит от чего)
- Строит **сводную таблицу** всех ключевых метрик из документа
- Находит **противоречия** между утверждениями в тексте и цифрами в графиках
- Выделяет **тренды** через сравнение нескольких диаграмм

### 3. Reasoning по математической задаче со схемой

Задача из олимпиады/учебника с геометрической схемой или физической диаграммой:
- Распознаёт элементы схемы (углы, отрезки, силы, векторы)
- Связывает с условием задачи
- Решает пошагово с обоснованием каждого шага
- На сложных задачах превосходит чисто текстовые LLM, потому что "видит" то, что в условии описано неявно

### 4. ChartQA / Plot interpretation

Скриншот сложного графика с несколькими сериями данных, double-axis, аннотациями:
- Идентифицирует тип графика и каждую серию данных
- Извлекает значения по запросу ("что было в Q3 2023?")
- Сравнивает серии между собой ("когда серия A впервые превысила B?")
- Делает predictions ("исходя из тренда, какое значение ожидается в Q1 2024?")

InternVL3.5 -- один из лучших на ChartQA benchmark в open-source.

### 5. Анализ ML training curves

Скриншоты из TensorBoard / Weights & Biases с loss/accuracy/learning rate кривыми:
- Распознаёт **признаки overfitting** (расхождение train/val loss)
- Находит **проблемы learning rate** (слишком высокий → расходится, слишком низкий → плато)
- Сравнивает несколько runs и выбирает лучший
- Предлагает **гиперпараметры** для следующей итерации

### 6. Извлечение структуры из инфографики

Сложная инфографика (например про устройство клетки, архитектуру системы, исторический таймлайн):
- Распознаёт визуальную иерархию и связи между элементами
- Выводит структурированный JSON с узлами и рёбрами графа
- Может ответить на вопросы про конкретный элемент в контексте всей инфографики

### 7. Сравнение двух научных диаграмм

Загрузить две статьи с похожими экспериментами. Модель:
- Находит **методологические различия** в схемах эксперимента
- Сравнивает **результаты** и объясняет, почему они различаются
- Указывает, какая статья более убедительна и почему

### Когда брать какую модель

| Задача | Модель | Почему |
|--------|--------|--------|
| Простой ChartQA, OCR таблицы | InternVL3-14B / 3.5-14B | Достаточно качества, ~25 tok/s |
| Multi-page reasoning, сложные диаграммы | **InternVL3.5-38B** | Лидер dense MMMU, помещается на платформу |
| Reasoning над несколькими источниками | InternVL3-78B | Если нужен ещё больший контекст и качество |
| Frontier multi-image, peer-review | InternVL3.5-241B-A28B | Только через API/cloud, не помещается локально |

### Альтернативы по задаче

- **Чистый OCR (особенно мелкий текст, не-латинские шрифты)** -- лучше [Qwen3-VL 30B-A3B](qwen3-vl.md#30b-a3b), у InternVL фокус на reasoning, не на OCR
- **Скриншот UI → код** -- [Gemma 4 26B-A4B](gemma4.md), специально натренирована на screenshot-to-code
- **Видео и аудио** -- [Qwen2.5-Omni](qwen25-omni.md), у InternVL нет нативной поддержки видео

## Загрузка

```bash
# InternVL3.5-38B (рекомендуется для платформы) -- ~24 GiB модель + ~3 GiB mmproj
./scripts/inference/download-model.sh QuantStack/InternVL3_5-38B-gguf \
    --include '*Q4_K_M*' --include 'mmproj*'

# InternVL3-14B (компактный)
./scripts/inference/download-model.sh bartowski/InternVL3-14B-GGUF \
    --include '*Q4_K_M*' --include 'mmproj*'
```

## Бенчмарки

| Модель | MMMU | Примечание |
|--------|------|------------|
| InternVL3.5-241B-A28B | **77.7** | frontier, не помещается |
| InternVL3.5-38B | ~74 | топ dense на платформе |
| InternVL3.5-30B-A3B | ~73 | MoE-альтернатива |
| InternVL3-78B | 72.2 | предыдущее поколение |

## Ссылки

**Официально**:
- [HuggingFace: OpenGVLab](https://huggingface.co/OpenGVLab) -- организация
- [GitHub: OpenGVLab/InternVL](https://github.com/OpenGVLab/InternVL)
- [InternVL3.5 paper (arXiv)](https://arxiv.org/abs/2508.18265)

**GGUF-квантизации (3.5)**:
- [QuantStack/InternVL3_5-38B-gguf](https://huggingface.co/QuantStack/InternVL3_5-38B-gguf) -- 38B + mmproj
- [bartowski/OpenGVLab_InternVL3_5-30B-A3B-GGUF](https://huggingface.co/bartowski/OpenGVLab_InternVL3_5-30B-A3B-GGUF)
- [bartowski/OpenGVLab_InternVL3_5-14B-GGUF](https://huggingface.co/bartowski/OpenGVLab_InternVL3_5-14B-GGUF)
- [bartowski/OpenGVLab_InternVL3_5-8B-GGUF](https://huggingface.co/bartowski/OpenGVLab_InternVL3_5-8B-GGUF)
- [bartowski/OpenGVLab_InternVL3_5-4B-GGUF](https://huggingface.co/bartowski/OpenGVLab_InternVL3_5-4B-GGUF)

**GGUF-квантизации (3)**:
- [bartowski/InternVL3-14B-GGUF](https://huggingface.co/bartowski/InternVL3-14B-GGUF)
- [bartowski/InternVL3-78B-GGUF](https://huggingface.co/bartowski/InternVL3-78B-GGUF)

## Связано

- Направления: [vision](../vision.md)
- Альтернативы: [qwen3-vl](qwen3-vl.md) (OCR/документы), [gemma4](gemma4.md) (function calling)
