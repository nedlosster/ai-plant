# XTTS v2 (Coqui, 2023)

> Классика open-source voice cloning, 16 языков, 6 секунд reference, проверенная временем.

**Тип**: GPT-style decoder + HiFiGAN (~750M)
**Лицензия**: CPML (для коммерции -- проверить)
**Статус на сервере**: не скачана
**Направления**: [tts](../tts.md)

## Обзор

XTTS v2 -- самый скачиваемый TTS на HuggingFace. GPT-2-style decoder + HiFiGAN vocoder + speaker encoder. Возрастом 2-3 года, но качество всё ещё конкурентное. **Самый короткий reference в индустрии (6 секунд)**, 16 языков из коробки.

**Coqui (компания) закрылась в 2024**. Проект community-maintained.

## Варианты

| Вариант | Параметры | Языки | VRAM | Reference | Статус | Hub |
|---------|-----------|-------|------|-----------|--------|-----|
| XTTS v2 | ~750M | 16 | ~4 GiB | 6 сек | не скачана | [coqui/XTTS-v2](https://huggingface.co/coqui/XTTS-v2) |

GitHub: [idiap/coqui-ai-TTS](https://github.com/idiap/coqui-ai-TTS) (community fork)

## Сильные кейсы

- **6 секунд reference** -- самый короткий в индустрии
- **16 языков из коробки** -- максимум среди TTS-моделей (рус, англ, нем, исп, фр, ит, пор, пол, тур, чеш, нид, яп, кит, ара, корей, венг)
- **Streaming поддержка** для real-time
- **Самый низкий VRAM** -- ~4 GiB, можно крутить на слабых GPU
- **Fine-tuning из коробки** -- лучшая для создания "корпоративного голоса"
- **Зрелая экосистема** -- максимум туториалов и интеграций

## Слабые стороны

- **Самая старая в TTS-списке** -- по чисто акустическому качеству уступает [f5-tts](f5-tts.md) / [indextts2](indextts2.md)
- **Coqui закрылась в 2024** -- проект community-maintained, новых релизов не будет
- **CPML-лицензия** -- для коммерции нужно проверять условия
- Без emotional control
- Без free-form voice design

## Идеальные сценарии

- **16-язычный TTS** для глобальных продуктов
- **Минимальный reference** -- если есть только 6 сек, больше нет
- **Самый зрелый production-ready вариант** -- если нужна стабильность сегодня
- **Слабый GPU** или CPU-only deployment
- **Fine-tuning под уникальный корпоративный голос** на 30 минут датасета

## Загрузка

```bash
hf download coqui/XTTS-v2 --local-dir ~/models/XTTS-v2
git clone https://github.com/idiap/coqui-ai-TTS ~/projects/coqui-tts
```

## Связано

- Направления: [tts](../tts.md)
- Альтернативы: [qwen3-tts](qwen3-tts.md) (нативный русский), [f5-tts](f5-tts.md) (лучше качество)
