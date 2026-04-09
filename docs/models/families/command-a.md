# Command A (Cohere, 2025)

> 111B dense, специализирована под RAG, tool use, enterprise-задачи, контекст 256K.

**Тип**: dense (111B)
**Лицензия**: CC-BY-NC (только некоммерческое)
**Статус на сервере**: не скачана
**Направления**: [llm](../llm.md)

## Обзор

Command A от Cohere -- 111B dense-модель, оптимизированная для RAG (Retrieval-Augmented Generation), function calling, enterprise-сценариев. Контекст 256K. На 120 GiB помещается комфортно: Q4_K_M ~65 GiB, Q5_K_M ~78 GiB.

## Варианты

| Вариант | Параметры | Контекст | VRAM Q4 | VRAM Q5 | Статус | Hub |
|---------|-----------|----------|---------|---------|--------|-----|
| Command A 111B | 111B dense | 256K | ~65 GiB | ~78 GiB | не скачана | [bartowski/command-a-111b-GGUF](https://huggingface.co/bartowski/command-a-111b-GGUF) |

## Сильные кейсы

- **RAG из коробки** -- оптимизирована под извлечение фактов из контекста
- **Function calling** -- сильная поддержка tool use
- **Контекст 256K** -- много документов в одном запросе
- **Enterprise-готовность** -- консистентные ответы, низкая галлюцинация
- **Q5 на 120 GiB** -- помещается с запасом

## Слабые стороны

- **CC-BY-NC** -- запрещено коммерческое использование
- Dense 111B -- ~5 tok/s генерация, не для интерактивного chat'а
- Хуже на обычном чате чем universal-модели

## Идеальные сценарии

- **RAG-системы** в личных/исследовательских проектах
- **Document QA** на больших корпусах
- **Tool use agents** для некоммерческих задач
- Эксперименты с function calling

## Загрузка

```bash
./scripts/inference/download-model.sh bartowski/command-a-111b-GGUF --include "*Q4_K_M*"
```

## Ссылки

**Официально**:
- [HuggingFace: CohereForAI](https://huggingface.co/CohereForAI) -- организация
- [HuggingFace: CohereForAI/c4ai-command-a-03-2025](https://huggingface.co/CohereForAI/c4ai-command-a-03-2025) -- основная модель

**GGUF-квантизации**:
- [bartowski/command-a-111b-GGUF](https://huggingface.co/bartowski/command-a-111b-GGUF)
- [mradermacher/c4ai-command-a-03-2025-GGUF](https://huggingface.co/mradermacher/c4ai-command-a-03-2025-GGUF)

## Связано

- Направления: [llm](../llm.md)
- Альтернативы (для коммерции): [qwen35-122b](qwen35.md#122b-a10b), [mixtral](mixtral.md)
