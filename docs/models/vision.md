# Vision LLM (multimodal)

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти), llama.cpp + Vulkan/HIP.

Vision LLM принимают на вход текст и изображения. Используются для: описания фото, OCR, понимания диаграмм/схем/UI, анализа графиков, visual QA.

Полные описания моделей -- в `families/`. Эта страница: архитектура mmproj, сравнительные таблицы, выбор под задачу.

## Архитектура: модель + mmproj

В llama.cpp vision реализован двухкомпонентно:

1. **Основная LLM** (текстовая часть) -- стандартный GGUF
2. **Vision-проектор (`mmproj`)** -- отдельный GGUF с весами vision-encoder'а (ViT/SigLIP) + проектор в эмбеддинг-пространство LLM

```bash
llama-server -m model.gguf --mmproj mmproj-BF16.gguf -ngl 99 ...
```

Без `--mmproj` модель работает только с текстом. Vision-вход вернёт ошибку
`image input is not supported - hint: if this is unexpected, you may need to provide the mmproj`.

## Скачано на платформе

| Модель | Семейство | Параметры | mmproj | Пресет |
|--------|-----------|-----------|--------|--------|
| Gemma 4 26B-A4B | [gemma4](families/gemma4.md) | 26B MoE / 3.8B | mmproj-BF16 (1.19 GB) | `vulkan/preset/gemma4.sh` |

