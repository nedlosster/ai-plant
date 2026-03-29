# Pipeline: полный RAG от индексации до ответа

Практикум: собираем рабочий RAG pipeline с нуля. Индексация документов,
поиск по запросу, генерация ответа с указанием источников.


## Содержание

- [Архитектура: два сервера](#архитектура-два-сервера)
- [Запуск серверов](#запуск-серверов)
- [Prompt templates](#prompt-templates)
- [Полный pipeline: rag_pipeline.py](#полный-pipeline-rag_pipelinepy)
- [Запуск и тестирование](#запуск-и-тестирование)
- [Варианты deployment](#варианты-deployment)


## Архитектура: два сервера

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
Общий VRAM: ~19.3 GB.


## Запуск серверов

```bash
# Терминал 1: Embedding-сервер
llama-server \
    --model ~/models/nomic-embed-text-v1.5.Q8_0.gguf \
    --host 0.0.0.0 \
    --port 8081 \
    --embedding \
    --ctx-size 2048 \
    --n-gpu-layers 999

# Терминал 2: LLM-сервер
llama-server \
    --model ~/models/qwen2.5-32b-q4_k_m.gguf \
    --host 0.0.0.0 \
    --port 8080 \
    --ctx-size 8192 \
    --n-gpu-layers 999

# Проверка
curl http://localhost:8081/health
curl http://localhost:8080/health
```

Или через скрипты проекта:

```bash
./scripts/inference/vulkan/start-server.sh nomic-embed-text-v1.5.Q8_0.gguf --port 8081 --embedding --daemon
./scripts/inference/vulkan/start-server.sh qwen2.5-32b-q4_k_m.gguf --daemon
```


## Prompt templates

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
{code_chunk_1}
---
Файл: {file_2}
{code_chunk_2}
---

Вопрос: {question}

Формат ответа:
1. Объяснение (2-3 предложения)
2. Пример кода (если нужен)
3. Ссылка на файл
```


## Полный pipeline: rag_pipeline.py

```python
"""
RAG pipeline: индексация документов и ответы на вопросы.

Зависимости:
  pip install chromadb requests

Требует:
  - llama-server с embedding-моделью на порту 8081
  - llama-server с LLM на порту 8080
"""
import os
import sys
import requests
import chromadb
from pathlib import Path


# --- Конфигурация ---

EMBEDDING_URL = os.getenv("EMBEDDING_URL", "http://localhost:8081")
LLM_URL = os.getenv("LLM_URL", "http://localhost:8080")
CHUNK_SIZE = 400        # Символов на chunk
CHUNK_OVERLAP = 50      # Перекрытие
TOP_K = 5               # Количество фрагментов для контекста
CHROMA_DIR = "./chroma_db"


# --- Embedding ---

def embed_texts(texts: list[str]) -> list[list[float]]:
    """Получение embedding-ов через llama-server."""
    response = requests.post(
        f"{EMBEDDING_URL}/v1/embeddings",
        json={"input": texts, "model": "embed"}
    )
    response.raise_for_status()
    data = response.json()["data"]
    data.sort(key=lambda x: x["index"])
    return [d["embedding"] for d in data]


# --- Chunking ---

def chunk_text(text: str, source: str) -> list[dict]:
    """Разбиение текста на фрагменты с метаданными."""
    chunks = []
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
    client = chromadb.PersistentClient(path=CHROMA_DIR)
    collection = client.get_or_create_collection(
        name=collection_name,
        metadata={"hnsw:space": "cosine"}
    )

    # Проверить нужна ли переиндексация
    existing_count = collection.count()
    if existing_count > 0:
        print(f"Коллекция содержит {existing_count} chunks (используем существующую)")
        return collection

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

    # Пакетная обработка (по 32 за раз)
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
        print(f"  Проиндексировано: {min(i + batch_size, len(all_chunks))}/{len(all_chunks)}")

    print(f"Индексация завершена: {len(all_chunks)} фрагментов")
    return collection


# --- Контекст ---

def format_context(
    chunks: list[str],
    sources: list[str],
    max_context_chars: int = 6000
) -> str:
    """Форматирование chunks для вставки в промпт."""
    parts = []
    total = 0

    for i, (chunk, source) in enumerate(zip(chunks, sources)):
        part = f"[{i + 1}] Источник: {source}\n{chunk}"
        if total + len(part) > max_context_chars:
            break
        parts.append(part)
        total += len(part)

    return "\n---\n".join(parts)


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
    chunks = results["documents"][0]
    sources = [m["source"] for m in results["metadatas"][0]]
    distances = results["distances"][0]
    context = format_context(chunks, sources)

    # Лог retrieval для отладки
    print(f"\n  Retrieval ({len(chunks)} chunks):")
    for i, (src, dist) in enumerate(zip(sources, distances)):
        print(f"    [{i + 1}] {src} (similarity: {1 - dist:.3f})")

    # 4. Генерация ответа
    prompt = f"""Ответь на вопрос, используя ТОЛЬКО предоставленный контекст.
Если ответа нет в контексте -- скажи об этом.
После ответа укажи источники в формате [1], [2], ...

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
    response.raise_for_status()

    return response.json()["choices"][0]["message"]["content"]


# --- CLI ---

def main():
    """Точка входа: индексация + интерактивный режим."""
    docs_dir = sys.argv[1] if len(sys.argv) > 1 else "./docs/"

    print(f"Индексация: {docs_dir}")
    collection = index_directory(docs_dir)

    print("\nRAG готов. Введите вопрос (Ctrl+C для выхода):\n")
    while True:
        try:
            question = input("> ").strip()
            if not question:
                continue
            answer = ask(question, collection)
            print(f"\n{answer}\n")
            print("-" * 60)
        except KeyboardInterrupt:
            print("\nВыход")
            break


if __name__ == "__main__":
    main()
```


## Запуск и тестирование

```bash
# Зависимости
pip install chromadb requests

# Запуск (индексация docs/ проекта)
python rag_pipeline.py ./docs/

# Тестовые вопросы
> Как запустить llama-server?
> Какие модели помещаются в 96 GiB?
> Как настроить квантизацию KV-cache?
> Как запустить ComfyUI?
```

### Переиндексация

```bash
# Удалить существующую базу для переиндексации
rm -rf ./chroma_db/
python rag_pipeline.py ./docs/
```


## Варианты deployment

### 1. CLI (текущий вариант)

Минимальный вариант для тестирования. Код выше.

### 2. Gradio UI

```python
import gradio as gr


def gradio_ask(question: str) -> str:
    return ask(question, collection)

collection = index_directory("./docs/")
demo = gr.Interface(
    fn=gradio_ask,
    inputs=gr.Textbox(label="Вопрос", lines=2),
    outputs=gr.Textbox(label="Ответ", lines=10),
    title="RAG: документация проекта"
)
demo.launch(server_name="0.0.0.0", server_port=7861)
```

```bash
pip install gradio
python rag_gradio.py
# Открыть http://localhost:7861
```

### 3. FastAPI

```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()


class Question(BaseModel):
    text: str
    top_k: int = 5


class Answer(BaseModel):
    answer: str
    sources: list[str]


@app.post("/ask", response_model=Answer)
def api_ask(q: Question):
    # Retrieval
    query_embedding = embed_texts([q.text])[0]
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=q.top_k,
        include=["documents", "metadatas", "distances"]
    )

    sources = [m["source"] for m in results["metadatas"][0]]
    answer_text = ask(q.text, collection)

    return Answer(answer=answer_text, sources=sources)
```

```bash
pip install fastapi uvicorn
uvicorn rag_api:app --host 0.0.0.0 --port 7862
# POST http://localhost:7862/ask {"text": "Как запустить сервер?"}
```


## Связанные статьи

- <-- [Retrieval](retrieval.md)
- --> [Evaluation](evaluation.md)
- [Embeddings](embeddings.md) -- запуск embedding-сервера
- [Chunking](chunking.md) -- стратегии разбиения
