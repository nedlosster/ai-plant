# Vikhr (Vikhrmodels, 2024)

> Мelкая russian-LLM на базе Mistral 7B, открытая community.

**Тип**: dense (7B)
**Лицензия**: Apache 2.0
**Статус на сервере**: не скачана
**Направления**: [russian-llm](../russian-llm.md), [llm](../llm.md)

## Обзор

Vikhr -- российская community-LLM на базе Mistral 7B. Apache 2.0. Один из первых проектов с фокусом на русский. Меньше Saiga, но активная экосистема и регулярные обновления.

## Варианты

| Вариант | База | Параметры | Hub |
|---------|------|-----------|-----|
| Vikhr 7B | Mistral 7B | 7B dense | [Vikhrmodels/Vikhr-7B-instruct_0.5](https://huggingface.co/Vikhrmodels) |

## Сильные кейсы

- **Apache 2.0** -- полная свобода
- **Быстрая** -- 7B параметров, мгновенный отклик
- **Community-проект** -- открытость, можно участвовать
- **Один из первых** русских open-source

## Слабые стороны

- Маленький размер -- уступает 32B+ моделям
- Контекст ограничен (~32K)
- Меньше внимания community чем у Saiga

## Идеальные сценарии

- **Edge-deployment** -- слабые серверы, embedded
- **Прототипирование** русскоязычных задач
- **Образовательные проекты**

## Загрузка

```bash
./scripts/inference/download-model.sh Vikhrmodels/Vikhr-7B-instruct_0.5 --include "*Q4_K_M*"
```

## Связано

- Направления: [russian-llm](../russian-llm.md), [llm](../llm.md)
- Альтернативы: [saiga](saiga.md) (большие модели), [qwen35](qwen35.md)
