# LLM Guide -- навигация и обзор

Раздел содержит справочные статьи по теории и практике работы с большими
языковыми моделями (LLM). Материал рассчитан на инженера, впервые
погружающегося в область AI/LLM, и организован по уровням сложности.

Цель раздела: дать системное понимание того, как LLM устроены изнутри,
как генерируют текст, чем отличаются друг от друга и как выбрать
модель и параметры для конкретной задачи. Все примеры привязаны
к конкретной аппаратной платформе (Radeon 8060S, 96 GiB, 256 GB/s)
и inference-серверу (llama-server + Vulkan).


## Содержание

- [Уровни](#уровни)
  - [Уровень 0 -- основы](#уровень-0----основы)
  - [Уровень 1 -- практика](#уровень-1----практика)
  - [Уровень 2 -- продвинутое](#уровень-2----продвинутое)
- [Полная таблица статей](#полная-таблица-статей)
- [Рекомендуемый порядок чтения](#рекомендуемый-порядок-чтения)
- [Карта знаний](#карта-знаний)
- [Связанные разделы](#связанные-разделы)
- [Платформа для примеров](#платформа-для-примеров)
- [Соглашения](#соглашения)
- [Обозначения в тексте](#обозначения-в-тексте)
- [Структура каждой статьи](#структура-каждой-статьи)
- [Глоссарий ключевых терминов](#глоссарий-ключевых-терминов)
- [FAQ: частые вопросы](#faq-частые-вопросы)


## Уровни

Раздел разбит на три уровня. Каждый следующий опирается на материал
предыдущего.


### Уровень 0 -- основы

Минимальный набор знаний для понимания того, как LLM работают внутри.
Без этого уровня дальнейшее чтение бессмысленно.

| Статья | Описание |
|--------|----------|
| [Что такое LLM](what-is-llm.md) | Определение, история, семейства моделей, размеры, open-source vs API |
| [Transformer](transformer.md) | Архитектура: attention, multi-head, feed-forward, positional encoding |
| [Токенизация](tokenization.md) | Как текст превращается в числа: BPE, SentencePiece, словарь, спецтокены |
| [Генерация текста](generation.md) | Авторегрессия, prefill vs decode, memory-bound, KV-cache |
| [Сэмплирование](sampling.md) | Logits, temperature, top-k, top-p, repetition penalty, min-p |
| [Анатомия LLM](model-anatomy.md) | Что внутри модели: параметры, слои, размерности, scaling laws |
| [HuggingFace](huggingface.md) | Как найти, выбрать и загрузить модель. CLI, Spaces, Leaderboard |

#### Что такое LLM (what-is-llm.md)

Стартовая статья раздела. Определяет LLM как нейросеть с миллиардами
параметров, обученную на текстовых данных для предсказания следующего
токена. Рассматривает историю развития от GPT-2 (2019) до DeepSeek-V3
и Llama 4 (2025). Описывает основные семейства open-source моделей:
Llama, Qwen, DeepSeek, Mistral, Gemma -- с характеристиками, лицензиями
и рекомендациями по выбору. Объясняет, что означает "B" в названии
модели, как размер влияет на качество, и какие модели помещаются
на платформу с 96 GiB VRAM.

Ключевые понятия: параметры (веса), pre-training, fine-tuning,
alignment, base model, instruct model, GGUF, VRAM.


#### Transformer (transformer.md)

Объясняет архитектуру Transformer для инженера без ML-бэкграунда.
Начинает с проблемы (RNN были медленными для последовательностей)
и переходит к решению -- механизму attention, который позволяет
каждому токену "смотреть" на все остальные параллельно.

Подробно разбирает:
- Scaled dot-product attention с числовыми примерами
- Self-Attention: Query, Key, Value -- аналогия с поиском в базе данных
- Multi-Head Attention: несколько "голов" смотрят на разные аспекты
- GQA (Grouped Query Attention): оптимизация KV-cache
- Feed-Forward (SwiGLU): обработка каждого токена после attention
- Layer Norm и Residual Connections: стабилизация обучения
- RoPE (Rotary Positional Embedding): кодирование позиции токенов
- Decoder-only архитектура (GPT-стиль)

Включает ASCII-диаграммы transformer block и полной модели.
Таблица параметров для Llama и Qwen разных размеров.

Ключевые понятия: attention, Q/K/V, multi-head, causal mask,
feed-forward, SwiGLU, RMSNorm, residual connections, RoPE,
encoder-decoder, decoder-only.


#### Токенизация (tokenization.md)

Объясняет, как текст преобразуется в числа. Нейросеть работает
с тензорами -- текст сначала разбивается на токены (подслова),
каждому присваивается числовой ID из словаря.

Пошагово разбирает алгоритм BPE (Byte Pair Encoding) на примере.
Сравнивает SentencePiece и tiktoken. Демонстрирует разницу
токенизации для английского, русского, китайского текста и кода.
Показывает, что русский текст в ~1.5 раза "тяжелее" по токенам.

Описывает специальные токены (BOS, EOS, PAD), chat templates
(Llama 3, ChatML, Mistral), FIM-токены для автодополнения кода.
Содержит примеры проверки токенизации через Python (transformers,
tiktoken) и llama-server API.

Ключевые понятия: токен, vocabulary, BPE, SentencePiece, tiktoken,
byte-level BPE, chat template, FIM, специальные токены.


#### Генерация текста (generation.md)

Описывает процесс авторегрессивной генерации: каждый новый токен
зависит от всех предыдущих. Разделяет inference на две фазы:

- Prompt processing (prefill): параллельная обработка всего входа,
  compute-bound. Формирует KV-cache.
- Token generation (decode): последовательная генерация по одному
  токену за шаг, memory-bound.

Объясняет, почему decode ограничен пропускной способностью памяти
(bandwidth), а не вычислительной мощностью GPU. Выводит формулу
`tok/s ~ bandwidth / model_size` с примерами для 256 GB/s.

Описывает KV-cache: зачем нужен, как растёт с контекстом, как
влияет на скорость. Кратко затрагивает speculative decoding
и continuous batching. Таблица tok/s для разных моделей на
Radeon 8060S.

Ключевые понятия: авторегрессия, prefill, decode, compute-bound,
memory-bound, bandwidth, arithmetic intensity, KV-cache,
speculative decoding, continuous batching, TTFT, tok/s.


#### Сэмплирование (sampling.md)

Описывает, как модель выбирает следующий токен из распределения
вероятностей. На каждом decode-шаге модель выдаёт вектор logits
(по одному числу на каждый токен словаря), из которого нужно
выбрать один токен.

Подробно разбирает:
- Logits и Softmax: преобразование "сырых" оценок в вероятности
- Greedy decoding: всегда top-1, детерминированный, скучный
- Temperature: масштабирование логитов, управление "остротой"
  распределения. С формулой и числовыми примерами
- Top-K: фиксированный порог по количеству кандидатов
- Top-P (nucleus sampling): динамический порог по кумулятивной
  вероятности
- Min-P: относительный порог к вероятности top-токена
- Repetition penalty: штраф за повторение уже сгенерированных токенов
- Beam search: параллельный поиск (для перевода, не для chat)

Таблица рекомендуемых параметров по задачам: код (T=0),
chat (T=0.7, P=0.9), creative (T=1.0, P=0.95), перевод (T=0.3).
Связь с параметрами llama-server.

Ключевые понятия: logits, softmax, temperature, top-k, top-p,
min-p, repetition penalty, frequency penalty, presence penalty,
beam search, greedy decoding, seed.


### Уровень 1 -- практика

Знания, необходимые для осознанного выбора модели и настройки inference.

| Статья | Описание |
|--------|----------|
| [Контекстное окно](context-window.md) | Размеры, KV-cache, VRAM, RoPE, truncation, sliding window |
| [Архитектуры](architectures.md) | Dense vs MoE, GQA, sparse attention, практические рекомендации |
| [Квантизация](quantization.md) | GGUF, GPTQ, AWQ, влияние на качество и скорость |
| [Системные промпты](system-prompts.md) | Формат, шаблоны чатов, роль system message |
| [Prompt engineering](prompt-engineering.md) | Техники: few-shot, chain-of-thought, structured output |

#### Контекстное окно (context-window.md)

Контекстное окно -- максимум токенов (input + output), которые
модель может обработать за один сеанс. Это главный ограничивающий
ресурс при работе с LLM.

Содержит:
- Таблицу размеров контекстов: от 1K (GPT-2) до 10M (Llama 4 Scout)
- Формулу KV-cache с пошаговыми расчётами
- Таблицу KV-cache по моделям (7B, 13B, 32B, 70B) для контекстов
  4K, 8K, 32K, 128K
- Полный бюджет VRAM: модель + KV-cache + overhead
- Поведение при превышении: truncation, sliding window
- RoPE scaling для длинных контекстов (linear, NTK, YaRN)
- "Lost in the middle": деградация на средних позициях
- Оптимизации: KV-cache quantization, prompt caching, context pruning
- Сценарии для Radeon 8060S: 4 конфигурации с расчётом VRAM

Ключевые понятия: context window, KV-cache, truncation,
sliding window, RoPE scaling, prompt caching, context pruning,
VRAM budget, "lost in the middle".


#### Архитектуры (architectures.md)

Сравнивает Dense и MoE (Mixture of Experts) -- две основные
архитектуры современных LLM.

Dense: все параметры активны на каждый токен. Llama 3.1 70B,
Qwen2.5-Coder-32B. Простая, стабильная, предсказуемая.

MoE: только часть параметров активна. Mixtral 8x7B (47B total,
13B active), DeepSeek-V3 (671B total, 37B active). Больше знаний
при меньших вычислениях, но все эксперты в VRAM.

Разбирает:
- Router: как выбираются эксперты
- Load balancing: равномерное распределение нагрузки
- Trade-offs при равном compute, при равном VRAM
- Скорость: prefill (MoE быстрее) vs decode (зависит от реализации)
- GQA: оптимизация KV-cache (4-16x экономия)
- Sparse Attention: sliding window, dilated, Flash Attention
- MLA (Multi-head Latent Attention): инновация DeepSeek
- Практические рекомендации для Radeon 8060S
- Сводная таблица Dense vs MoE моделей

Ключевые понятия: Dense, MoE, router, expert, active params,
total params, GQA, MQA, sparse attention, Flash Attention,
MLA, expert offloading, load balancing.


### Уровень 2 -- продвинутое

Специализированные темы для конкретных задач.

| Статья | Описание |
|--------|----------|
| [RAG](rag.md) | Retrieval-Augmented Generation: архитектура, embeddings, vector DB |
| [Function calling](function-calling.md) | Tool use, JSON schema, интеграция с внешними системами |
| [Multimodal](multimodal.md) | Vision, audio, объединение модальностей |
| [Локальный запуск vs API](local-vs-api.md) | Сравнение подходов, стоимость, латентность, приватность |


## Полная таблица статей

| # | Статья | Уровень | Объём | Статус |
|---|--------|---------|-------|--------|
| 1 | [Что такое LLM](what-is-llm.md) | 0 | ~660 строк | Написана |
| 2 | [Transformer](transformer.md) | 0 | ~1000 строк | Написана |
| 3 | [Токенизация](tokenization.md) | 0 | ~890 строк | Написана |
| 4 | [Генерация текста](generation.md) | 0 | ~830 строк | Написана |
| 5 | [Сэмплирование](sampling.md) | 0 | ~960 строк | Написана |
| 6 | [Контекстное окно](context-window.md) | 1 | ~840 строк | Написана |
| 7 | [Архитектуры](architectures.md) | 1 | ~850 строк | Написана |
| 8 | [Квантизация](quantization.md) | 1 | ~585 строк | Написана |
| 9 | [Системные промпты](system-prompts.md) | 1 | ~817 строк | Написана |
| 10 | [Prompt engineering](prompt-engineering.md) | 1 | ~1032 строк | Написана |
| 11 | [RAG](rag.md) | 2 | ~1229 строк | Написана |
| 12 | [Function calling](function-calling.md) | 2 | ~1162 строк | Написана |
| 13 | [Multimodal](multimodal.md) | 2 | ~930 строк | Написана |
| 14 | [Локальный запуск vs API](local-vs-api.md) | 2 | ~926 строк | Написана |


## Рекомендуемый порядок чтения

### Основной маршрут (уровень 0 + 1)

Оптимальный маршрут для первого прочтения:

```
1. what-is-llm.md        -- общая картина, семейства моделей
2. transformer.md         -- как устроена модель внутри
3. tokenization.md        -- как текст становится числами
4. generation.md          -- как модель генерирует текст
5. sampling.md            -- как выбирается каждый токен
6. context-window.md      -- главный ресурс, KV-cache, VRAM
7. architectures.md       -- Dense vs MoE, выбор архитектуры
```

Время на прочтение (оценка):
- Каждая статья: 20-40 минут
- Весь маршрут: 3-5 часов

### Быстрый маршрут (для нетерпеливых)

```
1. what-is-llm.md        -- 15 минут, пропустить историю
2. generation.md          -- 15 минут, фокус на формулы tok/s
3. sampling.md            -- 10 минут, таблица рекомендаций
4. context-window.md      -- 10 минут, расчёт VRAM
```

Время: ~1 час. Достаточно для осознанного запуска модели.

### Маршрут "я хочу генерировать код"

```
1. what-is-llm.md        -- обзор, фокус на Qwen2.5-Coder
2. generation.md          -- tok/s, KV-cache
3. sampling.md            -- T=0 для кода, FIM
4. context-window.md      -- VRAM для 32K контекста
5. architectures.md       -- Dense vs MoE для кодирования
```

### Маршрут "я хочу понять теорию"

```
1. what-is-llm.md        -- полностью
2. transformer.md         -- полностью, с формулами
3. tokenization.md        -- полностью, с алгоритмом BPE
4. generation.md          -- полностью
5. sampling.md            -- полностью
```

После прочтения уровня 0 и 1 рекомендуется перейти к практическим
руководствам в разделе [Inference](../inference/README.md).


## Карта знаний

Граф зависимостей между статьями:

```
                    what-is-llm
                    /    |     \
                   /     |      \
          transformer  tokenization  (общие знания)
                |        |
                v        v
              generation             (как работает inference)
              /       \
             v         v
         sampling    context-window  (параметры и ресурсы)
             |         |
             v         v
           architectures             (выбор модели)
             |
             v
         [inference guides]          (практика)
```

Каждая стрелка означает: нижняя статья использует понятия
из верхней. Читать снизу вверх не рекомендуется.


### Матрица зависимостей

```
                     Требует знания из:
                     what  trans  token  gen  samp  ctx  arch
what-is-llm           -     -      -     -    -     -    -
transformer          [v]    -      -     -    -     -    -
tokenization         [v]    -      -     -    -     -    -
generation           [v]   [v]    [v]    -    -     -    -
sampling             [v]    -     [v]   [v]   -     -    -
context-window       [v]   [v]    [v]   [v]   -     -    -
architectures        [v]   [v]     -    [v]   -    [v]   -

[v] = зависимость, - = независимо
```


## Связанные разделы

| Раздел | Содержание | Связь с LLM Guide |
|--------|------------|--------------------|
| [Inference](../inference/README.md) | Практические руководства по запуску моделей | Применение знаний из LLM Guide на практике |
| [Training](../training/README.md) | Fine-tuning, датасеты, методы обучения | Дополняет раздел "обучение" из what-is-llm |
| [Use Cases](../use-cases/README.md) | Конкретные сценарии: код, музыка, изображения | Примеры применения LLM |
| [Models](../models/README.md) | Каталог моделей и их характеристики | Конкретные модели из what-is-llm и architectures |
| [Platform](../platform/) | Описание аппаратной платформы | Hardware для примеров |
| [Glossary](../glossary.md) | Глоссарий терминов | Определения терминов из LLM Guide |


### Связи со статьями inference

| Статья LLM Guide | Связанные статьи inference |
|-------------------|---------------------------|
| generation.md | [benchmarking.md](../inference/benchmarking.md) -- замеры скорости |
| generation.md, architectures.md | [vulkan-llama-cpp.md](../inference/vulkan-llama-cpp.md) -- настройка сервера |
| what-is-llm.md, architectures.md | [model-selection.md](../inference/model-selection.md) -- выбор модели |
| context-window.md | [troubleshooting.md](../inference/troubleshooting.md) -- проблемы с VRAM |


## Платформа для примеров

Все примеры в статьях ориентированы на следующую конфигурацию:

| Параметр | Значение |
|----------|----------|
| GPU | Radeon 8060S |
| Unified VRAM | 96 GiB |
| Bandwidth | 256 GB/s |
| Inference server | llama-server (llama.cpp) |
| Backend | Vulkan |

### Что это означает для примеров

```
96 GiB VRAM:
  - Модели до 70B в Q4_K_M (40 GB) с запасом для контекста
  - Модели до 32B в FP16 (64 GB) с ограниченным контекстом
  - Параллельный запуск нескольких моделей

256 GB/s bandwidth:
  - Потолок скорости decode:
    8B Q4:  ~45 tok/s
    32B Q4: ~11 tok/s
    70B Q4: ~5.5 tok/s
  - Memory-bound для decode (GPU-compute простаивает)

Vulkan backend:
  - Кроссплатформенный, поддерживает AMD и NVIDIA
  - Чуть медленнее CUDA на NVIDIA, единственный вариант для AMD
  - Flash Attention: ограниченная поддержка
```

Подробнее о настройке inference-сервера:
[Vulkan + llama.cpp](../inference/vulkan-llama-cpp.md).


## Соглашения

Единые соглашения для всех статей раздела:

### Единицы измерения

- Размеры моделей указаны в миллиардах параметров (B = billion)
- VRAM указан для квантизации Q4_K_M, если не оговорено иное
- Скорость генерации (tok/s) измерена на Radeon 8060S, 256 GB/s
- Bandwidth указан в GB/s (гигабайтах в секунду, не гигабитах)
- 1 GiB = 1024^3 bytes, 1 GB = 10^9 bytes (различие указывается, где важно)

### Терминология

- "Контекст" и "контекстное окно" -- синонимы
- "Модель" без уточнения -- LLM (не диффузионная модель)
- "Inference" -- процесс генерации текста (не обучение)
- "Веса" и "параметры" -- синонимы
- "VRAM" -- видеопамять GPU (или unified memory)
- "Токен" -- минимальная единица текста для модели

### Код и команды

- Примеры кода даны для llama-server и Python
- Комментарии в коде -- по-русски
- Пути файлов -- абсолютные (от корня проекта)
- Команды llama-server -- для Vulkan backend


## Обозначения в тексте

```
[!] -- важное замечание, влияющее на практику
      Пропускать не рекомендуется.

[?] -- дополнительная информация, можно пропустить при первом чтении
      Для углублённого понимания.

-->  -- переход к следующей статье
<--  -- ссылка на предыдущую статью
```

Пример использования:

```
[!] Русский текст в ~1.5 раза "тяжелее" по токенам, чем английский.
    Контекст заполняется быстрее, inference дороже.

[?] BPE был предложен Gage (1994) для сжатия данных и адаптирован
    для NLP Sennrich et al. (2016).

--> Следующая статья: [Генерация текста](generation.md)
```


## Структура каждой статьи

Каждая статья следует единому шаблону:

```
# Заголовок

Краткое описание (1-2 предложения).

## Содержание
- [Раздел 1](#раздел-1)
- [Раздел 2](#раздел-2)
- ...

## Раздел 1
Основной материал с таблицами и ASCII-диаграммами.

## Раздел N
...

## Связь с платформой
Примеры для Radeon 8060S, команды llama-server.

## Ключевые формулы (справочник)
Сводка формул из статьи.

## Ссылки
- <-- Предыдущая: [...]
- --> Следующая: [...]
- Связанные статьи
```


## Глоссарий ключевых терминов

Краткий справочник терминов, используемых в статьях.
Полный глоссарий: [../glossary.md](../glossary.md).

### A-E

| Термин | Определение | Статья |
|--------|-------------|--------|
| Alignment | Процесс "выравнивания" модели с предпочтениями людей (RLHF, DPO) | what-is-llm |
| Attention | Механизм взвешенного внимания к разным частям входа | transformer |
| Авторегрессия | Генерация по одному токену, каждый зависит от предыдущих | generation |
| Bandwidth | Пропускная способность памяти GPU (GB/s) | generation |
| Base model | Модель после pre-training, без instruct fine-tuning | what-is-llm |
| Beam search | Поиск наиболее вероятной последовательности (несколько "лучей") | sampling |
| BOS / EOS | Begin/End of Sequence -- специальные токены | tokenization |
| BPE | Byte Pair Encoding -- алгоритм построения словаря токенизатора | tokenization |

### D-K

| Термин | Определение | Статья |
|--------|-------------|--------|
| Decode | Фаза генерации: по одному токену за шаг, memory-bound | generation |
| Dense | Архитектура: все параметры активны на каждый токен | architectures |
| d_model | Размерность скрытого состояния Transformer | transformer |
| Expert | Один FFN-блок в MoE-архитектуре | architectures |
| FFN | Feed-Forward Network -- полносвязная сеть после attention | transformer |
| FIM | Fill-in-the-Middle -- режим заполнения пропусков (для кода) | tokenization |
| Flash Attention | Оптимизация attention через тайлинг (не sparse) | architectures |
| GGUF | Формат файла модели для llama.cpp | what-is-llm |
| GQA | Grouped Query Attention -- оптимизация KV-cache | transformer, architectures |
| Greedy decoding | Всегда выбирать самый вероятный токен | sampling |
| Instruct model | Модель, дообученная для следования инструкциям | what-is-llm |
| KV-cache | Хранилище Key/Value для уже обработанных токенов | generation, context-window |

### L-R

| Термин | Определение | Статья |
|--------|-------------|--------|
| Logits | "Сырые" оценки вероятности перед softmax | sampling |
| LM Head | Финальный линейный слой: [d_model] -> [vocab_size] | transformer |
| Memory-bound | Производительность ограничена скоростью чтения из памяти | generation |
| Min-P | Фильтрация: порог относительно top-токена | sampling |
| MLA | Multi-head Latent Attention -- оптимизация DeepSeek | architectures |
| MoE | Mixture of Experts -- частичная активация параметров | architectures |
| Multi-Head | Несколько параллельных attention heads | transformer |
| n_layers | Количество слоёв (блоков) Transformer | transformer |
| Prefill | Фаза обработки промпта: параллельная, compute-bound | generation |
| Q/K/V | Query, Key, Value -- три компонента attention | transformer |
| Repetition penalty | Штраф за повторение уже сгенерированных токенов | sampling |
| RMSNorm | Root Mean Square Normalization -- упрощённая нормализация | transformer |
| RoPE | Rotary Positional Embedding -- кодирование позиции | transformer, context-window |
| Router | Маршрутизатор в MoE: выбирает экспертов для каждого токена | architectures |

### S-V

| Термин | Определение | Статья |
|--------|-------------|--------|
| Self-Attention | Attention, где Q, K, V получены из одного входа | transformer |
| Sliding window | Ограниченное "зрение" attention (W последних токенов) | context-window |
| Softmax | Преобразование logits в вероятности (сумма = 1) | sampling |
| Speculative decoding | Ускорение через draft model | generation |
| SwiGLU | Вариант FFN с гейтированием (Llama, Qwen) | transformer |
| Temperature | Масштабирование logits, управление разнообразием | sampling |
| Tokenizer | Алгоритм преобразования текст <-> token IDs | tokenization |
| tok/s | Токенов в секунду -- метрика скорости decode | generation |
| Top-K | Фильтрация: оставить K наиболее вероятных токенов | sampling |
| Top-P | Фильтрация: оставить токены до кумулятивной P | sampling |
| Truncation | Обрезка контекста при превышении лимита | context-window |
| TTFT | Time to First Token -- задержка до начала ответа | generation |
| Vocabulary | Фиксированный набор всех токенов модели (32K-256K) | tokenization |
| VRAM | Видеопамять GPU (или unified memory) | generation, context-window |


## FAQ: частые вопросы

### Какую модель запустить первой?

Для знакомства: Llama 3.1 8B Instruct Q4_K_M. Занимает 5 GB VRAM,
генерирует ~45 tok/s, поддерживает 128K контекст. Хороший баланс
качества и скорости.

Для кода: Qwen2.5-Coder-32B Instruct Q4_K_M. Занимает 20 GB,
~11 tok/s. Одна из лучших open-source моделей для программирования.

### Сколько VRAM нужно для модели X?

Быстрая формула для Q4_K_M: `VRAM (GB) ~ params (B) * 0.58`.

```
8B  -> ~4.6 GB
13B -> ~7.5 GB
32B -> ~18.6 GB
70B -> ~40.6 GB
```

Плюс KV-cache: см. [context-window.md](context-window.md).

### Почему модель генерирует медленно?

Скорость ограничена bandwidth: `tok/s ~ 256 / model_size_GB`.
Единственные способы ускорить:
- Уменьшить модель (меньше параметров)
- Уменьшить квантизацию (Q4 -> Q3, но теряется качество)
- Speculative decoding (2-4x ускорение)

Подробнее: [generation.md](generation.md).

### Русский текст -- почему дороже?

Русский текст в ~1.5 раза длиннее в токенах, чем английский
(из-за кириллицы в BPE-словаре). Последствия:
- Контекст заполняется быстрее
- Inference дольше (больше токенов на тот же смысл)
- API стоит дороже

Подробнее: [tokenization.md](tokenization.md).

### Temperature 0 или 0.7?

- T=0: для кода, фактов, JSON, классификации (детерминированный)
- T=0.7: для чата, текстов, рассуждений (естественный)

Подробнее: [sampling.md](sampling.md).

### Dense или MoE для моей задачи?

Для Radeon 8060S (256 GB/s bandwidth): Dense предпочтительнее
в большинстве случаев. MoE выгоднее при высоком bandwidth
(>500 GB/s) или когда нужна очень большая модель на кластере.

Подробнее: [architectures.md](architectures.md).


--> Начать чтение: [Что такое LLM](what-is-llm.md)
