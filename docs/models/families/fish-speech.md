# Fish Speech (fishaudio, 2024-2025)

> Apache 2.0 TTS с voice cloning, 8 языков, ELO 1339 на TTS Arena.

**Тип**: VQGAN + Llama-decoder (~500M)
**Лицензия**: Apache 2.0
**Статус на сервере**: не скачана
**Направления**: [tts](../tts.md)

## Обзор

Fish Speech 1.5 -- необычная архитектура: VQGAN audio tokenizer + Llama-based decoder. Аудио кодируется в дискретные токены, дальше Llama их генерирует. Один из лидеров на TTS Arena (ELO 1339). 8 языков. **Apache 2.0** -- единственная топовая TTS с такой свободной лицензией.

## Варианты

| Вариант | Параметры | Языки | VRAM | TTS Arena ELO | Статус | Hub |
|---------|-----------|-------|------|---------------|--------|-----|
| 1.5 | ~500M | 8 (en, zh, ru, ja, ko, fr, de, es) | ~6 GiB | 1339 | не скачана | [fishaudio/fish-speech-1.5](https://huggingface.co/fishaudio/fish-speech-1.5) |

GitHub: [fishaudio/fish-speech](https://github.com/fishaudio/fish-speech)

## Сильные кейсы

- **Apache 2.0** -- единственная топовая TTS с такой свободной лицензией
- **8 языков с приличным качеством** -- включая русский
- **VQGAN + Llama** архитектура -- стабильная и быстрая
- **TTS Arena ELO 1339** -- по слепым тестам один из самых натуральных
- **Streaming поддержка** -- встраивание в real-time системы
- **Эмоциональная согласованность** -- если в reference радость, в output тоже

## Слабые стороны

- Без free-form voice design
- Русский немного хуже [qwen3-tts](qwen3-tts.md) (community-сравнения)
- Не лидер ни в одной отдельной нише -- "ровно хорош везде"

## Идеальные сценарии

- **Коммерческие SaaS-продукты** -- TTS как часть платного сервиса (Apache 2.0!)
- API-сервис озвучки внутри компании
- Локализация контента в маркетинге
- Замена платных AWS Polly / Google TTS

## Загрузка

```bash
hf download fishaudio/fish-speech-1.5 --local-dir ~/models/fish-speech-1.5
git clone https://github.com/fishaudio/fish-speech ~/projects/fish-speech
```

## Ссылки

**Официально**:
- [HuggingFace: fishaudio/fish-speech-1.5](https://huggingface.co/fishaudio/fish-speech-1.5)
- [HuggingFace: fishaudio](https://huggingface.co/fishaudio) -- организация
- [GitHub: fishaudio/fish-speech](https://github.com/fishaudio/fish-speech)

## Связано

- Направления: [tts](../tts.md)
- Альтернативы: [qwen3-tts](qwen3-tts.md), [f5-tts](f5-tts.md), [indextts2](indextts2.md)
