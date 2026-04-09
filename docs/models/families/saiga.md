# Saiga (Илья Гусев, 2024-2025)

> Семейство finetune'ов Llama / Qwen / Mistral под русский язык.

**Тип**: dense (8B / 32B / 72B)
**Лицензия**: зависит от базы (Llama CL / Apache 2.0)
**Статус на сервере**: не скачана
**Направления**: [russian-llm](../russian-llm.md), [llm](../llm.md)

## Обзор

Saiga от Ильи Гусева -- серия dense-finetune'ов с фокусом на качественный русский язык. Базируется на Qwen2.5-72B/32B и Llama-3.1-8B. Один из ведущих российских open-source проектов в LLM.

## Варианты

| Вариант | База | Параметры | Лицензия | Hub |
|---------|------|-----------|----------|-----|
| Saiga Qwen2.5-72B | Qwen2.5-72B | 72B dense | Apache 2.0 | [IlyaGusev/saiga_qwen2.5_72b_gguf](https://huggingface.co/IlyaGusev) |
| Saiga Qwen2.5-32B | Qwen2.5-32B | 32B dense | Apache 2.0 | [IlyaGusev/saiga_qwen2.5_32b_gguf](https://huggingface.co/IlyaGusev) |
| Saiga Llama3.1-8B | Llama-3.1-8B | 8B dense | Llama CL | [IlyaGusev/saiga_llama3_8b_gguf](https://huggingface.co/IlyaGusev) |

## Сильные кейсы

- **Качественный русский** -- топ-уровень среди finetune'ов
- **Линейка размеров** -- от 8B до 72B
- **Активное обновление** -- регулярные релизы
- **Apache 2.0 для Qwen-баз** -- коммерция

## Слабые стороны

- Мультимодальности нет -- только текст
- Базовые ограничения базы (Llama CL для Llama-варианта)

## Идеальные сценарии

- **Русскоязычные чат-боты**
- **Перевод и суммаризация** на русском
- **RAG-системы** для русских документов
- **Замена ChatGPT в локальном режиме** для русского

## Загрузка

```bash
./scripts/inference/download-model.sh IlyaGusev/saiga_qwen2.5_32b_gguf --include "*Q4_K_M*"
```

## Связано

- Направления: [russian-llm](../russian-llm.md), [llm](../llm.md)
- Альтернативы: [qwen35](qwen35.md) (нативный русский без finetune), [t-bank](t-bank.md), [vikhr](vikhr.md)
