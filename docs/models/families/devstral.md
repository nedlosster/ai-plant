# Devstral 2 (Mistral, 2025-2026)

> Универсальный кодинг -- лидер dense-сегмента по SWE-bench Verified, FIM+agent в одной модели.

**Тип**: dense (24B)
**Лицензия**: Apache 2.0
**Статус на сервере**: скачана (Q4_K_M, ~14 GiB)
**Направления**: [coding](../coding.md)
**Function calling**: native (Mistral [TOOL_CALLS] формат, dense alternative для agent loops)
**FIM**: да

## Обзор

Devstral 2 от Mistral AI (декабрь 2025) -- 24B dense-модель специально для кодинга. Лучший SWE-bench Verified среди компактных моделей (72.2% при всего 24B параметров), помещается на одном RTX 4090 или Mac 32GB. Универсальная: поддерживает FIM (inline-автодополнение) и agent-style работу одновременно.

## Варианты

| Вариант | Параметры | Контекст | VRAM Q4 | Статус | Hub |
|---------|-----------|----------|---------|--------|-----|
| Small 2 24B Instruct | 24B dense | 256K | ~15 GiB | не скачана | [unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF](https://huggingface.co/unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF) |

## Сильные кейсы

- **Лучший SWE-bench среди компактных моделей** -- 72.2% при 24B
- **256K контекст** -- весь проект целиком
- **FIM из коробки** -- одна модель для inline и chat-режимов
- **Универсальность** -- покрывает FIM, chat, agent в одном файле
- **Apache 2.0** -- коммерция без оговорок
- **Стабильность Mistral** -- проверенная экосистема

## Слабые стороны

- Dense 24B -- медленнее MoE того же качества (~20 vs 86 tok/s у [qwen3-coder 30B-A3B](qwen3-coder.md#30b-a3b))
- Русские комментарии слабее Qwen-серии
- Не лидер по чистому HumanEval (там [qwen25-coder 32B](qwen25-coder.md#32b) сильнее)

## Идеальные сценарии

- **"Одна модель на всё"** -- FIM + chat + agent
- Когда нужны FIM **и** strong agent в одной модели
- Production-окружения с predictable timings
- Замена нескольких отдельных моделей одной

## Загрузка

```bash
./scripts/inference/download-model.sh unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF --include "*Q4_K_M*"
```

## Бенчмарки

| Бенч | Значение |
|------|----------|
| SWE-bench Verified | **72.2%** |

## Ссылки

**Официально**:
- [HuggingFace: mistralai](https://huggingface.co/mistralai) -- организация Mistral
- [HuggingFace: mistralai/Devstral-Small-2-24B](https://huggingface.co/mistralai/Devstral-Small-2-24B-Instruct-2512) -- основная модель

**GGUF-квантизации**:
- [unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF](https://huggingface.co/unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF)
- [bartowski/Devstral-Small-2-24B-Instruct-2512-GGUF](https://huggingface.co/bartowski/Devstral-Small-2-24B-Instruct-2512-GGUF)

## Связано

- Направления: [coding](../coding.md)
- Альтернативы: [qwen3-coder Next](qwen3-coder.md#next-80b-a3b) (MoE, 70.6% SWE-V), [codestral](codestral.md) (FIM-чемпион)
