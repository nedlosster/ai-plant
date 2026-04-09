# Mistral Small 3.1 (Mistral, 2025)

> 24B multimodal, Apache 2.0, function calling, контекст 128K.

**Тип**: dense (24B)
**Лицензия**: Apache 2.0
**Статус на сервере**: не скачана
**Направления**: [vision](../vision.md), [llm](../llm.md)

## Обзор

Mistral Small 3.1 24B -- multimodal модель Mistral с vision-encoder Pixtral-style. Контекст 128K. Function calling из коробки. Сбалансированный размер для production-нагрузки.

## Варианты

| Вариант | Параметры | VRAM Q4 | mmproj | Контекст | Статус | Hub |
|---------|-----------|---------|--------|----------|--------|-----|
| Small 3.1 24B Instruct | 24B dense | ~14 GiB | ~1 GiB | 128K | не скачана | [ggml-org/Mistral-Small-3.1-24B-Instruct-2503-GGUF](https://huggingface.co/ggml-org/Mistral-Small-3.1-24B-Instruct-2503-GGUF) |

## Сильные кейсы

- **Универсальная workhorse** -- неплохо во всех задачах
- **Function calling по vision** -- скриншот + tool call в одном request
- **Production stability** -- зрелая Mistral-серия
- **Apache 2.0** + 128K контекст
- **Хороший русский и европейские языки** -- лучше [pixtral](pixtral.md) на не-английском

## Слабые стороны

- Dense 24B -- медленнее MoE того же качества (~20 vs 80 у [qwen3-vl 30B-A3B](qwen3-vl.md#30b-a3b))
- На каждой отдельной задаче есть более сильный специалист
- "Серединка по всему"

## Идеальные сценарии

- **Single-model setup** для небольшой команды -- одна модель на все задачи
- **Production API** когда нужны predictable timings
- **Mistral-экосистема** (если уже используешь их LLM)

## Загрузка

```bash
./scripts/inference/download-model.sh ggml-org/Mistral-Small-3.1-24B-Instruct-2503-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*'
```

## Связано

- Направления: [vision](../vision.md), [llm](../llm.md)
- Альтернативы: [pixtral](pixtral.md), [gemma4](gemma4.md), [qwen3-vl](qwen3-vl.md)
