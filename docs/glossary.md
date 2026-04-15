# Глоссарий

Термины, используемые в документации проекта ai-plant.

## Аппаратная часть

| Термин | Описание |
|--------|----------|
| **APU** | Accelerated Processing Unit -- чип, объединяющий CPU и GPU на одном кристалле |
| **Ascend** | Семейство AI-ускорителей Huawei (910B, 910C, 910D). Используются для обучения GLM-5 и других китайских моделей через фреймворк MindSpore. Аналог NVIDIA H100/H200 для китайского рынка |
| **BAR** | Base Address Register -- область адресного пространства PCI-устройства. BAR0 GPU определяет, какой объем VRAM доступен CPU напрямую |
| **Bandwidth** | Пропускная способность памяти (GB/s). Для LPDDR5 8000MT/s x 256 bit = 256 GB/s |
| **CCX** | Core Complex -- кластер ядер CPU с общим L3 кэшем. Ryzen AI MAX+ 395 имеет 2 CCX по 8 ядер |
| **CU** | Compute Unit -- базовый вычислительный блок GPU. Radeon 8060S содержит 40 CU |
| **C-states** | Состояния энергосбережения CPU (C0 -- активный, C1--C3 -- различные уровни сна). Отключение снижает латентность |
| **DCN** | Display Core Next -- подсистема дисплейного вывода в amdgpu. Версия 3.5.1 для Strix Halo |
| **DPMS** | Display Power Management Signaling -- управление энергосбережением монитора |
| **ECC** | Error Correcting Code -- контроль ошибок памяти. В LPDDR5 данной платформы отсутствует |
| **GTT** | Graphics Translation Table -- область системной памяти, доступная GPU через GART |
| **gfx1151** | Идентификатор GPU ISA (Instruction Set Architecture) для Radeon 8060S (RDNA 3.5, Strix Halo) |
| **GPU** | Graphics Processing Unit -- графический процессор, используемый для compute и отображения |
| **HBM** | High Bandwidth Memory -- тип памяти с высокой пропускной способностью, используется в серверных GPU |
| **IOMMU** | Input/Output Memory Management Unit -- аппаратная виртуализация ввода-вывода |
| **KFD** | Kernel Fusion Driver -- интерфейс ядра Linux для ROCm/HIP доступа к GPU |
| **KFD firmware table** | Таблица в firmware APU, определяющая carved-out VRAM сегмент. На gfx1151 ограничивает доступную GPU-память до 15.5 GiB, обходится через TTM pages_limit |
| **KMS** | Kernel Mode Setting -- управление видеорежимами на уровне ядра |
| **LPDDR5** | Low Power DDR5 -- тип оперативной памяти. 8000 MT/s, 256-bit шина |
| **NPU** | Neural Processing Unit -- специализированный процессор для AI-инференса. XDNA 2 в Strix Halo |
| **NVFP4 / NVFP8** | NVIDIA-специфичные 4-/8-битные форматы с аппаратной поддержкой в Blackwell Tensor Cores (RTX 50xx, B200). На AMD не работают |
| **PCIe** | Peripheral Component Interconnect Express -- шина подключения устройств. Gen4 x16 на данной платформе |
| **PSR** | Panel Self Refresh -- технология обновления экрана без участия GPU. Вызывает баги на DCN 3.5.1 |
| **Resizable BAR** | Технология расширения BAR для прямого доступа CPU ко всему объему VRAM |
| **RDNA 3.5** | Архитектура GPU AMD (Radeon 8060S). Поддержка Vulkan 1.3, compute, ray tracing |
| **SMT** | Simultaneous Multithreading -- одновременное выполнение двух потоков на одном ядре CPU (аналог Intel HT) |
| **Strix Halo** | Кодовое имя платформы AMD Ryzen AI MAX+ 395 |
| **TDP** | Thermal Design Power -- тепловой пакет процессора (до 120W для данной платформы) |
| **UMA** | Unified Memory Architecture -- единый пул памяти для CPU и GPU |
| **Unified Memory** | Архитектура с общей памятью CPU и GPU. Нет PCIe-трансфера, но bandwidth делится |
| **VRAM** | Video RAM -- память GPU. На данной платформе -- часть unified LPDDR5, выделяемая в BIOS |
| **XDNA / XDNA 2** | AMD Neural Processing Unit IP. XDNA 2 в Strix Halo: 32 AI Engine tiles, 50 TOPS INT8. Поддерживается через amdxdna драйвер в ядре 6.14+ |

