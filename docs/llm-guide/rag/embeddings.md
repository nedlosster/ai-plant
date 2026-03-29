# Embeddings

Embedding -- числовой вектор фиксированной длины, представляющий смысл текста.
Тексты с похожим смыслом имеют близкие вектора. Это фундамент RAG: именно
embedding-ы позволяют искать документы "по смыслу", а не по ключевым словам.


## Содержание

- [Что такое embedding](#что-такое-embedding)
- [Близость векторов](#близость-векторов)
- [Размерность](#размерность)
- [Модели](#модели)
- [Запуск через llama-server](#запуск-через-llama-server)
- [API: получение embedding-ов](#api-получение-embedding-ов)
- [Prefix instruction](#prefix-instruction)
- [Нормализация](#нормализация)
- [Визуализация embedding-пространства](#визуализация-embedding-пространства)
- [Выбор модели для русского языка](#выбор-модели-для-русского-языка)


## Что такое embedding

Embedding-модель принимает текст и возвращает вектор фиксированной длины.
Каждое число в векторе -- "координата" в пространстве смыслов.

```
"кот сидит на коврике"  -> [0.12, -0.34, 0.56, ..., 0.78]  (768 чисел)
"кошка лежит на ковре"  -> [0.11, -0.33, 0.55, ..., 0.77]  (похожий вектор)
"акции Tesla растут"    -> [0.89, 0.12, -0.45, ..., -0.23]  (далёкий вектор)
```

Ключевое свойство: семантически близкие тексты -> близкие вектора.
Это позволяет находить релевантные документы даже когда слова не совпадают:
запрос "домашний питомец" найдет документ про "кота".


## Близость векторов

### Cosine similarity

Основная метрика близости в RAG -- косинусная близость:

```
cos(A, B) = (A * B) / (|A| * |B|)

Значения:
  1.0  = идентичные тексты
  0.7+ = высокая релевантность
  0.5  = средняя релевантность
  0.0  = нет связи
```

### Реализация

```python
import numpy as np


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    """Косинусная близость двух векторов."""
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))


# Пример (упрощённо, 4 измерения)
vec_cat = np.array([0.8, 0.1, 0.6, 0.3])      # "кот на коврике"
vec_kitten = np.array([0.7, 0.2, 0.5, 0.4])    # "котёнок на полу"
vec_stock = np.array([-0.2, 0.9, -0.1, 0.8])    # "акции на бирже"

print(cosine_similarity(vec_cat, vec_kitten))  # ~0.97 (похожи)
print(cosine_similarity(vec_cat, vec_stock))   # ~0.32 (далеки)
```

### Другие метрики

```
Метрика            | Формула                | Когда использовать
-------------------|------------------------|----------------------------
Cosine similarity  | dot(A,B) / (|A|*|B|)  | По умолчанию, для нормализованных
Dot product        | dot(A, B)              | Если вектора уже нормализованы
Euclidean (L2)     | sqrt(sum((A-B)^2))     | Для ненормализованных, кластеризация
```

Cosine similarity не зависит от длины вектора (только от направления).
Для нормализованных векторов cosine similarity = dot product.


## Размерность

Размерность -- количество чисел в векторе. Больше измерений = больше нюансов
смысла, но и больше памяти.

```
Размерность | Память на 1M документов | Качество
------------|-------------------------|----------
384         | ~1.5 GB                | Базовое
768         | ~3 GB                  | Хорошее (достаточно для большинства задач)
1024        | ~4 GB                  | Отличное
1536        | ~6 GB                  | Максимальное
```

Формула: память = N_docs * dimensions * 4 байта (float32).
Для 1M документов с 768-мерными вектором: 1M * 768 * 4 = ~3 GB.

Для большинства задач 768-1024 измерений достаточно. Больше -- для
высоконагруженных систем с тонкими семантическими различиями.


## Модели

### Таблица embedding-моделей

```
Модель                | Размерность | Язык    | Размер  | Качество (MTEB)
----------------------|-------------|---------|---------|------------------
nomic-embed-text      | 768         | EN (OK) | 274 MB  | Хорошее
bge-large-en-v1.5     | 1024        | EN      | 1.3 GB  | Отличное
bge-m3                | 1024        | Multi   | 2.2 GB  | Отличное (RU)
e5-large-v2           | 1024        | EN (OK) | 1.3 GB  | Отличное
gte-Qwen2-1.5B        | 1536        | Multi   | 3.0 GB  | Отличное (RU)
multilingual-e5-large | 1024        | Multi   | 1.1 GB  | Хорошее (RU)
```

### Как выбрать

```
Задача                            | Рекомендация
----------------------------------|----------------------------------
Прототип, английские документы    | nomic-embed-text (маленькая, быстрая)
Production, английские документы  | bge-large-en-v1.5 или e5-large-v2
Русскоязычные документы           | bge-m3 или gte-Qwen2-1.5B
Мультиязычный проект              | bge-m3 (1024D, хорошая поддержка RU)
Максимальное качество             | gte-Qwen2-1.5B (1536D, но 3 GB)
```


## Запуск через llama-server

Embedding-модели можно запустить через llama-server в GGUF-формате.
Модели маленькие -- квантизация обычно не нужна (Q8_0 или F16).

```bash
# Запуск embedding-сервера
llama-server \
    --model ~/models/nomic-embed-text-v1.5.Q8_0.gguf \
    --host 0.0.0.0 \
    --port 8081 \
    --embedding \
    --ctx-size 2048 \
    --n-gpu-layers 999

# Проверка
curl http://localhost:8081/health
```

Параметры:
- `--embedding` -- обязательный флаг для embedding-режима
- `--ctx-size 2048` -- максимальная длина входного текста (в токенах)
- `--port 8081` -- отдельный порт (8080 занят LLM-сервером)

На Radeon 8060S embedding-модель занимает ~300 MB VRAM и не мешает LLM-серверу.


## API: получение embedding-ов

### Одиночный запрос

```python
import requests


def get_embedding(
    text: str,
    base_url: str = "http://localhost:8081"
) -> list[float]:
    """Получение embedding-а через llama-server."""
    response = requests.post(
        f"{base_url}/v1/embeddings",
        json={
            "input": text,
            "model": "nomic-embed-text"  # Имя не важно для llama-server
        }
    )
    return response.json()["data"][0]["embedding"]


embedding = get_embedding("Квантизация снижает размер модели")
print(f"Размерность: {len(embedding)}")  # 768
```

### Пакетный запрос

```python
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
    # Сортировка по индексу (API может вернуть в другом порядке)
    data.sort(key=lambda x: x["index"])
    return [d["embedding"] for d in data]


# Индексация 100 документов пакетами по 32
batch_size = 32
all_texts = ["документ 1", "документ 2", ...]  # 100 текстов

for i in range(0, len(all_texts), batch_size):
    batch = all_texts[i:i + batch_size]
    embeddings = get_embeddings_batch(batch)
    # Сохранить в vector DB
```

Пакетная обработка в 5-10x быстрее одиночных запросов за счёт GPU-батчинга.


## Prefix instruction

Некоторые модели (e5, gte-Qwen2) требуют prefix -- инструкцию перед текстом.
Prefix отличается для документов (при индексации) и запросов (при поиске).

```python
# Модели семейства e5
doc_prefix = "passage: "      # Для документов при индексации
query_prefix = "query: "      # Для запросов при поиске

# Индексация
doc_embedding = get_embedding(doc_prefix + "FastAPI -- веб-фреймворк")

# Поиск
query_embedding = get_embedding(query_prefix + "как создать REST API")
```

```
Модель            | Нужен prefix | Документ      | Запрос
------------------|--------------|---------------|---------------
nomic-embed-text  | Да (опцион.) | search_document: | search_query:
bge-large         | Нет          | --            | --
e5-large-v2       | Да           | passage:      | query:
gte-Qwen2         | Да           | --            | Instruct: ...
bge-m3            | Нет          | --            | --
```

Неправильный prefix снижает качество retrieval на 10-30%.
При использовании через llama-server prefix нужно добавлять вручную.


## Нормализация

Нормализация -- приведение вектора к единичной длине (L2 norm = 1).
После нормализации cosine similarity = dot product, что ускоряет поиск.

```python
import numpy as np


def normalize(embedding: list[float]) -> list[float]:
    """L2-нормализация вектора."""
    vec = np.array(embedding)
    norm = np.linalg.norm(vec)
    if norm == 0:
        return embedding
    return (vec / norm).tolist()
```

Большинство embedding-моделей возвращают уже нормализованные вектора.
Если нет -- нормализовать перед записью в vector DB.


## Визуализация embedding-пространства

Embedding-пространство многомерное (768+), но можно спроецировать в 2D
для визуальной оценки кластеров документов.

```python
from sklearn.manifold import TSNE
import matplotlib.pyplot as plt


def visualize_embeddings(
    embeddings: list[list[float]],
    labels: list[str],
    output_path: str = "embeddings_2d.png"
):
    """Проекция embedding-ов в 2D через t-SNE."""
    tsne = TSNE(n_components=2, random_state=42, perplexity=min(30, len(embeddings) - 1))
    coords = tsne.fit_transform(embeddings)

    plt.figure(figsize=(12, 8))
    plt.scatter(coords[:, 0], coords[:, 1], alpha=0.6)
    for i, label in enumerate(labels):
        plt.annotate(label[:30], (coords[i, 0], coords[i, 1]), fontsize=7)
    plt.title("Embedding space (t-SNE)")
    plt.savefig(output_path, dpi=150)
    print(f"Сохранено: {output_path}")
```

Если документы одной темы группируются на графике -- embedding-модель
хорошо различает темы. Если всё "размазано" -- модель плохо подходит
для ваших данных.


## Выбор модели для русского языка

Большинство embedding-моделей обучены преимущественно на английском.
Для русскоязычных документов критично выбрать мультиязычную модель.

### Рекомендации

```
Приоритет | Модель                | Почему
----------|----------------------|-----------------------------------
1         | bge-m3               | Лучший баланс: RU + EN, 1024D, 2.2 GB
2         | gte-Qwen2-1.5B       | Максимальное качество RU, 1536D, 3 GB
3         | multilingual-e5-large| Хорошее RU, 1024D, 1.1 GB (легче)
4         | nomic-embed-text     | Приемлемое RU, 768D, 274 MB (прототип)
```

### Тест на русском

Простой способ оценить модель на русском тексте:

```python
# Тестовые пары (похожие и далёкие)
pairs = [
    ("Как настроить CI/CD?", "Инструкция по деплою через GitLab"),  # Похожие
    ("Как настроить CI/CD?", "Рецепт борща"),                       # Далёкие
    ("Квантизация модели", "Снижение размера через GGUF Q4"),       # Похожие
    ("Квантизация модели", "Погода в Москве"),                      # Далёкие
]

for text_a, text_b in pairs:
    emb_a = get_embedding(text_a)
    emb_b = get_embedding(text_b)
    sim = cosine_similarity(np.array(emb_a), np.array(emb_b))
    print(f"{sim:.3f}  {text_a[:30]} <-> {text_b[:30]}")

# Хорошая модель: похожие пары > 0.7, далёкие < 0.4
```


## Связанные статьи

- <-- [RAG: обзор](README.md)
- --> [Vector Databases](vector-databases.md)
- [Квантизация](../quantization.md) -- размеры GGUF-моделей
