# Llama (Meta, 2024-2026)

> Эталон open-source LLM, максимальная экосистема. Llama 3.1/3.3/4.

**Тип**: dense (3.1/3.3) + MoE (4 Scout)
**Лицензия**: Llama Community License (ограничение 700M MAU)
**Статус на сервере**: не скачана
**Направления**: [llm](../llm.md), [vision](../vision.md) (4 Scout)

## Обзор

Llama от Meta -- эталон open-source. Лучший английский язык, максимально зрелая экосистема (тысячи fine-tune'ов, интеграции, гайды).

На платформе при 120 GiB можно держать **Llama-3.3-70B в Q8_0** с контекстом 32K -- максимум качества dense.

## Варианты

| Вариант | Параметры | Active | VRAM Q4 | VRAM Q8 | Контекст | Статус | Hub |
|---------|-----------|--------|---------|---------|----------|--------|-----|
| 3.1-8B Instruct | 8B dense | 8B | ~5 GiB | ~9 GiB | 128K | не скачана | [bartowski/Llama-3.1-8B-Instruct-GGUF](https://huggingface.co/bartowski/Llama-3.1-8B-Instruct-GGUF) |
| 3.3-70B Instruct | 70B dense | 70B | ~42 GiB | ~74 GiB | 128K | не скачана | [bartowski/Llama-3.3-70B-Instruct-GGUF](https://huggingface.co/bartowski/Llama-3.3-70B-Instruct-GGUF) |
| 4 Scout | 109B MoE | 17B | ~67 GiB | -- | **10M** | не скачана | [bartowski/Llama-4-Scout-17B-16E-Instruct-GGUF](https://huggingface.co/bartowski/Llama-4-Scout-17B-16E-Instruct-GGUF) |

### 3.3-70B {#3-3-70b}

Эталон 70B dense. **Q8 на 120 GiB помещается с запасом**: 74 GB модель + ctx 32K (~20 GB) = ~94 GB. При 96 GiB это было на пределе.

### 4 Scout {#4-scout}

Multimodal MoE с **контекстом 10M токенов**. Уникальное предложение для работы с очень длинными документами.

## Сильные кейсы

- **Лучший английский** среди open-source
- **Зрелая экосистема** -- максимум интеграций, fine-tune'ов, документации
- **Llama-3.3-70B Q8** -- максимальное качество dense, помещается на 120 GiB
- **4 Scout: контекст 10M** -- уникально для open-source
- **Vision (4 Scout)** -- multimodal из коробки

## Слабые стороны

- **Русский базовый** -- хуже Qwen-серии
- Llama Community License -- ограничение 700M MAU (для большинства проектов несущественно)
- 70B dense медленнее MoE того же качества

## Идеальные сценарии

- Англоязычные проекты с фокусом на качество
- Очень длинные документы (4 Scout, 10M контекст)
- Замена платных API в production (Llama -- эталон)
- Reference baseline для тестирования

## Загрузка

```bash
# 3.3-70B Q8 (~74 GiB) -- максимум качества
./scripts/inference/download-model.sh bartowski/Llama-3.3-70B-Instruct-GGUF --include "*Q8_0*"

# 3.3-70B Q4 (~42 GiB) -- быстрее, меньше памяти
./scripts/inference/download-model.sh bartowski/Llama-3.3-70B-Instruct-GGUF --include "*Q4_K_M*"

# 3.1-8B (~5 GiB) -- baseline
./scripts/inference/download-model.sh bartowski/Llama-3.1-8B-Instruct-GGUF --include "*Q4_K_M*"

# 4 Scout (~67 GiB, vision + 10M context)
./scripts/inference/download-model.sh bartowski/Llama-4-Scout-17B-16E-Instruct-GGUF --include "*Q4_K_M*"
```

## Связано

- Направления: [llm](../llm.md), [vision](../vision.md)
- Альтернативы: [qwen35](qwen35.md) (лучший русский), [mixtral](mixtral.md) (MoE альтернатива)