## Драйверы и ядро

| Термин | Описание |
|--------|----------|
| **amdgpu** | Драйвер ядра Linux для AMD GPU. In-tree (встроен в ядро) |
| **amdxdna** | Драйвер ядра Linux для AMD XDNA NPU. В mainline с ядра 6.14+. Экспонирует `/dev/accel0` |
| **DRM** | Direct Rendering Manager -- подсистема ядра Linux для управления GPU |
| **DMUB** | Display MicroController Unit Buddy -- firmware для управления дисплеем в amdgpu |
| **GDM** | GNOME Display Manager -- менеджер входа в систему |
| **GRUB** | GRand Unified Bootloader -- загрузчик Linux. Параметры ядра задаются в /etc/default/grub |
| **hwmon** | Hardware Monitoring -- подсистема ядра для мониторинга температуры, напряжения, частот |
| **Mainline-ядро** | Ядро из основной ветки Linux (kernel.org), в отличие от стокового Ubuntu |
| **Mesa** | Open-source реализация Vulkan и OpenGL для AMD/Intel GPU |
| **PSP** | Platform Security Processor -- модуль безопасности AMD, загружает firmware GPU |
| **SMU** | System Management Unit -- управление частотами и энергопотреблением GPU |
| **sysfs** | Виртуальная файловая система Linux для доступа к параметрам устройств (/sys/) |
| **VCN** | Video Core Next -- аппаратный кодек видео в AMD GPU |
| **Wayland** | Протокол оконной системы Linux. На DCN 3.5.1 нестабилен, используется X11 |

## Inference

