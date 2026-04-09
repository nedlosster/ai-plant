# Qwen2.5-Omni (Alibaba, 2025)

> Multimodal в три стороны: vision + audio + text. Real-time speech, voice agent.

**Тип**: dense (7B)
**Лицензия**: Apache 2.0
**Статус на сервере**: скачана (7B Q4_K_M + mmproj Q8_0 + mmproj F16)
**Направления**: [vision](../vision.md), [tts](../tts.md)

## Обзор

Qwen2.5-Omni -- единственная в коллекции **omni-модель**: понимает картинки И аудио. Talker-Thinker архитектура: один поток для генерации текста, другой для синтеза речи. От ggml-org (официальный конвертер llama.cpp).

## Варианты

| Вариант | Параметры | VRAM Q4 | mmproj | Статус | Hub |
|---------|-----------|---------|--------|--------|-----|
| 7B | 7B dense | ~5 GiB | ~1 GiB | **скачана** | [ggml-org/Qwen2.5-Omni-7B-GGUF](https://huggingface.co/ggml-org/Qwen2.5-Omni-7B-GGUF) |
| 3B | 3B dense | ~2 GiB | ~0.5 GiB | не скачана | [ggml-org/Qwen2.5-Omni-3B-GGUF](https://huggingface.co/ggml-org/Qwen2.5-Omni-3B-GGUF) |

## Архитектура

- Qwen2.5 base + два encoder'а: vision (Qwen-VL ViT) + audio (Whisper-style)
- Talker-Thinker: один поток для текста, другой для речи
- End-to-end -- все модальности в одном forward pass

## Сильные кейсы

- **Real-time speech conversation** -- голос на входе и на выходе, streaming
- **Анализ видео-звонков** -- картинка (что показывают) + звук (что говорят) одновременно
- **Audio captioning** -- транскрипция + описание (музыка, шумы, эмоции)
- **Voice-controlled vision agent** -- "посмотри что на экране и опиши голосом"
- **Аудиокниги по картинкам** для слабовидящих
- **Multimodal обучение** -- видеолекции с речью лектора

## Слабые стороны

- 7B -- слабее 30B+ моделей на сложных vision-задачах
- OCR хуже [qwen3-vl](qwen3-vl.md)
- Качество speech уступает специализированным TTS (см. [tts.md](../tts.md))

## Идеальные сценарии

- Голосовой ассистент в умном доме (Home Assistant + Wyoming protocol)
- Real-time captioning для слабослышащих
- Анализ записей встреч (Zoom/Teams)
- Доступность для слабовидящих
- Multimodal CLI

## Загрузка

```bash
./scripts/inference/download-model.sh ggml-org/Qwen2.5-Omni-7B-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*'
```

## Связано

- Направления: [vision](../vision.md), [tts](../tts.md)
- Альтернативы: [minicpm-o](minicpm-o.md) (тоже omni), [qwen3-vl](qwen3-vl.md) (только vision, мощнее)
