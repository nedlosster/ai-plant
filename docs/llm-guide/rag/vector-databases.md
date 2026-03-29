# Vector Databases

Vector database -- хранилище embedding-ов с поддержкой быстрого поиска
ближайших соседей (Approximate Nearest Neighbors, ANN). В RAG pipeline
vector DB хранит вектора документов и находит релевантные по запросу.


## Содержание

- [Зачем нужна vector DB](#зачем-нужна-vector-db)
- [Алгоритмы поиска: ANN](#алгоритмы-поиска-ann)
- [Сравнение баз](#сравнение-баз)
- [ChromaDB](#chromadb)
- [Qdrant](#qdrant)
- [FAISS](#faiss)
- [pgvector](#pgvector)
- [Инкрементальная индексация](#инкрементальная-индексация)
- [Выбор для проекта](#выбор-для-проекта)


## Зачем нужна vector DB

Наивный подход: хранить все вектора в массиве, при поиске вычислить
cosine similarity со всеми. Работает для 1K документов, но не масштабируется:

```
Документов | Время поиска (brute force) | Время (HNSW)
-----------|---------------------------|-------------
1 000      | 1 мс                      | 0.1 мс
100 000    | 100 мс                    | 0.5 мс
1 000 000  | 1 сек                     | 1 мс
10 000 000 | 10 сек                    | 2 мс
```

Vector DB использует специальные индексы для поиска за O(log N) вместо O(N).


## Алгоритмы поиска: ANN

### HNSW (Hierarchical Navigable Small World)

Основной алгоритм в современных vector DB. Строит многоуровневый граф
ближайших соседей.

```
Уровень 2:  [A] ---- [B]                    (крупные "шаги")
             |         |
Уровень 1:  [A] - [C] [B] - [D]             (средние "шаги")
             |    |    |    |
Уровень 0:  [A] [E] [C] [F] [B] [G] [D] [H] (все точки)
```

Поиск начинается с верхнего уровня (быстрые крупные шаги),
спускается на нижний (точные мелкие шаги).

```
Параметры HNSW:
  M = 16           -- количество связей на узел (больше = точнее, больше памяти)
  ef_construction = 200  -- точность при построении индекса
  ef_search = 50   -- точность при поиске (можно менять на лету)
```

### IVF (Inverted File Index)

Разбивает пространство на кластеры (Voronoi cells). При поиске проверяет
только ближайшие кластеры.

```
Пространство разбито на 100 кластеров:
  Запрос попадает в кластер #42
  Проверяем кластер #42 + 5 соседних = 6 кластеров вместо 100
  Скорость: ~17x быстрее brute force
```

```
Параметр  | HNSW           | IVF
----------|----------------|------------------
Скорость  | Высокая        | Средняя
Точность  | 95-99%         | 90-95%
Память    | Больше (+граф)  | Меньше
Обновление| Быстрое (online)| Медленное (ребилд)
```

### Flat (Brute Force)

Точный поиск без индекса. Используется для маленьких коллекций (<50K)
или как baseline для сравнения.


## Сравнение баз

```
База          | Тип          | Плюсы                    | Минусы
--------------|--------------|--------------------------|------------------
ChromaDB      | Встраиваемая | Простота, Python API     | Не для production
Qdrant        | Сервер       | Быстрый, фильтрация     | Требует запуска
FAISS         | Библиотека   | Максимальная скорость    | Низкоуровневый API
Milvus        | Сервер       | Масштабируемость         | Сложная настройка
pgvector      | PostgreSQL   | Знакомый SQL             | Медленнее спец. баз
```


## ChromaDB

Встраиваемая vector database на Python. Лучший выбор для прототипов
и проектов до 1M документов.

### Установка

```bash
pip install chromadb
```

### In-memory (для тестов)

```python
import chromadb

client = chromadb.Client()

collection = client.create_collection(
    name="project_docs",
    metadata={"hnsw:space": "cosine"}
)

# Добавление документов (ChromaDB генерирует embedding-ы сам,
# но мы передадим свои из llama-server)
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
# [["FastAPI -- веб-фреймворк...", "Docker -- платформа..."]]
```

### Persistent (на диск)

```python
client = chromadb.PersistentClient(path="./chroma_db")

# Получить или создать коллекцию
collection = client.get_or_create_collection(
    name="project_docs",
    metadata={"hnsw:space": "cosine"}
)
# Данные сохраняются на диск автоматически
```

### С предвычисленными embedding-ами

```python
# Используем embedding-ы из llama-server (embeddings.md)
embeddings = get_embeddings_batch(["текст 1", "текст 2", "текст 3"])

collection.add(
    documents=["текст 1", "текст 2", "текст 3"],
    embeddings=embeddings,
    ids=["id_1", "id_2", "id_3"],
    metadatas=[{"source": "file1.md"}, {"source": "file2.md"}, {"source": "file3.md"}]
)
```

### Фильтрация по метаданным

```python
# Поиск только среди документов категории "framework"
results = collection.query(
    query_texts=["REST API"],
    n_results=5,
    where={"category": "framework"}
)

# Комбинированные фильтры
results = collection.query(
    query_texts=["деплой"],
    n_results=5,
    where={
        "$and": [
            {"category": {"$in": ["devops", "infra"]}},
            {"year": {"$gte": 2024}}
        ]
    }
)
```


## Qdrant

Production-ready vector database. Docker-контейнер, REST + gRPC API,
фильтрация по payload, шардирование.

### Установка

```bash
# Docker
docker run -p 6333:6333 -v ./qdrant_storage:/qdrant/storage qdrant/qdrant

# Python-клиент
pip install qdrant-client
```

### Создание коллекции

```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

client = QdrantClient(host="localhost", port=6333)

client.create_collection(
    collection_name="project_docs",
    vectors_config=VectorParams(
        size=768,              # Размерность embedding-модели
        distance=Distance.COSINE
    )
)
```

### Добавление документов

```python
# Предвычисленные embedding-ы
points = [
    PointStruct(
        id=i,
        vector=embedding,
        payload={
            "text": text,
            "source": source,
            "category": category
        }
    )
    for i, (embedding, text, source, category) in enumerate(zip(
        embeddings, texts, sources, categories
    ))
]

client.upsert(
    collection_name="project_docs",
    points=points
)
```

### Поиск

```python
results = client.search(
    collection_name="project_docs",
    query_vector=query_embedding,
    limit=5,
    query_filter={
        "must": [
            {"key": "category", "match": {"value": "framework"}}
        ]
    }
)

for result in results:
    print(f"Score: {result.score:.3f}")
    print(f"Text: {result.payload['text'][:100]}")
    print(f"Source: {result.payload['source']}")
```

### Гибридный поиск (sparse + dense)

Qdrant поддерживает одновременный поиск по плотным (semantic)
и разреженным (keyword) векторам:

```python
from qdrant_client.models import SparseVectorParams, SparseVector

# Коллекция с двумя типами векторов
client.create_collection(
    collection_name="hybrid_docs",
    vectors_config={
        "dense": VectorParams(size=768, distance=Distance.COSINE),
    },
    sparse_vectors_config={
        "sparse": SparseVectorParams()
    }
)

# Добавление: плотный + разреженный вектор
client.upsert(
    collection_name="hybrid_docs",
    points=[
        PointStruct(
            id=1,
            vector={
                "dense": dense_embedding,    # Из embedding-модели
            },
            payload={"text": "..."}
        )
    ]
)
```


## FAISS

Библиотека от Meta для быстрого ANN-поиска. Максимальная производительность,
минимальный overhead. Подходит для высоконагруженных систем.

### Установка

```bash
pip install faiss-cpu
# Или для GPU: pip install faiss-gpu
```

### Базовый пример

```python
import faiss
import numpy as np

dimension = 768
n_docs = 10000

# Создание индекса
index = faiss.IndexFlatIP(dimension)  # Inner Product (= cosine для нормализованных)

# Нормализация и добавление
vectors = np.random.randn(n_docs, dimension).astype("float32")
faiss.normalize_L2(vectors)
index.add(vectors)

# Поиск
query = np.random.randn(1, dimension).astype("float32")
faiss.normalize_L2(query)
distances, indices = index.search(query, k=5)

print(f"Top-5 индексов: {indices[0]}")
print(f"Top-5 scores: {distances[0]}")
```

### IVF-индекс (для больших коллекций)

```python
# IVF: разбиение на кластеры для ускорения
n_clusters = 100
quantizer = faiss.IndexFlatIP(dimension)
index = faiss.IndexIVFFlat(quantizer, dimension, n_clusters)

# Обучение на данных (нужно для IVF)
index.train(vectors)
index.add(vectors)

# Настройка точности поиска
index.nprobe = 10  # Проверять 10 кластеров из 100

distances, indices = index.search(query, k=5)
```

### Сохранение/загрузка

```python
# Сохранить
faiss.write_index(index, "docs.index")

# Загрузить
index = faiss.read_index("docs.index")
```

FAISS не хранит payload (текст, метаданные). Нужно хранить отдельно
(dict, SQLite, etc.) и маппить по индексу.


## pgvector

Расширение PostgreSQL для работы с векторами. Знакомый SQL-интерфейс,
транзакции, JOIN с другими таблицами.

### Установка

```bash
# Ubuntu
sudo apt install postgresql-16-pgvector

# Или через Docker
docker run -e POSTGRES_PASSWORD=pass -p 5432:5432 pgvector/pgvector:pg16
```

### Использование

```sql
-- Включить расширение
CREATE EXTENSION vector;

-- Создать таблицу
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    text TEXT NOT NULL,
    source VARCHAR(255),
    embedding vector(768)   -- 768-мерный вектор
);

-- Создать индекс (HNSW)
CREATE INDEX ON documents
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 200);

-- Вставка
INSERT INTO documents (text, source, embedding)
VALUES ('FastAPI -- фреймворк', 'fastapi.md', '[0.12, -0.34, ...]');

-- Поиск Top-5 по косинусной близости
SELECT text, source, 1 - (embedding <=> '[0.11, -0.33, ...]') AS similarity
FROM documents
ORDER BY embedding <=> '[0.11, -0.33, ...]'
LIMIT 5;

-- Поиск с фильтром
SELECT text, source
FROM documents
WHERE source LIKE '%.md'
ORDER BY embedding <=> '[0.11, -0.33, ...]'
LIMIT 5;
```

Плюс pgvector: JOIN с бизнес-таблицами (пользователи, права, теги).
Минус: медленнее специализированных баз на больших объёмах.


## Инкрементальная индексация

RAG-система должна обновляться при изменении документов.
Три стратегии:

### 1. Полная переиндексация

```python
# Удалить коллекцию, создать заново, проиндексировать все документы
client.delete_collection("project_docs")
collection = client.create_collection("project_docs", ...)
index_all_documents(collection)
```

Просто, но медленно для больших баз. Подходит для <10K документов.

### 2. Hash-based (по содержимому)

```python
import hashlib


def content_hash(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()[:16]


def incremental_index(docs_dir: str, collection):
    """Индексация только изменённых документов."""
    # Получить текущие хэши из коллекции
    existing = collection.get(include=["metadatas"])
    existing_hashes = {
        m["source"]: m.get("hash", "")
        for m in existing["metadatas"]
    }

    for path in Path(docs_dir).rglob("*.md"):
        text = path.read_text()
        source = str(path.relative_to(docs_dir))
        h = content_hash(text)

        if existing_hashes.get(source) == h:
            continue  # Не изменился

        # Удалить старую версию
        try:
            collection.delete(where={"source": source})
        except Exception:
            pass

        # Проиндексировать новую
        chunks = chunk_text(text, source)
        embeddings = embed_texts([c["text"] for c in chunks])
        collection.add(
            documents=[c["text"] for c in chunks],
            embeddings=embeddings,
            ids=[f"{source}_{i}" for i in range(len(chunks))],
            metadatas=[{"source": source, "hash": h} for _ in chunks]
        )
```

### 3. Timestamp-based (по дате)

```python
# Индексировать файлы изменённые после последнего запуска
import os
import time

LAST_INDEX_FILE = ".last_index_time"

def get_modified_files(docs_dir: str) -> list[Path]:
    last_time = 0
    if os.path.exists(LAST_INDEX_FILE):
        last_time = float(open(LAST_INDEX_FILE).read())

    modified = []
    for path in Path(docs_dir).rglob("*.md"):
        if path.stat().st_mtime > last_time:
            modified.append(path)

    # Обновить timestamp
    open(LAST_INDEX_FILE, "w").write(str(time.time()))
    return modified
```


## Выбор для проекта

```
Этап             | База      | Почему
-----------------|-----------|-----------------------------------
Прототип         | ChromaDB  | 5 строк кода, встраиваемая, бесплатная
MVP              | ChromaDB  | До 500K документов, persistent mode
Production       | Qdrant    | Фильтрация, гибридный поиск, docker
Enterprise       | Milvus    | Шардирование, высокая нагрузка
Уже есть Postgres| pgvector  | Без нового сервиса, JOIN с данными
Нужна скорость   | FAISS     | Минимальный overhead, GPU-ускорение
```

Рекомендация для этого проекта:
- Начать с ChromaDB (PersistentClient)
- Перейти на Qdrant когда нужна фильтрация или >500K документов


## Связанные статьи

- <-- [Embeddings](embeddings.md)
- --> [Chunking](chunking.md)
- [Pipeline](pipeline.md) -- полный пример с ChromaDB
