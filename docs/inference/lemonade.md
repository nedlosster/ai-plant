# Lemonade: local inference с NPU-ускорением для Ryzen AI

Платформа: Radeon 8060S (gfx1151, RDNA 3.5), XDNA 2 NPU (50 TOPS INT8), 120 GiB unified memory. Эта статья -- профиль проекта Lemonade: архитектура, hybrid NPU/iGPU-исполнение, ONNX Runtime GenAI, Quark-квантизация, текущее состояние на Linux и применимость на нашей платформе.

Контекст: на Strix Halo сейчас основной inference-стек -- [llama.cpp](llama-cpp.md) + [LM Studio](lm-studio.md) на Vulkan backend. NPU (XDNA 2) в этом стеке **не используется** -- из 50 TOPS INT8 тензорного железа на чипе мы эксплуатируем только iGPU. Lemonade -- это проект, который пытается это изменить.

## Содержание

- [Что это и откуда](#что-это-и-откуда)
- [Зачем нужна третья inference-обёртка](#зачем-нужна-третья-inference-обёртка)
- [Архитектура: ONNX Runtime GenAI + llama.cpp + гибридный планировщик](#архитектура-onnx-runtime-genai--llamacpp--гибридный-планировщик)
- [Hybrid execution: prefill на NPU, decode на iGPU](#hybrid-execution-prefill-на-npu-decode-на-igpu)
- [Модели: AMD-оптимизированные чекпоинты](#модели-amd-оптимизированные-чекпоинты)
- [Quark и AWQ-квантизация](#quark-и-awq-квантизация)
- [Три режима работы: Hybrid / NPU / Generic](#три-режима-работы-hybrid--npu--generic)
- [API и CLI](#api-и-cli)
- [Экосистема: GAIA, FastFlowLM, Tiny Agents](#экосистема-gaia-fastflowlm-tiny-agents)
- [На нашей платформе: что работает, что нет](#на-нашей-платформе-что-работает-что-нет)
- [Сравнение с llama.cpp, Ollama, LM Studio](#сравнение-с-llama-cpp-ollama-lm-studio)
- [Критика и ограничения](#критика-и-ограничения)
- [Будущее: когда Lemonade станет актуален на Strix Halo Linux](#будущее-когда-lemonade-станет-актуален-на-strix-halo-linux)
- [Связанные статьи](#связанные-статьи)

---

## Что это и откуда

**Lemonade** -- open-source inference-сервер для локальных LLM с поддержкой **AMD Ryzen AI NPU (XDNA/XDNA 2)** через гибридный NPU+iGPU режим. Репозиторий: [github.com/lemonade-sdk/lemonade](https://github.com/lemonade-sdk/lemonade). Официальный сайт: [lemonade-server.ai](https://lemonade-server.ai). PyPI пакет: `lemonade-sdk`.

Проект **позиционируется как community-driven**, но фактически AMD Engineering даёт основную часть коммитов и оптимизаций. Релизы идут через GitHub, но AMD также включает Lemonade в свой Ryzen AI Software Stack и продвигает его через [AMD Developer Resources](https://www.amd.com/en/developer/resources/technical-articles/2026/lemonade-for-local-ai.html).

Первый публичный релиз -- 2024, после того как AMD выпустила Ryzen AI 300-серию (Strix Point) с XDNA 2 NPU. На апрель 2026 проект активно развивается: поддерживает Ryzen AI 300/400 (Strix Point, **Strix Halo**, Kraken Point), дискретные GPU через ROCm, и CPU fallback.

Ключевое отличие от [llama.cpp](llama-cpp.md) и [Ollama](ollama.md): **Lemonade -- единственный open-source inference-стек, который умеет гнать LLM через NPU**. Это не косметическая фича: на NPU модель работает **в десятки раз энергоэффективнее**, чем на iGPU, и фундаментально меняет расклад для мобильного inference.

## Зачем нужна третья inference-обёртка

Логичный вопрос: у нас уже есть llama.cpp (универсальный), Ollama (docker-стиль), LM Studio (GUI). Зачем ещё один стек?

Короткий ответ: **чтобы использовать NPU**. Длинный -- ниже.

### Проблема: 50 TOPS лежат без дела

Ryzen AI Max+ 395 (Strix Halo) содержит три вычислителя:
- **CPU (Zen 5)** -- 16 ядер, ~500 GFLOPS FP32
- **iGPU (Radeon 8060S, RDNA 3.5)** -- 40 CU, ~30 TFLOPS FP16
- **NPU (XDNA 2)** -- 32 AI Engine tiles, **50 TOPS INT8** (**~2.5x** больше чем у iGPU на INT8)

Если запускать inference через llama.cpp Vulkan backend, мы используем только iGPU. NPU спит. Это означает:
- **~30% неиспользованной вычислительной мощности чипа** (в INT8)
- **потеря energy efficiency**: NPU по tokens/J значительно эффективнее iGPU на малых моделях

### Идеальный сценарий

Распределить работу так, чтобы каждый вычислитель делал то, в чём он силён:

| Фаза inference | Характер нагрузки | Что требуется | Кому отдать |
|----------------|-------------------|---------------|-------------|
| **Prefill (обработка промпта)** | Compute-bound | INT8/FP16 matmul на big batch | **NPU** -- 50 TOPS INT8 |
| **Decode (генерация токенов)** | Memory-bound | Чтение всех весов на каждый токен | **iGPU** -- 256 GB/s bandwidth |

**Prefill** -- это перемножение матриц большого размера (весь промпт за раз). Здесь выигрывает железо с высоким compute throughput. NPU заточен под это: tensor units стройными рядами молотят матрицы в INT8.

**Decode** -- это чтение всех весов модели из памяти для генерации ОДНОГО токена. Процесс memory-bound: скорость ограничена bandwidth памяти. NPU тут не поможет -- ему тоже нужно читать веса, а bandwidth у него не больше чем у iGPU (они используют одну и ту же LPDDR5).

Lemonade реализует именно такое разделение. На профиль нагрузки накладывается железная архитектура:

```
Промпт → ... 2000 токенов ... →  [NPU: batch matmul] → embeddings
                                         |
                                         v
                      [iGPU: sequential matmul per token] → токен 1
                                         |
                                         v
                             [iGPU: per token] → токен 2
                                         ...
                             [iGPU: per token] → токен 200
```

### Компромисс: энергоэффективность vs peak throughput

Важный нюанс: **Lemonade не всегда быстрее alternatives**. Официальная документация AMD честно признаёт:

> Hybrid NPU+iGPU execution on Ryzen AI 300 series optimizes power efficiency. ROCm is still faster for use cases that prioritize prefill speed (time-to-first-token). Vulkan continues to be favorable on Strix Halo in particular.

То есть hybrid-режим оптимизирован под **ватты**, а не под **tok/s**. Если задача -- максимальная скорость на plugged-in десктопе, то [Vulkan backend в llama.cpp](vulkan-llama-cpp.md) выигрывает. Hybrid через NPU имеет смысл на **ноутбуке от батареи**, где важно затратить как можно меньше энергии на те же токены.

На Strix Halo в desktop-конфигурации (наша платформа -- mini PC Meigao MS-S1 MAX, от сети) этот компромисс в основном работает против Lemonade. Но для Ryzen AI 365 в ноутбуке или для edge-устройств Lemonade становится единственным разумным выбором.

## Архитектура: ONNX Runtime GenAI + llama.cpp + гибридный планировщик

Lemonade -- это **не новый inference-движок**. Как Ollama, это **метастек**, обёртка вокруг нескольких существующих движков. Под капотом:

```
                       +-------------------------+
                       |   lemonade-server [Py]  |
                       |   OpenAI-compat API     |
                       |   :8000/api/v0          |
                       +-----------+-------------+
                                   |
                    +--------------+-----------------+
                    |                                |
                    v                                v
       +---------------------------+  +-----------------------------+
       |  ONNX Runtime GenAI (OGA) |  |  llama.cpp (vendored)       |
       |  - ONNX .onnx формат      |  |  - GGUF формат              |
       |  - EP: VitisAI (NPU)      |  |  - CPU / Vulkan / ROCm      |
       |  - EP: DirectML / CUDA    |  |                             |
       |  - EP: CPU                |  |                             |
       +------------+--------------+  +----------+------------------+
                    |                            |
        +-----------+----------+                 |
        |           |          |                 |
        v           v          v                 v
     +-----+   +---------+  +---+         +-------------+
     | NPU |   | iGPU    |  |CPU|         | CPU / GPU   |
     | XDNA|   | RDNA3.5 |  |AVX|         | (for GGUF)  |
     +-----+   +---------+  +---+         +-------------+
```

### Два backend'а в одном сервере

Lemonade может загружать модель через **два разных движка** в зависимости от её формата:

1. **ONNX Runtime GenAI (OGA)** -- для моделей в формате `.onnx` с `genai_config.json`. Это путь через VitisAI Execution Provider, который и даёт доступ к NPU
2. **llama.cpp** (vendored, как в Ollama) -- для моделей в формате GGUF. Путь через Vulkan, ROCm или CPU, без NPU

Ключ: **NPU-ускорение доступно ТОЛЬКО через ONNX path**. GGUF через llama.cpp внутри Lemonade работает, но не использует NPU. Это означает, что для прироста от NPU нужны специально подготовленные модели -- см. следующий раздел.

### ONNX Runtime GenAI: зачем он нужен

**ONNX Runtime GenAI** (далее OGA) -- библиотека от Microsoft для generative-inference поверх стандартного ONNX Runtime. Она добавляет:

- Токенизация и detokenization (включает tokenizer внутри ONNX-графа)
- KV-cache management (persistent state между forward pass'ами)
- Sampling (top-k, top-p, temperature, beam search)
- Continuous batching (частично)
- Высокоуровневый API `Generator.generate()`

Без OGA раб с ONNX-моделями для LLM был бы кошмаром: пришлось бы самому управлять KV-cache, вручную токенизировать, считать логиты, сэмплить. OGA делает всё это поверх ONNX Runtime, сохраняя совместимость с разными Execution Providers (EP).

### VitisAI Execution Provider

**VitisAI EP** -- это execution provider для ONNX Runtime, разработанный AMD. Он умеет запускать ONNX-операции на XDNA NPU через Vitis AI Runtime (`xrt`). При загрузке ONNX-графа провайдер:

1. Парсит граф
2. Выделяет подграфы, поддерживаемые NPU (обычно большие matmul, conv)
3. Компилирует их в binary для XDNA (используя компилятор Vitis AI)
4. Остальное оставляет на CPU через стандартный CPU EP

То есть тот же **hybrid compute как в llama.cpp**, но на уровне ONNX Runtime и NPU. Когда модель загружается через OGA + VitisAI EP, решение "что где считать" принимает не Lemonade, а сам VitisAI. Lemonade только говорит: "вот ONNX файл, сервери".

## Hybrid execution: prefill на NPU, decode на iGPU

Это главный технический трюк Lemonade и самая интересная часть архитектуры. Разберёмся подробнее.

### Что такое hybrid mode

"Hybrid" в терминологии Lemonade означает **загрузку двух версий модели одновременно**:
- **Prefill graph** -- ONNX-модель, скомпилированная под NPU (через VitisAI EP). Принимает большой batch токенов, выдаёт вектор скрытого состояния + начальный KV-cache
- **Decode graph** -- ONNX-модель, скомпилированная под iGPU (через DirectML EP на Windows или CPU fallback). Принимает один токен + KV-cache, выдаёт следующий логит

Они загружаются как **два OGA sessions** одной модели, но шарят KV-cache. Scheduler переключается между ними:

```
Request: "Объясни квантизацию"

1. Tokenize: [842, 123, 4567, 2891, 5612] (5 токенов)

2. Prefill на NPU:
   - NPU получает все 5 токенов разом
   - Выполняет 32 attention layers в одном batch matmul
   - Возвращает: [hidden_state_5, kv_cache_partial]
   - Время: ~50 ms (быстро из-за compute-efficient NPU)

3. Decode на iGPU, по одному токену:
   - Token 1: iGPU reads kv_cache + hidden, produces token_1, time: ~10 ms
   - Token 2: iGPU reads kv_cache (+1) + hidden, produces token_2, time: ~10 ms
   - ...
   - Token 200: ..., time: ~10 ms
   - Total decode: 200 * 10 = 2000 ms

4. Detokenize → stream to client
```

Для сравнения, на чистом iGPU prefill тех же 5 токенов занимает ~30 ms (iGPU лучше на малых prefill'ах), но на 2000 токенов prefill разница становится существенной: ~1500 ms на iGPU vs ~200 ms на NPU -- **NPU в 7x быстрее на длинных промптах**.

### Почему decode не на NPU

Казалось бы, раз NPU так быстр на matmul -- давайте decode тоже на NPU. Но это не работает по нескольким причинам:

1. **Batch size = 1 для decode**. NPU spec'нут на максимальную утилизацию параллелизма: tiles, systolic arrays, load/store units одновременно. При batch=1 полностью задействовать это железо не получится -- большинство tiles простаивают
2. **Memory bandwidth bottleneck**. Decode -- это memory-bound фаза: нужно перечитать ВСЕ веса модели для КАЖДОГО токена. NPU подключён к тем же LPDDR5-8000 (256 GB/s), что и iGPU. Bandwidth одинаков -- значит decode будет с той же скоростью на обоих, но iGPU при этом не требует специального ONNX-графа
3. **Latency switching**. Перенос KV-cache между NPU memory и iGPU memory дорог (даже в unified memory нужна pagetable sync и cache flush). Дешевле держать decode на одном устройстве

Отсюда разделение: NPU для prefill (compute-heavy, один раз на запрос), iGPU для decode (memory-heavy, много раз на запрос).

### Результат в цифрах (из официальных benchmarks AMD)

Для Llama-3.1-8B Instruct в AWQ int4 на Ryzen AI 9 HX 370 (Strix Point):

| Backend | TTFT (prefill 512 tok) | tg (tok/s) | Питание |
|---------|------------------------|------------|---------|
| CPU AVX-512 | ~2500 ms | ~6 | ~25W |
| iGPU Vulkan | ~450 ms | ~22 | ~35W |
| iGPU DirectML | ~500 ms | ~20 | ~35W |
| **NPU+iGPU Hybrid** | **~180 ms** | **~21** | **~15W** |

TTFT (time to first token) на hybrid **в 2.5x быстрее** чем на iGPU alone благодаря NPU prefill. Decode скорость **такая же** (iGPU делает и там, и там). Но energy per token -- в 2-3 раза меньше.

На **Strix Halo** (наша платформа, Ryzen AI Max+ 395) эти цифры не проверены официально -- AMD пока не публиковала benchmarks для Strix Halo с Lemonade, так как Linux-поддержка XDNA 2 ограничена. См. ниже раздел "На нашей платформе".

## Модели: AMD-оптимизированные чекпоинты

NPU не запускает произвольную модель. Для hybrid-режима нужен **специально подготовленный ONNX-файл**, который VitisAI EP сможет скомпилировать под XDNA. AMD публикует такие чекпоинты в своём [HuggingFace organization](https://huggingface.co/amd).

Именование: `amd/<model-name>-awq-g128-int4-asym-fp16-onnx-hybrid`

Расшифровка:
- **`awq`** -- квантизация методом Activation-aware Weight Quantization (Lin et al. 2023)
- **`g128`** -- group size 128 (масштаб применяется на группы по 128 элементов)
- **`int4`** -- 4-битные веса
- **`asym`** -- asymmetric quantization (zero-point, не фиксированный в нуле)
- **`fp16`** -- активации и вычисления в FP16
- **`onnx`** -- формат контейнера
- **`hybrid`** -- подготовлено для NPU+iGPU hybrid режима (два графа внутри)

### Официально поддерживаемые модели (AMD HF checkpoints, апрель 2026)

| Модель | Размер | HF checkpoint |
|--------|--------|---------------|
| Phi-3 Mini Instruct | 3.8B | `amd/Phi-3-mini-4k-instruct-awq-g128-int4-asym-fp16-onnx-hybrid` |
| Phi-3.5 Mini Instruct | 3.8B | `amd/Phi-3.5-mini-instruct-awq-g128-int4-asym-fp16-onnx-hybrid` |
| Llama-2 7B Chat | 7B | `amd/Llama-2-7b-chat-hf-awq-g128-int4-asym-fp16-onnx-hybrid` |
| Llama-3.2 1B Instruct | 1B | `amd/Llama-3.2-1B-Instruct-awq-g128-int4-asym-fp16-onnx-hybrid` |
| Llama-3.2 3B Instruct | 3B | `amd/Llama-3.2-3B-Instruct-awq-g128-int4-asym-fp16-onnx-hybrid` |
| Qwen 1.5 7B Chat | 7B | `amd/Qwen1.5-7B-Chat-awq-g128-int4-asym-fp16-onnx-hybrid` |
| Mistral 7B Instruct v0.3 | 7B | `amd/Mistral-7B-Instruct-v0.3-awq-g128-int4-asym-fp16-onnx-hybrid` |

**Что обращает на себя внимание**: это всё модели 2023-2024. Нет Qwen3, Qwen3-Coder, Llama 3.3/4, Gemma 3/4, DeepSeek. Это связано с тем, что для каждой новой модели AMD должен:

1. Обновить Quark toolchain под новую архитектуру (attention-варианты, RoPE scaling, GQA patterns)
2. Сконвертировать в ONNX через OGA exporter
3. Квантизовать через AWQ
4. Протестировать на NPU
5. Опубликовать на HF

Это занимает **недели-месяцы на модель**. Отсюда lag: новая модель доступна через llama.cpp за 1-2 недели, в Ollama за 2-4, в Lemonade для NPU -- через 1-3 месяца.

В апреле 2026 AMD обещает "day 0 support для Gemma 4 E2B/E4B" -- но для NPU-режима эта поддержка приходит "with the next Ryzen AI SW update", то есть позже дня релиза Gemma 4.

### Свои ONNX-модели

Технически можно взять любую HF-модель и прогнать её через Quark + ONNX exporter. На практике это **нетривиально**: требуется Linux-машина с CUDA (для экспорта), знание specifics модельной архитектуры, часы калибровки AWQ. Community-tooling для этого существует, но не на уровне `ollama pull`.

Для массового использования проще подождать, пока AMD опубликует официальный чекпоинт.

### GGUF через Lemonade (без NPU)

Альтернатива: можно запустить любую GGUF-модель (Qwen3, Llama 4, Devstral 2 -- что угодно с HuggingFace) через Lemonade, но она пойдёт **через llama.cpp-путь без NPU**. Это даёт OpenAI-compatible API, но без уникальной ценности Lemonade (hybrid NPU). В таком режиме Lemonade = тот же llama-server, только с другим CLI.

## Quark и AWQ-квантизация

**AMD Quark** -- собственный toolkit AMD для квантизации моделей под NPU. Репозиторий: [github.com/amd/Quark](https://github.com/amd/Quark) (публичный с 2024). Quark делает:

- **AWQ** (Activation-aware Weight Quantization) -- алгоритм, который при квантизации учитывает распределение активаций и защищает salient weights (те, через которые проходят большие значения). Популярен в vLLM, llama.cpp, GPTQ-экосистеме
- **Post-training quantization (PTQ)** с калибровочным датасетом
- **Mixed-precision**: разные слои могут быть в разных битах
- **ONNX export** с учётом ограничений NPU (поддерживаемые операции)
- **Группирование по g128** (группы по 128 элементов имеют общий scale/zero_point)

### Почему AWQ, а не K-quants

llama.cpp использует [K-quants](llama-cpp.md#квантизация----визитная-карточка) (собственная разработка Kawrakow), которые дают лучшую perplexity при том же bpw. Но K-quants тесно завязаны на ggml tensor format и CPU/GPU compute shaders. **NPU не умеет K-quants**: у XDNA нет нативных операций для "двухуровневого scaling c 6-битными sub-block scales".

AWQ проще для hardware: один scale + zero-point на группу 128, прямая dequantization перед INT8 matmul. Это легко ложится на NPU dataflow.

Компромисс: perplexity AWQ на 0.05-0.15 хуже чем Q4_K_M того же bpw (по публичным benchmarks), но это разменивается на возможность исполнения на NPU. Для 3-8B моделей разница практически незаметна в выводе.

## Три режима работы: Hybrid / NPU / Generic

Lemonade (и построенный на нём GAIA) поддерживает три режима установки:

### 1. Hybrid Mode (основной use case)

- Требует Ryzen AI 300/400 series (Strix Point, **Strix Halo**, Kraken Point)
- NPU используется для prefill
- iGPU (или dGPU через ROCm) используется для decode
- Модели: AMD ONNX checkpoints (`*-onnx-hybrid`)
- Максимальная производительность + energy efficiency

### 2. NPU-only Mode (в разработке)

- Всё на NPU, без iGPU
- Максимальная energy efficiency
- Ограничение: bandwidth и decode-скорость ниже, поэтому пригодно только для малых моделей (до 3B)
- Статус на апрель 2026: **coming soon** (в документации AMD GAIA)

### 3. Generic Mode (fallback)

- Для Windows PC без Ryzen AI NPU (Intel, старые AMD, NVIDIA)
- Lemonade **делегирует работу Ollama**: под капотом запускается ollama server, Lemonade только транслирует API-запросы
- Это означает что Lemonade может работать как **унифицированный клиент**: один и тот же код на разных машинах, где-то с NPU, где-то без

## API и CLI

### Запуск сервера

```bash
# После pip install lemonade-sdk
python -m lemonade.server --host 0.0.0.0 --port 8000

# Или через lemonade CLI
lemonade-server serve
```

### OpenAI-compatible API

По умолчанию сервер слушает на `127.0.0.1:8000/api/v0`. Эндпоинты совместимы с OpenAI:

```python
from openai import OpenAI

llm = OpenAI(base_url="http://localhost:8000/api/v0", api_key="none")

response = llm.completions.create(
    model="Llama-3.2-3B-Instruct-Hybrid",
    prompt="What is the capital of the moon?"
)
print(response.choices[0].text)
```

Streaming тоже работает:

```python
response = llm.completions.create(
    model="Llama-3.2-3B-Instruct-Hybrid",
    prompt="Explain quantization in one paragraph",
    stream=True
)
for chunk in response:
    print(chunk.choices[0].text, end="", flush=True)
```

### CLI для управления моделями

```bash
# Список установленных моделей
lemonade-server list

# Скачать модель с HuggingFace
lemonade-server pull amd/Llama-3.2-3B-Instruct-awq-g128-int4-asym-fp16-onnx-hybrid

# Запустить сервер с конкретной моделью
lemonade-server serve --model Llama-3.2-3B-Instruct-Hybrid --device hybrid

# Информация о NPU
lemonade-server info --device
```

## Экосистема: GAIA, FastFlowLM, Tiny Agents

### GAIA

**GAIA** ([github.com/amd/gaia](https://github.com/amd/gaia)) -- full-stack generative AI framework от AMD, построенный поверх Lemonade Server. Предоставляет:

- Windows installer `gaia-windows-setup.exe` -- в один клик ставит Lemonade + модели + UI
- Chat UI (voice + text)
- RAG pipeline поверх локальных документов
- Agent framework (Blender agent, Clip agent, Joker agent и другие demo)
- Whisper для распознавания речи, TTS для синтеза

GAIA -- это **продукт для конечных пользователей**, а Lemonade -- backend, на котором он работает. Всё что делает GAIA, можно сделать напрямую через Lemonade API + Open WebUI, но GAIA упаковывает опыт в один установщик.

### FastFlowLM

**FastFlowLM** -- другой community-проект (не AMD), который использует Lemonade как backend для своих моделей. Специализация: streaming, low-latency inference на NPU. В релизе 2026 добавили поддержку Qwen2.5-VL-3B-Instruct. Связь с Lemonade: FastFlowLM использует Lemonade API, AMD включает FastFlowLM-оптимизации в официальные релизы Lemonade.

### Tiny Agents

**[Tiny Agents](https://huggingface.co/learn/mcp-course/en/unit2/lemonade-server)** -- курс от HuggingFace о создании локальных AI-агентов на базе MCP (Model Context Protocol). Отдельная секция посвящена использованию Lemonade Server как backend'а с NPU-ускорением. Показательный use case: агенты на ноутбуке с Ryzen AI работают от батареи часами, чего нельзя достичь с llama.cpp на iGPU.

## На нашей платформе: что работает, что нет

Наша платформа -- Meigao MS-S1 MAX с **AMD Ryzen AI Max+ 395 (Strix Halo)**, Ubuntu 24.04. В теории это целевое железо для Lemonade. На практике есть серьёзные ограничения.

### XDNA 2 NPU на Linux: статус

NPU-чип на Strix Halo -- **XDNA 2** (50 TOPS INT8, 32 AI Engine tiles). Linux-поддержка через проект [amd/xdna-driver](https://github.com/amd/xdna-driver):

| Компонент | Статус | Примечание |
|-----------|--------|------------|
| `amdxdna` kernel driver | **в mainline с 6.14** | Обнаруживает устройство, создаёт `/dev/accel0` |
| Вендерный userspace `xrt` | публичный | Требует сборки из исходников |
| VitisAI ONNX EP для Linux | **экспериментальный** | Не все операции поддерживаются на Linux |
| Lemonade Server Linux + NPU | **не проверен в production** | AMD не публикует официальные Linux-builds |

**Практически**: на апрель 2026 запустить Lemonade hybrid-режим на Linux Strix Halo -- **не готовое решение**. Требуется:
1. Собрать xdna-driver userspace
2. Собрать ONNX Runtime c VitisAI EP из исходников
3. Собрать lemonade-sdk и подружить с вручную собранным OGA
4. Надеяться, что VitisAI EP поддержит операции в нужной модели (часть моделей фейлится с "op not supported")

Это путь для энтузиаста, а не для production. Сравните с `pip install lemonade-sdk` на Windows, где всё просто работает.

См. также [acceleration-outlook.md](acceleration-outlook.md#npu-xdna-2-50-int8-tops) -- там подробный анализ ограничений XDNA на Linux.

### Что можно сделать сейчас

1. **Установить lemonade-sdk в generic mode**: `pip install lemonade-sdk` в venv, запустить сервер, использовать с GGUF-моделями через llama.cpp-путь. Получим ещё один OpenAI-compatible сервер, но без NPU и без уникальной ценности Lemonade. **Не делаем, это дубликат llama-server**.

2. **Отслеживать [релизы xdna-driver](https://github.com/amd/xdna-driver/releases)** и [релизы lemonade](https://github.com/lemonade-sdk/lemonade/releases). Когда VitisAI EP стабилизируется на Linux -- можно будет попробовать реально.

3. **В сценарии Linux ↔ Windows**: если есть вторая машина с Windows + Ryzen AI (например, ноутбук HP Zbook Ryzen AI 9 HX), можно запустить Lemonade там и использовать его API с Linux как внешний backend через LAN. Это даёт доступ к NPU, не требуя Linux-ковыряний. Но наш сервер -- всё-таки Linux-only, так что это скорее мысленный эксперимент.

### Текущий практический вердикт

На Strix Halo Linux **в апреле 2026 Lemonade практически не работает для своего главного use case -- NPU ускорения**. Это не недостаток проекта, а следствие того, что AMD ещё не довёл Linux-стек для XDNA 2 до production. Ожидание: **Q3-Q4 2026**, когда ROCm 7.3 или 8.0 интегрируют VitisAI EP и Lemonade получит официальные Linux-builds для Strix Halo.

До этого основной inference-стек остаётся на [llama.cpp](llama-cpp.md) + Vulkan.

## Сравнение с llama.cpp, Ollama, LM Studio

| Параметр | Lemonade | llama.cpp | Ollama | LM Studio |
|----------|----------|-----------|--------|-----------|
| **Язык** | Python (server) + C++ (OGA) | C/C++ | Go + cgo | Closed-source |
| **Inference engine** | ONNX RT GenAI + llama.cpp | собственный (ggml) | vendored llama.cpp | vendored llama.cpp |
| **Поддержка NPU** | **да (XDNA / XDNA 2)** | нет | нет | нет |
| **Поддержка GPU** | iGPU/dGPU через ROCm, DirectML, Vulkan | CUDA/ROCm/Metal/Vulkan/SYCL | тот же что llama.cpp | Vulkan (main) |
| **Поддержка CPU** | да | флагман | да (через llama.cpp) | да (через llama.cpp) |
| **Формат моделей** | ONNX (для NPU) + GGUF (для GPU/CPU) | GGUF | GGUF + OCI blob layers | GGUF |
| **Доступных моделей для NPU** | ~7 официальных (Phi, Llama 3.2, Qwen 1.5, Mistral) | нет NPU | нет NPU | нет NPU |
| **Доступных моделей для GPU/CPU** | любая GGUF с HuggingFace | любая GGUF | ollama.com/library + GGUF | GGUF browser |
| **Формат квантизации** | AWQ int4 (ONNX) + K-quants (GGUF) | K-quants, IQ-quants | K-quants (через llama.cpp) | K-quants (через llama.cpp) |
| **Hybrid prefill/decode split** | **да (NPU+iGPU)** | нет | нет | нет |
| **Speculative decoding** | частично | да | да | да |
| **Concurrent models** | да | через отдельные процессы | да | нет |
| **API** | OpenAI-compat | native + OpenAI-compat | native + OpenAI-compat | OpenAI-compat |
| **Linux support** | экспериментальный | полный | полный | полный |
| **Windows support** | **флагман** | да | да | да (флагман GUI) |
| **Production-ready на Ryzen AI** | Windows да, Linux нет | да (через Vulkan) | да | да |
| **Energy efficiency (mobile)** | **лучший** | базовый | ~базовый | ~базовый |
| **Peak throughput (desktop)** | средний | **лучший на Strix Halo** | ~llama.cpp | ~llama.cpp |

### Когда выбирать Lemonade

- **Ноутбук с Ryzen AI от батареи**: energy efficiency -- ключевой фактор. NPU даёт в 2-3x лучше tokens/J чем iGPU
- **Edge-устройства с Ryzen AI Embedded**: там NPU часто -- единственный компонент с реальным AI compute
- **Разработка под Ryzen AI ecosystem**: демки, агенты, продукты, которые потом пойдут на Ryzen AI ноутбуки массово
- **Когда важны модели в ONNX формате**: если основная разработка уже на ONNX Runtime (enterprise ML-стеки), интеграция с Lemonade упрощена

### Когда НЕ выбирать Lemonade (на нашей платформе)

- **Максимальный throughput на Strix Halo desktop**: Vulkan llama.cpp быстрее, AMD сама это признаёт
- **Новейшие модели**: Lemonade NPU-caталог отстаёт на 1-3 месяца
- **Linux сервер**: Lemonade Linux stack для NPU не production-ready

## Критика и ограничения

### 1. Фрагментация моделей

Lemonade не работает с каталогом HuggingFace моделей в целом -- только с теми, что конкретно конвертированы AMD в ONNX hybrid. Это ~7 моделей, все 2023-2024 года. Для сравнения, llama.cpp поддерживает сотни GGUF из коробки.

### 2. Lag от новых архитектур

Новая модельная архитектура (например, Qwen3-Next с hybrid Mamba/Transformer) требует:
1. Поддержки операции в ONNX Runtime (несколько недель)
2. Поддержки в VitisAI EP для NPU (несколько недель)
3. AMD должен обновить Quark и сделать AWQ-квантизацию (несколько недель)
4. Публикацию на HF (день)

Итого: 2-3 месяца от модели до NPU-поддержки. llama.cpp обычно успевает за 1 неделю.

### 3. AWQ vs K-quants compromise

AWQ int4 даёт perplexity на 0.05-0.15 хуже чем Q4_K_M. Для серьёзных coding-задач (Qwen3-Coder Next) это может быть заметно. Но Qwen3-Coder Next всё равно нет в NPU-каталоге AMD, так что этот trade-off в основном теоретический.

### 4. Generic mode = Ollama wrapper

В режиме без NPU Lemonade делегирует всё Ollama. Это означает, что Lemonade-сервер на машине без Ryzen AI -- просто proxy над Ollama. Возникает вопрос: зачем он нужен тогда? Ответ: **унифицированный клиент-код**, который на одной машине использует NPU, а на другой -- Ollama, без знания deployment-контекста.

### 5. Linux support не production

Как отмечено выше -- на Linux Strix Halo Lemonade NPU-режим требует ручной сборки и не стабилен. AMD сама рекомендует Windows как основную платформу для Ryzen AI development.

### 6. Python сервер

В отличие от llama.cpp (C++) и Ollama (Go), Lemonade сервер -- на Python. Это добавляет:
- Зависимость от CPython interpreter (~30 MB)
- Более медленный startup (~3-5 сек vs ~500 ms для Ollama)
- Больший memory footprint (~200 MB базы vs ~50 MB для llama-server)

Для datacenter это неважно, но для edge (Ryzen AI IoT boards) уже ощутимо.

### 7. Нет multi-GPU tensor parallelism

Lemonade не умеет шардировать модель между двумя дискретными GPU или комбинировать iGPU + dGPU для одной модели. Для 100B+ моделей это критично, для 8B -- не важно. Ryzen AI платформы всё равно редко имеют multi-GPU, так что это концептуальный лимит.

## Будущее: когда Lemonade станет актуален на Strix Halo Linux

Суммируя ожидания:

| Срок | Событие | Что меняется |
|------|---------|--------------|
| **Q2 2026** | Gemma 4 E2B/E4B NPU support (Ryzen AI SW 1.4+) | Первая серьёзная новая модель в NPU-каталоге |
| **Q3 2026** | VitisAI EP for Linux stable | Reproducible builds, less manual steps |
| **Q3-Q4 2026** | ROCm 7.3/8.0 с integrated XDNA support | Единый runtime для iGPU+NPU |
| **Q4 2026** | Lemonade official Linux builds для Strix Halo | Можно будет ставить как `pip install` без самосборки |
| **2027** | Qwen3 / Llama 4 в NPU-каталоге | Relevance на уровне llama.cpp |

До этого llama.cpp + Vulkan -- основной выбор, Lemonade -- watch list.

### Что мониторить

- [lemonade-sdk/lemonade releases](https://github.com/lemonade-sdk/lemonade/releases) -- еженедельно
- [amd/xdna-driver](https://github.com/amd/xdna-driver) -- ядро-драйвер XDNA 2
- [amd/Quark](https://github.com/amd/Quark) -- AWQ toolchain updates
- [AMD Ryzen AI Developer blog](https://www.amd.com/en/developer/resources/technical-articles/) -- официальные анонсы
- HuggingFace [amd organization](https://huggingface.co/amd) -- новые ONNX hybrid checkpoints
- `ls /sys/class/accel/accel0 && dmesg | grep amdxdna` -- проверка что NPU виден ядру

## Связанные статьи

- [llama.cpp (профиль проекта)](llama-cpp.md) -- основной inference-движок на нашей платформе
- [Ollama (профиль проекта)](ollama.md) -- альтернативная обёртка, которую Lemonade использует в Generic mode
- [LM Studio](lm-studio.md) -- GUI-обёртка для llama.cpp
- [backends-comparison.md](backends-comparison.md) -- сравнение Vulkan, ROCm, CPU, NPU на Strix Halo
- [acceleration-outlook.md](acceleration-outlook.md) -- перспективы NPU/Vulkan/ROCm на Strix Halo, статус XDNA 2
- [rocm-setup.md](rocm-setup.md) -- установка ROCm, который понадобится для VitisAI EP
- [../platform/server-spec.md](../platform/server-spec.md) -- спецификация XDNA 2 NPU на платформе
- [../llm-guide/quantization.md](../llm-guide/quantization.md) -- AWQ vs K-quants, почему AWQ для NPU
