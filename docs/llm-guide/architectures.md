# Архитектуры: Dense vs MoE

Современные LLM используют две основных архитектуры:
Dense (все параметры активны на каждый токен) и
MoE (Mixture of Experts -- только часть параметров активна).
Выбор архитектуры определяет баланс между качеством,
скоростью и потреблением VRAM.


## Содержание

- [Dense модели](#dense-модели)
- [MoE: Mixture of Experts](#moe-mixture-of-experts)
- [Как работает MoE](#как-работает-moe)
- [Trade-offs Dense vs MoE](#trade-offs-dense-vs-moe)
- [VRAM и MoE](#vram-и-moe)
- [Скорость: prefill и decode](#скорость-prefill-и-decode)
- [GQA (Grouped Query Attention)](#gqa-grouped-query-attention)
- [Sparse Attention](#sparse-attention)
- [MLA (Multi-head Latent Attention)](#mla-multi-head-latent-attention)
- [Практические рекомендации](#практические-рекомендации)
- [Сводная таблица моделей](#сводная-таблица-моделей)
- [Связь с платформой](#связь-с-платформой)
- [Ссылки](#ссылки)


## Dense модели

### Определение

Dense (плотная) модель -- все параметры задействованы
при обработке каждого токена. Каждый токен проходит
через все слои, все головы attention и все нейроны FFN.

```
Dense model (Llama 3.1 8B):

  Параметры: 8B
  Активные параметры: 8B (100%)

  Токен --> [Attention: все 32 головы] --> [FFN: все 14336 нейронов]
                                             (повторить 32 раза)
  --> Logits
```

### Примеры Dense моделей

| Модель | Параметры | Контекст | Год |
|--------|-----------|----------|-----|
| Llama 3.1 8B | 8B | 128K | 2024 |
| Llama 3.1 70B | 70B | 128K | 2024 |
| Llama 3.1 405B | 405B | 128K | 2024 |
| Qwen2.5-Coder-32B | 32B | 128K | 2024 |
| Qwen2.5-72B | 72B | 128K | 2024 |
| Mistral 7B | 7B | 32K | 2023 |
| Gemma 2 27B | 27B | 128K | 2024 |

### Характеристики Dense

```
Плюсы:
  + Простая архитектура
  + Предсказуемое поведение
  + Стабильное обучение
  + Весь VRAM == все параметры используются
  + Хорошо изучены и отлажены

Минусы:
  - Линейный рост compute с размером модели
  - Для улучшения качества нужно увеличивать ВСЕ параметры
  - 70B модель в 8.75x медленнее 8B (при равном hardware)
```

### Масштабирование Dense

```
Размер   | VRAM (Q4) | tok/s (256 GB/s) | Качество (условно)
---------|-----------|------------------|-------------------
    1B   |   0.8 GB  |     ~200         |     30
    3B   |   2.0 GB  |     ~100         |     45
    8B   |   4.9 GB  |     ~45          |     60
   13B   |   7.5 GB  |     ~30          |     68
   32B   |  19.8 GB  |     ~11          |     78
   70B   |  40.8 GB  |     ~5.5         |     85
  405B   | 230 GB    |     нет          |     92
```

Закономерность: удвоение параметров даёт ~5-10% прироста
качества, но замедляет вдвое.


## MoE: Mixture of Experts

### Определение

MoE (Mixture of Experts) -- архитектура, в которой
каждый токен обрабатывается только подмножеством
параметров модели. FFN-слой разбит на несколько "экспертов",
из которых router активирует лишь 2-4 на каждый токен.

```
MoE model (пример: 8 экспертов, 2 активных):

  Общие параметры: 47B
  Активные параметры: ~13B (на один токен)

  Токен --> [Attention: все головы]
        --> [Router: выбрать 2 из 8 экспертов]
        --> [Expert_3: FFN] + [Expert_7: FFN]
        --> [Суммировать с весами от router]
  --> Logits
```

### Примеры MoE моделей

| Модель | Total params | Active params | Эксперты | Активных | Год |
|--------|-------------|---------------|----------|----------|-----|
| Mixtral 8x7B | 46.7B | 12.9B | 8 | 2 | 2023 |
| Mixtral 8x22B | 141B | 39B | 8 | 2 | 2024 |
| DeepSeek-V2 | 236B | 21B | 160 | 6 | 2024 |
| DeepSeek-V3 | 671B | 37B | 256 | 8 | 2025 |
| DeepSeek-R1 | 671B | 37B | 256 | 8 | 2025 |
| DBRX | 132B | 36B | 16 | 4 | 2024 |
| Llama 4 Scout | MoE | - | - | - | 2025 |
| Qwen3-Coder-Next | ~80B | ~3B | - | - | 2025 |

### Ключевая идея

```
Dense 70B:
  Каждый токен использует все 70B параметров
  Compute: пропорционален 70B
  VRAM: 70B параметров

MoE 8x7B (Mixtral):
  Каждый токен использует ~13B параметров
  Compute: пропорционален 13B     <-- в 5x меньше
  VRAM: 47B параметров             <-- все эксперты в памяти
  Качество: сопоставимо с Dense 13-30B
```

[!] MoE -- это "больше знаний при меньших вычислениях за токен,
но все знания хранятся в VRAM".


## Как работает MoE

### Архитектура MoE-слоя

В MoE-модели attention-слой остаётся стандартным (Dense).
Заменяется только FFN-слой: вместо одного FFN появляется
N экспертов + router.

```
Стандартный Dense блок:        MoE блок:

  +-----------+                  +-----------+
  | Attention |                  | Attention |  (без изменений)
  +-----------+                  +-----------+
       |                              |
       v                              v
  +-----------+                  +-----------+
  |    FFN    |                  |  Router   |  (выбор экспертов)
  |  (один)   |                  +-----------+
  +-----------+                  /   |   |   \
                            +---+ +---+ +---+ +---+
                            |E1 | |E2 | |E3 | |E4 |  (N экспертов)
                            +---+ +---+ +---+ +---+
                               \   /
                            (2 активных)
                                 |
                            +---------+
                            | Сумма   |  (взвешенная)
                            +---------+
```

### Router (маршрутизатор)

Router -- маленькая нейронная сеть, которая для каждого токена
определяет, какие эксперты активировать и с какими весами.

```
Router: x [d_model] --> W_router [d_model, n_experts] --> logits [n_experts]
        --> Top-K --> (expert_indices, expert_weights)

Пример (8 экспертов, Top-2):
  Router logits: [2.1, 0.3, -1.5, 4.2, 0.8, -0.1, 3.7, -2.0]
                                   ^^^               ^^^
                                   E4 (4.2)          E7 (3.7)

  Softmax по выбранным:
    weight_E4 = exp(4.2) / (exp(4.2) + exp(3.7)) = 0.62
    weight_E7 = exp(3.7) / (exp(4.2) + exp(3.7)) = 0.38

  Результат: 0.62 * Expert_4(x) + 0.38 * Expert_7(x)
```

### Каждый эксперт -- обычный FFN

```
Expert_i(x) = W_down_i * (SiLU(W_gate_i * x) * (W_up_i * x))

W_gate_i: [d_model, d_ff]
W_up_i:   [d_model, d_ff]
W_down_i: [d_ff, d_model]

Каждый эксперт -- полноценный FFN (SwiGLU), идентичный по структуре.
Различаются только выученные веса.
```

### Специализация экспертов

При обучении эксперты специализируются на разных типах токенов:

```
Expert 1: код (Python, JavaScript)
Expert 2: математика, формулы
Expert 3: английская проза
Expert 4: имена собственные, факты
Expert 5: русский язык
Expert 6: структурированные данные (JSON, CSV)
Expert 7: инструкции, команды
Expert 8: научные термины

(Упрощённая иллюстрация. Реальная специализация
 размыта и определяется данными обучения.)
```

### Load Balancing

Проблема: router может направлять все токены на 1-2 эксперта,
игнорируя остальные.

```
Плохо (дисбаланс):
  Expert 1: 80% токенов  <-- перегружен
  Expert 2: 15%
  Expert 3: 5%
  Expert 4-8: 0%          <-- простаивают

Хорошо (баланс):
  Expert 1: 13%
  Expert 2: 12%
  Expert 3: 13%
  Expert 4: 12%
  Expert 5: 13%
  Expert 6: 12%
  Expert 7: 12%
  Expert 8: 13%
```

Решение: load balancing loss -- дополнительная функция потерь
при обучении, штрафующая неравномерное распределение.

DeepSeek-V3 использует auxiliary-free load balancing --
без явного loss, через bias-коррекцию router.


## Trade-offs Dense vs MoE

### Сравнение при равном compute

```
Одинаковые вычисления за токен (~13B active params):

  Dense 13B:
    Total params:    13B
    Active params:   13B
    VRAM (Q4):       7.5 GB
    Качество:        68 (условно)

  Mixtral 8x7B (MoE):
    Total params:    47B
    Active params:   13B
    VRAM (Q4):       26 GB        <-- в 3.5x больше
    Качество:        75 (условно)  <-- лучше, т.к. больше знаний

  --> MoE лучше по качеству при равном compute,
      но требует больше VRAM
```

### Сравнение при равном VRAM

```
Одинаковый VRAM (~40 GB в Q4):

  Dense 70B (Q4_K_M):
    Total params:    70B
    Active params:   70B
    VRAM (Q4):       41 GB
    tok/s (256 GB/s): ~5.5
    Качество:        85

  DeepSeek-V3 671B (Q4): не помещается (>300 GB)

  Mixtral 8x22B (Q4):
    Total params:    141B
    Active params:   39B
    VRAM (Q4):       ~80 GB
    tok/s (256 GB/s): ~3
    Качество:        82

  --> Dense лучше по скорости при равном VRAM
      MoE может дать лучшее качество, если помещается
```

### Сводная таблица trade-offs

| Аспект | Dense | MoE |
|--------|-------|-----|
| Compute за токен | Пропорционален total params | Пропорционален active params |
| VRAM | Пропорционален total params | Пропорционален total params |
| tok/s (decode) | bandwidth / model_size | bandwidth / model_size |
| pp tok/s (prefill) | Зависит от total params | Сложнее: зависит от routing |
| Качество vs compute | Хорошее | Лучше (больше "знаний") |
| Качество vs VRAM | Лучше | Хуже (VRAM "тратится" на неактивных) |
| Обучение | Проще | Сложнее (load balancing, routing) |
| Стабильность | Высокая | Могут быть артефакты routing |
| Inference-оптимизация | Проще | Сложнее (динамический routing) |


## VRAM и MoE

### Почему MoE занимает столько же VRAM

Все эксперты хранятся в VRAM, даже если активны только 2 из 8:

```
Mixtral 8x7B:
  Attention (shared):  ~6B параметров
  Expert 1-8:         ~5B * 8 = 40B параметров
  Router:             ~незначительно
  Итого:              ~46.7B параметров

  В Q4_K_M: ~26 GB VRAM

  Активные на токен: 6B (attention) + 5B*2 (experts) = 16B
  Но хранить нужно все 47B!
```

### Сравнение VRAM

```
                    VRAM (Q4_K_M)
                    |
  Dense 13B:        |=======|           7.5 GB
                    |
  MoE 8x7B:        |=====================|   26 GB
  (47B total,       |
   13B active)      |
                    |
  Dense 70B:        |=====================================| 41 GB
                    |
  MoE 671B:         Не помещается в 96 GB (~350 GB)
  (DeepSeek-V3)     |
```

### Expert Offloading

Для MoE-моделей, не помещающихся в VRAM, можно выгружать
неактивных экспертов в RAM:

```
Expert offloading (концептуально):

  GPU VRAM (96 GB):
    - Attention layers (shared): все в VRAM
    - Active experts (2-4): в VRAM
    - Router: в VRAM

  CPU RAM (128+ GB):
    - Неактивные эксперты: в RAM

  Процесс:
    1. Router выбирает экспертов для текущего токена
    2. Нужные эксперты загружаются из RAM в VRAM
    3. Вычисления
    4. Эксперты возвращаются в RAM (или остаются если кэш)

  Скорость: значительно медленнее (PCIe bandwidth << VRAM bandwidth)
```

[!] Expert offloading -- компромисс для запуска моделей,
не помещающихся в VRAM. Скорость падает в 5-20x.
Поддерживается в llama.cpp через `--override-kv`.


## Скорость: prefill и decode

### Decode (token generation)

Для decode ключевой фактор -- чтение весов из памяти.
MoE-модель хранит все эксперты в VRAM, и нужно читать ВСЕ:

```
Dense 13B (Q4):
  Чтение за токен: 7.5 GB
  tok/s = 256 / 7.5 = ~34

MoE 8x7B (Q4):
  Чтение за токен: 26 GB  (все эксперты читаются*)
  tok/s = 256 / 26 = ~10

  * На практике: можно читать только active experts + attention
    Но router нужно прочитать все параметры для маршрутизации
```

[!] Реальная ситуация сложнее. Оптимизированные реализации
могут читать только active experts из VRAM, что ускоряет
decode. Но это зависит от конкретной реализации.

```
Оптимизированный MoE decode:
  Чтение: attention_params + router + 2 * expert_params
  MoE 8x7B: 6B + ~0.01B + 2*5B = ~16B params
  В Q4: ~9 GB
  tok/s = 256 / 9 = ~28  (ближе к Dense 13B)
```

### Prefill (prompt processing)

Для prefill MoE эффективнее: вычисления пропорциональны
active params, а не total params:

```
Dense 70B, prompt 4K:
  Compute: ~2 * 4K * 70B = 560 TFLOPS
  Время: ~5 с

MoE 8x7B (active 13B), prompt 4K:
  Compute: ~2 * 4K * 13B = 104 TFLOPS
  Время: ~1 с

  --> MoE в 5x быстрее на prefill при сопоставимом качестве
```

### Итого по скорости

| Метрика | Dense 70B | MoE 8x7B | Комментарий |
|---------|-----------|----------|------------|
| VRAM (Q4) | 41 GB | 26 GB | MoE меньше |
| Prefill tok/s | ~1800 | ~7000 | MoE быстрее (меньше compute) |
| Decode tok/s | ~5.5 | ~10-28 | MoE быстрее (зависит от оптимизации) |
| Качество | 85 | 75 | Dense лучше при равном VRAM |
| Active params | 70B | 13B | Dense больше "думает" за токен |


## GQA (Grouped Query Attention)

### Суть оптимизации

GQA -- оптимизация attention, не отдельная архитектура.
Вместо отдельных K и V для каждой Q-головы, несколько Q-голов
разделяют одни K и V.

Подробная механика: [transformer.md](transformer.md).

### Влияние на KV-cache

```
MHA (Multi-Head Attention):
  n_heads = 32, n_kv_heads = 32
  KV-cache: n_layers * 32 * head_dim * 2 * ctx * 2 bytes

GQA (Grouped Query Attention):
  n_heads = 32, n_kv_heads = 8   (Llama 3.1 8B)
  KV-cache: n_layers * 8 * head_dim * 2 * ctx * 2 bytes
  Экономия: 4x меньше KV-cache

MQA (Multi-Query Attention):
  n_heads = 32, n_kv_heads = 1
  KV-cache: n_layers * 1 * head_dim * 2 * ctx * 2 bytes
  Экономия: 32x меньше KV-cache
```

### Сравнение для Llama 3.1 70B (32K контекст, FP16)

```
Гипотетический MHA (64 KV-heads):
  KV-cache = 80 * 64 * 128 * 2 * 32768 * 2 = 40 GB

Реальный GQA (8 KV-heads):
  KV-cache = 80 * 8 * 128 * 2 * 32768 * 2 = 5 GB

Экономия: 35 GB VRAM (8x)
```

### GQA-ratio для разных моделей

| Модель | n_heads | n_kv_heads | GQA-ratio | Экономия KV |
|--------|---------|------------|-----------|-------------|
| Llama 2 7B | 32 | 32 | 1:1 (MHA) | Нет |
| Llama 3.1 8B | 32 | 8 | 4:1 | 4x |
| Llama 3.1 70B | 64 | 8 | 8:1 | 8x |
| Llama 3.1 405B | 128 | 8 | 16:1 | 16x |
| Qwen2.5 7B | 28 | 4 | 7:1 | 7x |
| Qwen2.5 72B | 64 | 8 | 8:1 | 8x |
| Mistral 7B | 32 | 8 | 4:1 | 4x |
| Gemma 2 27B | 32 | 16 | 2:1 | 2x |

[!] GQA -- одна из ключевых оптимизаций для длинных контекстов.
Без неё KV-cache для 128K контекста был бы непрактично большим.

Подробнее о KV-cache: [context-window.md](context-window.md).


## Sparse Attention

### Определение

Sparse Attention -- техника сокращения вычислений attention
путём обработки не всех пар токенов, а только подмножества.

```
Full Attention (стандарт):
  Каждый токен "видит" все предыдущие
  Сложность: O(n^2)

Sparse Attention:
  Каждый токен "видит" подмножество предыдущих
  Сложность: O(n * sqrt(n)) или O(n * log(n))
```

### Виды Sparse Attention

```
1. Sliding Window (Mistral):
   Каждый токен видит W ближайших предыдущих

   Позиция -->
   W=4: [####....]   Токен 8 видит 5,6,7,8
        [.####...]   Токен 9 видит 6,7,8,9
        [..####..]   Токен 10 видит 7,8,9,10

2. Dilated (с пропусками):
   Каждый токен видит каждый K-й предыдущий

   [#.#.#.#.]   Видит позиции 1,3,5,7

3. Block Sparse:
   Attention вычисляется для блоков токенов

   [####........]   Блок 1-4
   [....####....]   Блок 5-8
   [........####]   Блок 9-12

4. Combinеd (BigBird, Longformer):
   Sliding window + global tokens + random

   [#G###.....]   G=global, #=local window, .=sparse
```

### Flash Attention

Flash Attention -- не sparse attention, а оптимизация
паттернов доступа к памяти для стандартного full attention.

```
Стандартный Attention:
  1. Вычислить Q*K^T (полная матрица [n,n]) -> записать в HBM
  2. Softmax -> записать в HBM
  3. Умножить на V -> записать в HBM
  Проблема: матрица [n,n] огромна, много записей в память

Flash Attention:
  1. Разбить на блоки (tiles)
  2. Для каждого блока: Q*K^T + softmax + *V -- всё в SRAM (быстрая память)
  3. Объединить результаты блоков
  Результат: не нужно хранить полную матрицу [n,n] в HBM
```

Преимущества Flash Attention:
- Точно тот же результат (не приближение)
- 2-4x ускорение на длинных контекстах
- Меньше VRAM (не нужна матрица [n,n])

```bash
# llama-server с Flash Attention
llama-server --model model.gguf --flash-attn
```

[!] Flash Attention поддерживается в llama.cpp для CUDA.
Для Vulkan поддержка ограничена.


## MLA (Multi-head Latent Attention)

### Определение

MLA -- оптимизация attention, используемая в DeepSeek-V2/V3.
Вместо хранения полных K и V в KV-cache, хранится
сжатое latent-представление.

```
Стандартный GQA:
  KV-cache: [n_kv_heads * head_dim] на токен на слой

MLA:
  KV-cache: [c_kv] на токен на слой
  c_kv << n_kv_heads * head_dim

  K = down_proj(latent)    -- восстановление K из latent
  V = down_proj(latent)    -- восстановление V из latent
```

### Преимущества MLA

```
DeepSeek-V3 (61 слоёв):

  Без MLA (гипотетическое MHA, 128 heads):
    KV-cache (32K, FP16): ~250 GB  (невозможно)

  С GQA (8 KV-heads):
    KV-cache (32K, FP16): ~16 GB

  С MLA:
    KV-cache (32K, FP16): ~2-4 GB  (приблизительно)
    Экономия: 4-8x по сравнению с GQA
```

[!] MLA -- ключевая инновация DeepSeek-V2/V3.
Позволяет работать с длинными контекстами при огромном
количестве параметров.

### Цена MLA

- Дополнительные вычисления на восстановление K,V из latent
- Более сложная реализация
- Менее универсальная оптимизация (специфична для DeepSeek)


## Практические рекомендации

### Выбор архитектуры

```
Решающий вопрос: что ограничивает -- VRAM или скорость?

VRAM ограничен (< 24 GB):
  --> Dense модели оптимальны
  --> 8B Q4 (5 GB) или 13B Q4 (7.5 GB)
  --> MoE нецелесообразен (большой VRAM на неактивные эксперты)

VRAM достаточно (24-48 GB):
  --> Dense или MoE, зависит от задачи
  --> Dense 32B Q4 (20 GB) -- хороший выбор
  --> MoE может быть интересен для скорости

VRAM много (48-96 GB):
  --> Dense 70B Q4 (41 GB) -- максимальное качество
  --> MoE 8x22B (80 GB) -- альтернатива
  --> Radeon 8060S попадает в эту категорию

VRAM огромный (>200 GB, кластер):
  --> DeepSeek-V3 671B -- максимальный open-source
  --> Dense 405B -- если позволяет compute
```

### Рекомендации для Radeon 8060S (96 GiB)

| Задача | Рекомендуемая модель | Архитектура | VRAM | tok/s |
|--------|---------------------|-------------|------|-------|
| Автодополнение кода | Qwen2.5-Coder-3B | Dense | 2 GB | ~100 |
| Чат (быстрый) | Llama 3.1 8B Q4 | Dense | 5 GB | ~45 |
| Код (основная) | Qwen2.5-Coder-32B Q4 | Dense | 20 GB | ~11 |
| Чат (качественный) | Qwen2.5-72B Q4 | Dense | 42 GB | ~5.5 |
| Максимум качества | Llama 3.1 70B Q4 | Dense | 41 GB | ~5.5 |
| Reasoning | DeepSeek-R1-Distill-32B | Dense | 20 GB | ~11 |

[!] Для Radeon 8060S с 256 GB/s bandwidth Dense-модели
предпочтительнее MoE. Причина: при ограниченном bandwidth
скорость определяется total model size (который для MoE
больше при равном качестве). Dense 70B даёт лучшее качество
на потраченный VRAM, чем MoE с таким же VRAM.

### Когда MoE имеет смысл

```
1. Скорость prefill критична:
   MoE обрабатывает prompt быстрее (меньше active params)
   Пример: RAG с длинными документами

2. Compute-bound сценарий:
   GPU с высоким bandwidth и VRAM (A100, H100)
   MoE 671B на кластере -- лучшее качество

3. Expert offloading возможен:
   MoE с 256 экспертами, 8 активных
   На кластере: каждый GPU хранит часть экспертов

4. Дистиллированные MoE:
   Маленькие MoE (Qwen3-Coder-Next ~80B total, ~3B active)
   Могут быть быстрее Dense 3B при лучшем качестве
```


### Dense vs MoE: правило выбора

```
Если VRAM < total_params_MoE * 0.6 bytes:
  --> Dense (MoE не поместится)

Если bandwidth > 500 GB/s:
  --> MoE может быть выгоден (compute-bound)

Если bandwidth < 300 GB/s:
  --> Dense (memory-bound, все параметры MoE в VRAM)

Radeon 8060S (256 GB/s, 96 GiB):
  --> Dense предпочтительнее в большинстве случаев
```


## Сводная таблица моделей

### Dense модели

| Модель | Params | VRAM Q4 | tok/s* | Контекст | Лучше для |
|--------|--------|---------|--------|----------|-----------|
| Llama 3.2 1B | 1.2B | 0.8 GB | ~200 | 128K | Draft model, edge |
| Llama 3.2 3B | 3.2B | 2.0 GB | ~100 | 128K | FIM, автодополнение |
| Llama 3.1 8B | 8.0B | 4.9 GB | ~45 | 128K | Chat, универсальная |
| Qwen2.5-Coder-7B | 7.6B | 4.5 GB | ~48 | 128K | Код (средний) |
| Mistral 7B | 7.3B | 4.4 GB | ~48 | 32K | Chat, быстрая |
| Qwen2.5 14B | 14.8B | 9.0 GB | ~24 | 128K | Баланс |
| Gemma 2 27B | 27.2B | 16 GB | ~14 | 128K | Компактная мощная |
| Qwen2.5-Coder-32B | 32.5B | 19.8 GB | ~11 | 128K | Код (лучшая OS) |
| DeepSeek-R1-Distill-32B | 32.8B | 20 GB | ~11 | 128K | Reasoning |
| Llama 3.1 70B | 70.6B | 40.8 GB | ~5.5 | 128K | Макс. качество |
| Qwen2.5-72B | 72.7B | 42 GB | ~5.3 | 128K | Мультиязычная |

### MoE модели

| Модель | Total | Active | VRAM Q4 | tok/s* | Контекст |
|--------|-------|--------|---------|--------|----------|
| Mixtral 8x7B | 46.7B | 12.9B | 26 GB | ~10 | 32K |
| Mixtral 8x22B | 141B | 39B | 80 GB | ~3 | 64K |
| DeepSeek-V3 | 671B | 37B | ~350 GB | - | 128K |
| DeepSeek-R1 | 671B | 37B | ~350 GB | - | 128K |

*tok/s -- приблизительная скорость decode на Radeon 8060S (256 GB/s)

### Визуальное сравнение

```
VRAM (Q4_K_M) vs Качество (условное):

  Качество
    |
 95 |                                            * DeepSeek-V3 (350 GB)
    |
 90 |                                   * 405B
    |
 85 |                         * 70B/72B
    |
 80 |               * 32B     * Mixtral 8x22B
    |
 75 |        * 14B   * Mixtral 8x7B
    |
 70 |  * 8B
    |
 60 |* 3B
    +--+-------+-------+-------+-------+-----> VRAM (GB)
       2      10      20      40      80
```


## Связь с платформой

### Рекомендуемые конфигурации для Radeon 8060S

```bash
# Быстрый кодинг: Qwen2.5-Coder-32B
llama-server \
    --model Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf \
    --gpu-layers 99 \
    --ctx-size 32768 \
    --port 8080

# VRAM: 20 + 4 + 2 = ~26 GB
# tok/s: ~11
# Свободно: ~70 GB

# Максимальное качество: Llama 3.1 70B
llama-server \
    --model Llama-3.1-70B-Instruct-Q4_K_M.gguf \
    --gpu-layers 99 \
    --ctx-size 16384 \
    --port 8080

# VRAM: 41 + 2.5 + 2 = ~45 GB
# tok/s: ~5.5
# Свободно: ~51 GB

# Speculative decoding: 70B + 1B draft
llama-server \
    --model Llama-3.1-70B-Instruct-Q4_K_M.gguf \
    --model-draft Llama-3.2-1B-Instruct-Q8_0.gguf \
    --gpu-layers 99 \
    --gpu-layers-draft 99 \
    --ctx-size 8192 \
    --draft-max 8 \
    --port 8080

# VRAM: 41 + 1 + 1.3 + 2 = ~45 GB
# tok/s: ~8-15 (ускорение speculative)
```

Подробнее: [Vulkan + llama.cpp](../inference/vulkan-llama-cpp.md),
[Выбор модели](../inference/model-selection.md).


## Ключевые формулы (справочник)

```
Dense модель:
  Compute за токен: ~2 * total_params FLOPS
  VRAM: total_params * bytes_per_param
  tok/s: bandwidth / model_size

MoE модель:
  Compute за токен: ~2 * active_params FLOPS
  VRAM: total_params * bytes_per_param (все эксперты)
  tok/s: bandwidth / model_size (если все в VRAM)
       или bandwidth / active_size (оптимизированный)

GQA KV-cache:
  Экономия: n_heads / n_kv_heads (по сравнению с MHA)

Размер эксперта:
  expert_params = 3 * d_model * d_ff (SwiGLU)
  total_expert_params = n_experts * expert_params
```


## Ссылки

- <-- Предыдущая: [Контекстное окно](context-window.md)
- [Что такое LLM](what-is-llm.md) -- обзор семейств моделей
- [Transformer](transformer.md) -- базовая архитектура, GQA
- [Генерация текста](generation.md) -- prefill vs decode, bandwidth
- [Контекстное окно](context-window.md) -- KV-cache и VRAM
- [Inference: Vulkan + llama.cpp](../inference/vulkan-llama-cpp.md)
- [Inference: выбор модели](../inference/model-selection.md)
- [Inference: бенчмарки](../inference/benchmarking.md)
