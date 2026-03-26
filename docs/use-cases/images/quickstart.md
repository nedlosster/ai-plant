# Быстрый старт: генерация изображений на AMD

Установка ComfyUI на Radeon 8060S (ROCm), загрузка FLUX.1-schnell, генерация первого изображения.

## Требования

- Python 3.10+
- ROCm-совместимый GPU (gfx1151 через `HSA_OVERRIDE_GFX_VERSION=11.5.0`)
- ~15 GiB свободного места на диске (модель + text encoders + VAE)

## 1. Установка ComfyUI

```bash
# Клонирование репозитория
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI

# Создание виртуального окружения
python3 -m venv venv
source venv/bin/activate

# Установка PyTorch с ROCm
pip install torch torchvision --index-url https://download.pytorch.org/whl/rocm6.2

# Зависимости ComfyUI
pip install -r requirements.txt
```

## 2. Установка ComfyUI-GGUF

Плагин от city96 для загрузки GGUF-квантизаций diffusion-моделей.

```bash
cd custom_nodes
git clone https://github.com/city96/ComfyUI-GGUF.git
cd ComfyUI-GGUF
pip install -r requirements.txt
cd ../..
```

## 3. Загрузка модели FLUX.1-schnell (GGUF Q4_K)

FLUX.1-schnell -- быстрая модель (4 шага), лицензия Apache 2.0. Q4_K -- компромисс между качеством и размером (~6.7 GiB).

```bash
# Diffusion-модель
huggingface-cli download city96/FLUX.1-schnell-gguf \
    --include "flux1-schnell-Q4_K.gguf" \
    --local-dir models/diffusion_models/
```

## 4. Загрузка text encoders

FLUX использует два text encoder: CLIP-L и T5-XXL.

```bash
# CLIP-L (~250 MiB)
huggingface-cli download comfyanonymous/flux_text_encoders \
    --include "clip_l.safetensors" \
    --local-dir models/text_encoders/

# T5-XXL GGUF (~5 GiB, квантизация для экономии памяти)
huggingface-cli download city96/t5-v1_1-xxl-encoder-gguf \
    --include "t5-v1_1-xxl-encoder-Q8_0.gguf" \
    --local-dir models/text_encoders/
```

## 5. Загрузка VAE

```bash
# FLUX VAE (ae.safetensors, ~335 MiB)
huggingface-cli download black-forest-labs/FLUX.1-schnell \
    --include "ae.safetensors" \
    --local-dir models/vae/
```

## 6. Итоговая структура файлов

```
ComfyUI/models/
  diffusion_models/
    flux1-schnell-Q4_K.gguf        # ~6.7 GiB
  text_encoders/
    clip_l.safetensors              # ~250 MiB
    t5-v1_1-xxl-encoder-Q8_0.gguf  # ~5 GiB
  vae/
    ae.safetensors                  # ~335 MiB
```

## 7. Запуск ComfyUI

```bash
# Переменная для совместимости gfx1151 с ROCm
HSA_OVERRIDE_GFX_VERSION=11.5.0 python main.py --listen 0.0.0.0 --port 8188
```

Открыть в браузере: `http://localhost:8188`

## 8. Первый workflow: txt2img с FLUX.1-schnell

В web-интерфейсе ComfyUI собрать workflow из нод:

1. **Unet Loader (GGUF)** -- загрузить `flux1-schnell-Q4_K.gguf`
2. **DualCLIPLoader (GGUF)** -- загрузить `clip_l.safetensors` и `t5-v1_1-xxl-encoder-Q8_0.gguf`
3. **CLIP Text Encode** -- ввести промпт, например:
   ```
   a cat sitting on a windowsill, golden hour sunlight, photorealistic
   ```
4. **Empty Latent Image** -- разрешение 1024x1024, batch size 1
5. **KSampler** -- steps: 4, cfg: 1.0, sampler: euler, scheduler: simple
6. **VAE Decode** -- подключить VAE (ae.safetensors)
7. **Save Image** -- сохранение результата

Параметры KSampler для FLUX.1-schnell:
- **steps**: 4 (schnell оптимизирован для малого числа шагов)
- **cfg**: 1.0 (FLUX не использует classifier-free guidance стандартным образом)
- **sampler**: euler
- **scheduler**: simple

Нажать **Queue Prompt** для запуска генерации.

## 9. Проверка использования GPU

Во время генерации в терминале ComfyUI отображается прогресс. Для проверки загрузки GPU:

```bash
# В отдельном терминале
# ROCm-утилита мониторинга
rocm-smi

# Или непрерывный мониторинг (обновление каждую секунду)
watch -n 1 rocm-smi
```

Если GPU используется, столбец "GPU%" покажет загрузку, а "VRAM Used" -- потребление видеопамяти.

При проблемах с ROCm -- запуск в CPU-режиме для диагностики:

```bash
python main.py --listen 0.0.0.0 --port 8188 --cpu
```

## Следующие шаги

- [prompting.md](prompting.md) -- как формулировать промпты для лучших результатов
- [workflows.md](workflows.md) -- img2img, inpainting, upscale и другие пайплайны
- [Справочник моделей](../../models/images.md) -- все поддерживаемые модели и квантизации

## Связанные статьи

- [Промпт-инжиниринг](prompting.md)
- [Workflows](workflows.md)
- [Модели для картинок](../../models/images.md)