| Термин | Описание |
|--------|----------|
| **Batch size** | Количество токенов, обрабатываемых за один шаг. Влияет на throughput pp |
| **BM25** | Классическая lexical ranking функция из information retrieval. Используется в hybrid search RAG вместе с semantic search |
| **Compute-bound** | Операция, ограниченная вычислительной мощностью GPU |
| **Context window** | Максимальное количество токенов, которые модель может обработать за один раз |
| **Continuous batching** | Техника параллельной обработки нескольких запросов в одном batch inference-сервером. Впервые в vLLM, затем в llama.cpp. Повышает throughput в 3-5x для multi-user нагрузки |
| **Cross-attention** | Attention между разными модальностями / потоками данных (text ↔ image в FLUX, video ↔ audio в LTX-2, video ↔ text в vision-моделях) |
| **DSA** | Dynamically Sparse Attention -- механизм attention с динамическим отбором top-K ключей для каждого запроса. Используется в DeepSeek V3.2 и Mistral Next. Снижает compute и KV-cache при длинных контекстах |
| **Embeddings** | Векторное представление текста/токена в n-мерном пространстве, где семантически близкие элементы имеют близкие векторы. Основа RAG и semantic search |
| **Flash Attention** | Оптимизация attention через tiling и кооперативное использование SRAM/HBM. Снижает memory-bandwidth, ускоряет inference. Включается через `-fa` в llama-server |
| **Function calling** | Способность LLM генерировать запросы к внешним инструментам через tool definitions в промпте. Синоним: tool use, tool calling |
| **GLM** | Семейство открытых LLM от Zhipu AI / THUDM. GLM-5 (2026) -- MoE 744B total / 44B active под MIT-лицензией. Обучено на Huawei Ascend + MindSpore. Vision-вариант GLM-V использует CogViT |
| **GPU offload (-ngl)** | Перенос слоев модели на GPU. -ngl 99 = все слои на GPU |
| **Hybrid search** | Поиск, объединяющий lexical (BM25) и semantic (embeddings) -- часто через Reciprocal Rank Fusion. Улучшает recall в RAG |
| **Inference** | Выполнение обученной нейросети для генерации ответов. Не меняет веса модели |
| **KV-cache** | Key-Value cache -- кэш промежуточных результатов attention. Растет с размером контекста |
| **LLM** | Large Language Model -- большая языковая модель (GPT, Llama, Qwen и т.д.) |
| **MCP** | Model Context Protocol -- стандарт Anthropic 2024 для интеграции AI с внешними инструментами через MCP-серверы. Поддерживается Claude Code, Open WebUI, Ollama |
| **Memory-bound** | Операция, ограниченная пропускной способностью памяти (не compute). LLM tg -- memory-bound |
| **MLA** | Multi-head Latent Attention -- вариант attention в DeepSeek V2/V3, где K/V факторизуются через low-rank projection. Снижает размер KV-cache в 5-10x |
| **MTP** | Multi-Token Prediction -- техника обучения, где модель одновременно предсказывает несколько следующих токенов. Ускоряет обучение и даёт "speculative" generation on-the-fly. Используется в DeepSeek V3 и Qwen3.5 |
| **Partial offload** | Часть слоев на GPU, часть на CPU. Для моделей, не помещающихся в VRAM целиком |
| **PLE** | Per-Layer Embeddings -- техника в Gemma 4, где каждый слой имеет собственные эмбеддинги, хранимые отдельно. Позволяет выгружать эмбеддинг-таблицу на CPU, экономя VRAM для активаций |
| **pp** | Prompt processing -- фаза обработки входного контекста. Compute-bound |
| **RAG** | Retrieval-Augmented Generation -- техника обогащения LLM-промпта релевантными документами из внешнего хранилища перед генерацией |
| **Reranker** | Cross-encoder модель, переоценивающая top-K результатов retrieval для улучшения precision. Пример: `bge-reranker-v2-m3` |
| **Slots** | Параллельные sequence-ы в llama-server: каждый слот -- независимая генерация с собственным KV-cache. Управляется через `--parallel N` |
| **Speculative decoding** | Техника ускорения inference: draft-модель быстро генерирует K токенов, target-модель проверяет их за одну forward pass. Ускорение 1.5-3x на memory-bound задачах |
| **SWA** | Sliding Window Attention -- attention, ограниченный окном вокруг текущего токена. В Gemma/Phi чередуется с global attention, радикально снижает KV-cache для длинных контекстов |
| **Temperature** | Параметр "случайности" генерации. 0 -- детерминированный, 1+ -- более случайный |
| **tg** | Token generation -- фаза генерации ответа. Memory-bound |
| **Token** | Единица текста для LLM (~0.75 слова для английского, ~0.5 слова для русского) |
| **tok/s** | Tokens per second -- основная метрика скорости инференса |
| **Top-P** | Nucleus sampling -- фильтрация токенов по кумулятивной вероятности |
| **Training** | Обучение нейросети -- подбор весов на данных. Требует значительно больше ресурсов |
| **TTFT** | Time To First Token -- время до первого сгенерированного токена |
| **Vector store** | Специализированная БД для хранения и поиска embeddings. Примеры: Chroma, Qdrant, Milvus, PgVector, LanceDB, FAISS |

## Форматы и квантизация

