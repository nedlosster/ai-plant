# FLUX (Black Forest Labs, 2024)

> Эталон open-source diffusion для генерации изображений, GGUF-совместимый.

**Тип**: diffusion (12B параметров)
**Лицензия**: Schnell -- Apache 2.0; Dev -- FLUX-1-dev (некоммерческая)
**Статус на сервере**: скачаны (FLUX.1-schnell Q4_K_S + T5-XXL encoder + CLIP-L + VAE)
**Направления**: [images](../images.md)

## Обзор

FLUX -- семейство diffusion-моделей от Black Forest Labs (создателей Stable Diffusion). На момент выхода стало эталоном open-source: точный prompt following, photo-realistic качество, поддержка длинных промптов через T5-XXL encoder.

На платформе работает через ComfyUI + ComfyUI-GGUF plugin -- GGUF-квантизации позволяют запускать без ROCm (через Vulkan/CPU backend в llama.cpp интеграции).

## Варианты

| Вариант | Параметры | GGUF Q8 | GGUF Q4 | Скорость | Лицензия | Статус | Hub |
|---------|-----------|---------|---------|----------|----------|--------|-----|
| FLUX.1-dev | 12B | 12.6 GiB | 6.7 GiB | ~50 шагов | FLUX-1-dev (некоммерч.) | не скачана | [city96/FLUX.1-dev-gguf](https://huggingface.co/city96/FLUX.1-dev-gguf) |
| FLUX.1-schnell | 12B | 12.6 GiB | 6.7 GiB Q4_K_S | **4 шага** | Apache 2.0 | **скачана (Q4_K_S)** | [city96/FLUX.1-schnell-gguf](https://huggingface.co/city96/FLUX.1-schnell-gguf) |

### FLUX.1-dev {#dev}

Полное качество, медленнее. Требует ~50 шагов diffusion для лучшего результата.

- ~12.6 GiB Q8_0 -- максимум качества
- Лицензия запрещает коммерческое использование (для бизнеса -- нужна Pro-подписка от BFL)
- Идеально для arts, экспериментов, личного использования

### FLUX.1-schnell {#schnell}

Дистиллированная "быстрая" версия. **4 шага** вместо 50 -- генерация занимает секунды.

- Apache 2.0 -- полная коммерческая свобода
- Качество чуть ниже dev, но достаточное для большинства задач
- Идеально для интерактивного UX, batch-генерации, прототипирования

## Сопутствующие компоненты

FLUX требует трёх компонентов:

1. **Diffusion model** -- GGUF выше
2. **T5-XXL text encoder** -- понимание длинных промптов (русский тоже!)
3. **CLIP encoder** -- стандартный
4. **VAE** (`ae.safetensors`) -- декодер latent → image

### T5-XXL Encoder

| Файл | Размер | Hub |
|------|--------|-----|
| t5-v1_1-xxl-encoder Q8_0 | 4.7 GiB | [city96/t5-v1_1-xxl-encoder-gguf](https://huggingface.co/city96/t5-v1_1-xxl-encoder-gguf) |

**Статус на сервере**: скачан (Q8_0).

T5-XXL -- ключевой компонент для понимания **длинных и сложных промптов**, включая русский. Без него FLUX работает только с короткими CLIP-промптами.

### CLIP и VAE

```bash
# CLIP для FLUX
huggingface-cli download comfyanonymous/flux_text_encoders \
    --local-dir ComfyUI/models/text_encoders/

# FLUX VAE (ae.safetensors, 160 MiB)
huggingface-cli download black-forest-labs/FLUX.1-dev \
    --include "ae.safetensors" \
    --local-dir ComfyUI/models/vae/
```

## Архитектура и особенности

- **12B параметров** -- значительно больше Stable Diffusion (1-3B)
- **Точное prompt following** -- лучше других open-source на момент выхода
- **Длинные промпты через T5-XXL** -- до 512 токенов вместо 77 у CLIP-only
- **GGUF квантизации от city96** -- от Q2 до Q8, можно адаптировать под VRAM
- **Native multilingual** -- понимает русский, китайский, японский через T5-XXL

## Сильные кейсы

- **Photo-realistic портреты** -- лучший open-source на момент выхода
- **Точное следование промпту** -- если описать сцену детально, получишь именно её
- **Длинные промпты** -- сложные сцены с несколькими объектами и взаимодействиями
- **Многоязычность** -- русские промпты работают через T5-XXL без дополнительных моделей
- **Apache 2.0 (Schnell)** -- коммерческое использование
- **120 GiB на платформе** -- можно держать FLUX + SD + LoRA + ControlNet одновременно

## Слабые стороны / ограничения

- **FLUX.1-dev запрещает коммерцию** -- использовать только Schnell для бизнеса
- **Большая модель (12B)** -- медленнее SD 3.5 Medium на consumer GPU
- **Аниме/стилизация** -- хуже SDXL и его finetune'ов
- **Slower training** для LoRA -- но это компенсируется качеством

## Идеальные сценарии применения

- **Photo-realistic иллюстрации** -- арт, концепты, маркетинг
- **Длинные сложные промпты** на русском или мультиязык
- **Текст в изображениях** -- FLUX хорошо отрисовывает буквы (одна из немногих open-source)
- **Коммерческое использование** -- обязательно Schnell (Apache 2.0)
- **Хайповая генерация** для соцсетей и блогов

## Загрузка

```bash
# FLUX.1-dev Q8_0 (~12.6 GiB)
huggingface-cli download city96/FLUX.1-dev-gguf \
    --include "flux1-dev-Q8_0.gguf" \
    --local-dir ComfyUI/models/diffusion_models/

# FLUX.1-schnell Q4 (~6.7 GiB) -- для коммерции
huggingface-cli download city96/FLUX.1-schnell-gguf \
    --include "flux1-schnell-Q4_K.gguf" \
    --local-dir ComfyUI/models/diffusion_models/

# T5-XXL encoder Q8 (~4.7 GiB) -- обязательный компонент
huggingface-cli download city96/t5-v1_1-xxl-encoder-gguf \
    --include "*Q8_0*" \
    --local-dir ComfyUI/models/text_encoders/

# CLIP-L (235 MiB)
huggingface-cli download comfyanonymous/flux_text_encoders \
    --include "clip_l.safetensors" \
    --local-dir ComfyUI/models/text_encoders/

# VAE (160 MiB)
huggingface-cli download black-forest-labs/FLUX.1-dev \
    --include "ae.safetensors" \
    --local-dir ComfyUI/models/vae/
```

Или через скрипт `scripts/comfyui/download-models.sh` (уже включает FLUX schnell + dev + T5-XXL + CLIP + VAE).

## Запуск

```bash
# ComfyUI с ROCm
./scripts/comfyui/start.sh

# Web UI: http://localhost:8188
```

В ComfyUI workflow:
1. Load Diffusion Model (GGUF) -- flux1-dev-Q8_0.gguf или flux1-schnell-Q4_K.gguf
2. DualCLIPLoader -- clip_l + t5xxl
3. Load VAE -- ae.safetensors
4. CLIP Text Encode (positive/negative prompts)
5. KSampler (для dev: ~50 steps, для schnell: 4 steps)
6. VAE Decode → Save Image

## VRAM по разрешениям

| Модель | 512x512 | 1024x1024 | 1536x1536 | 2048x2048 |
|--------|---------|-----------|-----------|-----------|
| FLUX.1-dev Q8 | ~14 GiB | ~18 GiB | ~28 GiB | ~42 GiB |
| FLUX.1-schnell Q4 | ~9 GiB | ~13 GiB | ~22 GiB | ~32 GiB |

На 120 GiB можно генерировать в 2K без tiling.

## Связано

- Направления: [images](../images.md)
- Родственные семейства: [sd35](sd35.md) (Stable Diffusion 3.5 -- альтернатива), [hidream](hidream.md) (HiDream-I1 Full -- Apache 2.0 17B)
- Скрипты: `scripts/comfyui/start.sh`, `scripts/comfyui/download-models.sh`
