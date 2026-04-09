# Open-Sora (HPC-AI Tech, 2024-2025)

> Open-source реализация Sora-подобной DiT-архитектуры, длинные видео.

**Тип**: DiT (3B)
**Лицензия**: Apache 2.0
**Статус на сервере**: не скачана
**Направления**: [video](../video.md)

## Обзор

Open-Sora 2.0 -- open-source реализация Sora-подобной архитектуры от HPC-AI Tech. DiT (Diffusion Transformer) -- та же база что у Sora. Различные разрешения и aspect ratio. Длинные видео (до 30 секунд).

## Варианты

| Вариант | Параметры | fp16 | Длительность | Hub |
|---------|-----------|------|--------------|-----|
| 2.0 | ~3B | ~6 GB | до 30 сек | [hpcai-tech/Open-Sora](https://huggingface.co/hpcai-tech/Open-Sora) |

GitHub: [hpcaitech/Open-Sora](https://github.com/hpcaitech/Open-Sora)

## Сильные кейсы

- **Длинные видео** -- лидер по длительности среди open-source (до 30 сек)
- **Variable aspect ratio** -- горизонталь, вертикаль, square
- **Apache 2.0** + research-friendly
- **Open-source реализация Sora** -- интересно для исследователей

## Слабые стороны

- Качество ниже [wan](wan.md) / [hunyuanvideo](hunyuanvideo.md)
- Не лидер ни в одной отдельной нише
- Slower development cycle (research, не product)

## Идеальные сценарии

- **Исследовательские проекты** в video generation
- Когда нужны **длинные видео (>10 сек)** с приемлемым качеством
- **Эксперименты с DiT-архитектурой**
- Образовательные проекты

## Загрузка

```bash
hf download hpcai-tech/Open-Sora --local-dir ~/models/open-sora-2.0
```

## Связано

- Направления: [video](../video.md)
- Альтернативы: [wan](wan.md), [cogvideox](cogvideox.md)
