# Модели для генерации изображений

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), Vulkan + ROCm.

Полные описания моделей -- в [`families/`](families/README.md). Эта страница: сравнительные таблицы и выбор под задачу.

## Статус на платформе

Diffusion-модели работают через:
- **ComfyUI + ComfyUI-GGUF** -- GGUF-квантизации через Vulkan/CPU, без ROCm
- **ComfyUI + PyTorch ROCm** -- нативные safetensors

GGUF позволяет запускать diffusion без ROCm.

## Скачано на платформе

| Модель | Семейство | Параметры | Запуск |
|--------|-----------|-----------|--------|
| FLUX.1-schnell | [flux](families/flux.md#schnell) | 12B Q4 | ComfyUI |
| FLUX.1-dev | [flux](families/flux.md#dev) | 12B Q8 | ComfyUI |
| T5-XXL encoder | [flux](families/flux.md) | -- Q8 | ComfyUI |

## Сравнительная таблица

| Модель | Семейство | Параметры | GGUF Q8 | GGUF Q4 | Лицензия |
|--------|-----------|-----------|---------|---------|----------|
| FLUX.1-dev | [flux](families/flux.md#dev) | 12B | 12.6 GiB | 6.7 GiB | FLUX-1-dev (некоммерч.) |
| FLUX.1-schnell | [flux](families/flux.md#schnell) | 12B | 12.6 GiB | 6.7 GiB | Apache 2.0 |
| HiDream-I1 Full | [hidream](families/hidream.md) | 17B | 18 GiB | 11.5 GiB | Apache 2.0 |
| SD 3.5 Large | [sd35](families/sd35.md) | 8B | ~12 GiB | ~7 GiB | Stability CL |
| SD 3.5 Medium | [sd35](families/sd35.md) | 2.6B | ~4 GiB | ~2.5 GiB | Stability CL |

## Выбор под задачу

### Максимальное качество photo-realistic

[FLUX.1-dev](families/flux.md#dev) -- эталон open-source.

### Коммерческое использование (Apache 2.0)

[FLUX.1-schnell](families/flux.md#schnell) -- быстрая (4 шага), Apache 2.0.
[HiDream-I1 Full](families/hidream.md) -- 17B, Apache 2.0, конкурент FLUX dev.

### Минимальный VRAM

[SD 3.5 Medium](families/sd35.md) -- ~4 GiB Q8.

### Длинные промпты, многоязычность

[FLUX](families/flux.md) с T5-XXL encoder -- понимание длинных промптов на русском, китайском, японском.

### Большая LoRA-экосистема

[SD 3.5](families/sd35.md) -- максимум community-LoRA от SD-эпохи.

## Что выбрать для 120 GiB

| Задача | Модель | VRAM |
|--------|--------|------|
| Лучшее качество | [FLUX.1-dev Q8](families/flux.md#dev) | ~13 GiB |
| Быстрая генерация | [FLUX.1-schnell Q4](families/flux.md#schnell) | ~7 GiB |
| Apache 2.0 | [HiDream-I1 Q8](families/hidream.md) | ~18 GiB |
| Минимум VRAM | [SD 3.5 Medium Q8](families/sd35.md) | ~4 GiB |

120 GiB позволяет загружать любую модель в Q8 и держать несколько одновременно.

## ComfyUI -- основной инструмент

```bash
# Установка через готовый скрипт
./scripts/comfyui/install.sh
./scripts/comfyui/download-models.sh   # FLUX schnell + dev + T5-XXL + CLIP + VAE

# Запуск
./scripts/comfyui/start.sh
# Web UI: http://localhost:8188
```

## Структура файлов ComfyUI

```
ComfyUI/models/
  diffusion_models/
    flux1-dev-Q8_0.gguf
    flux1-schnell-Q4_K.gguf
  text_encoders/
    clip_l.safetensors
    t5xxl_fp16.safetensors    # или GGUF
  vae/
    ae.safetensors
  loras/                      # LoRA-адаптеры
  controlnet/                 # ControlNet
```

## VRAM по разрешениям

| Модель (Q8) | 512x512 | 1024x1024 | 1536x1536 | 2048x2048 |
|-------------|---------|-----------|-----------|-----------|
| SD 3.5 Medium | ~4 GiB | ~6 GiB | ~10 GiB | ~16 GiB |
| SD 3.5 Large | ~12 GiB | ~16 GiB | ~24 GiB | ~36 GiB |
| FLUX.1 Dev | ~14 GiB | ~18 GiB | ~28 GiB | ~42 GiB |
| HiDream-I1 | ~20 GiB | ~26 GiB | ~38 GiB | ~54 GiB |

120 GiB позволяет генерировать в 2K без tiling.

## LoRA и ControlNet

LoRA -- легковесные адаптеры для стилей и концептов. Источник: [CivitAI](https://civitai.com/) и HuggingFace.

ControlNet -- управление генерацией через дополнительные входы (Canny, Depth, OpenPose, Tile).

## Связанные направления

- [video.md](video.md) -- генерация видео
- [vision.md](vision.md) -- понимание изображений (не генерация)

## Связанные статьи

- [ComfyUI: быстрый старт](../use-cases/images/quickstart.md)
- [LoRA](../use-cases/images/lora-guide.md)
- [Fine-tuning Diffusion](../training/diffusion-finetuning.md)
