# Модели для генерации видео

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти, 256 GB/s), ROCm экспериментальный (HSA_OVERRIDE_GFX_VERSION=11.5.0).

## Статус на платформе

Видеогенерация работает через:
- **ComfyUI + PyTorch ROCm** -- нативные safetensors/bf16/fp16, требует ROCm (экспериментально)
- **ComfyUI + ComfyUI-WanVideoWrapper** -- специализированный плагин для Wan2.1

ROCm для gfx1151 экспериментальный. Обязательна переменная `HSA_OVERRIDE_GFX_VERSION=11.5.0`.

GGUF-квантизации для видеомоделей отсутствуют -- используются safetensors в fp16/bf16.

## Рейтинг моделей

| Модель | Параметры | Размер (fp16) | VRAM (оценка) | Качество | Лицензия | AMD ROCm |
|--------|-----------|---------------|---------------|----------|----------|----------|
| **Wan2.1 14B** | 14B | ~28 GiB | 45-70 GiB | отличное | Apache 2.0 | да (экспериментально) |
| **Wan2.1 1.3B** | 1.3B | ~2.6 GiB | 8-16 GiB | хорошее | Apache 2.0 | да (экспериментально) |
| **HunyuanVideo** | 13B | ~26 GiB | 45-60 GiB | отличное | Tencent HunyuanVideo | частично |
| **CogVideoX 5B** | 5B | ~10 GiB | 18-30 GiB | высокое | Apache 2.0 | частично |
| **CogVideoX 2B** | 2B | ~4 GiB | 10-16 GiB | среднее | Apache 2.0 | частично |
| **LTX Video** | 2B | ~4 GiB | 8-12 GiB | среднее | LTX License | частично |
| **AnimateDiff v3** | ~1.5B (LoRA) | ~3 GiB | 10-16 GiB | среднее | Apache 2.0 | через SD base |
| **SVD (Stable Video Diffusion)** | ~1.5B | ~3 GiB | 10-18 GiB | высокое (I2V) | Stability AI | частично |
| **Open-Sora 1.2** | ~1.1B | ~2.2 GiB | 10-20 GiB | среднее | Apache 2.0 | ограничено |
| **Mochi 1** | 10B | ~20 GiB | 40-60 GiB | высокое | Apache 2.0 | ограничено |

### Пояснения к таблице

- **VRAM** -- оценочный диапазон: зависит от разрешения, длительности и числа кадров
- **AMD ROCm** -- "да" означает запуск через PyTorch ROCm с HSA_OVERRIDE_GFX_VERSION=11.5.0; "частично" -- требует дополнительной настройки или не тестировалось; "ограничено" -- проблемы с совместимостью
- Все размеры указаны для fp16/bf16 без квантизации

## Что выбрать для 120 GiB VRAM

| Задача | Модель | Точность | VRAM |
|--------|--------|----------|------|
| Максимальное качество (T2V) | Wan2.1 14B | fp16 | ~45-70 GiB |
| Быстрый старт / эксперименты | Wan2.1 1.3B | fp16 | ~8-16 GiB |
| Image-to-video | SVD / Wan2.1 14B I2V | fp16 | ~18-70 GiB |
| Длинные видео | CogVideoX 5B | fp16 | ~18-30 GiB |
| Минимальный VRAM | LTX Video | fp16 | ~8-12 GiB |

120 GiB -- уникальное преимущество. Wan2.1 14B в fp16 помещается целиком без квантизации. На consumer GPU (8-24 GiB) это невозможно.

## Детальное описание моделей

### Wan2.1 (Alibaba)

Text-to-video и image-to-video модель. Два варианта: 14B (максимальное качество) и 1.3B (быстрый/легкий). Поддерживает 480p и 720p, длительность до 5-21 секунд (зависит от настроек). Генерация motion, стабильная физика объектов.

- GitHub: github.com/Wan-Video/Wan2.1
- HuggingFace: huggingface.co/Wan-AI/Wan2.1-T2V-14B, huggingface.co/Wan-AI/Wan2.1-T2V-1.3B
- Лицензия: Apache 2.0

### CogVideoX (Tsinghua / THUDM)

Text-to-video модель на базе 3D-трансформера. Версии 2B и 5B. Генерация видео 6-10 секунд, 480p-720p. Стабильная работа, хороший motion. Официальная интеграция с diffusers.

