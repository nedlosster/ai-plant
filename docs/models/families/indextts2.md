# IndexTTS-2 (IndexTeam, 2025-2026)

> Industrial-level controllable TTS -- контроль эмоций и длительности, лидер по WER и speaker similarity.

**Тип**: GPT-based + emotion conditioning (~1.5B)
**Лицензия**: Open
**Статус на сервере**: не скачана
**Направления**: [tts](../tts.md)

## Обзор

IndexTTS-2 -- продвинутая TTS-модель с контролем эмоций и точной длительности. Превосходит state-of-the-art по WER, speaker similarity, emotional fidelity. Имеет emotion conditioning module и duration controller -- эмоция и tempo задаются как параметры, а не выводятся из reference.

## Варианты

| Вариант | Параметры | Языки | VRAM | Статус | Hub |
|---------|-----------|-------|------|--------|-----|
| IndexTTS-1.5 (стабильная) | ~1.5B | en, zh, ru, и др. | ~8 GiB | не скачана | [IndexTeam/IndexTTS-1.5](https://huggingface.co/IndexTeam/IndexTTS-1.5) |
| IndexTTS-2 | ~1.5B | en, zh, ru, и др. | ~8 GiB | не скачана | [IndexTeam/IndexTTS-2](https://huggingface.co/IndexTeam/IndexTTS-2) |

GitHub: [index-tts/index-tts](https://github.com/index-tts/index-tts)

## Сильные кейсы

- **Контроль длительности** -- задать точное время произнесения фразы (для дубляжа под движение губ)
- **Контроль эмоций**: радость, грусть, нейтрально, агрессия, удивление, страх
- **Контроль характеристик голоса** -- возраст, пол, акцент
- **Лучшая в классе zero-shot voice cloning** по WER, speaker similarity
- **Industrial-level controllable** -- продакшн-уровень

## Слабые стороны

- Самая большая в TTS-списке (~1.5B параметров, ~8 GiB VRAM)
- Сложнее в использовании (больше параметров для tuning)
- Слабее на длинных монотонных текстах -- акцент на эмоциональности

## Идеальные сценарии

- **Кинодубляж с lip-sync** -- единственная open-source с реальным контролем длительности
- **Игровая озвучка** -- один персонаж разными эмоциями для разных сцен
- **Audiobook narration** -- эмоционально окрашенное чтение
- **Best WER** -- лучшая разборчивость для слабослышащих
- **A/B-тестирование голосов** для UX-исследований

## Загрузка

```bash
hf download IndexTeam/IndexTTS-1.5 --local-dir ~/models/IndexTTS-1.5
git clone https://github.com/index-tts/index-tts ~/projects/index-tts
```

## Связано

- Направления: [tts](../tts.md)
- Альтернативы: [qwen3-tts](qwen3-tts.md), [f5-tts](f5-tts.md), [fish-speech](fish-speech.md)
