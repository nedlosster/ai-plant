# T-pro / T-lite (Т-Банк, 2024-2025)

> Russian-LLM от Т-Банка: T-pro (большие, продакшн) и T-lite (быстрые).

**Тип**: dense
**Лицензия**: зависит от базы
**Статус на сервере**: не скачана
**Направления**: [russian-llm](../russian-llm.md), [llm](../llm.md)

## Обзор

T-pro и T-lite -- семейство russian-LLM от Т-Банка (бывший Тинькофф). T-pro: большие модели для качества (Qwen2.5-72B base). T-lite: компактные для скорости (Qwen2.5-7B/8B).

## Варианты

| Вариант | База | Параметры | Hub |
|---------|------|-----------|-----|
| T-pro 72B | Qwen2.5-72B | 72B dense | [t-tech/T-pro-it-1.0](https://huggingface.co/t-tech) |
| T-lite 8B | Qwen2.5-7B / Llama-3-8B | 7-8B dense | [t-tech/T-lite-instruct-0.1](https://huggingface.co/t-tech) |

## Сильные кейсы

- **Корпоративный focus** -- модели обученные с упором на банковские/финансовые задачи
- **Стабильность Т-Банка** -- регулярные обновления
- **Хороший русский** -- сравнимо с Saiga
- **T-lite быстрая** -- ~5 GiB, мгновенный отклик

## Слабые стороны

- Меньше community-внимания чем у Saiga
- Базовые ограничения Llama-base (для T-lite на Llama)

## Идеальные сценарии

- **Финансовые / банковские чат-боты**
- **Локальная замена облачных API** для бизнеса
- **Compliance-friendly** российская модель

## Загрузка

```bash
./scripts/inference/download-model.sh t-tech/T-pro-it-1.0 --include "*Q4_K_M*"
```

## Связано

- Направления: [russian-llm](../russian-llm.md), [llm](../llm.md)
- Альтернативы: [saiga](saiga.md), [vikhr](vikhr.md), [qwen35](qwen35.md)
