# Модели для генерации изображений

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), Vulkan 1.4.318, ROCm экспериментальный.

## Статус на платформе

Diffusion-модели работают через:
- **ComfyUI + ComfyUI-GGUF** -- GGUF-квантизации через Vulkan/CPU, без ROCm
- **ComfyUI + PyTorch ROCm** -- нативные safetensors, требует ROCm (экспериментально)

GGUF-формат позволяет запускать diffusion-модели без ROCm -- через llama.cpp backend в ComfyUI.

## Рейтинг моделей

| Модель | Параметры | GGUF Q8 | GGUF Q4 | Качество | Лицензия |
|--------|-----------|---------|---------|----------|----------|
| **FLUX.1 Dev** | 12B | 12.6 GiB | 6.7 GiB | отличное | FLUX-1-dev |
| **FLUX.1 Schnell** | 12B | 12.6 GiB | 6.7 GiB | хорошее (быстрый) | Apache 2.0 |
| **HiDream-I1 Full** | 17B | 18 GiB | 11.5 GiB | отличное | Apache 2.0 |
| **SD 3.5 Large** | 8B | ~12 GiB | ~7 GiB | высокое | Stability AI |
| **SD 3.5 Medium** | 2.6B | ~4 GiB | ~2.5 GiB | хорошее | Stability AI |

### Что выбрать для 120 GiB GPU-памяти

| Задача | Модель | Квантизация | VRAM |
|--------|--------|------------|------|
| Лучшее качество | FLUX.1 Dev | Q8_0 | ~13 GiB |
| Быстрая генерация | FLUX.1 Schnell | Q4_K | ~7 GiB |
| Open-source (Apache) | HiDream-I1 Full | Q8_0 | ~18 GiB |
| Минимальный VRAM | SD 3.5 Medium | Q8_0 | ~4 GiB |
| Баланс | SD 3.5 Large | Q4_K | ~7 GiB |

120 GiB позволяет загружать любую модель в Q8 без ограничений и держать несколько моделей одновременно.

## ComfyUI -- основной инструмент

Node-based интерфейс для генерации изображений. Поддерживает все основные diffusion-модели.

### Установка ComfyUI

```bash
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI

python3 -m venv venv
source venv/bin/activate

# Для AMD ROCm (если работает)
pip install torch torchvision --index-url https://download.pytorch.org/whl/rocm6.2
pip install -r requirements.txt

# Или CPU-only (медленно, но стабильно)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
pip install -r requirements.txt
```

### Установка ComfyUI-GGUF plugin

Позволяет загружать GGUF-квантизации diffusion-моделей. Работает без ROCm.

```bash
cd ComfyUI/custom_nodes
git clone https://github.com/city96/ComfyUI-GGUF.git
cd ComfyUI-GGUF
pip install -r requirements.txt
```

### Запуск

```bash
cd ComfyUI

# С ROCm
HSA_OVERRIDE_GFX_VERSION=11.5.0 python main.py --listen 0.0.0.0 --port 8188

# CPU-only
python main.py --listen 0.0.0.0 --port 8188 --cpu
```

Web-интерфейс: `http://localhost:8188`

## Загрузка моделей

### GGUF-квантизации (city96 на HuggingFace)

```bash
# FLUX.1 Dev (Q8_0, 12.6 GiB)
huggingface-cli download city96/FLUX.1-dev-gguf \
    --include "flux1-dev-Q8_0.gguf" \
    --local-dir ComfyUI/models/diffusion_models/

# FLUX.1 Schnell (Q4_K, 6.7 GiB)
huggingface-cli download city96/FLUX.1-schnell-gguf \
    --include "flux1-schnell-Q4_K.gguf" \
    --local-dir ComfyUI/models/diffusion_models/

# HiDream-I1 Full (Q8_0, 18 GiB)
huggingface-cli download city96/HiDream-I1-Full-gguf \
    --include "*Q8_0*" \
    --local-dir ComfyUI/models/diffusion_models/

# SD 3.5 Large (Q4_K, 7 GiB)
huggingface-cli download city96/sd3.5-large-gguf \
    --include "*Q4_K*" \
    --local-dir ComfyUI/models/diffusion_models/
```

### Text Encoder (CLIP)

Для FLUX и SD 3.5 нужны text encoder модели:

```bash
# CLIP для FLUX
huggingface-cli download comfyanonymous/flux_text_encoders \
    --local-dir ComfyUI/models/text_encoders/

# T5-XXL (для FLUX, ~10 GiB)
huggingface-cli download city96/t5-v1_1-xxl-encoder-gguf \
    --include "*Q8_0*" \
    --local-dir ComfyUI/models/text_encoders/
```

### VAE

```bash
# FLUX VAE
huggingface-cli download black-forest-labs/FLUX.1-dev \
    --include "ae.safetensors" \
    --local-dir ComfyUI/models/vae/
```

### Структура файлов ComfyUI

```
ComfyUI/models/
  diffusion_models/
    flux1-dev-Q8_0.gguf
    flux1-schnell-Q4_K.gguf
  text_encoders/
    clip_l.safetensors
    t5xxl_fp16.safetensors     # или GGUF
  vae/
    ae.safetensors
  loras/                        # LoRA-адаптеры
  controlnet/                   # ControlNet-модели
```

## VRAM по разрешениям

Потребление VRAM зависит от разрешения генерации:

| Модель (Q8) | 512x512 | 1024x1024 | 1536x1536 | 2048x2048 |
|-------------|---------|-----------|-----------|-----------|
| SD 3.5 Medium | ~4 GiB | ~6 GiB | ~10 GiB | ~16 GiB |
| SD 3.5 Large | ~12 GiB | ~16 GiB | ~24 GiB | ~36 GiB |
| FLUX.1 Dev | ~14 GiB | ~18 GiB | ~28 GiB | ~42 GiB |
| HiDream-I1 | ~20 GiB | ~26 GiB | ~38 GiB | ~54 GiB |

120 GiB GPU-памяти позволяет генерировать в высоком разрешении без tiling.

## LoRA и дообучение

LoRA (Low-Rank Adaptation) -- легковесные адаптеры для изменения стиля или добавления концептов.

### Источники LoRA

- **CivitAI** (civitai.com) -- крупнейший источник LoRA для SD и FLUX
- **HuggingFace** -- официальные и community LoRA

### Использование

Скачать .safetensors файл LoRA в `ComfyUI/models/loras/`, затем добавить узел "Load LoRA" в workflow ComfyUI.

## ControlNet

Управление генерацией через дополнительные входы (поза, глубина, контуры).

| Тип | Назначение |
|-----|-----------|
| Canny | Контуры объектов |
| Depth | Карта глубины |
| OpenPose | Поза человека |
| Tile | Upscale с сохранением деталей |

Модели ControlNet для FLUX/SD 3.5 -- на HuggingFace.

## Источники моделей

| Ресурс | Что искать |
|--------|-----------|
| [HuggingFace](https://huggingface.co/city96) | GGUF-квантизации FLUX, SD3, HiDream |
| [HuggingFace](https://huggingface.co/black-forest-labs) | Оригинальные FLUX модели |
| [HuggingFace](https://huggingface.co/stabilityai) | SD 3.5, Stable Audio |
| civitai.com | LoRA, стили, дообученные checkpoint |
| comfyanonymous/ComfyUI | Workflows, примеры, text encoders |

## Связанные статьи

- [ComfyUI: быстрый старт](../use-cases/images/quickstart.md)
- [LoRA](../use-cases/images/lora-guide.md)
- [Fine-tuning Diffusion](../training/diffusion-finetuning.md)
