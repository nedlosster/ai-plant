# SmolVLM2 (HuggingFace, 2025)

> Самая маленькая VLM -- 256M/500M/2.2B вариантов, edge-deployment, видео.

**Тип**: dense (256M / 500M / 2.2B)
**Лицензия**: Open
**Статус на сервере**: не скачана
**Направления**: [vision](../vision.md)

## Обзор

SmolVLM2 от HuggingFace -- линейка самых компактных VLM. SmolLM2 base + tiny SigLIP. **256M вариант -- меньше 1 GB VRAM**. Train набор сосредоточен на простых задачах. Поддержка видео.

## Варианты

| Вариант | Параметры | VRAM Q4 | Статус | Hub |
|---------|-----------|---------|--------|-----|
| SmolVLM2-2.2B | 2.2B | ~1.4 GiB + 0.5 GB mmproj | не скачана | [ggml-org/SmolVLM2-2.2B-Instruct-GGUF](https://huggingface.co/ggml-org/SmolVLM2-2.2B-Instruct-GGUF) |
| SmolVLM2-500M | 500M | ~0.5 GiB | не скачана | [HuggingFaceTB/SmolVLM2-500M-Instruct](https://huggingface.co/HuggingFaceTB/SmolVLM2-500M-Instruct) |
| SmolVLM2-256M | 256M | <1 GiB | не скачана | [HuggingFaceTB/SmolVLM2-256M-Instruct](https://huggingface.co/HuggingFaceTB/SmolVLM2-256M-Instruct) |

## Сильные кейсы

- **Скорость** -- ~150 tok/s, мгновенный отклик
- **Минимальный footprint** -- 256M вариант запустится даже на ноутбуке без GPU
- **Видео из коробки** -- понимание коротких клипов
- **Batch-обработка** -- тысячи фото за минуты
- **Edge-deployment** -- Raspberry Pi 5, мобильные устройства, embedded
- **Низкое энергопотребление**

## Слабые стороны

- Простая модель -- ошибается на сложных reasoning
- OCR ограничен (короткие тексты)
- Не понимает мелкие детали на больших изображениях
- Function calling отсутствует

## Идеальные сценарии

- **Tagging огромного фотоархива** (миллионы снимков)
- **Filter / first-pass**: SmolVLM делает быструю классификацию, сложные случаи отдаёт в [qwen3-vl](qwen3-vl.md)
- **Локально на телефоне** или Raspberry Pi
- **Realtime camera feed analysis**
- **Batch quality control** в производстве

## Загрузка

```bash
./scripts/inference/download-model.sh ggml-org/SmolVLM2-2.2B-Instruct-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*'
```

## Связано

- Направления: [vision](../vision.md)
- Альтернативы: [minicpm-o](minicpm-o.md), [qwen3-vl](qwen3-vl.md)
