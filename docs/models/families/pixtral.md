# Pixtral 12B (Mistral, 2024)

> Apache 2.0 multimodal с arbitrary resolution и multi-image input.

**Тип**: dense (12B)
**Лицензия**: Apache 2.0
**Статус на сервере**: не скачана
**Направления**: [vision](../vision.md)

## Обзор

Pixtral 12B от Mistral -- multimodal модель с custom Pixtral vision encoder. Поддержка arbitrary resolution и aspect ratio. Multi-image input с interleaving с текстом. Apache 2.0 -- полная коммерческая свобода. Превосходит Qwen2-VL 7B, LLaVa-OneVision 7B, Phi-3.5 Vision на instruction following.

## Варианты

| Вариант | Параметры | VRAM Q4 | mmproj | Статус | Hub |
|---------|-----------|---------|--------|--------|-----|
| Pixtral 12B | 12B dense | 7.48 GiB | 463 MB Q8_0 | не скачана | [ggml-org/pixtral-12b-GGUF](https://huggingface.co/ggml-org/pixtral-12b-GGUF) |

## Сильные кейсы

- **Instruction following на vision-задачах** -- лучше следует точным инструкциям
- **Multi-image input** -- несколько фото за раз с textual interleaving
- **Arbitrary resolution** -- картинки любого размера без resize
- **Apache 2.0** -- встраивание в коммерческие продукты без оговорок
- **Хорошая память** на длинные инструкции

## Слабые стороны

- OCR-русский слабее [qwen3-vl](qwen3-vl.md)
- Reasoning средний (12B dense, не MoE)
- Контекст ~128K (меньше Qwen3-VL)
- Не так силён на математике как [internvl](internvl.md)

## Идеальные сценарии

- **E-commerce**: "сравни 3 фото товаров и выбери лучший"
- **Quality control**: фото детали + чек-лист дефектов
- **Архивирование фото** с тегами по строгому schema
- **Замена платного OpenAI Vision API** в SaaS-продуктах (Apache 2.0)

## Загрузка

```bash
./scripts/inference/download-model.sh ggml-org/pixtral-12b-GGUF \
    --include '*Q4_K_M*' --include 'mmproj*Q8_0*'
```

## Ссылки

**Официально**:
- [HuggingFace: mistralai/Pixtral-12B-2409](https://huggingface.co/mistralai/Pixtral-12B-2409) -- основная модель
- [HuggingFace: mistralai](https://huggingface.co/mistralai) -- организация

**GGUF-квантизации**:
- [ggml-org/pixtral-12b-GGUF](https://huggingface.co/ggml-org/pixtral-12b-GGUF) -- официальный llama.cpp конвертер

## Связано

- Направления: [vision](../vision.md)
- Альтернативы: [qwen3-vl](qwen3-vl.md), [mistral-small-31](mistral-small-31.md)