| Термин | Описание |
|--------|----------|
| **AWQ** | Activation-aware Weight Quantization -- метод post-training квантизации, защищающий salient weights. Используется в Lemonade (NPU) и vLLM. Формат обычно `awq-g128-int4` |
| **Dense** | Архитектура, где все параметры активны на каждый токен (в отличие от MoE) |
| **FIM** | Fill-in-the-Middle -- режим автодополнения кода (вставка в середину текста) |
| **FP16 / BF16** | 16-bit floating point / brain float 16. Оригинальная точность весов |
| **GBNF** | GGML BNF -- расширенная Backus-Naur form для constrained generation в llama.cpp. Позволяет модели генерировать только валидный JSON/SQL/код через фильтрацию logits |
| **GGML** | Tensor library от Георги Герганова. Основа llama.cpp, whisper.cpp, stable-diffusion.cpp. Имеет свою tensor type system, graph executor, backend abstraction |
| **GGUF** | GGML Universal Format -- бинарный формат файлов llama.cpp (v3). Содержит header, metadata KV pairs, tensor info, mmap-friendly tensor data. Самодостаточный (токенизатор внутри файла) |
| **imatrix** | Importance matrix -- статистика активаций с калибровочного датасета, используется при IQ-квантизации для выделения "важных" весов |
| **IQ-quants** | Lookup-based квантизации (IQ1, IQ2, IQ3, IQ4) с imatrix-калибровкой. Дают лучшую perplexity при том же bpw чем K-quants, но медленнее на CPU |
| **K-quants** | Mixed-precision квантизации (Q2_K, Q3_K, Q4_K, Q5_K, Q6_K) с двухуровневым scaling: superblock 256 элементов с master scale + 8 subblocks с 6-bit sub-scales. Лучше perplexity чем базовые Q4_0/Q5_0 |
| **mmproj** | Multimodal projector -- отдельный GGUF-файл с CLIP/SigLIP encoder'ом для vision-моделей (LLaVA, Qwen3-VL, Gemma 4 vision). Загружается через `--mmproj` в llama-server |
| **MoE** | Mixture of Experts -- архитектура, где активируется только часть параметров на каждый токен |
| **Q4_K_M** | Квантизация ~4.83 бита. Оптимальный баланс размера и качества. M = medium = mixed precision (attention в Q6, FFN в Q4) |
| **Q5_K_M** | Квантизация ~5.69 бит. Чуть лучше качество, чуть больше размер |
| **Q8_0** | Квантизация 8 бит. Близко к оригиналу, хорошо работает с AVX-512 VNNI |
| **safetensors** | Формат PyTorch/HuggingFace для хранения тензоров. Набор файлов |
| **Квантизация** | Снижение точности весов модели (FP16 -> INT4/INT8) для экономии памяти и ускорения |

## Инструменты

