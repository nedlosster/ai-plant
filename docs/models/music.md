# Модели для генерации музыки и вокала

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), ROCm 7.2.1.

Полные описания моделей -- в `families/`. Эта страница: сравнительные таблицы и выбор под задачу.

## Скачано на платформе

| Модель | Семейство | Параметры | Бэкенд | Запуск |
|--------|-----------|-----------|--------|--------|
| ACE-Step 1.5 | [ace-step](families/ace-step.md) | <4 GiB DiT + 4B LM | PyTorch ROCm | `scripts/music/ace-step/start.sh` |

## Сравнительная таблица

| Модель | Семейство | Параметры | Вокал | Языки | Лицензия |
|--------|-----------|-----------|-------|-------|----------|
| ACE-Step 1.5 | [ace-step](families/ace-step.md) | <4 GiB | да | многоязычная (включая русский) | Apache 2.0 |
| MusicGen | [musicgen](families/musicgen.md) | 300M-3.3B | нет | -- | MIT |
| YuE | [yue](families/yue.md) | 7B+1B | да | многоязычная | Apache 2.0 |
| SongGeneration v2 | [songgeneration](families/songgeneration.md) | 4B | да | -- | Research only |
| Stable Audio Open | [stable-audio](families/stable-audio.md) | 1.2B | -- (sfx) | -- | Stability CL |
| Bark | [bark](families/bark.md) | -- | да | en, basic ru | MIT |

## Выбор под задачу

### Полные песни с вокалом (рекомендуется)

[ACE-Step 1.5](families/ace-step.md) -- единственная music-модель с явной поддержкой AMD ROCm, малый VRAM, Apache 2.0. Уже на платформе.
[YuE](families/yue.md) -- альтернатива для коммерции (Apache 2.0).

### Инструментальная музыка

[MusicGen](families/musicgen.md) -- инструментальная по описанию ("epic orchestral soundtrack"). MIT. Для AMD требует PyTorch ROCm.

### Sound effects и короткие фрагменты

[Stable Audio Open](families/stable-audio.md) -- до 47 секунд, sound design.

### Эксперименты с multi-modal

[Bark](families/bark.md) -- speech + sfx + простые песни в одной модели, MIT.

### Для исследований (некоммерческое)

[SongGeneration v2](families/songgeneration.md) -- 4B, высокое качество, но Research only.

## Рекомендуемая схема для платформы

1. **ACE-Step 1.5** -- основной инструмент для песен с вокалом (включая русский)
2. **MusicGen** -- если нужна инструментальная музыка отдельно

## Связанные направления

- [russian-vocals.md](russian-vocals.md) -- подробности про русский вокал в ACE-Step
- [tts.md](tts.md) -- TTS с клонированием голоса (отдельная задача)
- [llm.md](llm.md) -- общие LLM

## Связанные статьи

- [ACE-Step: быстрый старт](../use-cases/music/quickstart.md)