Также мультимодальные [Qwen3.5-27B](families/qwen35.md#27b) и [Qwen3.5-122B](families/qwen35.md#122b-a10b) -- но без отдельного mmproj (vision встроен).

## Топ vision-моделей для платформы (апрель 2026)

Ранжирование по совокупности MMMU/MMMU-Pro, OCR-качества, скорости на платформе, размера контекста и зрелости llama.cpp-интеграции. Все варианты помещаются в 120 GiB unified memory **с запасом** на контекст и параллельные сервера.

| # | Модель | Параметры | MMMU | VRAM Q4+mmproj | tg tok/s | Сильное место |
|---|--------|-----------|------|----------------|----------|----------------|
| 1 | [Qwen3-VL 30B-A3B Instruct](families/qwen3-vl.md#30b-a3b) | 30B MoE / 3B | ~70 | 19.7 GiB | ~80 | Лучший OCR open-source, structured JSON, video, 30+ языков |
| 2 | [Gemma 4 26B-A4B](families/gemma4.md) | 26B MoE / 3.8B | ~72 | 17 GiB | ~70 | Function calling, screenshot-to-code, 256K, thinking |
| 3 | [InternVL3-38B Instruct](families/internvl.md#3-5-38b) | 38B dense | 72.2 | ~24 GiB | ~15 | Лидер dense MMMU в GGUF, math/charts/диаграммы, reasoning (InternVL3.5-38B пока без GGUF) |
| 4 | [Qwen3-VL 30B-A3B Thinking](families/qwen3-vl.md#30b-a3b) | 30B MoE / 3B | ~73 | 19.7 GiB | ~50 | Reasoning-режим над визуальными задачами |
| 5 | [Mistral Small 3.1 24B](families/mistral-small-31.md) | 24B dense | 64 | ~16 GiB | ~22 | Function calling, balanced, Apache 2.0 |
| 6 | [Pixtral 12B](families/pixtral.md) | 12B dense | 52 | ~8.5 GiB | ~35 | Multi-image input, Apache 2.0, instruction following |
| 7 | [InternVL3-14B](families/internvl.md) | 14B dense | ~67 | ~12 GiB | ~25 | Math/charts фокус, reasoning |
| 8 | [Qwen2.5-Omni 7B](families/qwen25-omni.md) | 7B dense | 59 | ~5 GiB | ~50 | Vision + audio + text omni |
| 9 | [MiniCPM-o 2.6](families/minicpm-o.md) | 8B dense | 58 | ~5 GiB | ~55 | Streaming video, edge-friendly |
| 10 | [SmolVLM2 2.2B](families/smolvlm2.md) | 2.2B dense | 42 | ~2 GiB | ~150 | Edge, минимальная latency, Raspberry Pi |

**#1 [Qwen3-VL 30B-A3B Instruct](families/qwen3-vl.md#30b-a3b)** -- основной выбор для daily multimodal на платформе. MoE с 3B active даёт скорость ~80 tok/s. Лучший OCR в open-source (30+ языков), structured JSON output по schema, video understanding с таймкодами. Уже скачана. Минус -- контекст 128K (vs 256K у Gemma 4), reasoning только через Thinking-вариант.

**#2 [Gemma 4 26B-A4B](families/gemma4.md)** -- вторая основная на платформе. Native function calling + thinking mode + 256K контекст. Лучше Qwen3-VL на screenshot-to-code задачах (специально натренирована). Уже скачана. Минус -- OCR на не-латинских скриптах слабее Qwen3-VL.

**#3 [InternVL3-38B Instruct](families/internvl.md#3-5-38b)** -- лидер dense-сегмента в GGUF (MMMU 72.2). Сильнейший на математике, диаграммах, графиках, научных публикациях. На платформу влезает (~24 GiB Q4), но dense 38B даёт ~15 tok/s -- ощутимо медленнее MoE-вариантов. Для редких сложных задач reasoning -- стоит рассмотреть. Свежее поколение InternVL3.5-38B (MMMU ~74) пока доступно только в safetensors, GGUF не выложен.

**#4 [Qwen3-VL 30B-A3B Thinking](families/qwen3-vl.md#30b-a3b)** -- та же база, что #1, но с reasoning-loop в `<think>`. Жертвуем скоростью ради качества на сложных visual reasoning. Можно держать параллельно с Instruct (один порт занят, другой свободен).

**#5-7** -- специализированные альтернативы: Mistral Small 3.1 (function calling + Apache 2.0), Pixtral (multi-image), InternVL3-14B (компактный reasoning).

**#8-10** -- omni и edge-сегмент: для голосовых сценариев, streaming video, или работы на слабом железе.

### Что НЕ помещается на платформу

| Модель | Параметры | Q4 размер | Почему не помещается |
|--------|-----------|-----------|----------------------|
| [Qwen3-VL 235B-A22B](families/qwen3-vl.md#235b-a22b) | 235B MoE / 22B | 135 + 3 GiB | 145-150 GiB суммарно при 120 GiB доступно. См. [реалистичный вердикт](families/qwen3-vl.md#235b-a22b) |
| InternVL3.5-241B-A28B | 241B MoE / 28B | ~145 GiB | Лидер MMMU 77.7, но не помещается даже близко |
| Llama 4 Maverick 400B MoE | 400B / 17B | ~240 GiB | MMMU 73.4, frontier, доступ только через API |
| [Kimi K2.5](families/kimi-k25.md) | 1T MoE / 32B | 240+ GiB | Native multimodal (MoonViT 400M), MMMU Pro 78.5, через API |

Frontier-tier (235B+) для нашей платформы -- только через API. Локально потолок -- 30-38B.

## Сравнительная таблица

| Модель | Семейство | Параметры | mmproj | Контекст | FC | Особенность |
|--------|-----------|-----------|--------|----------|-----|-------------|
| Gemma 4 26B-A4B | [gemma4](families/gemma4.md) | 26B MoE / 3.8B | 1.2 GB | 256K | **native** ⭐ | function calling, thinking |
| Qwen3-VL 30B-A3B | [qwen3-vl](families/qwen3-vl.md#30b-a3b) | 30B MoE / 3B | 1.08 GB | 128K | native | OCR, document, video, structured output |
| Qwen3-VL 235B-A22B | [qwen3-vl](families/qwen3-vl.md#235b-a22b) | 235B MoE / 22B | ~3 GB | 128K | native | флагман уровня Gemini-2.5/GPT-5 |
| Qwen2.5-Omni 7B | [qwen25-omni](families/qwen25-omni.md) | 7B dense | ~1 GB | 128K | partial | vision + audio + text |
| Pixtral 12B | [pixtral](families/pixtral.md) | 12B dense | 463 MB | 128K | partial | Apache 2.0, multi-image input |
| Mistral Small 3.1 24B | [mistral-small-31](families/mistral-small-31.md) | 24B dense | ~1 GB | 128K | **native** | function calling, balanced |
| InternVL3-38B Instruct | [internvl](families/internvl.md#3-5-38b) | 38B dense | ~3 GB | 32-64K | partial | лидер dense MMMU в GGUF, reasoning |
| InternVL3-14B | [internvl](families/internvl.md) | 14B dense | ~3 GB | 32K | partial | math, charts, reasoning |
| MiniCPM-o 2.6 | [minicpm-o](families/minicpm-o.md) | 8B dense | ~1 GB | 32K | partial | omni: vision+video+audio |
| SmolVLM2 2.2B | [smolvlm2](families/smolvlm2.md) | 2.2B dense | ~0.5 GB | 16K | нет | edge, ~150 tok/s |

⭐ Лучшее сочетание FC + vision на платформе. Запуск с `--jinja` обязателен -- см. [llm-guide/function-calling.md](../llm-guide/function-calling.md#function-calling-на-платформе-2026).

## Выбор под задачу

### Универсальный multimodal assistant

[Gemma 4 26B-A4B](families/gemma4.md) -- function calling, 256K контекст, уже на платформе.
[Qwen3-VL 30B-A3B](families/qwen3-vl.md#30b-a3b) -- быстрая MoE (3B active), лучший OCR.

### OCR и документы

[Qwen3-VL 30B-A3B](families/qwen3-vl.md#30b-a3b) -- лучший OCR на 30+ языках, structured JSON output.
[InternVL3](families/internvl.md) -- если в документах много диаграмм и графиков.

### Сложные visual reasoning задачи

[Qwen3-VL 235B-A22B](families/qwen3-vl.md#235b-a22b) -- уровень Gemini-2.5/GPT-5.
[InternVL3-78B](families/internvl.md) -- математика и научные диаграммы.

### Vision + audio (omni)

[Qwen2.5-Omni 7B](families/qwen25-omni.md) -- real-time speech, видео-звонки.
[MiniCPM-o 2.6](families/minicpm-o.md) -- end-side, edge-устройства.

### Apache 2.0 коммерческое использование

[Pixtral 12B](families/pixtral.md) -- лучший instruction following в open-source среднего сегмента.
[Mistral Small 3.1 24B](families/mistral-small-31.md) -- сбалансированная.

### Edge / минимальная задержка

[SmolVLM2 2.2B](families/smolvlm2.md) -- ~150 tok/s, можно даже на телефоне.

### Function calling по визуальному входу

[Gemma 4 26B-A4B](families/gemma4.md) -- native function calling.
[Mistral Small 3.1 24B](families/mistral-small-31.md) -- function calling из коробки.

### Видео-понимание

[Qwen3-VL 30B-A3B](families/qwen3-vl.md#30b-a3b) -- video understanding, action recognition, таймкоды.
[MiniCPM-o 2.6](families/minicpm-o.md) -- streaming video с непрерывным обновлением.

## Запуск vision-модели через llama-server

Для своей кастомной модели:

```bash
~/projects/llama.cpp/build/bin/llama-server \
    -m /path/to/model.gguf \
    --mmproj /path/to/mmproj.gguf \
    --port 8081 -ngl 99 -fa on -c 32768 \
    --host 0.0.0.0 --jinja --parallel 1
```

Для Gemma 4 на платформе используется готовый пресет с защитами от OOM:
```bash
./scripts/inference/vulkan/preset/gemma4.sh -d
```

## Frontier multimodal через API (не помещается локально)

[Kimi K2.5](families/kimi-k25.md) -- 1T MoE с native multimodal от Moonshot AI. MoonViT 400M интегрирован в претрейн (не post-hoc adapter). MMMU Pro 78.5% обходит GPT-5.2. Веса открыты, но 240+ GiB не помещаются на платформу -- доступ через API за $0.45/1M input.

**GLM-5V-Turbo** (Z.ai, 1 апреля 2026) -- vision-language вариант GLM-5 семейства, оптимизирован под coding (screenshot-to-code, diagram understanding). Open weights, но часть GLM-5 семейства -- не помещается на платформу. См. [news.md](news.md).

## Использование из Open WebUI

Open WebUI автоматически определяет vision-возможности модели через `/v1/models` и показывает кнопку attach image. Достаточно настроить `inference.env` (см. [scripts/webui/README.md](../../scripts/webui/README.md)).

## Связанные направления

- [llm.md](llm.md) -- общие LLM (Qwen3.5, Gemma 4 -- мультимодальные тоже)
- [coding.md](coding.md) -- скриншоты ошибок в [opencode](../ai-agents/agents/opencode.md)
- [tts.md](tts.md) -- Qwen2.5-Omni для голос+картинки
- [images.md](images.md) -- генерация изображений (diffusion, не vision-LLM)
