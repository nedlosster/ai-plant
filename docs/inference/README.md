# Inference-стек для Strix Halo (Radeon 8060S)

Платформа: Meigao MS-S1 MAX, AMD Ryzen AI MAX+ 395, Radeon 8060S (RDNA 3.5, gfx1151, 40 CU), 120 GiB GPU-доступной памяти (unified LPDDR5, 256 GB/s).

## Что такое inference

Inference (инференс) -- выполнение обученной нейросети для генерации ответов. В контексте LLM -- подача промпта в модель и генерация текста токен за токеном. В отличие от training (обучения), инференс не меняет веса модели, только читает их.

LLM-инференс состоит из двух фаз:
- **Prompt processing (pp)** -- обработка входного контекста. Compute-bound: GPU загружен вычислениями, токены обрабатываются параллельно.
- **Token generation (tg)** -- генерация ответа по одному токену. Memory-bound: основное время тратится на чтение весов модели из памяти. Скорость ограничена пропускной способностью памяти (bandwidth).

Для данной платформы bandwidth 256 GB/s -- это потолок скорости token generation.

## Архитектура стека

```
Модель (GGUF / safetensors)
    |
Runtime (llama.cpp / vLLM / LM Studio)
    |
Backend (Vulkan / ROCm HIP / CPU AVX-512)
    |
Hardware (Radeon 8060S / Ryzen AI MAX+ 395)
```

## Доступные бэкенды

| Бэкенд | Статус | Плюсы | Минусы |
|--------|--------|-------|--------|
| **Vulkan** | работает, рекомендуемый | Стабильный, не требует ROCm, Mesa из коробки | Производительность ниже нативного HIP |
| **ROCm / HIP** | экспериментальный | Потенциально быстрее, совместим с PyTorch/vLLM | gfx1151 не в официальной матрице, требует HSA_OVERRIDE_GFX_VERSION |
| **CPU (AVX-512)** | работает всегда | Надежный, не зависит от GPU-драйверов | Значительно медленнее GPU |
| **NPU (XDNA 2)** | экспериментальный | 50 TOPS INT8 | Только ONNX Runtime, ограниченная экосистема |

## Что выбрать

| Задача | Рекомендуемый бэкенд |
|--------|---------------------|
| Быстрый старт, GUI | LM Studio (Vulkan) |
| Автоматизация, API-сервер | llama.cpp server (Vulkan) |
| PyTorch, vLLM, transformers | ROCm (экспериментальный) |
| Отладка, baseline | CPU (AVX-512 BF16) |
| Модель не помещается в VRAM | CPU + partial GPU offload |

## Ограничения платформы

### Bandwidth = потолок token generation

Теоретическая формула для memory-bound фазы:

```
tok/s (tg) ~ bandwidth / model_size_bytes
```

Для 256 GB/s:

| Модель | Квантизация | Размер | Теор. tok/s | Реальные ~70-90% |
|--------|------------|--------|-------------|-----------------|
| 7B | Q4_K_M | ~4 GiB | ~60 | 42--54 |
| 13B | Q4_K_M | ~7 GiB | ~35 | 24--31 |
| 34B | Q4_K_M | ~19 GiB | ~13 | 9--12 |
| 70B | Q4_K_M | ~40 GiB | ~6 | 4--5 |
| 70B | Q8_0 | ~70 GiB | ~3.5 | 2--3 |

### Compute

40 CU RDNA 3.5 -- достаточно для prompt processing моделей до 70B. Для batch-инференса нескольких запросов одновременно compute может стать узким местом.

## Текущее состояние ПО

| Компонент | Статус |
|-----------|--------|
| Vulkan 1.4.318 (Mesa 25.2.8) | работает |
| standalone llama.cpp b8708 (Vulkan) | работает |
| ROCm 7.2.1 (HIP) | работает |
| PyTorch ROCm 2.7.1 | работает |
| Ollama 0.9.x | установлен |
| Docker | не установлен |

## Документация

| N | Документ | Описание | Уровень |
|---|----------|----------|---------|
| 0 | [llama-cpp.md](llama-cpp.md) | llama.cpp: история, GGML, GGUF, квантизации, бэкенды, llama-server, speculative decoding, экосистема | обзор |
| 0 | [ollama.md](ollama.md) | Ollama: архитектура, Modelfile, OCI-registry, content-addressed storage, auto VRAM offload, экосистема | обзор |
| 0 | [lemonade.md](lemonade.md) | Lemonade: NPU-ускорение для Ryzen AI, hybrid prefill/decode, ONNX RT GenAI + VitisAI EP, AWQ-квантизация, Quark | обзор |
| 1 | [model-selection.md](model-selection.md) | Форматы, квантизация, расчет VRAM, загрузка моделей | базовый |
| 2 | [lm-studio.md](lm-studio.md) | LM Studio: настройка, модели, API-сервер | базовый |
| 3 | [vulkan-llama-cpp.md](vulkan-llama-cpp.md) | Standalone llama.cpp с Vulkan: сборка, запуск, параметры | базовый |
| 4 | [rocm-setup.md](rocm-setup.md) | Установка ROCm для gfx1151, HSA_OVERRIDE_GFX_VERSION | продвинутый |
| 5 | [rocm-llama-cpp.md](rocm-llama-cpp.md) | llama.cpp с HIP-бэкендом, сравнение с Vulkan | продвинутый |
| 6 | [cpu-inference.md](cpu-inference.md) | Inference на CPU: AVX-512 BF16, оптимизация | справочный |
| 7 | [benchmarking.md](benchmarking.md) | Методика замеров, теоретический анализ, мониторинг | справочный |
| 8 | [troubleshooting.md](troubleshooting.md) | Типичные ошибки и решения | справочный |
| 9 | [gpustack.md](gpustack.md) | GPUStack: Web UI, кластер, оркестрация | справочный |
| 10 | [backends-comparison.md](backends-comparison.md) | Сравнение backend'ов: Vulkan, ROCm, CPU, NPU | справочный |
| 11 | [acceleration-outlook.md](acceleration-outlook.md) | Перспективы ускорения: GPU/CPU/NPU, нерешённые вопросы, отслеживание | аналитический |

### Модели для специализированных задач ([models/](../models/README.md))

| Документ | Описание |
|----------|----------|
| [Кодинг](../models/coding.md) | Qwen-Coder, Devstral, DeepSeek -- рейтинг, стек (Continue.dev, Aider) |
| [Музыка и вокал](../models/music.md) | ACE-Step, MusicGen, YuE -- генерация песен по тексту |
| [Картинки](../models/images.md) | FLUX.1, SD 3.5, HiDream -- ComfyUI, GGUF, LoRA |

Рекомендуемый порядок: 1 -> 2 -> 3 -> 7 -> 4 -> 5 -> 8.
