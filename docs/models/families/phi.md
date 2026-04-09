# Phi (Microsoft, 2024-2026)

> Маленькие модели уровня больших -- reasoning при минимальном VRAM.

**Тип**: dense (14B)
**Лицензия**: MIT
**Статус на сервере**: не скачана
**Направления**: [llm](../llm.md)

## Обзор

Phi-серия от Microsoft -- модели обученные на качественных синтетических данных. Phi-4 (14B dense) даёт MMLU 84.8 -- уровень 70B при 14B параметрах. MIT-лицензия. Контекст 16K (короткий).

## Варианты

| Вариант | Параметры | Контекст | VRAM Q4 | MMLU | Статус | Hub |
|---------|-----------|----------|---------|------|--------|-----|
| Phi-4 | 14B dense | 16K | ~9 GiB | 84.8 | не скачана | [bartowski/phi-4-GGUF](https://huggingface.co/bartowski/phi-4-GGUF) |

## Сильные кейсы

- **MMLU 84.8 при 14B** -- уровень 70B-моделей
- **Низкий VRAM** -- ~9 GiB
- **MIT-лицензия** -- никаких ограничений
- **Хорошие математические способности** -- обучена на reasoning-данных

## Слабые стороны

- **Контекст всего 16K** -- мало для современных задач
- **Русский слабый** -- обучена в основном на английском
- Не для длинных документов и сложных контекстов

## Идеальные сценарии

- Reasoning при ограниченном VRAM
- Образовательные задачи (математика, логика)
- Локальный baseline для тестов
- Embedded-сценарии

## Загрузка

```bash
./scripts/inference/download-model.sh bartowski/phi-4-GGUF --include "*Q4_K_M*"
```

## Ссылки

**Официально**:
- [HuggingFace: microsoft/phi-4](https://huggingface.co/microsoft/phi-4) -- основная модель
- [HuggingFace: microsoft](https://huggingface.co/microsoft) -- организация Microsoft

**GGUF-квантизации**:
- [bartowski/phi-4-GGUF](https://huggingface.co/bartowski/phi-4-GGUF)
- [unsloth/phi-4-GGUF](https://huggingface.co/unsloth/phi-4-GGUF)
- [microsoft/phi-4-gguf](https://huggingface.co/microsoft/phi-4-gguf) -- официальный

## Связано

- Направления: [llm](../llm.md)
- Альтернативы: [qwen35](qwen35.md) (универсальнее), [qwq](qwq.md) (специализированный reasoning)
