# Evaluation: оценка качества RAG

RAG может молча деградировать: retrieval находит не те документы, LLM
галлюцинирует вместо признания "не знаю". Без метрик и тестирования
проблемы обнаруживаются только когда пользователь получает неправильный ответ.


## Содержание

- [Два уровня оценки](#два-уровня-оценки)
- [Метрики retrieval](#метрики-retrieval)
- [Метрики generation](#метрики-generation)
- [RAGAS: автоматическая оценка](#ragas-автоматическая-оценка)
- [Создание evaluation dataset](#создание-evaluation-dataset)
- [Отладка retrieval](#отладка-retrieval)
- [A/B тестирование параметров](#ab-тестирование-параметров)
- [Типичные проблемы и решения](#типичные-проблемы-и-решения)
- [Мониторинг в production](#мониторинг-в-production)


## Два уровня оценки

```
Уровень 1: Retrieval (поиск)
  Вопрос: Правильные ли документы найдены?
  Метрики: Recall@K, Precision@K, MRR, NDCG

Уровень 2: Generation (ответ)
  Вопрос: Правильный ли ответ сгенерирован?
  Метрики: Faithfulness, Relevance, Completeness
```

Retrieval -- фундамент. Если нужный chunk не найден, LLM не сможет
дать правильный ответ. Поэтому сначала оцениваем retrieval.


## Метрики retrieval

### Recall@K

Доля релевантных документов, которые попали в Top-K результатов.

```
Recall@K = |релевантные в Top-K| / |все релевантные|

Пример:
  Всего релевантных chunks = 3
  Top-5 содержит 2 из них
  Recall@5 = 2/3 = 0.67
```

### Precision@K

Доля релевантных среди возвращённых K результатов.

```
Precision@K = |релевантные в Top-K| / K

Пример:
  Top-5 содержит 2 релевантных
  Precision@5 = 2/5 = 0.40
```

### MRR (Mean Reciprocal Rank)

Средняя обратная позиция первого релевантного результата.

```
RR = 1 / позиция_первого_релевантного
MRR = среднее(RR по всем запросам)

Пример:
  Запрос 1: первый релевантный на позиции 1 -> RR = 1/1 = 1.0
  Запрос 2: первый релевантный на позиции 3 -> RR = 1/3 = 0.33
  MRR = (1.0 + 0.33) / 2 = 0.67
```

### NDCG (Normalized Discounted Cumulative Gain)

Учитывает не только наличие, но и позицию релевантных результатов.
Штрафует за релевантные документы на нижних позициях.

```
DCG@K = sum(rel_i / log2(i + 1))  для i от 1 до K
NDCG@K = DCG@K / идеальный_DCG@K
```

### Реализация

```python
import numpy as np


def recall_at_k(
    retrieved_ids: list[str],
    relevant_ids: list[str],
    k: int = 5
) -> float:
    """Recall@K."""
    retrieved_set = set(retrieved_ids[:k])
    relevant_set = set(relevant_ids)
    if not relevant_set:
        return 0.0
    return len(retrieved_set & relevant_set) / len(relevant_set)


def precision_at_k(
    retrieved_ids: list[str],
    relevant_ids: list[str],
    k: int = 5
) -> float:
    """Precision@K."""
    retrieved_set = set(retrieved_ids[:k])
    relevant_set = set(relevant_ids)
    return len(retrieved_set & relevant_set) / k


def mrr(
    queries_results: list[tuple[list[str], list[str]]]
) -> float:
    """Mean Reciprocal Rank.

    queries_results -- список (retrieved_ids, relevant_ids) для каждого запроса.
    """
    reciprocal_ranks = []
    for retrieved, relevant in queries_results:
        relevant_set = set(relevant)
        for i, doc_id in enumerate(retrieved):
            if doc_id in relevant_set:
                reciprocal_ranks.append(1 / (i + 1))
                break
        else:
            reciprocal_ranks.append(0)
    return np.mean(reciprocal_ranks)
```


## Метрики generation

### Faithfulness (верность контексту)

Ответ основан только на предоставленном контексте, без галлюцинаций.

```
Контекст: "llama-server запускается на порту 8080"
Ответ: "llama-server запускается на порту 8080"      -> Faithful
Ответ: "llama-server запускается на порту 3000"      -> Hallucination
Ответ: "llama-server использует gRPC на порту 50051" -> Hallucination
```

### Answer Relevancy (релевантность ответа)

Ответ отвечает на заданный вопрос.

```
Вопрос: "Как запустить llama-server?"
Ответ: "Команда: llama-server --model model.gguf"    -> Relevant
Ответ: "llama-server -- это инструмент от Meta"       -> Irrelevant (не отвечает)
```

### Completeness (полнота)

Ответ содержит всю необходимую информацию.

```
Вопрос: "Какие параметры у llama-server?"
Ответ: "--model, --host, --port"                      -> Partial
Ответ: "--model, --host, --port, --ctx-size, --n-gpu-layers, ..." -> Complete
```


## RAGAS: автоматическая оценка

RAGAS (Retrieval Augmented Generation Assessment) -- фреймворк
автоматической оценки RAG через LLM-as-judge.

### Принцип

LLM оценивает качество RAG по четырём метрикам:

```
Метрика            | Что оценивает                     | Вход
-------------------|-----------------------------------|---------------------------
Faithfulness       | Ответ не противоречит контексту?  | context + answer
Answer relevancy   | Ответ по теме вопроса?            | question + answer
Context precision  | Контекст релевантен вопросу?      | question + context
Context recall     | Все нужные факты найдены?         | question + context + golden
```

### Использование

```python
# pip install ragas

from ragas import evaluate
from ragas.metrics import (
    faithfulness,
    answer_relevancy,
    context_precision,
    context_recall
)
from datasets import Dataset

# Подготовка данных
data = {
    "question": ["Как запустить llama-server?"],
    "answer": ["Команда: llama-server --model model.gguf --port 8080"],
    "contexts": [["llama-server запускается командой llama-server --model ..."]],
    "ground_truth": ["llama-server запускается через CLI с указанием модели и порта"]
}
dataset = Dataset.from_dict(data)

# Оценка
result = evaluate(
    dataset,
    metrics=[
        faithfulness,
        answer_relevancy,
        context_precision,
        context_recall
    ]
)
print(result)
# {'faithfulness': 0.95, 'answer_relevancy': 0.88, ...}
```

### Без RAGAS: LLM-as-judge вручную

Если RAGAS не подходит (зависимость от OpenAI, тяжёлый setup),
можно оценивать через локальный LLM:

```python
def evaluate_faithfulness(
    context: str,
    answer: str,
    llm_url: str = "http://localhost:8080"
) -> float:
    """Оценка faithfulness через LLM-as-judge."""
    prompt = f"""Оцени, насколько ответ основан на контексте.
Верни число от 0.0 до 1.0:
  1.0 = ответ полностью основан на контексте
  0.5 = частично основан
  0.0 = ответ содержит информацию, отсутствующую в контексте

Контекст:
{context}

Ответ:
{answer}

Оценка (число от 0.0 до 1.0):"""

    response = requests.post(
        f"{llm_url}/v1/chat/completions",
        json={
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.0,
            "max_tokens": 10
        }
    )
    text = response.json()["choices"][0]["message"]["content"].strip()
    try:
        return float(text)
    except ValueError:
        return 0.0
```


## Создание evaluation dataset

Evaluation dataset -- набор (вопрос, golden_answer, golden_chunks)
для регрессионного тестирования RAG.

### Формат

```python
eval_dataset = [
    {
        "question": "Как запустить llama-server с Vulkan?",
        "golden_answer": "llama-server --model model.gguf --n-gpu-layers 999",
        "golden_chunks": ["docs/inference/vulkan-llama-cpp.md#chunk_3"],
        "category": "inference"
    },
    {
        "question": "Какой максимальный размер модели для 96 GiB?",
        "golden_answer": "~70B в Q4 квантизации",
        "golden_chunks": ["docs/models/llm.md#chunk_7"],
        "category": "models"
    },
    # 20-50 вопросов для начала
]
```

### Генерация через LLM

```python
def generate_eval_questions(
    chunk: str,
    source: str,
    llm_url: str = "http://localhost:8080",
    n_questions: int = 3
) -> list[dict]:
    """Генерация тестовых вопросов по chunk-у."""
    prompt = f"""На основе текста ниже сгенерируй {n_questions} вопроса,
на которые этот текст отвечает. Формат: по одному вопросу на строку.

Текст:
{chunk}

Вопросы:"""

    response = requests.post(
        f"{llm_url}/v1/chat/completions",
        json={
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.5,
            "max_tokens": 256
        }
    )
    questions = response.json()["choices"][0]["message"]["content"].strip().split("\n")

    return [
        {
            "question": q.strip().lstrip("0123456789.-) "),
            "golden_chunks": [source],
            "category": "auto"
        }
        for q in questions if q.strip()
    ]
```

Рекомендация: 20-50 вопросов, покрывающих разные разделы документации.
Часть генерируется автоматически, часть -- вручную (edge cases).


## Отладка retrieval

```python
def debug_retrieval(
    question: str,
    collection,
    n_results: int = 10
):
    """Показать, что находит retrieval."""
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
        marker = "**" if relevance > 0.7 else "  "
        print(f"{marker}#{i + 1} [{relevance:.3f}] {meta.get('source', '?')}")
        print(f"    {doc[:120]}...")
        print()
```

Что смотреть:
- Нужный chunk в Top-5? Если нет -- проблема в chunking или embedding-модели
- Similarity > 0.7? Если все < 0.5 -- запрос далёк от документов
- Дубликаты? Если 3 из 5 -- одно и то же, нужен MMR
- Все из одного файла? Нужно разнообразие (MMR или гибридный)


## A/B тестирование параметров

```python
def ab_test(
    eval_dataset: list[dict],
    configs: dict,
    docs_dir: str
):
    """A/B тестирование конфигураций RAG."""
    for config_name, params in configs.items():
        # Переиндексация с новыми параметрами
        collection = index_with_params(docs_dir, params)

        # Оценка
        recalls = []
        for item in eval_dataset:
            results = collection.query(
                query_texts=[item["question"]],
                n_results=params.get("top_k", 5)
            )
            retrieved_sources = [m["source"] for m in results["metadatas"][0]]
            r = recall_at_k(retrieved_sources, item["golden_chunks"], k=5)
            recalls.append(r)

        avg_recall = np.mean(recalls)
        print(f"{config_name}: Recall@5 = {avg_recall:.3f}")


# Конфигурации для сравнения
configs = {
    "small_chunks": {"chunk_size": 256, "overlap": 30, "top_k": 5},
    "medium_chunks": {"chunk_size": 512, "overlap": 50, "top_k": 5},
    "large_chunks": {"chunk_size": 1024, "overlap": 100, "top_k": 3},
    "small_top10": {"chunk_size": 256, "overlap": 30, "top_k": 10},
}

ab_test(eval_dataset, configs, "./docs/")
```


## Типичные проблемы и решения

```
Проблема                      | Диагностика              | Решение
------------------------------|--------------------------|----------------------------
Нужный chunk не в Top-5       | debug_retrieval          | Уменьшить chunk_size
Все результаты про одно       | debug_retrieval          | MMR (lambda=0.7)
Низкая similarity (<0.5)      | Проверить embedding-модель| Сменить на мультиязычную
Правильный chunk, плохой ответ| Проверить prompt         | Улучшить template
Ответ "не знаю" при наличии   | Проверить context length | Увеличить max_context
Галлюцинации                  | evaluate_faithfulness    | Снизить temperature, добавить "ТОЛЬКО из контекста"
Термины не находятся          | Тест BM25 отдельно       | Гибридный поиск
Долгий retrieval              | Замерить latency         | HNSW параметры, IVF
```


## Мониторинг в production

Логировать каждый запрос для анализа:

```python
import json
import time
from datetime import datetime


def ask_with_logging(
    question: str,
    collection,
    log_file: str = "rag_log.jsonl"
) -> str:
    """RAG с логированием для мониторинга."""
    start = time.time()

    # Retrieval
    query_embedding = embed_texts([question])[0]
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=TOP_K,
        include=["documents", "metadatas", "distances"]
    )

    retrieval_time = time.time() - start
    top_similarity = 1 - results["distances"][0][0]
    sources = [m["source"] for m in results["metadatas"][0]]

    # Generation
    answer = generate_answer(question, results)
    total_time = time.time() - start

    # Лог
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "question": question,
        "top_similarity": round(top_similarity, 3),
        "sources": sources,
        "retrieval_ms": round(retrieval_time * 1000),
        "total_ms": round(total_time * 1000),
        "answer_length": len(answer)
    }

    with open(log_file, "a") as f:
        f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")

    return answer
```

Алерты:
- `top_similarity < 0.3` -- retrieval не нашёл ничего релевантного
- `retrieval_ms > 500` -- деградация производительности
- `answer_length < 10` -- LLM вернул пустой ответ


## Связанные статьи

- <-- [Pipeline](pipeline.md)
- --> [Advanced](advanced.md)
- [Retrieval](retrieval.md) -- алгоритмы поиска для улучшения метрик
