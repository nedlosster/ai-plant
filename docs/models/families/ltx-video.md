# LTX-Video (Lightricks, 2024-2026)

> Real-time видео с фокусом на скорость и итерации, 4K 50fps, native audio.

**Тип**: ~13B
**Лицензия**: LTX License (не Apache)
**Статус на сервере**: не скачана
**Направления**: [video](../video.md)

## Обзор

LTX-Video от Lightricks -- видео с фокусом на скорость. **LTX-2.3** (март 2026) -- перестроенный VAE, text connector в 4 раза больше, native audio generation. **4K 50fps** -- единственная open-source с этим. Real-time generation на достаточном железе.

## Варианты

| Вариант | fp16 | VRAM | Разрешение | Аудио | Hub |
|---------|------|------|------------|-------|-----|
| LTX-2.3 | ~26 GB | 32 GB+ | **4K 50fps** | native | [Lightricks/LTX-Video](https://huggingface.co/Lightricks/LTX-Video) |

GitHub: [Lightricks/LTX-Video](https://github.com/Lightricks/LTX-Video)

## Сильные кейсы

- **4K 50fps** native -- единственная open-source с этим
- **Real-time generation** на достаточном железе
- **Native audio** -- генерация звука вместе с видео
- **30fps 1216x704 быстрее реального времени** на capable hardware
- **Большой text connector** -- лучшее текстовое следование в 2.3
- **Iterative editing** -- быстрая доводка результата

## Слабые стороны

- **LTX License** -- не подходит для всех коммерческих сценариев
- Минимум 32 GB VRAM
- Стилистика clean/коммерческая, не cinematic
- Длительность скромная (до 10 сек)

## Идеальные сценарии

- **Контент-мейкеры** с большим объёмом видео в день
- **Live brainstorming** видео-идей
- **Социальные сети** -- быстрая итерация для тестирования
- **Реклама** где важна скорость production
- **Замена платных сервисов** типа Runway/Pika для high-frequency пользователей

## Загрузка

```bash
hf download Lightricks/LTX-Video --local-dir ~/models/ltx-video-2.3
```

## Ссылки

**Официально**:
- [HuggingFace: Lightricks/LTX-Video](https://huggingface.co/Lightricks/LTX-Video)
- [HuggingFace: Lightricks](https://huggingface.co/Lightricks) -- организация
- [GitHub: Lightricks/LTX-Video](https://github.com/Lightricks/LTX-Video)

## Связано

- Направления: [video](../video.md)
- Альтернативы: [wan](wan.md) (cinematic), [hunyuanvideo](hunyuanvideo.md)
