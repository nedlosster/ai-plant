# CogVideoX (Tsinghua / THUDM, 2024-2025)

> Компактная T2V/I2V с лучшей ComfyUI-экосистемой и LoRA-библиотекой.

**Тип**: 3D-трансформер (5B)
**Лицензия**: Apache 2.0
**Статус на сервере**: не скачана
**Направления**: [video](../video.md)

## Обзор

CogVideoX от THUDM -- 5B T2V/I2V модель с image+video pre-training. Apache 2.0. Лучшая ComfyUI-поддержка через kijai/ComfyUI-CogVideoXWrapper. Большая community-библиотека LoRA для стилей.

## Варианты

| Вариант | Параметры | fp16 | Разрешение | Длительность | Hub |
|---------|-----------|------|------------|--------------|-----|
| CogVideoX 1.5-5B | 5B | ~10 GB | 720x480 | 6 сек 8 fps | [THUDM/CogVideoX1.5-5B](https://huggingface.co/THUDM/CogVideoX1.5-5B) |

GitHub: [THUDM/CogVideo](https://github.com/THUDM/CogVideo)

## Сильные кейсы

- **Лучшая ComfyUI-поддержка** -- готовые узлы, T2V/I2V/LoRA в одном wrapper
- **Зрелая экосистема** -- много туториалов, workflow-share
- **LoRA для стилей** -- большая community-библиотека (аниме, реализм, CGI)
- **Низкий VRAM** -- работает на 18-30 GB
- **Apache 2.0**

## Слабые стороны

- Старее новых моделей ([wan](wan.md), [hunyuanvideo](hunyuanvideo.md) 1.5)
- Низкое разрешение (720x480) -- нужен upscale для production
- Только 6 секунд -- не для длинных историй
- Качество motion уступает Wan 2.6

## Идеальные сценарии

- **Эксперименты и обучение** -- мало VRAM, быстрый старт
- **Кастомные LoRA-стили** -- если уже в экосистеме SD/SDXL
- **Прототипирование** -- быстрая проверка концепта перед запуском Wan 2.6
- **ComfyUI workflows** -- если цепочка уже на ComfyUI узлах

## Загрузка

```bash
hf download THUDM/CogVideoX1.5-5B --local-dir ~/models/cogvideox-1.5-5b
```

## Ссылки

**Официально**:
- [HuggingFace: THUDM/CogVideoX1.5-5B](https://huggingface.co/THUDM/CogVideoX1.5-5B)
- [HuggingFace: THUDM](https://huggingface.co/THUDM) -- Tsinghua / Zhipu AI
- [GitHub: THUDM/CogVideo](https://github.com/THUDM/CogVideo)
- [GitHub: kijai/ComfyUI-CogVideoXWrapper](https://github.com/kijai/ComfyUI-CogVideoXWrapper) -- ComfyUI плагин

## Связано

- Направления: [video](../video.md)
- Альтернативы: [wan](wan.md), [open-sora](open-sora.md)
