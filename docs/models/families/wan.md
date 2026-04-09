# Wan (Alibaba, 2024-2026)

> Cinematic text/image-to-video с native audio sync, MoE-архитектура, лидер 2026.

**Тип**: MoE diffusion (14B)
**Лицензия**: Apache 2.0
**Статус на сервере**: не скачана
**Направления**: [video](../video.md)

## Обзор

Wan от Alibaba -- лидер open-source video generation. MoE diffusion: разные эксперты для разных timestep'ов denoising. Эффективное масштабирование без линейного роста compute.

**Wan 2.6** (декабрь 2025): multi-shot generation, character consistency, native audio sync. **Wan 2.7** (Q1 2026): добавлены 1080p и улучшенная motion coherence.

## Варианты

| Вариант | Параметры | fp16 | Контекст | Аудио | Разрешение | Hub |
|---------|-----------|------|----------|-------|------------|-----|
| Wan 2.7 T2V/I2V | 14B MoE | ~28 GB | до 15 сек | native | 1080p | [Wan-AI/Wan2.7](https://huggingface.co/Wan-AI) |
| Wan 2.6 T2V | 14B MoE | ~28 GB | до 15 сек | native | 720p | [Wan-AI/Wan2.6-T2V-14B](https://huggingface.co/Wan-AI) |
| Wan 2.6 I2V | 14B MoE | ~28 GB | до 15 сек | native | 720p | [Wan-AI/Wan2.6-I2V-14B](https://huggingface.co/Wan-AI) |

GitHub: [Wan-Video/Wan2.2](https://github.com/Wan-Video/Wan2.2) (база), [Wan2.6](https://github.com/Wan-Video/Wan2.6)

## Сильные кейсы

- **Cinematic качество** -- лучший среди open-source по визуальной целостности
- **Multi-shot stories** -- "сначала персонаж в кафе, потом выходит на улицу" -- сохраняет ту же одежду и лицо
- **Character consistency** -- ушли morphing-артефакты Wan 2.5
- **Native audio sync** -- music + ambient + speech без отдельных сервисов
- **MoE-эффективность** -- 14B params, не вся модель активна одновременно
- **Apache 2.0**

## Слабые стороны

- На 12 GB VRAM требует FP8 + low-res. На 120 GiB -- fp16 без компромиссов
- 5 сек 720p ~5-9 мин -- не для live-генерации
- Большой инициализационный overhead

## Идеальные сценарии

- **Короткие рекламные ролики**
- **Music videos** с автогенерацией ambient
- **Storytelling** -- многосценные ролики с сюжетом
- **Image-to-video** для оживления статичных иллюстраций
- **Концепт-арт** для кино/игр (предвиз)

## Загрузка

```bash
hf download Wan-AI/Wan2.6-T2V-14B --local-dir ~/models/wan2.6-t2v
hf download Wan-AI/Wan2.6-I2V-14B --local-dir ~/models/wan2.6-i2v
```

## Связано

- Направления: [video](../video.md)
- Альтернативы: [hunyuanvideo](hunyuanvideo.md), [ltx-video](ltx-video.md), [cogvideox](cogvideox.md)
