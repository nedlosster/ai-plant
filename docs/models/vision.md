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

## Сравнительная таблица

| Модель | Семейство | Параметры | mmproj | Контекст | Особенность |
|--------|-----------|-----------|--------|----------|-------------|
| Gemma 4 26B-A4B | [gemma4](families/gemma4.md) | 26B MoE / 3.8B | 1.2 GB | 256K | function calling, thinking |
| Qwen3-VL 30B-A3B | [qwen3-vl](families/qwen3-vl.md#30b-a3b) | 30B MoE / 3B | 1.08 GB | 128K | OCR, document, video, structured output |
| Qwen3-VL 235B-A22B | [qwen3-vl](families/qwen3-vl.md#235b-a22b) | 235B MoE / 22B | ~3 GB | 128K | флагман уровня Gemini-2.5/GPT-5 |
| Qwen2.5-Omni 7B | [qwen25-omni](families/qwen25-omni.md) | 7B dense | ~1 GB | 128K | vision + audio + text |
| Pixtral 12B | [pixtral](families/pixtral.md) | 12B dense | 463 MB | 128K | Apache 2.0, multi-image input |
| Mistral Small 3.1 24B | [mistral-small-31](families/mistral-small-31.md) | 24B dense | ~1 GB | 128K | function calling, balanced |
| InternVL3-14B | [internvl](families/internvl.md) | 14B dense | ~3 GB | 32K | math, charts, reasoning |
| MiniCPM-o 2.6 | [minicpm-o](families/minicpm-o.md) | 8B dense | ~1 GB | 32K | omni: vision+video+audio |
| SmolVLM2 2.2B | [smolvlm2](families/smolvlm2.md) | 2.2B dense | ~0.5 GB | 16K | edge, ~150 tok/s |

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

## Использование из Open WebUI

Open WebUI автоматически определяет vision-возможности модели через `/v1/models` и показывает кнопку attach image. Достаточно настроить `inference.env` (см. [scripts/webui/README.md](../../scripts/webui/README.md)).

## Связанные направления

- [llm.md](llm.md) -- общие LLM (Qwen3.5, Gemma 4 -- мультимодальные тоже)
- [coding.md](coding.md) -- скриншоты ошибок в [opencode](../ai-agents/agents/opencode.md)
- [tts.md](tts.md) -- Qwen2.5-Omni для голос+картинки
- [images.md](images.md) -- генерация изображений (diffusion, не vision-LLM)