| Термин | Описание |
|--------|----------|
| **Agent Teams** | Экспериментальная возможность Claude Code (2026): главный агент координирует несколько sub-агентов, работающих параллельно над разными частями задачи. Подходит для refactor monorepo, multi-service migration, security audit. Включается через `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=true` |
| **Aider** | CLI-инструмент для рефакторинга кода через LLM |
| **Code Kit** | YAML-формат описания Agent Teams в Claude Code (v5.0+). Определяет роли (planner, executor, reviewer), граф взаимодействия, разделение контекста |
| **AVX-512** | Advanced Vector Extensions 512-bit -- набор SIMD-инструкций CPU. BF16, VNNI -- подмножества |
| **ComfyUI** | Node-based workflow engine для diffusion-моделей (картинки, видео, multi-modal). Python+JS, custom_nodes экосистема. Профиль: [docs/apps/comfyui/](apps/comfyui/README.md) |
| **ComfyUI-GGUF** | Custom node для ComfyUI от city96, добавляющий поддержку GGUF-квантизованных diffusion-моделей через ggml Vulkan backend |
| **Continue.dev** | IDE-расширение для интеграции LLM в VS Code / JetBrains |
| **Demucs** | Модель разделения аудио на stems (вокал, барабаны, бас, другое) |
| **Gradio** | Python-фреймворк для создания веб-UI поверх ML-моделей. Используется в ACE-Step, HuggingFace Spaces, многих demo |
| **HIP** | Heterogeneous-compute Interface for Portability -- API ROCm для программирования GPU |
| **HSA_OVERRIDE_GFX_VERSION** | Переменная окружения для обхода неподдерживаемых GPU в ROCm |
| **Lemonade** | Open-source inference-сервер от Lightning/AMD для Ryzen AI NPU через ONNX Runtime GenAI + VitisAI EP. Hybrid prefill/decode между NPU и iGPU. Профиль: [docs/inference/lemonade.md](inference/lemonade.md) |
| **llama.cpp** | C/C++ runtime для инференса LLM. Поддерживает Vulkan, ROCm, CPU, CUDA, Metal. Профиль: [docs/inference/llama-cpp.md](inference/llama-cpp.md) |
| **llama-server** | HTTP-сервер llama.cpp с OpenAI-совместимым API, continuous batching, speculative decoding |
| **LM Studio** | GUI-приложение для локального запуска LLM. Встроенный llama.cpp |
| **MindSpore** | Open-source ML-фреймворк Huawei (аналог PyTorch/TensorFlow). Оптимизирован под Ascend NPU. Используется для обучения GLM-5 и других моделей на китайском hardware-стеке |
| **LobeChat** | Markdown-first chat frontend с Plugin Market и Agents Market. Next.js SSR+SPA hybrid. Профиль: [docs/apps/lobe-chat/](apps/lobe-chat/README.md) |
| **Modelfile** | Dockerfile-style текстовый формат Ollama для описания кастомной модели (FROM, PARAMETER, TEMPLATE, SYSTEM) |
| **OGA** | ONNX Runtime GenAI -- библиотека Microsoft для generative-inference поверх ONNX Runtime. Включает tokenizer, KV-cache, sampling. Используется Lemonade для NPU-пути |
| **Ollama** | Go-сервер поверх vendored llama.cpp с docker-style управлением моделями через OCI Distribution Spec. Профиль: [docs/inference/ollama.md](inference/ollama.md) |
| **Open WebUI** | Self-hosted AI-платформа (SvelteKit + FastAPI) с встроенным RAG, Functions, Pipelines, RBAC. Профиль: [docs/apps/open-webui/](apps/open-webui/README.md) |
| **OpenUtau** | Редактор для синтеза вокала (DiffSinger, UTAU) |
| **Quark** | AMD toolkit для квантизации моделей под XDNA NPU. Поддерживает AWQ, mixed-precision, ONNX export |
| **ROCm** | Radeon Open Compute -- стек AMD для GPU-вычислений (аналог CUDA) |
| **RVC** | Retrieval-based Voice Conversion -- конвертация тембра голоса |
| **Tabby** | Self-hosted сервер автодополнения кода (альтернатива Copilot) |
| **VitisAI EP** | Execution Provider для ONNX Runtime от AMD. Компилирует ONNX-подграфы под XDNA NPU через Vitis AI Runtime |
| **Vulkan** | Кроссплатформенный API для GPU-вычислений и графики. Основной бэкенд на данной платформе |

## Модели для генерации

