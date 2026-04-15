# Retrieval: поиск релевантных фрагментов

Retrieval -- ключевой компонент RAG: из тысяч chunks нужно выбрать 5-10
максимально релевантных запросу. Качество retrieval определяет качество
всей системы -- если нужный chunk не найден, LLM не сможет дать правильный ответ.


## Содержание

- [Top-K: базовый поиск](#top-k-базовый-поиск)
- [MMR: разнообразие результатов](#mmr-разнообразие-результатов)
- [Гибридный поиск: semantic + BM25](#гибридный-поиск-semantic--bm25)
- [Re-ranking: уточнение результатов](#re-ranking-уточнение-результатов)
- [HyDE: гипотетический ответ](#hyde-гипотетический-ответ)
- [Query expansion: расширение запроса](#query-expansion-расширение-запроса)
- [Parent-child chunking](#parent-child-chunking)
- [Фильтрация по метаданным](#фильтрация-по-метаданным)
- [Сравнение подходов](#сравнение-подходов)


## Top-K: базовый поиск

Простейший retrieval: embedding запроса -> cosine similarity со всеми chunks
-> вернуть K ближайших.

```
Запрос -> embedding -> cosine similarity со всеми chunks -> Top-K
```

```python
def retrieve(
    query: str,
    collection,
    n_results: int = 5
) -> list[dict]:
    """Top-K поиск по cosine similarity."""
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

Плюсы: простой, быстрый.
Минусы: все K результатов могут быть про одно и то же (дубликаты).


## MMR: разнообразие результатов

MMR (Maximal Marginal Relevance) балансирует релевантность и разнообразие.
Каждый следующий результат должен быть и релевантен запросу, и отличаться
от уже выбранных.

```
MMR(d) = lambda * sim(d, query) - (1 - lambda) * max(sim(d, d_selected))

lambda = 1.0  -> только релевантность (как Top-K)
lambda = 0.7  -> баланс (рекомендация)
lambda = 0.5  -> больше разнообразия
lambda = 0.0  -> только разнообразие
```

```python
import numpy as np


def mmr_retrieve(
    query_embedding: list[float],
    candidate_embeddings: list[list[float]],
    candidate_texts: list[str],
    k: int = 5,
    lambda_param: float = 0.7
) -> list[str]:
    """Поиск с MMR для разнообразия результатов."""
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

            # Максимальная похожесть с уже выбранными
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

        best_idx = max(mmr_scores, key=lambda x: x[1])[0]
        selected_indices.append(best_idx)
        remaining.remove(best_idx)

    return [candidate_texts[i] for i in selected_indices]
```

Когда использовать: документация с повторяющимися темами, FAQ с похожими
вопросами, кодовая база с дублирующими паттернами.


## Гибридный поиск: semantic + BM25

Semantic search находит по смыслу, BM25 -- по точным словам. Комбинация
лучше каждого подхода отдельно, особенно для технической документации
где точные термины важны.

```
Semantic: "как настроить деплой" -> ищет по смыслу "развертывание"
BM25:     "как настроить деплой" -> ищет по словам "настроить", "деплой"

Гибрид: находит документы, релевантные и по смыслу, и по терминам
```

### Reciprocal Rank Fusion (RRF)

Объединение двух списков результатов через ранговое слияние:

```
RRF_score(d) = sum(1 / (k + rank_i(d)))

k = 60 (константа, стандарт)
rank_i(d) = позиция документа d в i-м списке
```

```python
from rank_bm25 import BM25Okapi


def hybrid_retrieve(
    query: str,
    collection,
    texts: list[str],
    n_results: int = 5,
    alpha: float = 0.5,
    rrf_k: int = 60
) -> list[dict]:
    """
    Гибридный поиск: semantic (ChromaDB) + keyword (BM25).

    alpha -- вес semantic поиска (1.0 = только semantic, 0.0 = только BM25).
    """
    # 1. Semantic поиск
    semantic_results = collection.query(
        query_texts=[query],
        n_results=n_results * 2,  # Берём больше для объединения
        include=["documents", "metadatas"]
    )
    semantic_docs = semantic_results["documents"][0]

    # 2. BM25 поиск
    tokenized = [doc.lower().split() for doc in texts]
    bm25 = BM25Okapi(tokenized)
    bm25_scores = bm25.get_scores(query.lower().split())
    bm25_top = sorted(
        range(len(bm25_scores)),
        key=lambda i: bm25_scores[i],
        reverse=True
    )[:n_results * 2]
    bm25_docs = [texts[i] for i in bm25_top]

    # 3. RRF: объединение рангов
    doc_scores = {}

    for rank, doc in enumerate(semantic_docs):
        doc_id = doc[:100]  # Ключ по первым 100 символам
        doc_scores[doc_id] = doc_scores.get(doc_id, 0) + alpha / (rrf_k + rank + 1)

    for rank, doc in enumerate(bm25_docs):
        doc_id = doc[:100]
        doc_scores[doc_id] = doc_scores.get(doc_id, 0) + (1 - alpha) / (rrf_k + rank + 1)

    # 4. Топ результатов
    sorted_docs = sorted(doc_scores.items(), key=lambda x: x[1], reverse=True)
    return [{"text": doc_id, "rrf_score": score} for doc_id, score in sorted_docs[:n_results]]
```


## Re-ranking: уточнение результатов

Двухстадийный pipeline: bi-encoder (быстрый, грубый) -> cross-encoder
(медленный, точный).

```
Этап 1: Bi-encoder (embedding)
  - Скорость: ~1 мс на 1M документов
  - Точность: средняя
  - Результат: Top-20 кандидатов

Этап 2: Cross-encoder (re-ranker)
  - Скорость: ~100 мс на 20 документов
  - Точность: высокая
  - Результат: Top-5 финальных
```

Bi-encoder сравнивает вектора по отдельности: embed(query), embed(doc).
Cross-encoder анализирует пару (query, doc) совместно -- точнее,
но в 100x медленнее.

### Re-ranking через sentence-transformers

```python
from sentence_transformers import CrossEncoder

# Модели для re-ranking
# bge-reranker-large -- хорошее качество, 1.3 GB
# bge-reranker-v2-m3 -- мультиязычная (RU), 2.2 GB
reranker = CrossEncoder("BAAI/bge-reranker-large")


def rerank(
    query: str,
    documents: list[str],
    top_k: int = 5
) -> list[dict]:
    """Re-ranking документов через cross-encoder."""
    # Формируем пары (query, document)
    pairs = [(query, doc) for doc in documents]

    # Скоринг всех пар
    scores = reranker.predict(pairs)

    # Сортировка по score
    ranked = sorted(
        zip(documents, scores),
        key=lambda x: x[1],
        reverse=True
    )

    return [
        {"text": doc, "rerank_score": float(score)}
        for doc, score in ranked[:top_k]
    ]


# Использование в pipeline
initial_results = retrieve(query, collection, n_results=20)  # Top-20
texts = [r["text"] for r in initial_results]
final_results = rerank(query, texts, top_k=5)                # Top-5
```


## HyDE: гипотетический ответ

HyDE (Hypothetical Document Embeddings): вместо поиска по вопросу --
генерация гипотетического ответа, затем поиск по нему.

Идея: embedding ответа ближе к embedding-ам документов, чем embedding вопроса.

```
Запрос: "Как настроить CI?"
  |
  v
LLM генерирует гипотетический ответ:
  "Для настройки CI создайте файл .gitlab-ci.yml с описанием stages..."
  |
  v
Embedding гипотетического ответа -> поиск в Vector DB
  -> Находит реальные документы про CI (ближе к ответу, чем к вопросу)
```

```python
import requests


def hyde_retrieve(
    question: str,
    collection,
    llm_url: str = "http://localhost:8080",
    embedding_url: str = "http://localhost:8081",
    n_results: int = 5
) -> list[dict]:
    """Поиск с HyDE."""
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

Плюсы: улучшает retrieval на 10-20% для сложных вопросов.
Минусы: дополнительный вызов LLM (задержка 1-5 сек).


## Query expansion: расширение запроса

LLM генерирует несколько формулировок запроса, поиск по каждой,
объединение результатов.

```
Оригинальный запрос: "настройка CI"

LLM генерирует вариации:
  1. "настройка continuous integration pipeline"
  2. "конфигурация CI/CD в проекте"
  3. "файл gitlab-ci.yml описание"

Поиск по каждой вариации -> RRF объединение -> Top-K
```

```python
def multi_query_retrieve(
    question: str,
    collection,
    llm_url: str = "http://localhost:8080",
    n_variations: int = 3,
    n_results: int = 5
) -> list[dict]:
    """Retrieval с расширением запроса через LLM."""
    # 1. Генерация вариаций запроса
    response = requests.post(
        f"{llm_url}/v1/chat/completions",
        json={
            "messages": [
                {"role": "system", "content":
                    f"Сгенерируй {n_variations} альтернативных формулировок "
                    "поискового запроса. Формат: по одной на строку, без нумерации."},
                {"role": "user", "content": question}
            ],
            "temperature": 0.7,
            "max_tokens": 256
        }
    )
    variations = response.json()["choices"][0]["message"]["content"].strip().split("\n")
    variations = [question] + [v.strip() for v in variations if v.strip()]

    # 2. Поиск по каждой вариации
    all_results = {}
    for rank_list_idx, q in enumerate(variations):
        results = collection.query(
            query_texts=[q],
            n_results=n_results,
            include=["documents", "metadatas"]
        )
        for rank, doc in enumerate(results["documents"][0]):
            key = doc[:100]
            if key not in all_results:
                all_results[key] = {"text": doc, "rrf_score": 0}
            all_results[key]["rrf_score"] += 1 / (60 + rank + 1)

    # 3. Топ по RRF
    sorted_results = sorted(all_results.values(), key=lambda x: x["rrf_score"], reverse=True)
    return sorted_results[:n_results]
```


## Parent-child chunking

Индексация маленькими chunks (точный поиск) + возврат больших chunks
(полный контекст). Два уровня chunk-ов:

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

Поиск находит child chunk 1b -> возвращает parent chunk 1 (500 слов)
```

```python
def parent_child_index(
    text: str,
    source: str,
    parent_size: int = 1000,
    child_size: int = 200
) -> tuple[list[dict], list[dict]]:
    """Создание parent и child chunks."""
    # Parent chunks
    parents = recursive_chunk(text, max_size=parent_size, overlap=0)

    # Child chunks с ссылкой на parent
    children = []
    for parent_idx, parent_text in enumerate(parents):
        child_chunks = recursive_chunk(parent_text, max_size=child_size, overlap=30)
        for child_idx, child_text in enumerate(child_chunks):
            children.append({
                "text": child_text,
                "parent_idx": parent_idx,
                "source": source
            })

    parent_docs = [{"text": p, "source": source, "idx": i} for i, p in enumerate(parents)]
    return parent_docs, children


def parent_child_retrieve(
    query: str,
    child_collection,
    parent_docs: list[dict],
    n_results: int = 5
) -> list[str]:
    """Поиск по children, возврат parents."""
    results = child_collection.query(
        query_texts=[query],
        n_results=n_results * 2,
        include=["metadatas"]
    )

    # Уникальные parent-ы
    seen_parents = set()
    parent_texts = []
    for meta in results["metadatas"][0]:
        parent_idx = meta["parent_idx"]
        if parent_idx not in seen_parents:
            seen_parents.add(parent_idx)
            parent_texts.append(parent_docs[parent_idx]["text"])
            if len(parent_texts) >= n_results:
                break

    return parent_texts
```


## Фильтрация по метаданным

Сужение поиска через метаданные chunk-ов:

```python
# Поиск только в определённых файлах
results = collection.query(
    query_texts=["настройка CI"],
    n_results=5,
    where={"source": {"$in": ["docs/ci.md", "docs/deploy.md"]}}
)

# Поиск по дате (только свежие документы)
results = collection.query(
    query_texts=["release notes"],
    n_results=5,
    where={"timestamp": {"$gte": "2026-01-01"}}
)

# Комбинация: категория + дата
results = collection.query(
    query_texts=["performance"],
    n_results=5,
    where={
        "$and": [
            {"category": "benchmark"},
            {"timestamp": {"$gte": "2025-06-01"}}
        ]
    }
)
```


## Сравнение подходов

```
Подход           | Precision | Latency   | Сложность | Когда
-----------------|-----------|-----------|-----------|---------------------------
Top-K            | Средняя   | 1 мс      | Низкая    | Прототип, простые запросы
MMR              | Средняя   | 2 мс      | Низкая    | Дубликаты в результатах
Гибридный (RRF)  | Высокая   | 5 мс      | Средняя   | Техническая документация
Re-ranking       | Высокая   | 100 мс    | Средняя   | Production, качество критично
HyDE             | Высокая   | 1-5 сек   | Средняя   | Сложные вопросы
Query expansion  | Высокая   | 2-10 сек  | Средняя   | Неоднозначные запросы
Parent-child     | Высокая   | 2 мс      | Высокая   | Нужен широкий контекст
```

Рекомендуемый путь: Top-K -> гибридный -> re-ranking. Добавлять сложность
только когда простой подход не даёт нужного качества ([evaluation.md](evaluation.md)).


## Связанные статьи

- <-- [Chunking](chunking.md)
- --> [Pipeline](pipeline.md)
- [Evaluation](evaluation.md) -- как измерить качество retrieval