- GitHub: github.com/THUDM/CogVideo
- HuggingFace: huggingface.co/THUDM/CogVideoX-5b, huggingface.co/THUDM/CogVideoX-2b
- Лицензия: Apache 2.0

### HunyuanVideo (Tencent)

13B text-to-video модель от Tencent. Высокое качество генерации, сложные сцены. Требует значительного VRAM, но помещается в 120 GiB.

- GitHub: github.com/Tencent/HunyuanVideo
- HuggingFace: huggingface.co/tencent/HunyuanVideo
- Лицензия: Tencent HunyuanVideo License

### AnimateDiff v3

LoRA-подход: добавляет motion module к существующим SD 1.5 моделям. Не требует отдельной видеомодели -- используется base SD + motion LoRA. Генерация 16-32 кадра.

- GitHub: github.com/guoyww/AnimateDiff
- HuggingFace: huggingface.co/guoyww/animatediff
- Лицензия: Apache 2.0

### SVD (Stable Video Diffusion)

Image-to-video модель от Stability AI. Превращает статичное изображение в короткое видео (14-25 кадров). Стабильный motion, хорошая coherence.

- GitHub: github.com/Stability-AI/generative-models
- HuggingFace: huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt
- Лицензия: Stability AI Community License

### LTX Video (Lightricks)

Легковесная text-to-video модель. Быстрая генерация, умеренное качество. Подходит для быстрых экспериментов.

- GitHub: github.com/Lightricks/LTX-Video
- HuggingFace: huggingface.co/Lightricks/LTX-Video
- Лицензия: LTX License

### Open-Sora 1.2 (HPC-AI Tech)

Open-source реализация Sora-подобной архитектуры. Поддержка различных разрешений и длительностей. Экспериментальный проект.

- GitHub: github.com/hpcaitech/Open-Sora
- HuggingFace: huggingface.co/hpcai-tech/Open-Sora
- Лицензия: Apache 2.0

### Mochi 1 (Genmo)

10B text-to-video модель. Высокое качество motion и coherence. Требует значительного VRAM (40-60 GiB), помещается в 120 GiB.

- GitHub: github.com/genmoai/mochi
- HuggingFace: huggingface.co/genmo/mochi-1-preview
- Лицензия: Apache 2.0

## Загрузка моделей

### Wan2.1 через CLI

```bash
# Wan2.1 1.3B (text-to-video, ~2.6 GiB)
huggingface-cli download Wan-AI/Wan2.1-T2V-1.3B \
    --local-dir ./models/wan2.1-1.3b/

# Wan2.1 14B (text-to-video, ~28 GiB)
huggingface-cli download Wan-AI/Wan2.1-T2V-14B \
    --local-dir ./models/wan2.1-14b/

# Wan2.1 14B (image-to-video)
huggingface-cli download Wan-AI/Wan2.1-I2V-14B \
    --local-dir ./models/wan2.1-i2v-14b/
```

### CogVideoX через CLI

```bash
# CogVideoX 2B
huggingface-cli download THUDM/CogVideoX-2b \
    --local-dir ./models/cogvideox-2b/

# CogVideoX 5B
huggingface-cli download THUDM/CogVideoX-5b \
    --local-dir ./models/cogvideox-5b/
```

### SVD через CLI

```bash
# Stable Video Diffusion XT
huggingface-cli download stabilityai/stable-video-diffusion-img2vid-xt \
    --local-dir ./models/svd-xt/
```

## Источники моделей

| Ресурс | Что искать |
|--------|-----------|
| [HuggingFace](https://huggingface.co/Wan-AI) | Wan2.1 T2V/I2V модели |
| [HuggingFace](https://huggingface.co/THUDM) | CogVideoX 2B/5B |
| [HuggingFace](https://huggingface.co/tencent) | HunyuanVideo |
| [HuggingFace](https://huggingface.co/stabilityai) | SVD |
| [HuggingFace](https://huggingface.co/Lightricks) | LTX Video |
| [HuggingFace](https://huggingface.co/genmo) | Mochi 1 |
| [GitHub](https://github.com/comfyanonymous/ComfyUI) | Workflows, примеры |

## Связанные статьи

- [Видео: быстрый старт](../use-cases/video/quickstart.md)
- [Видео: продвинутое](../use-cases/video/advanced.md)
