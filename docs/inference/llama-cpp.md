# llama.cpp: inference-движок, ставший стандартом индустрии

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти), llama.cpp собран с Vulkan + ROCm. Эта статья -- профиль самого проекта: история, архитектура, GGML, GGUF, квантизации, бэкенды, llama-server, экосистема.

Настройка платформенных бэкендов -- в [vulkan-llama-cpp.md](vulkan-llama-cpp.md), [rocm-llama-cpp.md](rocm-llama-cpp.md), [cpu-inference.md](cpu-inference.md). Сравнение backend'ов -- в [backends-comparison.md](backends-comparison.md).

## Содержание

- [Что это и откуда](#что-это-и-откуда)
- [Weekend-проект, захвативший индустрию](#weekend-проект-захвативший-индустрию)
- [Философия дизайна](#философия-дизайна)
- [GGML: tensor library под капотом](#ggml-tensor-library-под-капотом)
- [GGUF: что внутри квантизованного файла](#gguf-что-внутри-квантизованного-файла)
- [Квантизация -- визитная карточка](#квантизация----визитная-карточка)
- [Backends: восемь путей к железу](#backends-восемь-путей-к-железу)
- [KV-cache: память под контекст](#kv-cache-память-под-контекст)
- [llama-server: production HTTP API](#llama-server-production-http-api)
- [Continuous batching и slots](#continuous-batching-и-slots)
- [Speculative decoding](#speculative-decoding)
- [Multimodal, function calling, grammars](#multimodal-function-calling-grammars)
- [Экосистема форков и обёрток](#экосистема-форков-и-обёрток)
- [Сравнение с vLLM, TGI, TensorRT-LLM](#сравнение-с-vllm-tgi-tensorrt-llm)
- [На нашей платформе](#на-нашей-платформе)
- [Связанные статьи](#связанные-статьи)

---

## Что это и откуда

**llama.cpp** -- inference-движок для трансформерных языковых моделей, написанный на C/C++. Автор -- Георги Герганов (Georgi Gerganov, Bulgaria). Репозиторий: [github.com/ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp).

На момент апреля 2026 llama.cpp -- **де-факто стандарт локального inference**. Через него (или его форки) проходят:
- Все пользователи LM Studio, Ollama, KoboldCpp, text-generation-webui (один движок в основе)
- Большинство open-source моделей в формате GGUF скачаны через HuggingFace и запущены через llama.cpp
- ACE-Step, whisper.cpp, stable-diffusion.cpp -- весь ggml-семейство построено на том же tensor library

Проект существует чуть больше трёх лет, но уже стал «kernel'ом» огромной экосистемы. Это уникальный случай, когда weekend-хобби одного человека захватило нишу индустрии на фоне вливания миллиардов в vLLM, TGI, TensorRT-LLM.

## Weekend-проект, захвативший индустрию

**10 марта 2023**. Утечка весов Llama 1 с torrent'а Meta, всего через 10 дней после анонса модели. Веса попали в open-source неделю назад, но все существующие inference-решения требовали мощных NVIDIA A100 и Python-стеков. У обычного разработчика нет H100 в домашней лаборатории.

Георги Герганов начинает эксперимент: написать inference для Llama на чистом C/C++, **без внешних зависимостей**, чтобы модель запускалась на MacBook. Основа -- его же библиотека [ggml](https://github.com/ggml-org/ggml), которую он писал для whisper.cpp (port OpenAI Whisper на C++ для запуска на Apple M-серии).

К вечеру **11 марта 2023** первый коммит llama.cpp: модель запускается на Apple Silicon через Accelerate framework. За неделю -- квантизация в INT4, работа на x86 CPU, поддержка macOS + Linux. За месяц -- ARM NEON оптимизации, Metal backend для Apple GPU, Windows. За два месяца -- CUDA backend.

К концу 2023 -- llama.cpp уже проксирует большинство open-source inference-решений. Причина: **минимальные требования к железу, максимальная переносимость, простота сборки**. Любой разработчик может склонировать репо, набрать `make`, и через 2 минуты запустить 7B-модель на ноутбуке.

К 2026 репозиторий насчитывает **90000+ звёзд** на GitHub, **1200+ контрибьюторов**, и тысячи коммитов в месяц. Проект перешёл под организацию `ggml-org` с корпоративным спонсорством от Llamafile, HuggingFace и других.

## Философия дизайна

llama.cpp построен на нескольких жёстких принципах, которые объясняют и сильные стороны, и ограничения:

### 1. Zero dependencies (почти)

Единственные обязательные зависимости -- стандартная библиотека C/C++ и компилятор. Опциональные: CMake, BLAS, CUDA, Metal, HIP, Vulkan, SYCL -- но всё через условную компиляцию. Можно собрать llama.cpp в **~500 KB бинарник** без единой внешней ссылки.

Это принципиальная противоположность vLLM / TGI, которые тянут весь стек PyTorch + CUDA + NCCL + tokenizers + FlashAttention (~15 GB зависимостей).

### 2. CPU-first, GPU-second

Проект начинался как CPU-inference для MacBook. Все оптимизации сначала делаются для CPU (SIMD, cache-aware), потом для GPU. Это привело к отличной поддержке **slow-hardware**: модели 70B запускаются на Raspberry Pi 5 и старых Xeon.

Побочный эффект: llama.cpp плохо масштабируется на multi-GPU кластеры (нет ring-allreduce, нет tensor parallelism в классическом смысле). Для 8x H100 выбор -- vLLM, а llama.cpp остаётся для single-machine.

### 3. Graph-based computation

В llama.cpp вычисления организованы как **compute graph**: тензоры связаны операциями (matmul, add, softmax, rope, norm), граф строится один раз и исполняется для каждого токена. Это позволяет:
- Считать размеры памяти заранее (arena allocator)
- Подменять backend на уровне операций
- Проверять корректность: тот же граф можно прогнать на CPU и GPU и сравнить

### 4. Static memory allocation

Весь computation buffer выделяется одной большой ареной на старте. В runtime нет вызовов `malloc`. Это делает inference predictable (никаких page faults из-за фрагментации) и позволяет точно знать VRAM footprint заранее.

### 5. Header-only helper libraries

Многие помощники оформлены как header-only, чтобы встраиваться в один `.cpp`:
- **minja** -- Jinja2 parser для chat templates (собственная реализация, без внешнего yaml/libjinja2)
- **httplib** -- HTTP-сервер для llama-server (от yhirose, single-header)
- **nlohmann/json** -- JSON парсер
- **ggml** -- tensor library (тоже фактически header-only для минимальной сборки)

Итог: один бинарник без ad-hoc зависимостей запускается на любой машине.

## GGML: tensor library под капотом

**ggml** -- собственный tensor engine Герганова, который **не является** wrapper'ом над BLAS или cuBLAS. Это самостоятельная библиотека с собственными:

- **Tensor type system**: FP32, FP16, BF16, Q4_0, Q5_0, Q8_0, Q2_K, Q3_K, Q4_K, Q5_K, Q6_K, Q8_K, IQ1_S, IQ2_XXS, IQ3_XXS, IQ4_NL, ...
- **Graph builder**: `ggml_mul_mat`, `ggml_add`, `ggml_rope`, `ggml_soft_max`, `ggml_rms_norm`, `ggml_flash_attn_ext`, ...
- **Backend abstraction**: `ggml_backend_t` -- интерфейс, под который пишутся CPU/CUDA/Metal/Vulkan/HIP реализации
- **Scheduler**: `ggml_backend_sched` -- раскладывает граф по backend'ам, копирует тензоры между ними

### Backend abstraction

В ggml backend -- это объект с VTable:

```c
struct ggml_backend_i {
    const char * (*get_name)(ggml_backend_t backend);
    void         (*free)(ggml_backend_t backend);
    // выделение памяти
    ggml_backend_buffer_type_t (*get_default_buffer_type)(ggml_backend_t backend);
    // вычисление
    void (*set_tensor_async) (...);
    void (*get_tensor_async) (...);
    void (*synchronize)      (...);
    // граф
    ggml_status (*graph_compute)(ggml_backend_t backend, ggml_cgraph * cgraph);
    bool (*supports_op)(ggml_backend_t backend, const ggml_tensor * op);
    // ...
};
```

Ключевой метод -- `supports_op()`. Он вызывается для **каждой операции графа**: может ли данный backend её выполнить? Если нет -- scheduler назначит операцию другому backend'у (обычно CPU) и вставит копирование тензоров между device'ами.

На практике это означает **гибридное вычисление**. Пример: на платформе Strix Halo большая часть операций идёт через Vulkan на iGPU, но некоторые экзотические операции (например, `ggml_conv_2d` для CLIP-encoder'а vision-моделей) могут фолбэкнуться на CPU. Scheduler делает это прозрачно.

### Allocator: arena + static planning

Перед началом inference ggml проходит по графу и **планирует время жизни** каждого промежуточного тензора. Если `tensor_A` нужен только до операции 42, а `tensor_B` появляется после операции 42, их можно разместить в одной памяти. Это называется **tensor reuse**.

Результат: VRAM footprint предсказуем, аллокаций в runtime нет, никакого garbage collection. Как побочный эффект, `llama-bench` и `llama-server` могут точно сказать сколько памяти займёт модель до её загрузки.

## GGUF: что внутри квантизованного файла

**GGUF** (GGML Universal Format) -- бинарный формат для хранения моделей, заменивший старый GGML/GGJT (v1, v2). Версия 3 -- актуальная на 2026.

Файл GGUF состоит из трёх секций:

```
+----------------------------------+
|  HEADER                          |
|  magic = "GGUF" (0x47475546)     |
|  version = 3                     |
|  tensor_count                    |
|  metadata_kv_count               |
+----------------------------------+
|  METADATA (KV pairs)             |
|  general.architecture = "qwen3"  |
|  general.name = "Qwen3-32B"      |
|  general.license = "apache-2.0"  |
|  tokenizer.ggml.model = "gpt2"   |
|  tokenizer.ggml.tokens = [...]   |
|  qwen3.context_length = 131072   |
|  qwen3.embedding_length = 5120   |
|  qwen3.block_count = 64          |
|  qwen3.attention.head_count = 40 |
|  qwen3.rope.freq_base = 1000000  |
|  ...                             |
+----------------------------------+
|  TENSOR INFO                     |
|  name | dims | type | offset     |
|  "blk.0.attn_q.weight" | [5120,5120] | Q4_K | 0 |
|  "blk.0.attn_k.weight" | [5120,1024] | Q4_K | 6.5M |
|  ...                             |
+----------------------------------+
|  TENSOR DATA (aligned)           |
|  raw bytes, 32-byte aligned      |
|  (mmapped в memory at runtime)   |
+----------------------------------+
```

### Что важно в GGUF v3

1. **Self-describing**: файл содержит всё необходимое для загрузки модели -- архитектуру, размерности, токенизатор, chat template, метаданные -- без внешнего `config.json`.

2. **mmap-friendly**: tensor data aligned по 32 байтам, читается через `mmap(MAP_PRIVATE)`. Модель **не копируется в RAM** -- страницы подгружаются лениво по мере доступа. Это ключ к быстрому старту даже для 70B-моделей.

3. **Metadata как KV-store**: все гиперпараметры -- не жёсткая схема, а KV-pairs. Поддерживаются все типы: int8/16/32/64, uint*, bool, string, array, nested. Это позволило добавлять новые архитектуры (Mamba, Mamba2, RWKV, DeepSeek MLA, Gemma sliding window) без ломки формата.

4. **Tokenizer внутри**: словарь, merges (для BPE), chat template в Jinja2 -- всё в одном файле. Не нужно отдельно качать `tokenizer.json`.

5. **Byte order**: little-endian. Есть редкие варианты для big-endian систем (s390x), но на ARM/x86/RISC-V всегда LE.

### Где посмотреть

```bash
# GGUF parser в llama.cpp
./gguf-dump qwen3-coder-next-q4km.gguf
```

Выводит header, metadata, все тензоры с их типами и размерами. Полезно для отладки: можно проверить `general.architecture`, `rope.freq_base`, есть ли у модели `mmproj` (vision).

## Квантизация -- визитная карточка

Без квантизации llama.cpp не была бы нужна -- FP16 70B-модели требуют 140 GiB VRAM, что делает их недоступными для consumer-железа. Герганов сделал квантизацию **первоклассным гражданином**: она не навешана поверх, а встроена в ggml tensor types.

См. глубокое погружение в [quantization.md](../llm-guide/quantization.md). Здесь -- самые интересные внутренности.

### Base quantizations: Q4_0, Q4_1, Q5_0, Q5_1, Q8_0

Самая простая схема (март 2023):
- Блоки по **32 элемента** тензора
- Каждому блоку назначается `float16 scale` (для `_0` типов) или `float16 scale + float16 min` (для `_1`)
- Элементы хранятся как signed int4/int5/int8 (зависит от типа)

Формула декодирования:
```
float val = scale * int_val  (для Q4_0)
float val = scale * int_val + min  (для Q4_1)
```

Зачем блоки по 32? Это размер SIMD-регистра (AVX2, NEON) и warp'а (GPU). Один SIMD-инструкция dequantizes целый блок за цикл.

### K-quants: Q2_K, Q3_K, Q4_K, Q5_K, Q6_K (июнь 2023)

Серьёзный шаг. Авторство -- [Kawrakow](https://github.com/ikawrakow) (псевдоним ikawrakow, ключевой contributor llama.cpp по квантизациям). Идея: **два уровня scaling**.

- **Суперблок** из **256 элементов** (= 8 блоков по 32)
- Суперблок хранит `float16 d` (master scale) и `float16 dmin` (master min)
- Внутри суперблока 8 subblocks, каждый со своим **6-bit quantized scale** и **6-bit quantized min**
- Биты собственно значений: 2 (Q2), 3 (Q3), 4 (Q4), 5 (Q5), 6 (Q6)

Итого для Q4_K:
- `d`, `dmin` = 4 байта (2 + 2)
- 8 subblock scales + 8 subblock mins = 12 байт (8 * 12 bit = 96 bit = 12 байт)
- 256 * 4 bit = 128 байт значений
- Итого: **144 байта на 256 элементов = 4.5 bpw**

Двойной scaling даёт **существенно лучшую perplexity** при том же bpw: subblock-level calibration ловит локальные пики в распределении весов. Это объясняет суффиксы:
- `Q4_K_S` (small) -- только K-quant, самый компактный
- `Q4_K_M` (medium) -- K-quant + FP16 для attention weights (увеличивает качество с минимальным оверхедом)
- `Q4_K_L` (large) -- K-quant + Q6_K для attention (ещё лучше качество)

`_M` и `_L` -- это **mixed precision**: критичные для качества веса (Q/K/V проекции и output) квантуются точнее, чем feed-forward.

### IQ-quants: IQ1_S, IQ1_M, IQ2_XXS, IQ2_XS, IQ2_S, IQ2_M, IQ3_XXS, IQ3_S, IQ3_M, IQ4_NL, IQ4_XS (ноябрь 2023+)

Ещё глубже. Тоже Kawrakow. Главная идея: **lookup-based quantization** + **importance matrix**.

- Значения не хранятся напрямую, а **кодируются индексами** в заранее вычисленную таблицу константных значений (кодбук). Типичная таблица: 256 или 512 4D-векторов.
- **Imatrix** (importance matrix) -- это статистика активаций, собранная с калибровочного датасета (обычно wikitext или pile). Веса, через которые чаще проходят большие активации, получают больший вес в функции потерь при квантизации.

Результат: IQ2_XXS даёт perplexity **сравнимую с Q3_K при вдвое меньшем bpw** (2.06 bpw против 3.5). Это позволяет запустить Llama-70B в 18 GB вместо 40.

Минус: IQ-quants медленнее на CPU (чтение из lookup-таблицы ломает cache line prefetch), но на GPU разница меньше.

### Практика: что выбирать

На платформе Strix Halo 120 GiB -- памяти достаточно для `Q4_K_M` практически любой модели до 122B. IQ-варианты нужны только когда модель не влезает:

- **Kimi K2.5 (1T MoE)** в `IQ1_M` -- 240 GiB (всё равно не влезает, используется через API)
- **DeepSeek V3.2 (671B)** в `IQ2_XXS` -- 180 GiB (не влезает)
- **Qwen3.5-397B MoE** в `IQ4_XS` -- 210 GiB (не влезает)

Для помещающихся моделей (до 122B) Q4_K_M даёт лучшее качество при приемлемом размере. См. [quantization.md](../llm-guide/quantization.md#таблица-моделей-для-96-gib-vram).

## Backends: восемь путей к железу

К апрелю 2026 llama.cpp поддерживает восемь backend'ов, каждый со своей спецификой:

| Backend | Железо | Статус | Примечания |
|---------|--------|--------|------------|
| **CPU** | x86_64 / ARM / RISC-V | стабильно, флагман | AVX2/AVX-512/BF16/VNNI, NEON, SVE, MSA (MIPS), POWER9 |
| **CUDA** | NVIDIA GPU (CC 5.0+) | стабильно, флагман | FlashAttention, tensor cores, multi-GPU |
| **Metal** | Apple M1/M2/M3/M4/M5 | стабильно, флагман | Shader-based, unified memory |
| **ROCm/HIP** | AMD GPU (gfx8+) | стабильно | Тот же CUDA-код через HIP, hipify |
| **Vulkan** | Любой GPU с Vulkan 1.2+ | стабильно, самый универсальный | SPIR-V compute shaders, coopmat2 |
| **SYCL** | Intel GPU (Arc, Xe) | стабильно | oneAPI, OpenCL 3.0 |
| **CANN** | Huawei Ascend NPU | экспериментальный | Для китайского enterprise |
| **RPC** | Remote inference | экспериментальный | Запуск модели на удалённой машине |

### CPU-backend: не просто fallback

CPU в llama.cpp -- **не второсортный** backend. На машинах без GPU он держит основную нагрузку. Оптимизации:
- **AVX-512 VNNI** (Zen 5, Ice Lake+) для INT8 GEMM
- **AVX-512 BF16** (Zen 4+) для bfloat16
- **AVX-512 FP16** (Tiger Lake+)
- **ARM NEON i8mm** (Cortex-A710+) -- аналог VNNI для ARM
- **ARM SVE/SVE2** (Neoverse V1, Apple M4)
- **BLAS integration**: OpenBLAS, Intel MKL, Apple Accelerate -- опционально

На Ryzen AI Max+ 395 с AVX-512 BF16 CPU-inference даёт 8-12 tok/s на 7B-моделях -- медленнее GPU, но достаточно для fallback. См. [cpu-inference.md](cpu-inference.md).

### Vulkan: тёмная лошадка

Изначально Vulkan backend воспринимался как «лучше чем ничего» для владельцев Intel / AMD на Linux. К 2026 он стал **конкурентом ROCm и CUDA** на многих классах задач.

Причины:
- **coopmat2** (cooperative matrix version 2) -- расширение Vulkan 1.4, даёт доступ к matrix cores напрямую. На AMD RDNA3/3.5, NVIDIA Ampere+, Intel Xe это ~2-3x ускорение matmul.
- **Zero-driver-dependency**: работает на любом GPU с Mesa или проприетарным Vulkan driver. На Strix Halo (gfx1151) Vulkan через Mesa работает лучше чем ROCm из коробки.
- **SPIR-V**: шейдеры компилируются в платформо-независимый байт-код, кэшируются. Нет долгого «первого запуска» как на JIT-CUDA.

На платформе Strix Halo Vulkan опережает HIP на 26-57% в token generation. См. [backends-comparison.md](backends-comparison.md).

### Hybrid compute

Scheduler ggml позволяет запускать **один граф на нескольких backend'ах одновременно**. Пример: основные attention/matmul на GPU (Vulkan), но embeddings lookup и RoPE на CPU. Это важно для:
- **Multi-modal моделей**: CLIP-encoder для vision часто на CPU, language part на GPU
- **Small-tensor ops**: операции на маленьких тензорах (norm, softmax) быстрее на CPU (меньше latency копирования)
- **Fallback для unsupported ops**: если Vulkan backend не поддерживает какую-то новую операцию (напр., `ggml_ssm_scan` для Mamba), она автоматически идёт на CPU

## KV-cache: память под контекст

**KV-cache** -- массив тензоров `K` и `V` для каждого слоя attention, который накапливается в процессе генерации. При генерации токена `n` attention считается по всем предыдущим `n-1` токенам, которые уже закэшированы.

Размер KV-cache для одного токена:
```
2 * n_layers * n_kv_heads * head_dim * bytes_per_element
```

Пример для Qwen3.5-27B (dense, 64 layers, 40 kv heads, 128 head_dim, FP16 = 2 bytes):
```
2 * 64 * 40 * 128 * 2 = 1.3 MB на токен
```

При контексте 128K токенов: **1.3 MB × 131072 = ~170 GiB**. Это больше чем сама модель.

llama.cpp решает это через:

### 1. Grouped Query Attention (GQA)

Все современные модели (Llama 3+, Qwen2+, Mistral, Gemma, DeepSeek) используют GQA: несколько Q-heads делят одни K/V. Для Qwen3.5-27B: 40 Q-heads, но только **8 KV-heads**. Это уменьшает KV-cache в 5 раз.

### 2. Quantized KV-cache

Параметры `--cache-type-k` и `--cache-type-v`: можно хранить K и V в FP16, Q8_0, Q5_1, Q5_0, Q4_1, Q4_0.

```bash
llama-server ... --cache-type-k q8_0 --cache-type-v q8_0
```

Q8_0 дает половину размера FP16 практически без потери качества. Q4_0 -- в 4 раза меньше, но с ощутимой деградацией на длинных контекстах. Это позволяет уместить 1M контекст в разумную память.

### 3. Sliding window attention (SWA)

Gemma 2/3/4 и Phi-3/4 используют чередование global-attention и local-attention слоёв. Local-слои смотрят только на окно ~4K токенов, что радикально снижает KV-cache для длинных контекстов. llama.cpp поддерживает SWA через специальный маркер в GGUF.

### 4. MLA (Multi-head Latent Attention)

DeepSeek V2/V3 использует MLA: K/V факторизуются через low-rank projection, хранится только компрессированное представление. Размер KV-cache уменьшается в 5-10x без потери качества. llama.cpp получил поддержку MLA в b3800+ (весна 2025).

### 5. Context shifting

Когда контекст заполнен и генерация должна продолжиться, llama.cpp умеет **сдвигать окно**: выбрасывать старые токены и продолжать без reset. Управляется через `--ctx-shift`.

## llama-server: production HTTP API

`llama-server` -- это главный production-binary проекта. Легковесный HTTP-сервер (через header-only httplib) с OpenAI-compatible API. Именно его запускает большинство пользователей (и именно он стоит в основе Ollama, LM Studio API).

### Эндпоинты

| Endpoint | Назначение |
|----------|------------|
| `POST /completion` | Нативный llama.cpp формат с tokens/logprobs |
| `POST /v1/completions` | OpenAI legacy completion |
| `POST /v1/chat/completions` | OpenAI chat completion (с chat template) |
| `POST /v1/embeddings` | Эмбеддинги (если модель их поддерживает) |
| `POST /tokenize` | Токенизация текста |
| `POST /detokenize` | Обратное преобразование |
| `GET /health` | Health check |
| `GET /metrics` | Prometheus metrics |
| `GET /props` | Информация о модели, слотах, контексте |
| `GET /v1/models` | OpenAI list models |
| `POST /infill` | FIM (fill-in-the-middle) для coding-моделей |

### Ключевые параметры запуска

```bash
llama-server \
  -m model.gguf \
  -c 32768              # размер контекста
  -np 4                 # параллельные слоты (continuous batching)
  -ngl 99               # layers на GPU (99 = все)
  -fa                   # flash attention
  --jinja               # парсить jinja chat template из GGUF
  --cache-type-k q8_0   # квантизованный K-cache
  --host 0.0.0.0        # слушать на всех интерфейсах
  --port 8080
```

## Continuous batching и slots

`llama-server` поддерживает **continuous batching** -- классическая техника vLLM, перенесённая в llama.cpp. Работает так:

1. Сервер стартует с N "слотов" (`-np N`). Каждый слот -- независимый sequence с собственным KV-cache и позицией в нём.
2. Входящий запрос назначается на свободный слот. Если все слоты заняты -- в очередь.
3. На каждом шаге генерации сервер формирует **batch из активных слотов**. Если слот A на 50-м токене, слот B на 200-м, они идут в один matmul.
4. Когда запрос A завершается, его слот освобождается и сразу может принять следующий запрос -- не дожидаясь окончания B.

Результат: **throughput при многопользовательской нагрузке в 3-5 раз выше**, чем при последовательной обработке. При single-user нагрузке (чат с одним клиентом) разницы нет.

### Slot state

Каждый слот хранит:
- `id_task` -- ID текущего запроса
- `position` -- текущая позиция в KV-cache
- `kv_cache_slice` -- участок KV-cache, выделенный слоту
- `state` -- idle / processing_prompt / generating
- `params` -- sampling, max tokens, stop sequences

При `curl http://host:8080/slots` можно увидеть состояние всех слотов в реальном времени -- полезно для мониторинга production-нагрузки.

## Speculative decoding

**Speculative decoding** -- техника 2022-2023 года, получившая первую production-реализацию в llama.cpp в 2024. Идея:

1. Есть **draft model** (маленькая, например 1.5B) и **target model** (большая, например 70B)
2. Draft model **быстро** генерирует K токенов подряд (обычно K = 4-8)
3. Target model за **одну forward pass** проверяет все K токенов параллельно
4. Принимает префикс, где предсказания draft совпали с тем, что бы выдала target model
5. Если draft хорошо угадал -- мы сгенерировали K токенов за одну forward pass target model

Ключ: **target model всегда memory-bound**. Одна forward pass = одно чтение всех весов из памяти. Если проверяем 8 токенов или 1 -- затраты почти одинаковые (изменяется только batch внутри attention, а attention обычно не ограничивает на коротких контекстах).

Ожидаемое ускорение: **1.5-3x** на reasoning задачах, где draft хорошо угадывает (много "банального" текста). На креативных -- меньше.

### Запуск

```bash
llama-server \
  -m qwen3-coder-next-q4km.gguf \
  -md qwen2.5-coder-1.5b-q8.gguf  \  # draft model
  --draft 8 \
  ...
```

На платформе Strix Halo связка `Qwen3-Coder Next (80B-A3B)` + `Qwen2.5-Coder 1.5B` как draft даёт **1.8x ускорение** на типичных coding-задачах (по [benchmarking.md](benchmarking.md)).

## Multimodal, function calling, grammars

### Multimodal (vision)

Vision-модели в llama.cpp представлены двумя файлами:
- `model.gguf` -- основная language model
- `mmproj.gguf` -- multimodal projector (обычно CLIP / SigLIP encoder + linear projection в embedding space)

Запуск:
```bash
llama-server -m qwen3-vl.gguf --mmproj mmproj-qwen3-vl.gguf ...
```

Запросы идут через OpenAI vision format:
```json
{
  "messages": [{
    "role": "user",
    "content": [
      {"type": "text", "text": "Что на картинке?"},
      {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,..."}}
    ]
  }]
}
```

Поддерживаемые модели: LLaVA, InternVL, Qwen2.5-VL, Qwen3-VL, Pixtral, MiniCPM-O, SmolVLM, Gemma 4 vision. См. [vision.md](../models/vision.md).

### Function calling / Tool use

llama.cpp парсит **Jinja2 chat template прямо из GGUF** через встроенную библиотеку `minja`. Template определяет, как оформлять tool-calls (формат `<tool_call>...</tool_call>` или JSON-блок и т.п.).

Флаг `--jinja` обязателен для работы function calling. Без него сервер использует упрощённый HuggingFace chat template и ломает tool calls.

```bash
llama-server -m model.gguf --jinja ...
```

Клиент присылает `tools` в OpenAI-формате, сервер рендерит их в промпт через Jinja, модель генерирует tool-call, парсер на выходе валидирует JSON. См. [function-calling.md](../llm-guide/function-calling.md).

### GBNF grammars: constrained generation

**GBNF** (GGML BNF) -- расширенная Backus-Naur form для ограничения генерации. Синтаксис:

```
root   ::= object
object ::= "{" ws ( string ":" ws value ("," ws string ":" ws value)* )? "}"
value  ::= object | array | string | number | ("true" | "false" | "null")
array  ::= "[" ws ( value ("," ws value)* )? "]"
string ::= "\"" ([^"\\]|"\\".)* "\""
number ::= [0-9]+ ("." [0-9]+)?
ws     ::= [ \t\n]*
```

На каждом шаге семплинга llama.cpp фильтрует logits: токены, приводящие к невалидному BNF, получают `-inf`. Модель **не может** сгенерировать невалидный JSON/SQL/код.

Применения: строгий JSON output, structured extraction, ограничение языка ответа, валидация формата кода. llama.cpp была первой библиотекой с production-ready grammar-based sampling (2023); с тех пор аналогичное появилось в Outlines, Instructor, SGLang.

Параметр: `--grammar "..."` или `--grammar-file file.gbnf`. На платформе Strix Halo grammar практически не замедляет генерацию (фильтрация logits -- O(vocab_size) в CPU, ~микросекунды).

## Экосистема форков и обёрток

Большинство популярных local-inference тулов **обёртывают llama.cpp** внутри. Это не всегда очевидно:

| Продукт | Что это | Связь с llama.cpp |
|---------|---------|--------------------|
| **[LM Studio](lm-studio.md)** | Desktop GUI для local LLM | llama.cpp через feature-branch (дорабатывает Vulkan fixes, потом возвращает в upstream) |
| **[Ollama](ollama.md)** | CLI + REST wrapper, docker-стиль | llama.cpp как vendored snapshot + cgo bridge внутри Go-бинарника |
| **KoboldCpp** | Форк с фокусом на roleplay и NPC | Классический fork, дивергирует с 2023 |
| **llamafile** | One-binary distribution | llama.cpp + actually-portable-executable (APE) для single-file на любой ОС |
| **text-generation-webui** | Gradio UI для multiple backends | llama-cpp-python loader (Python biding) |
| **llama-cpp-python** | Python bindings | ctypes wrapper над `libllama.so` |
| **node-llama-cpp** | JavaScript/TypeScript bindings | N-API wrapper над llama.cpp |
| **[GPUStack](gpustack.md)** | Cluster orchestration | llama.cpp как один из backend'ов (наряду с vLLM) |

Практическое следствие: **любое улучшение upstream llama.cpp распространяется на все эти продукты через 1-2 недели**. Это делает llama.cpp-ecosystem самой быстрой по доставке новых моделей и оптимизаций.

### Пример жизненного цикла фичи

1. **Jan 2026**: появляется новая модель Qwen3-VL
2. **+3 дня**: патч в llama.cpp с поддержкой архитектуры (convert-hf-to-gguf.py + новый tensor types)
3. **+1 неделя**: оптимизации под Vulkan / CUDA
4. **+2 недели**: LM Studio, Ollama, KoboldCpp подтягивают upstream
5. **+3 недели**: в ЛЮБОМ GUI-клиенте можно запустить Qwen3-VL

Для сравнения: vLLM добавляет новую архитектуру обычно через 1-3 месяца, и только после написания кастомного CUDA kernel.

## Сравнение с vLLM, TGI, TensorRT-LLM

| Параметр | llama.cpp | vLLM | TGI | TensorRT-LLM |
|----------|-----------|------|-----|--------------|
| **Язык** | C/C++ | Python + CUDA | Rust + Python | Python + CUDA |
| **Зависимости** | ~0 | PyTorch, CUDA, NCCL | PyTorch, Rust | CUDA, TensorRT, Triton |
| **GPU поддержка** | NVIDIA/AMD/Intel/Apple/Huawei/Vulkan | NVIDIA (AMD в dev) | NVIDIA | только NVIDIA |
| **CPU inference** | флагман | fallback | нет | нет |
| **Форматы** | GGUF (квантизованный) | safetensors FP16/BF16, AWQ, GPTQ | safetensors | TensorRT engine |
| **Continuous batching** | да | да (первооткрыватель) | да | да |
| **Speculative decoding** | да | да | да | да |
| **Multimodal** | да | да (частично) | нет | да |
| **Grammar / constrained** | да (GBNF) | да (через Outlines) | да | через NeMo |
| **Throughput (single GPU, H100)** | ~70% vLLM | 100% (baseline) | ~85% vLLM | **~120% vLLM** |
| **Throughput (consumer GPU)** | **100%** (best) | работает, но медленнее | нет | нет |
| **Multi-GPU tensor parallel** | базовая | полная | полная | полная |
| **Deploy single binary** | **да** (500 KB) | нет (2 GB Python env) | нет (1.5 GB) | нет |
| **Production в datacenter** | редко | mainstream | mainstream | mainstream |
| **Production на edge/desktop** | **mainstream** | редко | редко | нет |

### Когда выбирать что

**llama.cpp**: local/edge inference, consumer-железо, CPU fallback, multiple GPU types, bundled deployments, embedded devices, privacy-sensitive. 80% use cases нашей платформы.

**vLLM**: datacenter-scale NVIDIA, high throughput single-model multi-user, Python integration, где важны PagedAttention и детальный control.

**TGI**: production HuggingFace deployment с managed hardware, Rust-based ecosystem.

**TensorRT-LLM**: maximum throughput на NVIDIA H100/H200/B200, готов к жёсткой оптимизации под конкретное железо, fixed model in production.

## На нашей платформе

На Strix Halo llama.cpp -- основной inference-движок. Собран дважды: с Vulkan backend (основной) и с ROCm/HIP (для сравнения и отдельных задач).

| Конфигурация | Задача |
|--------------|--------|
| `llama.cpp` + Vulkan | Основной inference: LLM, coding, vision, FIM |
| `llama.cpp` + ROCm/HIP | Бенчмарки, проверка, некоторые модели которые не поддерживает Vulkan |
| `llama.cpp` + CPU | Fallback, тесты, embedded-сценарии |

Скрипты управления -- в `scripts/inference/`:
- [`vulkan/`](../../scripts/inference/vulkan/README.md) -- сборка, проверка, пресеты моделей
- [`rocm/`](../../scripts/inference/rocm/README.md) -- ROCm установка, сборка, HSA overrides
- `start-server.sh` -- общий запуск llama-server с пресетами
- `bench.sh` -- запуск llama-bench по пресетам

Скилл [`/llama-cpp`](../../.claude/skills/llama-cpp/SKILL.md) автоматизирует сборку и обновление llama.cpp на inference-сервере.

### Типичная сборка на платформе

```bash
cd ~/projects/llama.cpp
cmake -B build \
  -DGGML_VULKAN=ON \
  -DGGML_NATIVE=ON \
  -DGGML_CCACHE=ON \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j$(nproc)
```

Итог: `build/bin/llama-server`, `llama-cli`, `llama-bench`, `llama-quantize`, `llama-gguf-split`, `llama-gguf` и около 30 других утилит. Один repo -- весь набор инструментов для работы с GGUF.

## Связанные статьи

- [Ollama (профиль проекта)](ollama.md) -- docker-стиль обёртка над тем же llama.cpp
- [Lemonade (профиль проекта)](lemonade.md) -- альтернативный inference-стек с поддержкой Ryzen AI NPU
- [vulkan-llama-cpp.md](vulkan-llama-cpp.md) -- сборка и запуск через Vulkan backend
- [rocm-llama-cpp.md](rocm-llama-cpp.md) -- сборка и запуск через ROCm/HIP backend
- [cpu-inference.md](cpu-inference.md) -- CPU-backend, AVX-512, BLAS
- [backends-comparison.md](backends-comparison.md) -- сравнение Vulkan vs ROCm vs CPU vs NPU
- [benchmarking.md](benchmarking.md) -- llama-bench, методология измерений на платформе
- [model-selection.md](model-selection.md) -- выбор моделей, GGUF vs safetensors
- [../llm-guide/quantization.md](../llm-guide/quantization.md) -- глубокое погружение в K-quants и IQ-quants
- [../llm-guide/generation.md](../llm-guide/generation.md) -- prefill vs decode, memory-bound
- [../llm-guide/context-window.md](../llm-guide/context-window.md) -- KV-cache, RoPE scaling
- [../llm-guide/function-calling.md](../llm-guide/function-calling.md) -- tool use, Jinja templates
- [../llm-guide/multimodal.md](../llm-guide/multimodal.md) -- vision-модели и mmproj
