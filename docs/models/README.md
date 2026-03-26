# Модели для специализированных задач

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти), Vulkan 1.4.318, ROCm экспериментальный.

## Категории

| Задача | Документ | Статус на платформе |
|--------|----------|-------------------|
| [LLM общего назначения](llm.md) | Qwen2.5, Llama 3.3, DeepSeek-R1, Phi-4 -- рейтинг, VRAM | работает (llama.cpp + Vulkan) |
| [Российские LLM](russian-llm.md) | Saiga, T-pro, Vikhr -- модели с фокусом на русский язык | работает (llama.cpp + Vulkan) |
| [Кодинг](coding.md) | Генерация и автодополнение кода | работает (llama.cpp + Vulkan) |
| [Музыка и вокал](music.md) | Генерация музыки и песен по тексту | частично (ACE-Step через ROCm) |
| [Русский вокал](russian-vocals.md) | Обзор: русскоязычные песни через AI, сравнение подходов, промпты | ACE-Step 1.5 |
| [Картинки](images.md) | Генерация изображений по описанию | частично (ComfyUI + GGUF) |
| [Видео](video.md) | Генерация видео по описанию и из изображений | частично (ComfyUI + ROCm) |

## Где брать модели

### HuggingFace (huggingface.co)

Основной источник open-source моделей. Авторы GGUF-квантизаций:

| Автор | Специализация |
|-------|--------------|
| **bartowski** | LLM, широкий выбор квантизаций |
| **unsloth** | LLM, оптимизированные квантизации |
| **city96** | Diffusion-модели (FLUX, SD3) в формате GGUF |
| **Qwen** (official) | Qwen-серия, включая Coder |

```bash
# Установка CLI
pip install huggingface-hub

# Загрузка модели
huggingface-cli download bartowski/Qwen2.5-Coder-32B-Instruct-GGUF \
    --include "*Q4_K_M*" \
    --local-dir ./models/
```

### CivitAI (civitai.com)

Источник diffusion-моделей, LoRA, ControlNet. Модели для генерации картинок, стили, дообученные версии SD/FLUX.

### GitHub

Репозитории проектов (ACE-Step, ComfyUI, llama.cpp) -- исходный код, инструкции, иногда веса.

## Преимущество 120 GiB GPU-памяти

Большинство consumer GPU имеют 8-24 GiB VRAM. 120 GiB GPU-доступной памяти (96 GiB carved-out + GTT) позволяет:

- Загружать LLM 70B+ без агрессивной квантизации (Q5/Q8 вместо Q2/Q4)
- Запускать diffusion-модели в полном разрешении без tiling
- Держать несколько моделей одновременно (LLM + diffusion)
- Использовать длинный контекст (32k+) без OOM

## Общие форматы

| Формат | Применение | Инструмент |
|--------|-----------|-----------|
| GGUF | LLM (text generation) | llama.cpp, LM Studio |
| GGUF (diffusion) | Генерация картинок | ComfyUI + ComfyUI-GGUF |
| safetensors | LLM, diffusion, audio | PyTorch, vLLM, ComfyUI |
| checkpoint (.ckpt) | Diffusion (legacy) | ComfyUI, Automatic1111 |

Для данной платформы **GGUF предпочтителен**: работает через Vulkan без ROCm.
