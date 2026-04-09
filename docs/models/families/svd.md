# SVD -- Stable Video Diffusion (Stability AI, 2023)

> Image-to-video классика, оживление статичных фото.

**Тип**: ~1.5B
**Лицензия**: Stability AI Community License
**Статус на сервере**: не скачана
**Направления**: [video](../video.md)

## Обзор

SVD от Stability AI -- модель **только image-to-video** (нет text). Превращает статичное фото в короткое видео (14-25 кадров, ~1-2 сек). Стабильный motion для портретов и пейзажей. Быстрая.

**Замечание**: устаревает на фоне [wan 2.6 I2V](wan.md). Используется только для специфичных кейсов.

## Варианты

| Вариант | Параметры | VRAM | Длительность | Hub |
|---------|-----------|------|--------------|-----|
| SVD-XT | ~1.5B | 10-18 GB | 14-25 кадров | [stabilityai/stable-video-diffusion-img2vid-xt](https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt) |

## Сильные кейсы (специфичные)

- **Single-purpose** -- только I2V, ничего больше
- **Скорость** -- самая быстрая I2V
- **Низкий VRAM** -- работает на старом железе
- Хорошая coherence motion для портретов и пейзажей

## Слабые стороны

- Только I2V (нет T2V)
- 1-2 секунды максимум
- Стилистика "natural" -- не cinematic
- **Stability CL** -- ограничения для коммерции
- **Устаревает на фоне Wan 2.6 I2V**

## Идеальные сценарии (когда выбирать вместо Wan 2.6)

- Очень короткие GIF-анимации из фото
- Batch-обработка тысяч фото за минимальное время
- Слабое железо (Wan 2.6 не помещается)

## Загрузка

```bash
hf download stabilityai/stable-video-diffusion-img2vid-xt --local-dir ~/models/svd-xt
```

## Связано

- Направления: [video](../video.md)
- Современная альтернатива: [wan](wan.md) (Wan 2.6 I2V)
