# RAG (Retrieval-Augmented Generation)

## Содержание

- [Проблема: LLM не знает ваших данных](#проблема-llm-не-знает-ваших-данных)
- [Решение: RAG](#решение-rag)
- [Архитектура RAG](#архитектура-rag)
- [Embeddings: преобразование текста в вектор](#embeddings-преобразование-текста-в-вектор)
- [Vector Database](#vector-database)
- [Chunking: разбиение документов](#chunking-разбиение-документов)
- [Retrieval: поиск релевантных фрагментов](#retrieval-поиск-релевантных-фрагментов)
- [Prompt template для RAG](#prompt-template-для-rag)
- [Модели для embeddings](#модели-для-embeddings)
- [Реализация с llama-server](#реализация-с-llama-server)
- [Пример: простой RAG pipeline](#пример-простой-rag-pipeline)
- [Когда RAG нужен и когда нет](#когда-rag-нужен-и-когда-нет)
- [Продвинутые техники](#продвинутые-техники)
- [Ограничения](#ограничения)
- [Отладка и оценка качества](#отладка-и-оценка-качества)

---

## Проблема: LLM не знает ваших данных

Языковая модель обучена на открытых данных из интернета. Она не знает:
- Внутреннюю документацию проекта
- Код вашего репозитория
- Корпоративную базу знаний
- FAQ вашего продукта
- Данные, появившиеся после даты обучения

```
Пользователь: Как настроить CI/CD в нашем проекте?
LLM без RAG: Вот общая инструкция для GitHub Actions...
LLM с RAG:   Согласно docs/ci.md, в проекте используется GitLab CI.
              Конфигурация в .gitlab-ci.yml, деплой через Ansible...
```

Можно вставить документы прямо в промпт, но:
- Context window ограничен (8K-128K токенов)
- Длинный контекст замедляет обработку
- Нерелевантная информация снижает качество ответов

RAG решает эту проблему: из всех документов выбираются только релевантные
фрагменты и вставляются в контекст.


## Решение: RAG

RAG (Retrieval-Augmented Generation) -- архитектурный паттерн:

1. **Retrieval**: найти документы, релевантные вопросу
2. **Augmented**: вставить их в контекст LLM
3. **Generation**: сгенерировать ответ на основе контекста

```
Вопрос пользователя
       |
       v
+-- Retrieval ---+     +-- Generation --+
|                |     |                |
| База знаний   |     | LLM            |
| -> Поиск      | --> | Контекст +     |
| -> Top-K      |     | Вопрос ->      |
| фрагментов    |     | Ответ          |
+----------------+     +----------------+
```


## Архитектура RAG

### Полная схема

```
ИНДЕКСАЦИЯ (один раз или периодически):

  Документы (.md, .py, .txt, .pdf)
       |
       v
  Chunking (разбиение на фрагменты)
       |
       v
  [chunk_1] [chunk_2] [chunk_3] ... [chunk_N]
       |         |         |              |
       v         v         v              v
  Embedding model (текст -> вектор)
       |         |         |              |
       v         v         v              v
  [vec_1]   [vec_2]   [vec_3]   ...  [vec_N]
       |         |         |              |
       +----+----+----+----+----+---------+
            |
            v
      Vector Database
      (хранение и индексация)


ЗАПРОС (при каждом вопросе):

  Вопрос пользователя
       |
       v
  Embedding model (вопрос -> вектор)
       |
       v
  [query_vec]
       |
       v
  Vector Database
  -> cosine similarity
  -> Top-K ближайших
       |
       v
  [chunk_3, chunk_7, chunk_12]  (релевантные фрагменты)
       |
       v
  Prompt template:
    "Контекст: {chunks}
     Вопрос: {question}
     Ответ:"
       |
       v
  LLM -> Ответ
```

### Компоненты

```
Компонент        | Задача                      | Варианты
-----------------|-----------------------------|---------------------------
Chunking         | Разбиение документов        | Fixed-size, semantic, recursive
Embedding model  | Текст -> вектор             | nomic-embed, bge, e5
Vector DB        | Хранение и поиск векторов   | ChromaDB, Qdrant, FAISS
Retrieval        | Поиск Top-K фрагментов      | Cosine similarity, MMR
LLM              | Генерация ответа            | Qwen, Llama (локально)
Prompt template  | Форматирование контекста    | Текстовый шаблон
```


## Embeddings: преобразование текста в вектор

### Что такое embedding

Embedding -- числовой вектор фиксированной длины, представляющий смысл текста.
Тексты с похожим смыслом имеют близкие вектора.

```
"кот сидит на коврике"  -> [0.12, -0.34, 0.56, ..., 0.78]  (768 чисел)
"кошка лежит на ковре"  -> [0.11, -0.33, 0.55, ..., 0.77]  (похожий вектор)
"акции Tesla растут"    -> [0.89, 0.12, -0.45, ..., -0.23]  (далекий вектор)
```

### Близость векторов

Cosine similarity -- мера близости двух векторов:

```
cos(A, B) = (A * B) / (|A| * |B|)

Значения:
  1.0  = идентичные тексты
  0.7+ = высокая релевантность
  0.5  = средняя релевантность
  0.0  = нет связи
  -1.0 = противоположные смыслы (редко на практике)
```

### Пример вычисления

```python
import numpy as np


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    """Вычисление косинусной близости двух векторов."""
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))


# Пример с реальными embedding-ами (упрощенно, 4 измерения)
vec_cat = np.array([0.8, 0.1, 0.6, 0.3])     # "кот на коврике"
vec_kitten = np.array([0.7, 0.2, 0.5, 0.4])   # "котенок на полу"
vec_stock = np.array([-0.2, 0.9, -0.1, 0.8])   # "акции на бирже"

print(cosine_similarity(vec_cat, vec_kitten))  # ~0.97 (похожи)
print(cosine_similarity(vec_cat, vec_stock))   # ~0.32 (далеки)
```

### Размерность embedding-ов

```
Модель              | Размерность | Размер модели
--------------------|-------------|-------------
nomic-embed-text    | 768         | 274 MB
bge-large-en-v1.5   | 1024        | 1.3 GB
e5-large-v2         | 1024        | 1.3 GB
bge-m3              | 1024        | 2.2 GB (мультиязычная)
gte-Qwen2-1.5B      | 1536        | 3.0 GB
```

Больше измерений = больше нюансов, но и больше памяти для хранения.
Для большинства задач 768-1024 измерений достаточно.


## Vector Database

Vector Database -- хранилище embedding-ов с поддержкой быстрого поиска
ближайших соседей (approximate nearest neighbors, ANN).

### Варианты

```
База          | Тип          | Плюсы                    | Минусы
--------------|--------------|--------------------------|------------------
ChromaDB      | Встраиваемая | Простота, Python API     | Не для production
Qdrant        | Сервер       | Быстрый, фильтрация     | Требует запуска
FAISS         | Библиотека   | Максимальная скорость    | Низкоуровневый API
Milvus        | Сервер       | Масштабируемость         | Сложная настройка
pgvector      | PostgreSQL   | Знакомый SQL             | Медленнее спец. баз
```

### ChromaDB -- для начала

ChromaDB -- встраиваемая vector database на Python. Идеальна для
прототипирования и небольших проектов (до 1 млн документов).

```python
import chromadb

# Создание клиента и коллекции
client = chromadb.Client()  # В памяти
# Или: client = chromadb.PersistentClient(path="./chroma_db")  # На диске

collection = client.create_collection(
    name="project_docs",
    metadata={"hnsw:space": "cosine"}  # Метрика: косинусная близость
)

# Добавление документов
collection.add(
    documents=[
        "FastAPI -- веб-фреймворк для создания API на Python",
        "PostgreSQL -- реляционная СУБД с поддержкой JSONB",
        "Docker -- платформа контейнеризации приложений",
    ],
    ids=["doc_1", "doc_2", "doc_3"],
    metadatas=[
        {"source": "fastapi.md", "category": "framework"},
        {"source": "postgres.md", "category": "database"},
        {"source": "docker.md", "category": "devops"},
    ]
)

# Поиск
results = collection.query(
    query_texts=["как создать REST API"],
    n_results=2
)
print(results["documents"])
# [["FastAPI -- веб-фреймворк для создания API на Python",
#   "Docker -- платформа контейнеризации приложений"]]
```

### Qdrant -- для production

```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

client = QdrantClient(host="localhost", port=6333)

# Создание коллекции
client.create_collection(
    collection_name="project_docs",
    vectors_config=VectorParams(
        size=768,           # Размерность embedding-а
        distance=Distance.COSINE
    )
)

# Добавление документов (нужны предвычисленные embedding-ы)
client.upsert(
    collection_name="project_docs",
    points=[
        PointStruct(
            id=1,
            vector=[0.12, -0.34, ...],  # Embedding из модели
            payload={
                "text": "FastAPI -- веб-фреймворк",
                "source": "fastapi.md"
            }
        ),
        # ...
    ]
)

# Поиск
results = client.search(
    collection_name="project_docs",
    query_vector=[0.11, -0.32, ...],  # Embedding запроса
    limit=5
)
```


## Chunking: разбиение документов

Документы разбиваются на фрагменты (chunks) перед индексацией. Размер
и стратегия chunking критически влияют на качество RAG.

### Почему нужен chunking

```
Документ: 10 000 слов
Embedding: один вектор на 768 чисел

Проблема: один вектор не может представить 10 000 слов.
Embedding "размазывает" смысл, теряя детали.

Решение: разбить на chunks по 200-500 слов.
Каждый chunk -- про одну тему -> точный embedding.
```

### Стратегии chunking

**1. Fixed-size (фиксированный размер)**

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

Плюсы: простота, предсказуемый размер
Минусы: может разрезать предложение или абзац

**2. Recursive text splitting (рекурсивное)**

Разбиение по иерархии разделителей: параграфы -> предложения -> слова.
Стремится сохранить логические блоки.

```
Разделители (по приоритету):
  1. "\n\n"  (параграф)
  2. "\n"    (строка)
  3. ". "    (предложение)
  4. " "     (слово)

Если chunk <= max_size после разбиения по "\n\n" -> готово.
Иначе -> разбиваем по "\n", и т.д.
```

**3. Semantic chunking**

Разбиение по смыслу: embedding каждого предложения, группировка близких.

```
Предложения:
  1. "Python -- интерпретируемый язык"    -> vec_1
  2. "Поддерживает ООП и ФП"              -> vec_2  (близко к vec_1)
  3. "PostgreSQL -- реляционная СУБД"     -> vec_3  (далеко от vec_2)
  4. "Поддерживает JSONB"                 -> vec_4  (близко к vec_3)

Chunks:
  Chunk 1: предложения 1-2 (про Python)
  Chunk 2: предложения 3-4 (про PostgreSQL)
```

### Реализация recursive chunking

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
        # Если ни один разделитель не сработал -- режем по max_size
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

    # Добавляем overlap
    if overlap > 0 and len(chunks) > 1:
        overlapped = [chunks[0]]
        for i in range(1, len(chunks)):
            prev_tail = chunks[i - 1][-overlap:]
            overlapped.append(prev_tail + chunks[i])
        return overlapped

    return chunks
```

### Параметры chunking

```
Параметр       | Диапазон       | Рекомендация
---------------|----------------|--------------------------
Размер chunk   | 100-2000 токенов| 256-512 для точного поиска
               |                | 512-1024 для длинных ответов
Overlap        | 0-200 токенов  | 50-100 (10-20% от размера)
Формат         | Символы/токены | Токены точнее, символы проще
```

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


## Retrieval: поиск релевантных фрагментов

### Базовый поиск: Top-K по cosine similarity

```
Запрос -> embedding -> cosine similarity со всеми chunks -> Top-K
```

```python
def retrieve(
    query: str,
    collection,
    n_results: int = 5
) -> list[dict]:
    """Поиск релевантных chunks по запросу."""
    results = collection.query(
        query_texts=[query],
        n_results=n_results,
        include=["documents", "metadatas", "distances"]
    )
    return [
        {
            "text": doc,
            "metadata": meta,
            "distance": dist
        }
        for doc, meta, dist in zip(
            results["documents"][0],
            results["metadatas"][0],
            results["distances"][0]
        )
    ]
```

### MMR (Maximal Marginal Relevance)

Проблема Top-K: все K фрагментов могут быть про одно и то же (дубликаты).
MMR балансирует релевантность и разнообразие.

```
MMR(d) = lambda * sim(d, query) - (1 - lambda) * max(sim(d, d_selected))

lambda = 1.0  -> только релевантность (как Top-K)
lambda = 0.5  -> баланс релевантности и разнообразия
lambda = 0.0  -> только разнообразие
```

```python
def mmr_retrieve(
    query_embedding: list[float],
    candidate_embeddings: list[list[float]],
    candidate_texts: list[str],
    k: int = 5,
    lambda_param: float = 0.7
) -> list[str]:
    """
    Поиск с MMR для разнообразия результатов.

    lambda_param -- баланс релевантности (1.0) и разнообразия (0.0).
    """
    import numpy as np

    query = np.array(query_embedding)
    candidates = np.array(candidate_embeddings)

    # Релевантность каждого кандидата к запросу
    relevance = np.array([
        np.dot(query, c) / (np.linalg.norm(query) * np.linalg.norm(c))
        for c in candidates
    ])

    selected_indices = []
    remaining = list(range(len(candidates)))

    for _ in range(k):
        if not remaining:
            break

        mmr_scores = []
        for idx in remaining:
            rel = relevance[idx]

            # Максимальная похожесть на уже выбранные
            if selected_indices:
                max_sim = max(
                    np.dot(candidates[idx], candidates[sel]) /
                    (np.linalg.norm(candidates[idx]) * np.linalg.norm(candidates[sel]))
                    for sel in selected_indices
                )
            else:
                max_sim = 0

            score = lambda_param * rel - (1 - lambda_param) * max_sim
            mmr_scores.append((idx, score))

        # Выбираем лучший по MMR
        best_idx = max(mmr_scores, key=lambda x: x[1])[0]
        selected_indices.append(best_idx)
        remaining.remove(best_idx)

    return [candidate_texts[i] for i in selected_indices]
```

### Гибридный поиск

Комбинация semantic search (embedding-ы) и keyword search (BM25):

```
Semantic: "как настроить деплой" -> ищет по смыслу
BM25:     "как настроить деплой" -> ищет по словам "настроить", "деплой"

Гибрид: (alpha * semantic_score) + ((1 - alpha) * bm25_score)
```

Гибридный поиск лучше для технической документации, где точные термины важны.


## Prompt template для RAG

### Базовый шаблон

```
Ты -- ассистент, отвечающий на вопросы на основе предоставленного контекста.
Используй ТОЛЬКО информацию из контекста ниже. Если ответа в контексте нет --
скажи "В предоставленных документах ответ не найден."

Контекст:
---
{context}
---

Вопрос: {question}

Ответ:
```

### Шаблон с источниками

```
Ты -- ассистент по документации проекта.
Отвечай на основе предоставленного контекста.
После ответа укажи источники в формате [1], [2], ...

Контекст:
[1] {source_1}: {chunk_1}
[2] {source_2}: {chunk_2}
[3] {source_3}: {chunk_3}

Вопрос: {question}

Ответ (с указанием источников):
```

### Шаблон для кода

```
Ты -- ассистент-разработчик. Отвечай на вопросы о коде проекта.

Релевантные фрагменты кода:
---
Файл: {file_1}
```python
{code_chunk_1}
```
---
Файл: {file_2}
```python
{code_chunk_2}
```
---

Вопрос: {question}

Формат ответа:
1. Объяснение (2-3 предложения)
2. Пример кода (если нужен)
3. Ссылка на файл
```

### Формирование контекста

```python
def format_rag_context(
    chunks: list[dict],
    max_context_tokens: int = 2000
) -> str:
    """
    Форматирование chunks для вставки в промпт.

    Ограничивает общий размер контекста.
    """
    context_parts = []
    total_chars = 0
    # Грубая оценка: 1 токен ~ 3 символа для русского
    max_chars = max_context_tokens * 3

    for i, chunk in enumerate(chunks):
        text = chunk["text"]
        source = chunk.get("metadata", {}).get("source", "unknown")

        part = f"[{i + 1}] Источник: {source}\n{text}"

        if total_chars + len(part) > max_chars:
            break

        context_parts.append(part)
        total_chars += len(part)

    return "\n---\n".join(context_parts)
```


## Модели для embeddings

### Локальные модели

Все embedding-модели можно запустить локально. Они небольшие (200 MB - 3 GB)
и быстрые.

```
Модель               | Размерность | Язык    | Размер  | Качество
---------------------|-------------|---------|---------|----------
nomic-embed-text     | 768         | EN (OK) | 274 MB  | Хорошее
bge-large-en-v1.5    | 1024        | EN      | 1.3 GB  | Отличное
bge-m3               | 1024        | Multi   | 2.2 GB  | Отличное (RU)
e5-large-v2          | 1024        | EN (OK) | 1.3 GB  | Отличное
gte-Qwen2-1.5B       | 1536        | Multi   | 3.0 GB  | Отличное (RU)
multilingual-e5-large | 1024       | Multi   | 1.1 GB  | Хорошее (RU)
```

Для русскоязычных документов рекомендуется bge-m3 или gte-Qwen2-1.5B --
обе модели имеют хорошую поддержку русского языка.

### Запуск через llama-server

llama-server может обслуживать embedding-модели:

```bash
# Скачать модель в GGUF-формате
# (embedding-модели обычно не квантуют -- они и так маленькие)
llama-server \
    --model ./models/nomic-embed-text-v1.5.Q8_0.gguf \
    --host 0.0.0.0 \
    --port 8081 \
    --embedding \
    --ctx-size 2048 \
    --n-gpu-layers 999
```

### Получение embedding-ов через API

```python
import requests
import numpy as np


def get_embedding(
    text: str,
    base_url: str = "http://localhost:8081"
) -> list[float]:
    """Получение embedding-а текста через llama-server."""
    response = requests.post(
        f"{base_url}/v1/embeddings",
        json={
            "input": text,
            "model": "nomic-embed-text"  # Имя не важно для llama-server
        }
    )
    return response.json()["data"][0]["embedding"]


def get_embeddings_batch(
    texts: list[str],
    base_url: str = "http://localhost:8081"
) -> list[list[float]]:
    """Пакетное получение embedding-ов."""
    response = requests.post(
        f"{base_url}/v1/embeddings",
        json={
            "input": texts,
            "model": "nomic-embed-text"
        }
    )
    data = response.json()["data"]
    # Сортируем по индексу (API может вернуть в другом порядке)
    data.sort(key=lambda x: x["index"])
    return [d["embedding"] for d in data]


# Пример
embedding = get_embedding("Квантизация снижает размер модели")
print(f"Размерность: {len(embedding)}")  # 768
```


## Реализация с llama-server

### Архитектура: два сервера

```
+-------------------+     +-------------------+
| llama-server      |     | llama-server      |
| Embedding model   |     | LLM (генерация)   |
| Порт: 8081        |     | Порт: 8080        |
| nomic-embed-text  |     | Qwen 2.5 32B Q4   |
| ~300 MB VRAM      |     | ~19 GB VRAM       |
+-------------------+     +-------------------+
        |                          |
        v                          v
+-------------------------------------------+
| Python RAG pipeline                       |
| ChromaDB + retrieval + prompt formatting  |
+-------------------------------------------+
```

На Radeon 8060S (96 GiB) оба сервера работают одновременно без проблем.

### Запуск

```bash
# Терминал 1: Embedding-сервер
llama-server \
    --model ./models/nomic-embed-text-v1.5.Q8_0.gguf \
    --host 0.0.0.0 \
    --port 8081 \
    --embedding \
    --ctx-size 2048 \
    --n-gpu-layers 999

# Терминал 2: LLM-сервер
llama-server \
    --model ./models/qwen2.5-32b-q4_k_m.gguf \
    --host 0.0.0.0 \
    --port 8080 \
    --ctx-size 8192 \
    --n-gpu-layers 999
```


## Пример: простой RAG pipeline

Полный рабочий пример RAG на Python с ChromaDB и llama-server.

```python
"""
Простой RAG pipeline: индексация документов и ответы на вопросы.

Зависимости:
  pip install chromadb requests

Требует:
  - llama-server с embedding-моделью на порту 8081
  - llama-server с LLM на порту 8080
"""
import os
import requests
import chromadb
from pathlib import Path


# --- Конфигурация ---

EMBEDDING_URL = "http://localhost:8081"
LLM_URL = "http://localhost:8080"
CHUNK_SIZE = 400       # Символов на chunk
CHUNK_OVERLAP = 50     # Перекрытие
TOP_K = 5              # Количество фрагментов для контекста


# --- Embedding ---

def embed_texts(texts: list[str]) -> list[list[float]]:
    """Получение embedding-ов для списка текстов."""
    response = requests.post(
        f"{EMBEDDING_URL}/v1/embeddings",
        json={"input": texts, "model": "embed"}
    )
    data = response.json()["data"]
    data.sort(key=lambda x: x["index"])
    return [d["embedding"] for d in data]


# --- Chunking ---

def chunk_text(text: str, source: str) -> list[dict]:
    """Разбиение текста на фрагменты с метаданными."""
    chunks = []
    # Разбиваем по параграфам
    paragraphs = text.split("\n\n")
    current = ""

    for para in paragraphs:
        if len(current) + len(para) <= CHUNK_SIZE:
            current = current + "\n\n" + para if current else para
        else:
            if current:
                chunks.append({
                    "text": current.strip(),
                    "source": source
                })
            current = para

    if current.strip():
        chunks.append({"text": current.strip(), "source": source})

    return chunks


# --- Индексация ---

def index_directory(
    docs_dir: str,
    collection_name: str = "docs"
) -> chromadb.Collection:
    """Индексация всех .md и .txt файлов в директории."""
    client = chromadb.Client()
    collection = client.get_or_create_collection(
        name=collection_name,
        metadata={"hnsw:space": "cosine"}
    )

    all_chunks = []
    for path in Path(docs_dir).rglob("*"):
        if path.suffix in (".md", ".txt", ".py"):
            text = path.read_text(encoding="utf-8")
            source = str(path.relative_to(docs_dir))
            chunks = chunk_text(text, source)
            all_chunks.extend(chunks)

    if not all_chunks:
        print("Нет документов для индексации")
        return collection

    # Пакетная обработка embedding-ов (по 32 за раз)
    batch_size = 32
    for i in range(0, len(all_chunks), batch_size):
        batch = all_chunks[i:i + batch_size]
        texts = [c["text"] for c in batch]
        embeddings = embed_texts(texts)

        collection.add(
            documents=texts,
            embeddings=embeddings,
            ids=[f"chunk_{i + j}" for j in range(len(batch))],
            metadatas=[{"source": c["source"]} for c in batch]
        )

    print(f"Проиндексировано {len(all_chunks)} фрагментов")
    return collection


# --- Поиск и генерация ---

def ask(
    question: str,
    collection: chromadb.Collection
) -> str:
    """Ответ на вопрос с использованием RAG."""
    # 1. Embedding запроса
    query_embedding = embed_texts([question])[0]

    # 2. Поиск релевантных фрагментов
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=TOP_K,
        include=["documents", "metadatas", "distances"]
    )

    # 3. Формирование контекста
    context_parts = []
    for doc, meta, dist in zip(
        results["documents"][0],
        results["metadatas"][0],
        results["distances"][0]
    ):
        context_parts.append(
            f"[Источник: {meta['source']}, релевантность: {1 - dist:.2f}]\n{doc}"
        )
    context = "\n---\n".join(context_parts)

    # 4. Генерация ответа
    prompt = f"""Ответь на вопрос, используя ТОЛЬКО предоставленный контекст.
Если ответа нет в контексте -- скажи об этом.
После ответа укажи источники.

Контекст:
{context}

Вопрос: {question}

Ответ:"""

    response = requests.post(
        f"{LLM_URL}/v1/chat/completions",
        json={
            "messages": [
                {"role": "system", "content": "Ты -- ассистент по документации. Отвечай по-русски."},
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.3,
            "max_tokens": 1024
        }
    )

    return response.json()["choices"][0]["message"]["content"]


# --- Использование ---

if __name__ == "__main__":
    # Индексация
    collection = index_directory("./docs/")

    # Вопросы
    questions = [
        "Как запустить llama-server?",
        "Какие модели помещаются в 96 GiB?",
        "Как настроить квантизацию KV-cache?",
    ]

    for q in questions:
        print(f"\nВопрос: {q}")
        print(f"Ответ: {ask(q, collection)}")
        print("-" * 60)
```


## Когда RAG нужен и когда нет

### RAG нужен

```
Сценарий                        | Почему RAG
--------------------------------|------------------------------------------
Документация проекта            | LLM не знает ваш проект
FAQ / база знаний               | Пользователи задают одни и те же вопросы
Code search                     | Поиск в кодовой базе по смыслу
Юридические документы           | Ответы должны основываться на конкретных документах
Медицинские справочники         | Точность критична, нельзя "галлюцинировать"
Техническая поддержка           | Ответы из базы тикетов и решений
Новостной агрегатор             | Данные обновляются постоянно
```

### RAG не нужен

```
Сценарий                        | Почему без RAG
--------------------------------|------------------------------------------
Генерация кода                  | LLM знает языки программирования
Перевод текста                  | Знания из обучения достаточно
Общие вопросы                   | "Что такое REST API?" -- LLM знает
Математика                      | Нет внешних данных для поиска
Суммаризация (данного текста)   | Текст уже в контексте
Брейнсторминг                   | Нужна генерация, не поиск
```

### Таблица решения

```
Вопрос                                        | Ответ   | Действие
-----------------------------------------------|---------|---------------
Данные меняются чаще, чем модель обновляется?  | Да      | Нужен RAG
Ответ должен основываться на конкретных документах? | Да | Нужен RAG
Данные приватные / корпоративные?              | Да      | Нужен RAG
Задача -- генерация (код, текст)?              | Да      | RAG не нужен
Задача -- общие знания?                        | Да      | RAG не нужен
```


## Продвинутые техники

### Re-ranking

После initial retrieval -- повторное ранжирование с помощью cross-encoder
(более точного, но медленного):

```
1. Top-20 по cosine similarity (быстро)
2. Cross-encoder переранжирует 20 -> Top-5 (точно)

Cross-encoder: берет пару (запрос, документ) и выдает score.
Точнее bi-encoder (embedding), но в 100x медленнее.
```

### Query expansion

Расширение запроса для улучшения retrieval:

```
Оригинальный запрос: "настройка CI"
Расширенный: "настройка CI continuous integration pipeline деплой"

Метод: попросить LLM сгенерировать 3-5 альтернативных формулировок запроса,
затем искать по всем.
```

### HyDE (Hypothetical Document Embeddings)

Вместо поиска по запросу -- генерация гипотетического ответа и поиск по нему:

```
Запрос: "Как настроить CI?"
  |
  v
LLM генерирует гипотетический ответ:
  "Для настройки CI создайте файл .gitlab-ci.yml с описанием stages..."
  |
  v
Embedding гипотетического ответа -> поиск в Vector DB
  -> Находит реальные документы про CI
```

```python
def hyde_retrieve(
    question: str,
    collection: chromadb.Collection,
    llm_url: str = "http://localhost:8080",
    embedding_url: str = "http://localhost:8081",
    n_results: int = 5
) -> list[dict]:
    """Поиск с HyDE: гипотетический ответ -> embedding -> retrieval."""
    # 1. Генерация гипотетического ответа
    response = requests.post(
        f"{llm_url}/v1/chat/completions",
        json={
            "messages": [
                {"role": "system", "content": "Ответь на вопрос кратко (3-5 предложений)."},
                {"role": "user", "content": question}
            ],
            "temperature": 0.3,
            "max_tokens": 256
        }
    )
    hypothetical = response.json()["choices"][0]["message"]["content"]

    # 2. Embedding гипотетического ответа
    emb_response = requests.post(
        f"{embedding_url}/v1/embeddings",
        json={"input": hypothetical, "model": "embed"}
    )
    query_embedding = emb_response.json()["data"][0]["embedding"]

    # 3. Поиск по embedding-у
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=n_results,
        include=["documents", "metadatas", "distances"]
    )

    return results
```

### Parent-child chunking

Индексируем маленькие chunks (для точного поиска), но возвращаем
родительские (большие) chunks (для полного контекста):

```
Документ (2000 слов)
  |
  +-- Parent chunk 1 (500 слов)
  |     +-- Child chunk 1a (100 слов)  <- индексируется
  |     +-- Child chunk 1b (100 слов)  <- индексируется
  |     +-- Child chunk 1c (100 слов)  <- индексируется
  |
  +-- Parent chunk 2 (500 слов)
        +-- Child chunk 2a (100 слов)  <- индексируется
        +-- Child chunk 2b (100 слов)  <- индексируется

Поиск находит child chunk 1b -> возвращаем parent chunk 1 (500 слов)
```


## Ограничения

### Качество зависит от chunking

```
Плохой chunking:
  Chunk: "...продолжение предыдущего абзаца. Для настройки CI нужно..."
  -> Embedding не понимает контекст ("настройка CI" потеряна в конце)
  -> Запрос "настройка CI" может не найти этот chunk

Хороший chunking:
  Chunk: "Настройка CI/CD. Для настройки CI создайте файл .gitlab-ci.yml..."
  -> Embedding четко: "настройка CI"
  -> Запрос "настройка CI" находит chunk
```

### Качество зависит от retrieval

```
Проблема: модель "галлюцинирует" несмотря на RAG
Причина: retrieval вернул нерелевантные chunks
Решение: улучшить embedding-модель, chunking, добавить re-ranking
```

### RAG -- не панацея

```
Ситуация                           | Проблема
-----------------------------------|----------------------------------
Вопрос требует рассуждения         | RAG дает факты, не рассуждения
Ответ в нескольких документах      | Нужен multi-hop reasoning
Данные в таблицах/графиках         | Embedding плохо работает с табличными данными
Вопрос о взаимосвязях              | Graph RAG лучше vector RAG
```


## Отладка и оценка качества

### Метрики

```
Retrieval:
  - Recall@K: доля релевантных документов в Top-K
  - Precision@K: доля релевантных среди возвращенных
  - MRR (Mean Reciprocal Rank): позиция первого релевантного документа

Generation:
  - Faithfulness: ответ соответствует контексту (нет галлюцинаций)
  - Relevance: ответ отвечает на вопрос
  - Completeness: ответ полный
```

### Отладка retrieval

```python
def debug_retrieval(
    question: str,
    collection: chromadb.Collection,
    n_results: int = 10
):
    """Отладка: показать, что находит retrieval."""
    query_embedding = embed_texts([question])[0]

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=n_results,
        include=["documents", "metadatas", "distances"]
    )

    print(f"Запрос: {question}\n")
    for i, (doc, meta, dist) in enumerate(zip(
        results["documents"][0],
        results["metadatas"][0],
        results["distances"][0]
    )):
        relevance = 1 - dist
        print(f"#{i + 1} [{relevance:.3f}] {meta.get('source', '?')}")
        # Показываем первые 100 символов
        print(f"    {doc[:100]}...")
        print()
```


## Дополнительные ресурсы

- [Квантизация](./quantization.md) -- размеры embedding-моделей и LLM
- [Function calling](./function-calling.md) -- RAG как инструмент для агентов
- [Prompt engineering](./prompt-engineering.md) -- техники составления промптов для RAG
- [Настройка llama-server](../inference/) -- запуск embedding-сервера
- [Выбор модели](../inference/model-selection.md)

## Связанные статьи

- [Prompt engineering](prompt-engineering.md)
- [Контекстное окно](context-window.md)
- [Function calling](function-calling.md)
- [Справочник LLM](../models/llm.md)
