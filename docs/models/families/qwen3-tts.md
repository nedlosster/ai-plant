# Qwen3-TTS (Alibaba, 2026)

> Свежайшая TTS от Qwen с нативной поддержкой русского, voice cloning, free-form voice design.

**Тип**: language model (audio tokens)
**Лицензия**: Open
**Статус на сервере**: не скачана
**Направления**: [tts](../tts.md)

## Обзор

Qwen3-TTS -- свежайшая TTS-модель от Alibaba (январь 2026). Token-based audio generation -- архитектурно как LLM, поэтому стабильна на длинных текстах. **10 языков нативно**, включая русский без дообучения.

## Варианты

| Вариант | Параметры | Языки | VRAM | Статус | Hub |
|---------|-----------|-------|------|--------|-----|
| Qwen3-TTS | ~7B | 10 | ~8 GiB | не скачана | [Qwen/Qwen3-TTS](https://huggingface.co/Qwen/Qwen3-TTS) |

GitHub: [QwenLM/Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS)

## Сильные кейсы

- **Voice cloning** -- голос по 10 сек reference аудио
- **Free-form voice design** -- описать желаемый голос ТЕКСТОМ ("молодой женский с лёгкой усталостью") -- модель сгенерирует
- **Streaming generation** -- output по мере генерации
- **Стабильная работа на длинных текстах** -- 10+ часов одним голосом
- **10 языков нативно** -- одна модель на всё
- **Русский без потери качества**

## Слабые стороны

- Самая большая в TTS-списке (~8 GiB)
- Свежий релиз -- инструменты ещё нарабатываются
- Эмоциональный контроль слабее [indextts2](indextts2.md)

## Идеальные сценарии

- **Длинные аудиокниги на русском**
- **Описать голос словами без референса** -- уникальная фича
- **Многоязычные TTS-сервисы** -- одна модель на 10 языков
- **Брендовый голос проекта**

## Загрузка

```bash
hf download Qwen/Qwen3-TTS --local-dir ~/models/Qwen3-TTS
git clone https://github.com/QwenLM/Qwen3-TTS ~/projects/Qwen3-TTS
```

## Ссылки

**Официально**:
- [HuggingFace: Qwen/Qwen3-TTS](https://huggingface.co/Qwen/Qwen3-TTS) -- основная модель
- [HuggingFace: Qwen](https://huggingface.co/Qwen) -- организация
- [GitHub: QwenLM/Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS) -- исходники

## Связано

- Направления: [tts](../tts.md)
- Альтернативы: [f5-tts](f5-tts.md), [fish-speech](fish-speech.md), [indextts2](indextts2.md), [xtts](xtts.md)
