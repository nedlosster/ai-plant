# QwQ (Alibaba, 2024-2026)

> Reasoning-модель Qwen с chain-of-thought, MATH-500 95.2.

**Тип**: dense (32B)
**Лицензия**: Apache 2.0
**Статус на сервере**: не скачана
**Направления**: [llm](../llm.md)

## Обзор

QwQ-32B -- специализированная reasoning-модель от Alibaba. Сильна на математических и логических задачах за счёт обучения на chain-of-thought. AIME24 79.5, MATH-500 95.2. 32B dense, ~19 GiB Q4_K_M. Apache 2.0.

## Варианты

| Вариант | Параметры | Контекст | VRAM Q4 | MATH-500 | AIME24 | Статус | Hub |
|---------|-----------|----------|---------|----------|--------|--------|-----|
| QwQ-32B Preview | 32B dense | 32K | ~19 GiB | 95.2 | 79.5 | не скачана | [bartowski/QwQ-32B-Preview-GGUF](https://huggingface.co/bartowski/QwQ-32B-Preview-GGUF) |

## Сильные кейсы

- **Математика** -- топ MATH-500 среди open-source среднего размера
- **Логика и reasoning** -- видно ход мысли модели
- **Apache 2.0** -- коммерция без ограничений
- **Хороший русский** -- линейка Qwen

## Слабые стороны

- **Длинные chain-of-thought** -- ответы занимают много токенов перед сутью
- **Не для quick chat** -- thinking-трасса перегружает простые ответы
- Контекст 32K -- меньше чем у универсальных Qwen3.5

## Идеальные сценарии

- **Решение математических задач** с пошаговым выводом
- **Логические головоломки**
- **Проверка доказательств**
- **Образовательные сценарии** -- видно как модель думает
- Альтернатива: [deepseek-distill](deepseek-distill.md) (тоже reasoning, MIT)

## Загрузка

```bash
./scripts/inference/download-model.sh bartowski/QwQ-32B-Preview-GGUF --include "*Q4_K_M*"
```

## Ссылки

**Официально**:
- [HuggingFace: Qwen/QwQ-32B-Preview](https://huggingface.co/Qwen/QwQ-32B-Preview) -- основная
- [HuggingFace: Qwen](https://huggingface.co/Qwen) -- организация

**GGUF-квантизации**:
- [bartowski/QwQ-32B-Preview-GGUF](https://huggingface.co/bartowski/QwQ-32B-Preview-GGUF)
- [unsloth/QwQ-32B-Preview-GGUF](https://huggingface.co/unsloth/QwQ-32B-Preview-GGUF)

## Связано

- Направления: [llm](../llm.md)
- Альтернативы: [deepseek-distill](deepseek-distill.md), [phi](phi.md)
