# Stable Audio Open (Stability AI, 2024)

> Text-to-audio для звуковых эффектов и коротких музыкальных фрагментов, 47 секунд.

**Тип**: diffusion (1.2B)
**Лицензия**: Stability AI Community License
**Статус на сервере**: не скачана
**Направления**: [music](../music.md)

## Обзор

Stable Audio Open от Stability AI -- diffusion-модель для генерации звуковых эффектов и коротких музыкальных фрагментов. До 47 секунд. ~24 GiB VRAM. Подходит для sound design, не для полных песен.

## Варианты

| Вариант | Параметры | VRAM | Длительность | Hub |
|---------|-----------|------|--------------|-----|
| Stable Audio Open 1.0 | 1.2B | ~24 GiB | до 47 сек | [stabilityai/stable-audio-open-1.0](https://huggingface.co/stabilityai/stable-audio-open-1.0) |

## Сильные кейсы

- **Sound effects** -- удары, шаги, эмбиент, природные звуки
- **Короткие музыкальные фрагменты** для джинглов и переходов
- **Diffusion-архитектура** -- стабильное качество, контроль через шаги

## Слабые стороны

- Только до 47 секунд
- Не для песен с вокалом
- Stability AI Community License -- ограничения

## Идеальные сценарии

- **Sound design** для игр и видео
- **Foley** (звуковое сопровождение)
- **Эмбиент-фоны** для медитаций
- **Звуковые переходы** для подкастов

## Загрузка

```bash
pip install stable-audio-tools
hf download stabilityai/stable-audio-open-1.0 --local-dir ~/models/stable-audio-open
```

## Ссылки

**Официально**:
- [HuggingFace: stabilityai/stable-audio-open-1.0](https://huggingface.co/stabilityai/stable-audio-open-1.0)
- [HuggingFace: stabilityai](https://huggingface.co/stabilityai) -- организация
- [GitHub: Stability-AI/stable-audio-tools](https://github.com/Stability-AI/stable-audio-tools)

## Связано

- Направления: [music](../music.md)
- Альтернативы: [musicgen](musicgen.md) (более длинная музыка), [bark](bark.md) (sfx + speech)
