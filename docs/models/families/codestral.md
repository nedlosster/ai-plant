# Codestral (Mistral, 2024-2026)

> Лидер LMsys copilot arena по FIM, специализированный code completion для 80+ языков.

**Тип**: dense (22B)
**Лицензия**: MNPL (для коммерции -- проверить)
**Статус на сервере**: не скачана
**Направления**: [coding](../coding.md)

## Обзор

Codestral от Mistral -- специализированная модель для inline code completion. Версия 25.08 -- лидер LMsys copilot arena по FIM. 80+ языков программирования, контекст 256K, HumanEval 86.6%, MBPP 91.2%.

## Варианты

| Вариант | Параметры | Контекст | VRAM Q4 | Статус | Hub |
|---------|-----------|----------|---------|--------|-----|
| 25.08 | 22B dense | 256K | ~13 GiB | не скачана | [bartowski/Codestral-25.08-GGUF](https://huggingface.co/bartowski/Codestral-25.08-GGUF) |

## Сильные кейсы

- **Лидер LMsys copilot arena по FIM** -- лучший выбор для autocompletion
- **80+ языков программирования** -- от стандартных до экзотики
- **256K контекст** -- repo-level FIM
- **HumanEval 86.6%, MBPP 91.2%** -- сильные синтетические бенчи
- **Mistral-стабильность**

## Слабые стороны

- **MNPL-лицензия** -- ограничения на коммерцию (проверить условия)
- 22B dense -- ~15 tok/s на платформе (для FIM ок, для chat медленно)
- Reasoning слабее [qwen3-coder](qwen3-coder.md)

## Идеальные сценарии

- **IDE FIM на максимальном качестве** -- [Continue.dev](../../ai-agents/agents/continue-dev.md), llama.vscode
- **Многоязычные проекты** -- 80+ языков, лучший выбор для polyglot
- **Repository-level completion** -- понимание всего проекта

## Загрузка

```bash
./scripts/inference/download-model.sh bartowski/Codestral-25.08-GGUF --include "*Q4_K_M*"
```

## Ссылки

**Официально**:
- [HuggingFace: mistralai](https://huggingface.co/mistralai) -- организация Mistral
- [Блог релиза Codestral 25.08](https://mistral.ai/news/codestral-25-08/)

**GGUF-квантизации**:
- [bartowski/Codestral-25.08-GGUF](https://huggingface.co/bartowski/Codestral-25.08-GGUF)
- [unsloth/Codestral-22B-v0.1-GGUF](https://huggingface.co/unsloth/Codestral-22B-v0.1-GGUF) -- предыдущая версия

## Связано

- Направления: [coding](../coding.md)
- Альтернативы FIM: [qwen25-coder](qwen25-coder.md), [devstral](devstral.md)