| Термин | Описание |
|--------|----------|
| **ACE-Step** | Модель генерации музыки с вокалом из текстового описания. Dual-component: DiT 3.5B + LM 4B. Поддерживает русский. Софтверный профиль: [docs/apps/ace-step/](apps/ace-step/README.md) |
| **Bark** | Модель генерации речи/пения от Suno. Поддерживает русский, нестабильное качество |
| **CFG scale** | Classifier-Free Guidance scale -- параметр diffusion, определяющий насколько сильно генерация должна следовать conditioning (tags, lyrics, prompt). Типично 5-10 |
| **CLIP** | Contrastive Language-Image Pre-training -- text encoder для diffusion-моделей |
| **ControlNet** | Модуль управления генерацией изображений через дополнительные входы (контуры, глубина, поза) |
| **Diffusion model** | Модель генерации через последовательное удаление шума из случайного сигнала |
| **DiffSinger** | Модель синтеза певческого голоса из нотной партитуры |
| **CogViT** | Vision Transformer encoder в Qwen3-VL / GLM-V (замена более раннего ViT-L/14 CLIP). Обрабатывает изображения в переменном разрешении через dynamic patches, подаёт токены в LLM-бэкбон |
| **DiT** | Diffusion Transformer -- диффузионная модель на основе transformer-архитектуры (вместо U-Net). Используется в SD 3.5, FLUX, LTX-Video, LTX-2, Wan. Впервые предложен Peebles & Xie 2023 |
| **Dual-stream DiT** | Архитектура LTX-2: два потока DiT (14B для видео + 5B для аудио) с cross-attention между ними. Генерируют синхронизированные audio+video в одном forward pass |
| **FLUX** | Семейство text-to-image моделей от Black Forest Labs |
| **LoRA** | Low-Rank Adaptation -- легковесный адаптер для изменения стиля/добавления концептов в diffusion-модель |
| **MusicGen** | Модель Meta для генерации инструментальной музыки по описанию |
| **Stable Diffusion** | Семейство text-to-image моделей от Stability AI |
| **T5** | Text-to-Text Transfer Transformer -- text encoder, используемый в FLUX и SD3 |
| **VAE** | Variational Autoencoder -- компонент diffusion-модели, преобразующий latent space в изображение (или аудио в ACE-Step) |
| **USM conformer** | Universal Speech Model conformer -- audio encoder от Google, используемый как backbone в TTS и speech-LLM (Gemma 4 audio, VoxCPM2). Conformer = transformer + convolution для локальной зависимости |
| **Vocoder** | Нейросеть, преобразующая mel-спектрограмму в raw waveform. Примеры: HiFi-GAN, BigVGAN. Используется в audio-диффузии (ACE-Step) и TTS |

## Distribution и storage

| Термин | Описание |
|--------|----------|
| **Content-addressed storage** | Хранилище, где данные адресуются по hash (обычно SHA256) от содержимого. Даёт автоматическую дедупликацию. Используется в git, Docker, Ollama |
| **OCI Distribution Spec** | Open Container Initiative Distribution Specification -- протокол для distribution образов контейнеров. Используется Docker Hub, GHCR, Quay, Ollama Registry |
| **OCI manifest** | JSON-описание образа/модели, содержащее список layers (blobs) с их digest, size и media type |
| **Media type** | MIME-тип для layer в OCI manifest. Ollama использует: `application/vnd.ollama.image.{model,template,system,params,tensor}` |

## Frontend стек (для chat-приложений)

| Термин | Описание |
|--------|----------|
| **Edge Runtime** | Лёгкий JavaScript runtime (без Node.js APIs) для serverless функций на edge locations. Используется в LobeChat для низко-latency API-routes |
| **FastAPI** | Python async web framework. Backend Open WebUI. Автогенерация OpenAPI, middleware stack, pydantic validation |
| **Functions (Open WebUI)** | Python-функции в workspace Open WebUI для tool calling. Подмножество: Tools, Filters |
| **Next.js** | React-фреймворк с SSR, API routes, Edge Runtime. Основа LobeChat |
| **Pipelines (Open WebUI)** | Отдельный OpenAI-compat proxy-сервер для middleware логики (rate limiting, logging, filtering). Проксирует между Open WebUI и LLM |
| **Plugin Market** | Curated marketplace плагинов LobeChat. SDK: `@lobehub/market-sdk` |
| **Agents Market** | Curated marketplace готовых prompt-агентов LobeChat |
| **SPA** | Single Page Application -- веб-приложение без перезагрузок страниц. ComfyUI frontend, Open WebUI, основная часть LobeChat |
| **SSR** | Server-Side Rendering -- рендеринг HTML на сервере. LobeChat использует для auth/landing страниц |
| **SvelteKit** | Svelte-фреймворк для SSR/SPA с Vite build. Frontend Open WebUI |
| **Workflow JSON** | JSON-формат сохранённых ComfyUI workflow'ов. Содержит nodes, links, widgets_values. Можно переносить между инстансами |

## Связанные статьи

- [Анатомия LLM](llm-guide/model-anatomy.md)
- [Квантизация](llm-guide/quantization.md)
- [Справочник LLM](models/llm.md)
- [llama.cpp](inference/llama-cpp.md) -- профиль движка
- [Приложения](apps/README.md) -- end-user applications
