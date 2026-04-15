# Модели для генерации видео

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти, 256 GB/s), ROCm 7.2.1 (HSA_OVERRIDE_GFX_VERSION=11.5.1).

Полные описания моделей -- в [`families/`](families/README.md). Эта страница: сравнительные таблицы и выбор под задачу.

## Статус на платформе

Видеогенерация работает через **ComfyUI + PyTorch ROCm**. Большинство современных моделей имеют:
- Нативные `safetensors` (fp16/bf16) -- основной формат
- **GGUF/FP8 квантизации** -- значительно уменьшают VRAM
- ComfyUI-нативные узлы или wrapper-плагины (kijai-серия)

ROCm 7.2.1 на gfx1151 стабилен. Запуск через `HSA_OVERRIDE_GFX_VERSION=11.5.1` и `.venv/bin/python` (не `uv run`).

## Преимущество 120 GiB

На consumer GPU (8-24 GiB) видеомодели либо не помещаются вообще, либо требуют агрессивной квантизации. На 120 GiB:

- Wan 2.6 14B MoE в **fp16** без квантизации
- HunyuanVideo 1.5 8.3B в fp16
- LTX-Video 2.3 в **4K 50fps** комфортно
- LTX-2 19B dual-stream в Q8_0 с sync audio+video в одном проходе
- Несколько моделей одновременно (LLM + видео)

## Сравнительная таблица

| Модель | Семейство | Параметры | T2V | I2V | Audio | Длительность | Разрешение | Лицензия |
|--------|-----------|-----------|-----|-----|-------|--------------|------------|----------|
| **LTX-2** | [ltx-2](families/ltx-2.md) | **19B (14B+5B)** | да | да | **sync single-pass** | **20 сек** | **4K 50fps** | open weights |
| **HappyHorse-1.0** | -- | -- | да | да | -- | -- | -- | open (Alibaba) |
| Wan 2.7 | [wan](families/wan.md) | 14B MoE | да | да | native | 15 сек | 1080p | Apache 2.0 |
| Wan 2.6 | [wan](families/wan.md) | 14B MoE | да | да | native | 15 сек | 720p | Apache 2.0 |
| HunyuanVideo 1.5 | [hunyuanvideo](families/hunyuanvideo.md) | 8.3B | да | да | нет | 5 сек | 720p | HunyuanVideo |
| LTX-Video 2.3 | [ltx-video](families/ltx-video.md) | ~13B | да | да | native | 10 сек | **4K 50fps** | LTX |
| CogVideoX 1.5-5B | [cogvideox](families/cogvideox.md) | 5B | да | да | нет | 6 сек | 720x480 | Apache 2.0 |
| Open-Sora 2.0 | [open-sora](families/open-sora.md) | 3B | да | да | нет | до 30 сек | -- | Apache 2.0 |
| SVD | [svd](families/svd.md) | 1.5B | нет | да | нет | 14-25 кадров | 576x1024 | Stability CL |

## Выбор под задачу

### Максимальное качество T2V

[Wan 2.7](families/wan.md) -- 1080p, лучшая motion coherence.
[Wan 2.6](families/wan.md) -- 720p, multi-shot, character consistency.

### Image-to-video

[Wan 2.6 I2V](families/wan.md) -- основной выбор.
[SVD](families/svd.md) -- только для очень коротких GIF-анимаций.

### Скорость + 4K

[LTX-Video 2.3](families/ltx-video.md) -- single-stream 4K 50fps, real-time на достаточном железе.
[LTX-2](families/ltx-2.md) -- dual-stream 4K 50fps + sync audio, медленнее но с звуком.

### Native audio

[LTX-2](families/ltx-2.md) -- **единственная** с sync audio+video в одном forward pass (dual-stream cross-attention). Выбор для storytelling где звук должен точно попадать в кадр.
[Wan 2.6/2.7](families/wan.md) -- native audio через отдельный модуль поверх видео, менее строгая синхронизация.
[LTX-Video 2.3](families/ltx-video.md) -- native audio.

### Длинные видео (>10 сек)

[LTX-2](families/ltx-2.md) -- до 20 секунд (рекорд для open-source видеомоделей с audio).
[Open-Sora 2.0](families/open-sora.md) -- до 30 секунд без audio.

### ComfyUI-эксперименты, кастомные LoRA-стили

[CogVideoX 1.5-5B](families/cogvideox.md) -- лучшая ComfyUI-поддержка через kijai/ComfyUI-CogVideoXWrapper, большая community-LoRA библиотека.

### Multi-shot stories с сохранением персонажей

[Wan 2.6](families/wan.md) -- единственная с реальным character consistency.

### Точное text-video alignment

[HunyuanVideo 1.5](families/hunyuanvideo.md) -- лучше следует сложным промптам.

## Что выбрать для 120 GiB

| Задача | Рекомендация | Альтернатива |
|--------|--------------|--------------|
| Cinematic T2V | [Wan 2.7](families/wan.md) | [HunyuanVideo 1.5](families/hunyuanvideo.md) |
| Image-to-video | [Wan 2.6 I2V](families/wan.md) | SVD (короткие) |
| Скорость + 4K | [LTX-Video 2.3](families/ltx-video.md) | -- |
| **Audio+video sync** | [LTX-2](families/ltx-2.md) (single-pass) | [Wan 2.7](families/wan.md) (модуль) |
| Длинные >10 сек с audio | [LTX-2](families/ltx-2.md) (20 сек) | -- |
| Длинные >10 сек без audio | [Open-Sora 2.0](families/open-sora.md) | -- |
| ComfyUI/LoRA | [CogVideoX 1.5](families/cogvideox.md) | -- |
| Multi-shot stories | [Wan 2.6](families/wan.md) | -- |

## Связанные направления

- [images.md](images.md) -- diffusion для статичных картинок
- [vision.md](vision.md) -- понимание видео (не генерация)

## Связанные статьи

- [Видео: быстрый старт](../use-cases/video/quickstart.md)
- [Видео: продвинутое](../use-cases/video/advanced.md)
