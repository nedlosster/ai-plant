# Bark (Suno, 2023)

> Экспериментальная text-to-audio модель: speech, sound effects, простые песни.

**Тип**: GPT-based audio generation
**Лицензия**: MIT
**Статус на сервере**: не скачана
**Направления**: [music](../music.md), [russian-vocals](../russian-vocals.md)

## Обзор

Bark от Suno -- ранняя экспериментальная audio-модель. Может генерировать речь, звуковые эффекты, простые песни. Не специализирована, поэтому уступает современным моделям, но универсальна. До 15 секунд за генерацию. MIT.

## Сильные кейсы

- **Универсальность** -- одна модель на speech + sfx + music
- **MIT** -- коммерция без ограничений
- **Эмоциональная речь** -- смех, вздохи, пение в одном выводе

## Слабые стороны

- **15 секунд max** за генерацию
- **Экспериментальная** -- уступает современным моделям почти везде
- **Русский слабый**

## Идеальные сценарии

- Эксперименты с multi-modal speech+sfx
- Прототипирование коротких аудио-сценок
- Образовательные демо

## Загрузка

```bash
pip install bark
# Модели подгрузятся автоматически
```

## Ссылки

**Официально**:
- [GitHub: suno-ai/bark](https://github.com/suno-ai/bark) -- основной репозиторий
- [HuggingFace: suno/bark](https://huggingface.co/suno/bark) -- основная модель
- [HuggingFace: suno/bark-small](https://huggingface.co/suno/bark-small) -- быстрый вариант

## Связано

- Направления: [music](../music.md), [russian-vocals](../russian-vocals.md)
- Альтернативы: [ace-step](ace-step.md) (полные песни), [stable-audio](stable-audio.md) (sfx)
