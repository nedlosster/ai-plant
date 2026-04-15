# Российские LLM (finetune под русский язык)

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), llama-server + Vulkan.

Полные описания моделей -- в [`families/`](families/README.md). Эта страница: сравнительные таблицы и выбор под задачу.

Замечание: для нативного русского без finetune -- см. [qwen35](families/qwen35.md), которая лидирует в open-source. Эти модели -- специализированные дообучения на русских корпусах.

## Сравнительная таблица

| Семья | Файл | База | Лучший вариант | VRAM Q4 |
|-------|------|------|----------------|---------|
| Saiga | [saiga](families/saiga.md) | Qwen2.5-72B / 32B / Llama-3.1-8B | saiga_qwen2.5_72b | ~44 GiB |
| T-pro / T-lite | [t-bank](families/t-bank.md) | Qwen2.5-72B / 7B-8B | T-pro 72B | ~44 GiB |
| Vikhr | [vikhr](families/vikhr.md) | Mistral 7B | Vikhr 7B | ~5 GiB |

## Выбор под задачу

### Максимальное качество русского

[Saiga (Qwen2.5-72B base)](families/saiga.md) -- топ среди finetune'ов, Apache 2.0 (база Qwen).
[T-pro 72B](families/t-bank.md) -- от Т-Банка, корпоративный фокус, Apache 2.0 (база Qwen).

### Быстрый русский (edge / прототипы)

[Vikhr 7B](families/vikhr.md) -- ~5 GiB, Apache 2.0.
[T-lite 8B](families/t-bank.md) -- ~5 GiB, корпоративный фокус.

### Альтернатива без finetune

[Qwen3.5-27B](families/qwen35.md#27b) или [Qwen3.5-122B-A10B](families/qwen35.md#122b-a10b) -- лучший русский в open-source без специального finetune.

## Бенчмарки русского

| Бенч | Назначение |
|------|-----------|
| MERA | Многозадачный русский benchmark |
| RuMMLU | Русский MMLU |
| Russian SuperGLUE | Понимание русского |

Saiga и T-pro демонстрируют топ-результаты среди finetune'ов на этих бенчмарках. Подробнее -- в файлах семейств.

## Связанные направления

- [llm.md](llm.md) -- общие LLM (Qwen3.5 как мультимодальная база с лучшим русским)
- [russian-vocals.md](russian-vocals.md) -- русский вокал через AI

## Связанные статьи

- [Анатомия LLM](../llm-guide/model-anatomy.md)
