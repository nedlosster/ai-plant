# MusicGen (Meta, 2023)

> Инструментальная музыка по тексту, MIT, линейка small/medium/large.

**Тип**: autoregressive transformer (300M-3.3B)
**Лицензия**: MIT
**Статус на сервере**: не скачана
**Направления**: [music](../music.md)

## Обзор

MusicGen от Meta -- инструментальная text-to-music модель. **Без вокала** -- только инструменты. Apache/MIT-стек. Линейка размеров от small (300M) до large (3.3B). На AMD требует PyTorch ROCm.

## Варианты

| Вариант | Параметры | VRAM | Качество | Hub |
|---------|-----------|------|----------|-----|
| musicgen-small | 300M | ~2 GiB | базовое | [facebook/musicgen-small](https://huggingface.co/facebook/musicgen-small) |
| musicgen-medium | 1.5B | ~8 GiB | хорошее | [facebook/musicgen-medium](https://huggingface.co/facebook/musicgen-medium) |
| musicgen-large | 3.3B | ~16 GiB | высокое | [facebook/musicgen-large](https://huggingface.co/facebook/musicgen-large) |
| musicgen-melody | 1.5B | ~8 GiB | хорошее + мелодия-промпт | [facebook/musicgen-melody](https://huggingface.co/facebook/musicgen-melody) |

## Сильные кейсы

- **Инструментальная музыка по описанию** -- "epic orchestral soundtrack"
- **Melody conditioning** (musicgen-melody) -- задать мелодию + описание стиля
- **MIT** -- коммерция без оговорок
- **Зрелая экосистема** -- audiocraft + transformers
- **Качество для своего размера**

## Слабые стороны

- **Без вокала** -- только инструментальная музыка (для песен с вокалом -- [ace-step](ace-step.md))
- На AMD требует PyTorch ROCm -- экспериментально
- Длительность ограничена (~30 секунд за раз)

## Идеальные сценарии

- **Background music для видео/презентаций**
- **Soundtrack для игр** -- инструментальные темы
- **Прототипирование музыки** под видео
- **Royalty-free аудио** для контента

## Загрузка

```bash
# Через transformers / audiocraft (PyTorch ROCm)
pip install audiocraft

# Модели подгрузятся автоматически при первом использовании
python -c "from audiocraft.models import MusicGen; MusicGen.get_pretrained('facebook/musicgen-large')"
```

## Связано

- Направления: [music](../music.md)
- Альтернативы: [ace-step](ace-step.md) (с вокалом), [stable-audio](stable-audio.md) (sound effects)
