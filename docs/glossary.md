# Глоссарий

Термины, используемые в документации проекта ai-plant.

## Аппаратная часть

| Термин | Описание |
|--------|----------|
| **APU** | Accelerated Processing Unit -- чип, объединяющий CPU и GPU на одном кристалле |
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
| **KMS** | Kernel Mode Setting -- управление видеорежимами на уровне ядра |
| **LPDDR5** | Low Power DDR5 -- тип оперативной памяти. 8000 MT/s, 256-bit шина |
| **NPU** | Neural Processing Unit -- специализированный процессор для AI-инференса. XDNA 2 в Strix Halo |
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

## Драйверы и ядро

| Термин | Описание |
|--------|----------|
| **amdgpu** | Драйвер ядра Linux для AMD GPU. In-tree (встроен в ядро) |
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
| **Inference** | Выполнение обученной нейросети для генерации ответов. Не меняет веса модели |
| **Training** | Обучение нейросети -- подбор весов на данных. Требует значительно больше ресурсов |
| **LLM** | Large Language Model -- большая языковая модель (GPT, Llama, Qwen и т.д.) |
| **Token** | Единица текста для LLM (~0.75 слова для английского, ~0.5 слова для русского) |
| **tok/s** | Tokens per second -- основная метрика скорости инференса |
| **pp** | Prompt processing -- фаза обработки входного контекста. Compute-bound |
| **tg** | Token generation -- фаза генерации ответа. Memory-bound |
| **TTFT** | Time To First Token -- время до первого сгенерированного токена |
| **Memory-bound** | Операция, ограниченная пропускной способностью памяти (не compute). LLM tg -- memory-bound |
| **Compute-bound** | Операция, ограниченная вычислительной мощностью GPU |
| **KV-cache** | Key-Value cache -- кэш промежуточных результатов attention. Растет с размером контекста |
| **Context window** | Максимальное количество токенов, которые модель может обработать за один раз |
| **Temperature** | Параметр "случайности" генерации. 0 -- детерминированный, 1+ -- более случайный |
| **Top-P** | Nucleus sampling -- фильтрация токенов по кумулятивной вероятности |
| **Batch size** | Количество токенов, обрабатываемых за один шаг. Влияет на throughput pp |
| **GPU offload (-ngl)** | Перенос слоев модели на GPU. -ngl 99 = все слои на GPU |
| **Partial offload** | Часть слоев на GPU, часть на CPU. Для моделей, не помещающихся в VRAM целиком |

## Форматы и квантизация

| Термин | Описание |
|--------|----------|
| **GGUF** | Формат файлов llama.cpp. Единый файл с весами и метаданными, поддерживает квантизацию |
| **safetensors** | Формат PyTorch/HuggingFace для хранения тензоров. Набор файлов |
| **Квантизация** | Снижение точности весов модели (FP16 -> INT4/INT8) для экономии памяти и ускорения |
| **Q4_K_M** | Квантизация ~4.83 бита. Оптимальный баланс размера и качества |
| **Q5_K_M** | Квантизация ~5.69 бит. Чуть лучше качество, чуть больше размер |
| **Q8_0** | Квантизация 8 бит. Близко к оригиналу, хорошо работает с AVX-512 VNNI |
| **FP16 / BF16** | 16-bit floating point / brain float 16. Оригинальная точность весов |
| **FIM** | Fill-in-the-Middle -- режим автодополнения кода (вставка в середину текста) |
| **MoE** | Mixture of Experts -- архитектура, где активируется только часть параметров на каждый токен |
| **Dense** | Архитектура, где все параметры активны на каждый токен (в отличие от MoE) |

## Инструменты

| Термин | Описание |
|--------|----------|
| **llama.cpp** | C/C++ runtime для инференса LLM. Поддерживает Vulkan, ROCm, CPU |
| **llama-server** | HTTP-сервер llama.cpp с OpenAI-совместимым API |
| **LM Studio** | GUI-приложение для локального запуска LLM. Встроенный llama.cpp |
| **Vulkan** | Кроссплатформенный API для GPU-вычислений и графики. Основной бэкенд на данной платформе |
| **ROCm** | Radeon Open Compute -- стек AMD для GPU-вычислений (аналог CUDA) |
| **HIP** | Heterogeneous-compute Interface for Portability -- API ROCm для программирования GPU |
| **HSA_OVERRIDE_GFX_VERSION** | Переменная окружения для обхода неподдерживаемых GPU в ROCm |
| **ComfyUI** | Node-based интерфейс для генерации изображений (Stable Diffusion, FLUX) |
| **Continue.dev** | IDE-расширение для интеграции LLM в VS Code / JetBrains |
| **Aider** | CLI-инструмент для рефакторинга кода через LLM |
| **Tabby** | Self-hosted сервер автодополнения кода (альтернатива Copilot) |
| **RVC** | Retrieval-based Voice Conversion -- конвертация тембра голоса |
| **Demucs** | Модель разделения аудио на stems (вокал, барабаны, бас, другое) |
| **OpenUtau** | Редактор для синтеза вокала (DiffSinger, UTAU) |
| **AVX-512** | Advanced Vector Extensions 512-bit -- набор SIMD-инструкций CPU. BF16, VNNI -- подмножества |

## Модели для генерации

| Термин | Описание |
|--------|----------|
| **Diffusion model** | Модель генерации через последовательное удаление шума из случайного сигнала |
| **FLUX** | Семейство text-to-image моделей от Black Forest Labs |
| **Stable Diffusion** | Семейство text-to-image моделей от Stability AI |
| **LoRA** | Low-Rank Adaptation -- легковесный адаптер для изменения стиля/добавления концептов в diffusion-модель |
| **ControlNet** | Модуль управления генерацией изображений через дополнительные входы (контуры, глубина, поза) |
| **VAE** | Variational Autoencoder -- компонент diffusion-модели, преобразующий latent space в изображение |
| **CLIP** | Contrastive Language-Image Pre-training -- text encoder для diffusion-моделей |
| **T5** | Text-to-Text Transfer Transformer -- text encoder, используемый в FLUX и SD3 |
| **ACE-Step** | Модель генерации музыки с вокалом из текстового описания. Поддерживает русский |
| **MusicGen** | Модель Meta для генерации инструментальной музыки по описанию |
| **DiffSinger** | Модель синтеза певческого голоса из нотной партитуры |
| **Bark** | Модель генерации речи/пения от Suno. Поддерживает русский, нестабильное качество |

## Связанные статьи

- [Анатомия LLM](llm-guide/model-anatomy.md)
- [Квантизация](llm-guide/quantization.md)
- [Справочник LLM](models/llm.md)
