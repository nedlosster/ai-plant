# Gemma 4 (Google, 2026)

> Multimodal MoE с native function calling, 256K контекстом и thinking-режимом.

**Тип**: MoE (3.8B active / 25.2B total)
**Лицензия**: Gemma Terms of Use
**Статус на сервере**: скачана (26B-A4B Q6_K_XL + mmproj-BF16)
**Направления**: [llm](../llm.md), [vision](../vision.md)

## Обзор

Gemma 4 26B-A4B -- multimodal MoE-модель от Google нового поколения 2026. Total 25.2B параметров, активных 3.8B, что даёт скорость как у dense 4B-модели. Поддерживает text и images, native function calling, контекст 256K, thinking-режим через `<|think|>` token.

На платформе используется как основная multimodal через `vulkan/preset/gemma4.sh`. Vision реализован двухкомпонентно: основной GGUF + отдельный `mmproj-BF16.gguf` (1.19 GB) с весами vision-encoder'а.

## Варианты

| Вариант | Параметры | Active | Контекст | VRAM | mmproj | Статус | Hub |
|---------|-----------|--------|----------|------|--------|--------|-----|
| 26B-A4B Q6_K_XL | 25.2B MoE | 3.8B | 256K | ~22 GiB | 1.19 GB | скачана | [unsloth/gemma-4-26B-A4B-it-GGUF](https://huggingface.co/unsloth/gemma-4-26B-A4B-it-GGUF) |
| 26B-A4B Q4_K_M | 25.2B MoE | 3.8B | 256K | ~16.9 GiB | 1.19 GB | не скачана | то же |
| 26B-A4B Q8_0 | 25.2B MoE | 3.8B | 256K | ~26.9 GiB | 1.19 GB | не скачана | то же |

### Варианты mmproj в репо

- **`mmproj-BF16.gguf`** (1.19 GB) -- рекомендуется
- `mmproj-F16.gguf` (1.19 GB) -- идентично BF16 по размеру
- `mmproj-F32.gguf` (2.29 GB) -- максимальная точность, не нужна для практики

## Архитектура и особенности

- **MoE 8/128 + 1 shared expert** -- активны 3.8B параметров на токен, скорость как у 4B-модели
- **SigLIP-style vision encoder** в отдельном `mmproj-BF16.gguf` файле
- **Контекст 256K** -- можно загрузить много кадров видео или серию скриншотов
- **Native function calling** -- из коробки, без отдельного fine-tune
- **Thinking-режим** через `<|think|>` token в начале system prompt
- **Variable aspect ratio** изображений -- понимает портрет/панораму без принудительного crop
- **Sliding window attention** -- эффективная работа с длинными контекстами, но чувствительна к OOM при больших контекстах (см. защиты в пресете)

### Бенчмарки

| Бенч | Значение |
|------|----------|
| LiveCodeBench v6 | 77.1% |
| Codeforces ELO | 1718 |
| AIME 2026 | 88.3% |

## Сильные кейсы

- **Function calling по визуальному входу** -- получает скриншот UI, вызывает tool с выделенными координатами
- **Reasoning по диаграмме** через thinking-режим
- **Длинный контекст 256K** -- много кадров видео, серия скриншотов, длинная инструкция
- **Универсальный VLM "общего назначения"** -- сильна на смешанных задачах
- **Variable aspect ratio** -- понимает портрет/панораму без потери информации
- **Скорость MoE** -- как у 4B при качестве 26B

## Слабые стороны / ограничения

- **Sliding window attention** -- чувствительна к OOM при больших контекстах (см. пресет gemma4.sh с защитами `--parallel 1 --no-mmap -c 65536`)
- **KV-cache shifting не работает** -- multi-turn чат пересчитывает префикс. `--cache-reuse 256` в пресете установлен, но llama.cpp выдаёт `cache reuse is not supported - ignoring n_cache_reuse = 256`
- **OCR хуже** [qwen3-vl](qwen3-vl.md) и [internvl](internvl.md)
- **Не специализирована под конкретный домен** (math/science -- лучше специализированные модели)

## Идеальные сценарии применения

- **"Опиши скриншот ошибки и предложи фикс"** в opencode
- **Анализ UI-макета** → tool calls для генерации компонентов
- **Reasoning-задачи** по фото с длинным контекстом инструкций
- **Universal multimodal assistant** -- одна модель на text+vision вместо двух
- **Function calling agents** с визуальным вводом

## Загрузка

```bash
# Основная модель Q6_K_XL (~22 GB) + vision (~1.2 GB)
./scripts/inference/download-model.sh unsloth/gemma-4-26B-A4B-it-GGUF \
    --include '*Q6_K_XL*' --include 'mmproj-BF16.gguf'

# Альтернатива: Q4_K_M (меньше) или Q8_0 (выше качество)
./scripts/inference/download-model.sh unsloth/gemma-4-26B-A4B-it-GGUF \
    --include '*Q4_K_M*' --include 'mmproj-BF16.gguf'
```

## Запуск

```bash
# Через Vulkan-пресет (защиты от OOM, mmproj подключен)
./scripts/inference/vulkan/preset/gemma4.sh -d
```

Пресет автоматически:
- Подключает `--mmproj $MODELS_DIR/mmproj-BF16.gguf`
- Устанавливает `--parallel 1` (защита от OOM из-за sliding window checkpoints)
- Устанавливает `--no-mmap` (модель сразу в RAM)
- `--jinja` для function calling
- `-c 65536` (64K -- меньше памяти на context checkpoints)

Подробности про OOM-защиту -- в комментариях `scripts/inference/vulkan/preset/gemma4.sh`.

## Связано

- Направления: [llm](../llm.md), [vision](../vision.md)
- Родственные семейства: альтернативы по vision -- [qwen3-vl](qwen3-vl.md) (лучше OCR), [qwen25-omni](qwen25-omni.md) (vision + audio)
- Пресет: `scripts/inference/vulkan/preset/gemma4.sh`
