# F5-TTS (SWivid, 2024)

> Эталон open-source voice cloning, MIT, мощное community с RU-форками.

**Тип**: Flow Matching + DiT (~330M)
**Лицензия**: MIT
**Статус на сервере**: не скачана
**Направления**: [tts](../tts.md)

## Обзор

F5-TTS -- "fairytaler that fakes fluent and faithful speech". Flow matching architecture (быстрее diffusion). 6 секунд reference достаточно для voice cloning. MIT-лицензия. Огромное community с дообученными весами для русского, японского, корейского и других языков.

## Варианты

| Вариант | Параметры | Языки | VRAM | Статус | Hub |
|---------|-----------|-------|------|--------|-----|
| Base | 330M | en, zh | ~6 GiB | не скачана | [SWivid/F5-TTS](https://huggingface.co/SWivid/F5-TTS) |
| Russian (Misha24-10) | 330M | ru | ~6 GiB | не скачана | [Misha24-10/F5-TTS_RUSSIAN](https://huggingface.co/Misha24-10/F5-TTS_RUSSIAN) |
| Russian (hotstone228) | 330M | ru | ~6 GiB | не скачана | [hotstone228/F5-TTS-Russian](https://huggingface.co/hotstone228/F5-TTS-Russian) |

GitHub: [SWivid/F5-TTS](https://github.com/SWivid/F5-TTS)

## Сильные кейсы

- **Самый быстрый старт** -- минимум зависимостей, простая API
- **Очень натуральные интонации** -- вопросительные/восклицательные/паузы
- **6 секунд reference** -- работает даже с микрофонной записью на телефон
- **Точное копирование акцента**
- **Локальный CPU-фоллбек** -- благодаря 330M можно даже без GPU
- **MIT** -- полная свобода
- **Огромное community** -- дообученные веса для многих языков

## Слабые стороны

- На длинных текстах (5+ минут) может терять характеристики голоса
- Русский только через community-форки -- качество зависит от датасета
- Без emotional control
- Без free-form voice design

## Идеальные сценарии

- **Дубляж видео** -- 10 сек оригинала актёра → весь дубляж его голосом
- **"Озвучь как Тарантино"** по 10-секундному youtube образцу
- Быстрая прототипная озвучка
- Реалтайм-аватары / virtual streamers
- Подкасты с цифровыми ведущими

## Загрузка

```bash
# Базовая модель
hf download SWivid/F5-TTS --local-dir ~/models/F5-TTS

# Русская версия (рекомендуется)
hf download Misha24-10/F5-TTS_RUSSIAN --local-dir ~/models/F5-TTS-RU

git clone https://github.com/SWivid/F5-TTS ~/projects/F5-TTS
```

## Связано

- Направления: [tts](../tts.md)
- Альтернативы: [qwen3-tts](qwen3-tts.md), [fish-speech](fish-speech.md), [xtts](xtts.md)
