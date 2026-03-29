# Chunking: разбиение документов

Chunking -- разбиение документов на фрагменты перед индексацией. Один embedding
не может представить 10 000 слов -- смысл "размазывается". Chunk по 200-500 слов
про одну тему дает точный embedding и точный поиск.

Размер и стратегия chunking -- главный рычаг качества RAG.


## Содержание

- [Зачем нужен chunking](#зачем-нужен-chunking)
- [Стратегии](#стратегии)
- [Fixed-size](#fixed-size)
- [Recursive text splitting](#recursive-text-splitting)
- [Semantic chunking](#semantic-chunking)
- [Markdown-aware chunking](#markdown-aware-chunking)
- [Code-aware chunking](#code-aware-chunking)
- [Overlap](#overlap)
- [Параметры: chunk_size vs качество](#параметры-chunk_size-vs-качество)
- [Метаданные chunk-а](#метаданные-chunk-а)


## Зачем нужен chunking

```
Документ: 10 000 слов
Embedding: один вектор на 768 чисел

Проблема: один вектор не может представить 10 000 слов.
Embedding "размазывает" смысл, теряя детали.

Решение: разбить на chunks по 200-500 слов.
Каждый chunk -- про одну тему -> точный embedding.
```

Без chunking:
- Запрос "настройка CI" не найдет документ, где CI упоминается в середине
- Весь документ уходит в контекст, тратя токены на нерелевантное

С chunking:
- Chunk "Настройка CI/CD..." найден по запросу
- В контекст попадает только релевантный фрагмент


## Стратегии

```
Стратегия       | Сложность | Качество | Когда использовать
----------------|-----------|----------|---------------------------
Fixed-size      | Низкая    | Среднее  | Быстрый прототип
Recursive       | Средняя   | Хорошее  | Большинство задач (по умолчанию)
Semantic        | Высокая   | Отличное | Гетерогенные документы
Markdown-aware  | Средняя   | Отличное | .md документация
Code-aware      | Средняя   | Отличное | Код (.py, .js, .go)
```


## Fixed-size

Простейший подход: нарезать текст на куски фиксированной длины.

```
Текст: "AAAAAA BBBBBB CCCCCC DDDDDD EEEEEE FFFFFF"
Chunk size: 10 символов
Overlap: 3 символа

Chunk 1: "AAAAAA BBB"
Chunk 2: "BBB CCCCCC"  (overlap: "BBB")
Chunk 3: "CCC DDDDDD"
Chunk 4: "DDD EEEEEE"
Chunk 5: "EEE FFFFFF"
```

Плюсы: простота, предсказуемый размер.
Минусы: может разрезать предложение или абзац.

```python
def fixed_size_chunk(
    text: str,
    chunk_size: int = 500,
    overlap: int = 50
) -> list[str]:
    """Разбиение на chunks фиксированного размера."""
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunks.append(text[start:end])
        start = end - overlap
    return chunks
```


## Recursive text splitting

Разбиение по иерархии разделителей: абзацы -> строки -> предложения -> слова.
Стремится сохранить логические блоки. **Рекомендуемый подход по умолчанию.**

```
Разделители (по приоритету):
  1. "\n\n"  (абзац)
  2. "\n"    (строка)
  3. ". "    (предложение)
  4. " "     (слово)

Если chunk <= max_size после разбиения по "\n\n" -> готово.
Иначе -> разбиваем по "\n", и т.д.
```

```python
def recursive_chunk(
    text: str,
    max_size: int = 500,
    overlap: int = 50,
    separators: list[str] | None = None
) -> list[str]:
    """
    Рекурсивное разбиение текста на фрагменты.

    max_size -- максимальная длина chunk-а в символах.
    overlap -- перекрытие между соседними chunk-ами.
    separators -- список разделителей по убыванию приоритета.
    """
    if separators is None:
        separators = ["\n\n", "\n", ". ", " "]

    if len(text) <= max_size:
        return [text]

    # Ищем подходящий разделитель
    for sep in separators:
        parts = text.split(sep)
        if len(parts) > 1:
            break
    else:
        # Ни один разделитель не сработал -- режем по max_size
        chunks = []
        for i in range(0, len(text), max_size - overlap):
            chunks.append(text[i:i + max_size])
        return chunks

    # Собираем chunk-и из частей
    chunks = []
    current = ""
    for part in parts:
        candidate = current + sep + part if current else part
        if len(candidate) <= max_size:
            current = candidate
        else:
            if current:
                chunks.append(current)
            # Если часть сама больше max_size -- рекурсия
            if len(part) > max_size:
                sub_chunks = recursive_chunk(
                    part, max_size, overlap, separators[1:]
                )
                chunks.extend(sub_chunks)
                current = ""
            else:
                current = part
    if current:
        chunks.append(current)

    # Добавление overlap
    if overlap > 0 and len(chunks) > 1:
        overlapped = [chunks[0]]
        for i in range(1, len(chunks)):
            prev_tail = chunks[i - 1][-overlap:]
            overlapped.append(prev_tail + chunks[i])
        return overlapped

    return chunks
```


## Semantic chunking

Разбиение по смыслу: embedding каждого предложения, группировка близких.
Граница chunk-а -- где смысл резко меняется.

```
Предложения:
  1. "Python -- интерпретируемый язык"    -> vec_1
  2. "Поддерживает ООП и ФП"              -> vec_2  (близко к vec_1)
  3. "PostgreSQL -- реляционная СУБД"     -> vec_3  (далеко от vec_2) <-- граница
  4. "Поддерживает JSONB"                 -> vec_4  (близко к vec_3)

Chunks:
  Chunk 1: предложения 1-2 (про Python)
  Chunk 2: предложения 3-4 (про PostgreSQL)
```

```python
import re
import numpy as np


def semantic_chunk(
    text: str,
    embed_fn,
    similarity_threshold: float = 0.5,
    max_chunk_size: int = 1000
) -> list[str]:
    """
    Разбиение по семантической близости предложений.

    embed_fn -- функция text -> embedding (из embeddings.md).
    similarity_threshold -- порог: если близость < threshold, граница chunk-а.
    """
    # Разбиение на предложения
    sentences = re.split(r'(?<=[.!?])\s+', text)
    if len(sentences) <= 1:
        return [text]

    # Embedding каждого предложения
    embeddings = [np.array(embed_fn(s)) for s in sentences]

    # Вычисление близости соседних предложений
    similarities = []
    for i in range(len(embeddings) - 1):
        sim = np.dot(embeddings[i], embeddings[i + 1]) / (
            np.linalg.norm(embeddings[i]) * np.linalg.norm(embeddings[i + 1])
        )
        similarities.append(sim)

    # Группировка: граница где similarity < threshold
    chunks = []
    current_sentences = [sentences[0]]

    for i, sim in enumerate(similarities):
        current_text = " ".join(current_sentences + [sentences[i + 1]])

        if sim < similarity_threshold or len(current_text) > max_chunk_size:
            # Граница: сохранить текущий chunk, начать новый
            chunks.append(" ".join(current_sentences))
            current_sentences = [sentences[i + 1]]
        else:
            current_sentences.append(sentences[i + 1])

    if current_sentences:
        chunks.append(" ".join(current_sentences))

    return chunks
```

Плюс: chunk-и семантически целостные.
Минус: нужен embedding-вызов для каждого предложения (медленнее).


## Markdown-aware chunking

Для .md документации: разбиение по заголовкам с сохранением иерархии.
Каждый chunk знает свой контекст (путь заголовков).

```
# Настройка сервера          <- H1: контекст для всех chunks
## Установка                  <- H2: chunk 1 начинается
Установите зависимости...
apt install ...
## Конфигурация               <- H2: chunk 2 начинается
### SSL                       <- H3: chunk 3 начинается
Генерация сертификатов...
```

```python
import re


def markdown_chunk(
    text: str,
    max_size: int = 500,
    source: str = ""
) -> list[dict]:
    """
    Разбиение Markdown по заголовкам.

    Возвращает chunks с метаданными: heading_path, level.
    """
    lines = text.split("\n")
    chunks = []
    current_text = []
    heading_stack = []  # Стек заголовков [(level, text), ...]

    for line in lines:
        heading_match = re.match(r'^(#{1,6})\s+(.+)', line)

        if heading_match:
            # Сохранить предыдущий chunk
            if current_text:
                content = "\n".join(current_text).strip()
                if content:
                    heading_path = " > ".join(h[1] for h in heading_stack)
                    chunks.append({
                        "text": f"{heading_path}\n\n{content}" if heading_path else content,
                        "heading": heading_stack[-1][1] if heading_stack else "",
                        "heading_path": heading_path,
                        "level": heading_stack[-1][0] if heading_stack else 0,
                        "source": source
                    })
                current_text = []

            # Обновить стек заголовков
            level = len(heading_match.group(1))
            title = heading_match.group(2)

            # Убрать заголовки того же или более низкого уровня
            while heading_stack and heading_stack[-1][0] >= level:
                heading_stack.pop()
            heading_stack.append((level, title))
        else:
            current_text.append(line)

    # Последний chunk
    if current_text:
        content = "\n".join(current_text).strip()
        if content:
            heading_path = " > ".join(h[1] for h in heading_stack)
            chunks.append({
                "text": f"{heading_path}\n\n{content}" if heading_path else content,
                "heading": heading_stack[-1][1] if heading_stack else "",
                "heading_path": heading_path,
                "level": heading_stack[-1][0] if heading_stack else 0,
                "source": source
            })

    # Дополнительно: разбить слишком большие chunks
    result = []
    for chunk in chunks:
        if len(chunk["text"]) > max_size:
            sub_chunks = recursive_chunk(chunk["text"], max_size)
            for i, sub in enumerate(sub_chunks):
                result.append({**chunk, "text": sub, "sub_index": i})
        else:
            result.append(chunk)

    return result
```

Плюс: heading_path добавляет контекст ("Настройка сервера > SSL").
Embedding точнее, retrieval находит нужную секцию.


## Code-aware chunking

Для кода: разбиение по функциям и классам. AST-parsing обеспечивает
целостность: chunk не разрежет функцию пополам.

```python
import ast


def python_chunk(
    code: str,
    source: str = ""
) -> list[dict]:
    """Разбиение Python-кода по функциям и классам."""
    try:
        tree = ast.parse(code)
    except SyntaxError:
        # Если не парсится -- fallback на recursive
        return [{"text": code, "source": source, "type": "raw"}]

    chunks = []
    lines = code.split("\n")

    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            start = node.lineno - 1
            end = node.end_lineno
            func_code = "\n".join(lines[start:end])
            # Добавить docstring как отдельное поле
            docstring = ast.get_docstring(node) or ""
            chunks.append({
                "text": func_code,
                "source": source,
                "type": "function",
                "name": node.name,
                "docstring": docstring
            })
        elif isinstance(node, ast.ClassDef):
            start = node.lineno - 1
            end = node.end_lineno
            class_code = "\n".join(lines[start:end])
            chunks.append({
                "text": class_code,
                "source": source,
                "type": "class",
                "name": node.name,
                "docstring": ast.get_docstring(node) or ""
            })

    # Если ничего не нашли -- весь файл как один chunk
    if not chunks:
        chunks.append({"text": code, "source": source, "type": "module"})

    return chunks
```

Для JavaScript/TypeScript: аналогичный подход через tree-sitter.


## Overlap

Overlap -- перекрытие между соседними chunks. Нужно, чтобы информация
на границе не терялась.

```
Без overlap:
  Chunk 1: "...для настройки нужно создать"
  Chunk 2: "файл .gitlab-ci.yml с описанием stages"
  -> Запрос "настройка CI" может не найти chunk 2

С overlap (50 символов):
  Chunk 1: "...для настройки нужно создать"
  Chunk 2: "нужно создать файл .gitlab-ci.yml с описанием stages"
  -> Запрос "настройка CI" найдет chunk 2
```

Рекомендация: overlap = 10-20% от chunk_size.

```
chunk_size | overlap | overlap %
-----------|---------|----------
256        | 30-50   | ~15%
512        | 50-100  | ~15%
1024       | 100-150 | ~12%
```


## Параметры: chunk_size vs качество

```
Маленькие chunks (100-256 токенов):
  + Точный поиск: chunk про конкретную тему
  + Меньше шума в контексте
  - Может потерять контекст (chunk без начала абзаца)
  - Нужно больше chunks в Top-K

Большие chunks (512-1024 токенов):
  + Больше контекста в каждом chunk
  + Меньше chunks для покрытия темы
  - Менее точный поиск: embedding "размазан"
  - Больше нерелевантного текста в контексте
```

### Рекомендации

```
Задача                | chunk_size   | Top-K | Почему
----------------------|-------------|-------|----------------------------
FAQ (короткие ответы) | 128-256     | 3-5   | Один chunk = один ответ
Документация          | 256-512     | 5-10  | Баланс точности и контекста
Код                   | По функциям | 5-10  | AST-based, без фиксации размера
Длинные статьи        | 512-1024    | 3-5   | Больше контекста на chunk
Юридические документы | 256-512     | 10-20 | Точность критична
```

### Эксперимент

Лучший способ выбрать chunk_size -- измерить Recall@K (evaluation.md):

```python
# Тестовый набор: 20 вопросов + известные ответы
# Для каждого chunk_size: индексация -> retrieval -> метрики

for chunk_size in [128, 256, 512, 1024]:
    collection = index_with_chunk_size(docs, chunk_size)
    recall = evaluate_recall(collection, test_questions, golden_chunks)
    print(f"chunk_size={chunk_size}: Recall@5 = {recall:.3f}")
```


## Метаданные chunk-а

Каждый chunk хранится с метаданными для фильтрации и отладки:

```python
chunk = {
    "text": "содержимое фрагмента",
    "source": "docs/inference/setup.md",   # Файл-источник
    "heading": "Настройка сервера",         # Заголовок секции
    "heading_path": "Inference > Настройка сервера",  # Полный путь
    "chunk_index": 3,                       # Порядковый номер в документе
    "total_chunks": 12,                     # Всего chunks в документе
    "hash": "a1b2c3d4",                    # Хэш содержимого (для обновления)
    "timestamp": "2026-03-29"              # Дата индексации
}
```

Метаданные позволяют:
- Фильтровать поиск по source, category, date
- Показывать источник в ответе: "[1] docs/inference/setup.md"
- Обновлять только изменённые документы (по hash)
- Восстанавливать контекст: перейти к соседним chunks по chunk_index


## Связанные статьи

- <-- [Vector Databases](vector-databases.md)
- --> [Retrieval](retrieval.md)
- [Pipeline](pipeline.md) -- chunking в рабочем примере
