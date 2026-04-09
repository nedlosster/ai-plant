# Mixtral 8x22B (Mistral, 2024)

> Большой быстрый MoE 141B / 39B active, 64K контекст, Apache 2.0.

**Тип**: MoE (39B active / 141B total)
**Лицензия**: Apache 2.0
**Статус на сервере**: не скачана
**Направления**: [llm](../llm.md)

## Обзор

Mixtral 8x22B -- проверенный MoE от Mistral. 141B параметров при 39B активных -- больше, чем у Qwen MoE (3-10B), потенциально выше качество на сложных задачах. Контекст 64K, Apache 2.0, зрелая экосистема.

## Варианты

| Вариант | Параметры | Active | Контекст | VRAM Q4 | Статус | Hub |
|---------|-----------|--------|----------|---------|--------|-----|
| 8x22B Instruct v0.1 | 141B MoE | 39B | 64K | ~82 GiB | не скачана | [bartowski/Mixtral-8x22B-Instruct-v0.1-GGUF](https://huggingface.co/bartowski/Mixtral-8x22B-Instruct-v0.1-GGUF) |

## Сильные кейсы

- **39B активных параметров** -- больше, чем у Qwen MoE, выше качество на сложных задачах
- **Контекст 64K**
- **Apache 2.0**
- **Проверенная экосистема** -- стабильная, много fine-tune'ов
- **При 120 GiB**: Q4_K_M (~82 GiB) + ctx 32K (~15 GiB) = ~97 GiB. При 96 GiB не помещалась с контекстом

## Слабые стороны

- 82 GiB Q4 -- занимает большую часть памяти
- Русский средний (хуже Qwen)
- Старее новых релизов 2026

## Идеальные сценарии

- Сложные reasoning-задачи требующие большой active-капасити
- Fine-tuning под доменные задачи (есть много community-вариантов)
- Замена платных API на стабильную open-source альтернативу

## Загрузка

```bash
./scripts/inference/download-model.sh bartowski/Mixtral-8x22B-Instruct-v0.1-GGUF --include "*Q4_K_M*"
```

## Ссылки

**Официально**:
- [HuggingFace: mistralai/Mixtral-8x22B-Instruct-v0.1](https://huggingface.co/mistralai/Mixtral-8x22B-Instruct-v0.1) -- основная
- [HuggingFace: mistralai](https://huggingface.co/mistralai) -- организация

**GGUF-квантизации**:
- [bartowski/Mixtral-8x22B-Instruct-v0.1-GGUF](https://huggingface.co/bartowski/Mixtral-8x22B-Instruct-v0.1-GGUF)
- [mradermacher/Mixtral-8x22B-Instruct-v0.1-GGUF](https://huggingface.co/mradermacher/Mixtral-8x22B-Instruct-v0.1-GGUF)

## Связано

- Направления: [llm](../llm.md)
- Альтернативы: [qwen35](qwen35.md) (новее, лучший русский), [llama](llama.md) (Llama 3.3 70B)
