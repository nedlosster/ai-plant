# Русский вокал через AI

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-памяти), PyTorch + ROCm 7.2.1.

Полные описания моделей -- в [`families/`](families/README.md). Эта страница: применение моделей к русскоязычным песням, форматы промптов, советы.

## Подходы

| Подход | Семейство модели | Качество | Сложность | Лицензия |
|--------|------------------|----------|-----------|----------|
| ACE-Step 1.5 (рекомендуется) | [ace-step](families/ace-step.md) | хорошее | низкая | Apache 2.0 |
| YuE | [yue](families/yue.md) | хорошее | средняя | Apache 2.0 |
| Bark | [bark](families/bark.md) | базовое | низкая | MIT |
| MusicGen + TTS | [musicgen](families/musicgen.md) + [tts](tts.md) | среднее | высокая | MIT |
| DiffSinger + LUNAI | -- | хорошее (ручной контроль) | очень высокая | -- |

## Скачано на платформе

[ACE-Step 1.5](families/ace-step.md) -- единственная music-модель с явной поддержкой AMD ROCm. Уже на платформе через [`scripts/music/ace-step/start.sh`](../../scripts/music/ace-step/start.sh).

## ACE-Step для русского -- основной workflow

### Формат промпта

```
Tags: <стиль>, <инструменты>, <темп>, <вокал>
Lyrics:
[Verse 1]
<текст>
[Chorus]
<припев>
```

Подробное описание архитектуры и установки -- в [families/ace-step.md](families/ace-step.md).

### Примеры по жанрам

#### Поп

```
Tags: russian pop, female vocals, upbeat, synth, drums, 120bpm
Lyrics:
[Verse 1]
Солнце светит за окном
Я иду по улице легко
[Chorus]
Это утро для меня
Это новый день моя
```

#### Рок

```
Tags: russian rock, male vocals, electric guitar, drums, energetic, 140bpm
Lyrics:
[Verse 1]
Город спит, а я не сплю
Жду рассвета, жду тебя
[Chorus]
Мы будем петь до утра
Мы будем жить навсегда
```

#### Фолк

```
Tags: russian folk, female vocals, acoustic guitar, slow, 80bpm
Lyrics:
[Verse 1]
Берёзы шепчут на ветру
Звезда упала вдаль
```

#### Электро

```
Tags: russian electronic, female vocals, synth, edm, 128bpm
```

#### Рэп

```
Tags: russian hip-hop, male vocals, trap beat, 90bpm, dark
```

## Параметры генерации (ACE-Step)

| Параметр | Назначение |
|----------|-----------|
| `--duration` | Длительность в секундах (60-240) |
| `--steps` | Diffusion steps (8 для turbo) |
| `--cfg_scale` | Соответствие промпту (7-12) |
| `--guidance_scale` | Сила vocal guidance |

## Советы для качества русского

1. **Простые рифмы** -- ACE-Step лучше понимает регулярные структуры
2. **Короткие строки** -- 6-10 слов
3. **Чёткая структура** -- `[Verse]`, `[Chorus]`, `[Bridge]` маркеры
4. **Описание стиля на английском** в Tags -- модель лучше реагирует
5. **Lyrics на русском** -- использует кириллицу как есть

## Постобработка

### Разделение вокала и инструментов

Использовать **Demucs** (Facebook) -- top open-source для voice separation.

```bash
pip install demucs
demucs --two-stems=vocals input.wav
# Результат: separated/htdemucs/input/vocals.wav, no_vocals.wav
```

### Voice cloning через RVC

После генерации в ACE-Step можно применить **RVC** (Retrieval-based Voice Conversion) для замены голоса на конкретного исполнителя.

GitHub: [RVC-Project/Retrieval-based-Voice-Conversion-WebUI](https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI)

## Связанные направления

- [music.md](music.md) -- общая страница про музыку
- [tts.md](tts.md) -- TTS с клонированием голоса
- [russian-llm.md](russian-llm.md) -- LLM для генерации лирики

## Связанные статьи

- [ACE-Step: быстрый старт](../use-cases/music/quickstart.md)
