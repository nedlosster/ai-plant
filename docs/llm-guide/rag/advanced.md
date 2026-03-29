# Advanced RAG

Продвинутые архитектуры RAG для задач, где базовый vector search недостаточен:
связи между сущностями, многошаговые рассуждения, мультимодальные данные,
автономный поиск.


## Содержание

- [Graph RAG](#graph-rag)
- [Agentic RAG](#agentic-rag)
- [Multi-modal RAG](#multi-modal-rag)
- [Multi-hop reasoning](#multi-hop-reasoning)
- [RAG vs Fine-tuning](#rag-vs-fine-tuning)
- [Ограничения RAG](#ограничения-rag)


## Graph RAG

### Проблема

Vector RAG находит похожие фрагменты, но не видит связи между сущностями:

```
Вопрос: "Кто работает над проектом X и какие у них зависимости?"

Vector RAG:
  Chunk 1: "Иван работает над проектом X"
  Chunk 2: "Проект X зависит от сервиса Y"
  Chunk 3: "Сервис Y поддерживает Мария"
  -> LLM может не связать все три факта

Graph RAG:
  Иван --работает_над--> Проект X --зависит_от--> Сервис Y <--поддерживает-- Мария
  -> Граф делает связи явными
```

### Архитектура

```
Документы
    |
    v
LLM: извлечение сущностей и связей
    |
    v
Knowledge Graph (Neo4j / NetworkX)
    |
    +-- Community detection (кластеризация связанных сущностей)
    |
    +-- Summarization (саммари каждого кластера)
    |
    v
При запросе: graph traversal + vector search -> контекст -> LLM
```

### Entity extraction через LLM

```python
import json


def extract_entities(
    text: str,
    llm_url: str = "http://localhost:8080"
) -> list[dict]:
    """Извлечение сущностей и связей из текста через LLM."""
    prompt = f"""Извлеки сущности и связи из текста. Верни JSON:
{{
  "entities": [
    {{"name": "имя", "type": "тип (person/project/service/concept)"}}
  ],
  "relations": [
    {{"source": "имя1", "target": "имя2", "relation": "описание_связи"}}
  ]
}}

Текст:
{text}

JSON:"""

    response = requests.post(
        f"{llm_url}/v1/chat/completions",
        json={
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.0,
            "max_tokens": 1024
        }
    )
    content = response.json()["choices"][0]["message"]["content"]

    try:
        return json.loads(content)
    except json.JSONDecodeError:
        return {"entities": [], "relations": []}
```

### Граф через NetworkX

```python
import networkx as nx


def build_knowledge_graph(
    documents: list[str]
) -> nx.DiGraph:
    """Построение knowledge graph из документов."""
    G = nx.DiGraph()

    for doc in documents:
        data = extract_entities(doc)

        for entity in data.get("entities", []):
            G.add_node(entity["name"], type=entity["type"])

        for rel in data.get("relations", []):
            G.add_edge(
                rel["source"],
                rel["target"],
                relation=rel["relation"]
            )

    return G


def graph_context(
    G: nx.DiGraph,
    query_entities: list[str],
    max_hops: int = 2
) -> str:
    """Извлечение контекста из графа вокруг сущностей запроса."""
    context_parts = []

    for entity in query_entities:
        if entity not in G:
            continue

        # Соседи в пределах max_hops
        neighbors = nx.single_source_shortest_path_length(G, entity, cutoff=max_hops)

        for neighbor, distance in neighbors.items():
            if neighbor == entity:
                continue
            # Найти путь
            try:
                path = nx.shortest_path(G, entity, neighbor)
                relations = []
                for i in range(len(path) - 1):
                    edge_data = G.edges[path[i], path[i + 1]]
                    relations.append(
                        f"{path[i]} --{edge_data.get('relation', '?')}--> {path[i + 1]}"
                    )
                context_parts.append(" | ".join(relations))
            except nx.NetworkXNoPath:
                pass

    return "\n".join(context_parts)
```

### Когда использовать

```
Задача                              | Graph RAG помогает?
------------------------------------|--------------------
Вопросы о связях между сущностями   | Да
Вопросы "кто/что зависит от чего"   | Да
Суммаризация большого корпуса       | Да (через community summaries)
Поиск конкретного факта             | Нет (vector RAG достаточно)
Вопросы по одному документу         | Нет (overkill)
```


## Agentic RAG

RAG как инструмент (tool) в агентской системе. Агент решает:
когда искать, что искать, достаточно ли результатов.

### Self-RAG

Модель оценивает: нужен ли retrieval для ответа на вопрос?

```
Вопрос: "Что такое Python?"
  -> Модель: "Знаю из обучения, retrieval не нужен"
  -> Ответ напрямую

Вопрос: "Как настроить CI в нашем проекте?"
  -> Модель: "Не знаю, нужен retrieval"
  -> Поиск -> Ответ по контексту
```

### Corrective RAG (CRAG)

Если retrieval вернул нерелевантное -- переформулировать и повторить.

```
Вопрос: "как ускорить inference"
  |
  v
Retrieval -> Top-5 chunks
  |
  v
Оценка: "релевантность < 0.5, результаты не по теме"
  |
  v
Переформулировка: "оптимизация скорости llama-server batch size gpu layers"
  |
  v
Повторный retrieval -> лучшие результаты
```

```python
def corrective_rag(
    question: str,
    collection,
    llm_url: str = "http://localhost:8080",
    min_relevance: float = 0.5,
    max_retries: int = 2
) -> str:
    """RAG с коррекцией: переформулировка при низкой релевантности."""
    current_query = question

    for attempt in range(max_retries + 1):
        # Retrieval
        query_embedding = embed_texts([current_query])[0]
        results = collection.query(
            query_embeddings=[query_embedding],
            n_results=5,
            include=["documents", "distances"]
        )

        top_relevance = 1 - results["distances"][0][0]

        if top_relevance >= min_relevance or attempt == max_retries:
            # Результаты достаточно релевантны (или последняя попытка)
            return generate_answer(question, results)

        # Переформулировка через LLM
        response = requests.post(
            f"{llm_url}/v1/chat/completions",
            json={
                "messages": [
                    {"role": "system", "content":
                        "Переформулируй поисковый запрос для лучшего поиска "
                        "в технической документации. Добавь синонимы и ключевые термины."},
                    {"role": "user", "content": current_query}
                ],
                "temperature": 0.5,
                "max_tokens": 100
            }
        )
        current_query = response.json()["choices"][0]["message"]["content"].strip()
        print(f"  Коррекция (попытка {attempt + 1}): {current_query}")
```

### RAG как tool (function calling)

```python
# RAG как tool в агентской системе
tools = [
    {
        "type": "function",
        "function": {
            "name": "search_docs",
            "description": "Поиск в документации проекта по запросу",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Поисковый запрос"},
                    "category": {
                        "type": "string",
                        "enum": ["inference", "models", "training", "platform"],
                        "description": "Категория документации"
                    }
                },
                "required": ["query"]
            }
        }
    }
]

# Агент сам решает когда вызывать search_docs
# Подробнее: function-calling.md
```

### Multi-step retrieval

Агент декомпозирует сложный вопрос на подвопросы:

```
Вопрос: "Какую модель выбрать для кодинга, учитывая наш VRAM?"

Шаг 1: search_docs("объем VRAM сервера")
  -> "96 GiB unified VRAM"

Шаг 2: search_docs("модели для кодинга размер VRAM")
  -> "Qwen2.5-Coder-32B Q4 = 19 GB, DeepSeek-Coder-33B Q4 = 20 GB"

Шаг 3: Агент формирует ответ на основе обоих результатов
  -> "При 96 GiB доступно несколько моделей для кодинга..."
```


## Multi-modal RAG

RAG с изображениями, таблицами и другими модальностями.

### Подходы

```
Подход          | Как работает                        | Когда
----------------|-------------------------------------|-------------------
CLIP embeddings | Текст и картинки в одном пространстве| Поиск картинок по тексту
OCR + text RAG  | Извлечь текст из изображений        | Сканы, скриншоты
Table parsing   | Таблицы -> structured data          | PDF с таблицами
Caption + embed | LLM описывает картинку -> embedding  | Диаграммы, схемы
```

### CLIP: текст + изображения

```python
# Концептуально (реализация через transformers)
from transformers import CLIPModel, CLIPProcessor

model = CLIPModel.from_pretrained("openai/clip-vit-large-patch14")
processor = CLIPProcessor.from_pretrained("openai/clip-vit-large-patch14")

# Embedding текста
text_inputs = processor(text=["диаграмма архитектуры"], return_tensors="pt")
text_embedding = model.get_text_features(**text_inputs)

# Embedding изображения
image_inputs = processor(images=[image], return_tensors="pt")
image_embedding = model.get_image_features(**image_inputs)

# Поиск: cosine similarity между text_embedding и image_embedding
# Те же операции, что и в text RAG
```

### Caption-based подход

Проще: vision LLM описывает изображение, описание индексируется как текст.

```python
def image_to_caption(image_path: str, llm_url: str) -> str:
    """Описание изображения через vision LLM."""
    # Зависит от модели: LLaVA, Qwen-VL, etc.
    # Описание индексируется в vector DB как обычный текст
    pass
```


## Multi-hop reasoning

Ответ требует информации из нескольких документов, связанных логически.

```
Вопрос: "Поместится ли Llama 3.1 70B в VRAM нашего сервера?"

Hop 1: "Llama 3.1 70B в Q4 = 40 GB" (из docs/models/)
Hop 2: "VRAM сервера = 96 GiB" (из docs/platform/)
Hop 3: Рассуждение: 40 GB < 96 GiB -> "Да, поместится"
```

### Chain of retrieval

```python
def multi_hop_ask(
    question: str,
    collection,
    llm_url: str = "http://localhost:8080",
    max_hops: int = 3
) -> str:
    """Multi-hop RAG: последовательные запросы для сложных вопросов."""
    accumulated_context = []
    current_query = question

    for hop in range(max_hops):
        # Retrieval
        results = collection.query(
            query_texts=[current_query],
            n_results=3,
            include=["documents"]
        )
        new_chunks = results["documents"][0]
        accumulated_context.extend(new_chunks)

        # Проверка: достаточно ли контекста?
        check_prompt = f"""На основе контекста ниже, можешь ли ты полностью ответить на вопрос?
Ответь ТОЛЬКО "да" или "нет, нужна информация о: <что именно>".

Контекст: {' '.join(accumulated_context[:3])}

Вопрос: {question}"""

        response = requests.post(
            f"{llm_url}/v1/chat/completions",
            json={
                "messages": [{"role": "user", "content": check_prompt}],
                "temperature": 0.0,
                "max_tokens": 100
            }
        )
        check = response.json()["choices"][0]["message"]["content"].lower()

        if check.startswith("да"):
            break

        # Извлечь подзапрос из "нужна информация о: ..."
        if "нужна информация о:" in check:
            current_query = check.split("нужна информация о:")[-1].strip()
        else:
            break

    # Финальный ответ
    context = "\n---\n".join(accumulated_context)
    return generate_answer_with_context(question, context)
```


## RAG vs Fine-tuning

```
Критерий          | RAG                      | Fine-tuning
------------------|--------------------------|---------------------------
Обновление данных | Мгновенно (переиндексация)| Дообучение (часы/дни)
Стоимость         | Дешево (inference only)  | Дорого (GPU для обучения)
Прозрачность      | Источники видны          | "Чёрный ящик"
Объём данных      | Любой (хранится в DB)    | Ограничен (влияет на обучение)
Качество          | Зависит от retrieval     | Может быть выше для узких задач
Hallucinations    | Контролируется (контекст)| Сложно контролировать
Latency           | Выше (+retrieval)        | Ниже (прямой inference)
```

### Когда что

```
RAG:
  - Данные меняются часто
  - Нужна прозрачность (источники)
  - Большой корпус документов
  - Нужна точность фактов

Fine-tuning:
  - Данные стабильны
  - Нужен определённый стиль/формат ответа
  - Специфическая терминология
  - Latency критична

Комбинация:
  - Fine-tuned модель + RAG для фактов
  - Модель обучена на формат, RAG даёт контекст
```


## Ограничения RAG

```
Ситуация                           | Проблема
-----------------------------------|----------------------------------
Вопрос требует рассуждения         | RAG даёт факты, не рассуждения
Ответ в нескольких документах      | Нужен multi-hop (выше)
Данные в таблицах/графиках         | Embedding плохо работает с табличными данными
Вопрос о взаимосвязях              | Graph RAG лучше vector RAG
Очень длинные документы            | Chunking критичен, может потерять контекст
Нет данных в базе                  | RAG не может ответить (в отличие от LLM)
```

RAG -- не панацея. Для каждой задачи нужно оценить: даёт ли RAG
преимущество над чистым LLM? Метрики из evaluation.md помогут ответить.


## Связанные статьи

- <-- [Evaluation](evaluation.md)
- [Function calling](../function-calling.md) -- RAG как tool для агентов
- [Multimodal](../multimodal.md) -- мультимодальные модели
- [RAG: обзор](README.md) -- архитектура и навигация
