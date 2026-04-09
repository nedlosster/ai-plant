# MiniCPM-o 2.6 (OpenBMB, 2025)

> End-side multimodal: vision + video + audio + text в 8B параметров.

**Тип**: dense (~8B)
**Лицензия**: Open
**Статус на сервере**: не скачана
**Направления**: [vision](../vision.md)

## Обзор

MiniCPM-o 2.6 -- compact omni-модель (vision + video + audio + text) в 8B параметров. Llama 3-based + SigLIP vision + Whisper-style audio. End-to-end -- все модальности в одном forward pass. Задумана для запуска на смартфонах и edge-устройствах.

## Варианты

| Вариант | Параметры | VRAM Q4 | mmproj | Статус | Hub |
|---------|-----------|---------|--------|--------|-----|
| 2.6 | ~8B | ~5 GiB | ~1 GiB | не скачана | [openbmb/MiniCPM-o-2_6-gguf](https://huggingface.co/openbmb/MiniCPM-o-2_6-gguf) |

## Сильные кейсы

- **End-side эффективность** -- работает молниеносно
- **Real-time multimodal streaming** -- видео + аудио + текст с минимальной латентностью
- **OCR компактного класса** -- лучшая среди 7-8B моделей
- **Видео-вопросы-ответы** -- "что происходит в этом 30-секундном клипе"
- **Continuous video analysis** -- streaming video с обновлением понимания
- **Function calling** из коробки

## Слабые стороны

- Меньше [qwen25-omni](qwen25-omni.md) по абсолютному качеству на сложных задачах
- Reasoning средний (8B размер)
- Аудио не такое качественное как у специализированных speech-моделей

## Идеальные сценарии

- **IoT/edge** -- умные камеры с локальным анализом
- **Видеонаблюдение** -- "был ли человек в кадре последний час"
- **Live captioning + action recognition**
- **Locally-running mobile assistant**
- **Embedded devices** с ограниченной памятью

## Загрузка

```bash
./scripts/inference/download-model.sh openbmb/MiniCPM-o-2_6-gguf \
    --include '*Q4_K_M*' --include 'mmproj*'
```

## Ссылки

**Официально**:
- [HuggingFace: openbmb/MiniCPM-o-2_6](https://huggingface.co/openbmb/MiniCPM-o-2_6)
- [HuggingFace: openbmb/MiniCPM-o-2_6-gguf](https://huggingface.co/openbmb/MiniCPM-o-2_6-gguf)
- [HuggingFace: openbmb](https://huggingface.co/openbmb)
- [GitHub: OpenBMB/MiniCPM-o](https://github.com/OpenBMB/MiniCPM-o)

## Связано

- Направления: [vision](../vision.md)
- Альтернативы: [qwen25-omni](qwen25-omni.md), [smolvlm2](smolvlm2.md)
