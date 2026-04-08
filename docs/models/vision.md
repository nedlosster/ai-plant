# Vision LLM (multimodal)

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти), llama.cpp + Vulkan/HIP.

Vision LLM принимают на вход не только текст, но и изображения. Используются для: описания фото, OCR, понимания диаграмм/схем/UI, анализа графиков, визуального QA, решения задач по картинке.

## Архитектура: модель + mmproj

В llama.cpp vision реализован двухкомпонентно:

1. **Основная LLM** (текстовая часть) -- стандартный GGUF-файл с весами трансформера
2. **Vision-проектор (`mmproj`)** -- отдельный GGUF-файл с весами vision-encoder'а (обычно ViT/SigLIP) + проектор в эмбеддинг-пространство LLM

При запуске llama-server обоим файлам соответствуют разные флаги:

```bash
llama-server -m model.gguf --mmproj mmproj-BF16.gguf -ngl 99 ...
```

Без `--mmproj` модель работает только с текстом, vision-вход возвращает ошибку
`image input is not supported - hint: if this is unexpected, you may need to provide the mmproj`.

## Загруженные на платформе

### Gemma 4 26B-A4B (multimodal)

Уже стоит. Vision-проектор -- отдельный файл в том же репо unsloth.

```bash
# Загрузка mmproj (1.19 GB)
./scripts/inference/download-model.sh unsloth/gemma-4-26B-A4B-it-GGUF --include 'mmproj-BF16.gguf'

# Запуск с vision (пресет уже учитывает mmproj)
./scripts/inference/vulkan/preset/gemma4.sh -d
```

Варианты mmproj в репо:
- `mmproj-BF16.gguf` (1.19 GB) -- рекомендуется
- `mmproj-F16.gguf` (1.19 GB) -- идентично BF16 по размеру
- `mmproj-F32.gguf` (2.29 GB) -- максимальная точность, не нужна для практики

## Альтернативные vision-модели (2026)

Все имеют GGUF-версии и работают через llama.cpp.

### 1. Qwen3-VL 30B-A3B (рекомендую как замену Gemma 4)

**MoE с 3B активных параметров** -- быстрая как Qwen3-Coder-Next, но с vision.

- **Параметры**: 30B (A3B)
- **Hub**: [Qwen/Qwen3-VL-30B-A3B-Instruct-GGUF](https://huggingface.co/Qwen/Qwen3-VL-30B-A3B-Instruct-GGUF)
- **Размер**: 18.6 GB Q4_K_M + 1.08 GB mmproj F16
- **Также**: [Thinking-вариант](https://huggingface.co/Qwen/Qwen3-VL-30B-A3B-Thinking-GGUF) с reasoning

**Что умеет**: structured outputs, document understanding, video, OCR на 30+ языках, agentic capabilities.

```bash
./scripts/inference/download-model.sh Qwen/Qwen3-VL-30B-A3B-Instruct-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*F16*'
```

### 2. Qwen3-VL 235B-A22B (флагман, на пределе платформы)

Конкурирует с Gemini-2.5-Pro и GPT-5 на multimodal-бенчмарках.

- **Параметры**: 235B (A22B)
- **Hub**: [Qwen/Qwen3-VL-235B-A22B-Instruct-GGUF](https://huggingface.co/Qwen/Qwen3-VL-235B-A22B-Instruct-GGUF)
- **Размер**: ~135 GB Q4_K_M + ~3 GB mmproj
- **VRAM**: на пределе 120 GiB Vulkan (без запаса на контекст)

**Что умеет**: лучшее качество vision-понимания среди open-source. Подходит для самых сложных задач (научные диаграммы, юридические документы, complex visual reasoning).

```bash
./scripts/inference/download-model.sh Qwen/Qwen3-VL-235B-A22B-Instruct-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*'
```

### 3. Qwen2.5-Omni 7B (vision + audio + text)

**Multimodal в три стороны** -- понимает картинки И аудио. От ggml-org (официальный конвертер llama.cpp).

- **Параметры**: 7B
- **Hub**: [ggml-org/Qwen2.5-Omni-7B-GGUF](https://huggingface.co/ggml-org/Qwen2.5-Omni-7B-GGUF)
- **Размер**: ~5 GB Q4_K_M + ~1 GB mmproj

**Что умеет**: real-time speech conversation, multimodal streaming, голосовой ассистент, анализ видео+звука одновременно (например запись звонка), audio-описание изображений.

```bash
./scripts/inference/download-model.sh ggml-org/Qwen2.5-Omni-7B-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*'
```

### 4. Pixtral 12B (Mistral)

**Apache 2.0** -- полная коммерческая свобода. Превосходит Qwen2-VL 7B, LLaVa-OneVision 7B, Phi-3.5 Vision.

- **Параметры**: 12B
- **Hub**: [ggml-org/pixtral-12b-GGUF](https://huggingface.co/ggml-org/pixtral-12b-GGUF)
- **Размер**: 7.48 GB Q4_K_M + 463 MB mmproj Q8_0

**Что умеет**: instruction following на vision-задачах -- сильнейший в среднем сегменте. Подходит когда нужна Apache 2.0 для коммерции.

```bash
./scripts/inference/download-model.sh ggml-org/pixtral-12b-GGUF \
    --include '*Q4_K_M*' --include 'mmproj*Q8_0*'
```

### 5. Mistral Small 3.1 24B (multimodal)

Сбалансированный размер, Apache 2.0.

- **Параметры**: 24B
- **Hub**: [ggml-org/Mistral-Small-3.1-24B-Instruct-2503-GGUF](https://huggingface.co/ggml-org/Mistral-Small-3.1-24B-Instruct-2503-GGUF)
- **Размер**: ~14 GB Q4_K_M + ~1 GB mmproj

**Что умеет**: сильная instruction following, vision-капабилитис, удобный размер для production-нагрузки.

```bash
./scripts/inference/download-model.sh ggml-org/Mistral-Small-3.1-24B-Instruct-2503-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*'
```

### 6. InternVL3 (OpenGVLab)

Серия с фокусом на reasoning и сложные задачи.

- **Параметры**: 2B / 14B / 78B
- **Hub**: [bartowski/InternVL3-14B-GGUF](https://huggingface.co/bartowski/InternVL3-14B-GGUF), [официальные](https://huggingface.co/OpenGVLab)
- **Размер 14B**: ~8 GB Q4_K_M + ~3 GB mmproj
- **InternVL3-78B**: 72.2 на MMMU benchmark

**Что умеет**: математика, диаграммы, графики, научные задачи. Использует InternViT-6B-448px-V2_5 как vision encoder.

```bash
./scripts/inference/download-model.sh bartowski/InternVL3-14B-GGUF \
    --include '*Q4_K_M*' --include 'mmproj*'
```

### 7. MiniCPM-o 2.6 (OpenBMB)

End-side multimodal с поддержкой **изображений + видео + аудио + текста**.

- **Параметры**: ~8B
- **Hub**: [openbmb/MiniCPM-o-2_6-gguf](https://huggingface.co/openbmb/MiniCPM-o-2_6-gguf)
- **Размер**: ~5 GB Q4_K_M + ~1 GB mmproj

**Что умеет**: real-time speech, multimodal streaming, эффективность для своего размера.

```bash
./scripts/inference/download-model.sh openbmb/MiniCPM-o-2_6-gguf \
    --include '*Q4_K_M*' --include 'mmproj*'
```

### 8. SmolVLM2 2.2B (компактная)

Самая лёгкая, для edge или экспериментов. Поддержка видео.

- **Параметры**: 2.2B (есть варианты 256M, 500M, 2.2B)
- **Hub**: [HuggingFaceTB/SmolVLM2-2.2B-Instruct](https://huggingface.co/HuggingFaceTB/SmolVLM2-2.2B-Instruct), GGUF: [ggml-org/SmolVLM2-2.2B-Instruct-GGUF](https://huggingface.co/ggml-org/SmolVLM2-2.2B-Instruct-GGUF)
- **Размер**: ~1.4 GB Q4_K_M + ~0.5 GB mmproj

**Что умеет**: мгновенная скорость (~150 tok/s), поддержка видео, локальные сценарии где нужна минимальная задержка. SmolVLM2-256M вообще требует <1 GB VRAM.

```bash
./scripts/inference/download-model.sh ggml-org/SmolVLM2-2.2B-Instruct-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*'
```

## Сравнение для платформы (gfx1151, 120 GiB)

| Модель | Размер Q4 | mmproj | tg (ожид.) | Особенность |
|--------|-----------|--------|------------|-------------|
| **Qwen3-VL 30B-A3B** ⭐ | 18.6 GB | 1.1 GB | ~80 tok/s | universal vision, OCR, video |
| Qwen3-VL 235B-A22B | 135 GB | ~3 GB | ~22 tok/s | флагман уровня Gemini-2.5/GPT-5 |
| Qwen2.5-Omni 7B | ~5 GB | ~1 GB | ~50 tok/s | vision + audio + text |
| Pixtral 12B | 7.5 GB | 463 MB | ~40 tok/s | instruction following, Apache 2.0 |
| Mistral Small 3.1 24B | ~14 GB | ~1 GB | ~20 tok/s | сбалансированная |
| InternVL3-14B | 8 GB | ~3 GB | ~25 tok/s | reasoning, диаграммы |
| MiniCPM-o 2.6 | ~5 GB | ~1 GB | ~40 tok/s | мультимодальность (audio/video) |
| SmolVLM2 2.2B | ~1.4 GB | ~0.5 GB | ~150 tok/s | edge, видео, минимум задержки |
| Gemma 4 26B-A4B | 17 GB | 1.2 GB | ~80 tok/s | function calling, reasoning |

## Запуск vision-модели через llama-server

Для своей кастомной модели (не из готовых пресетов):

```bash
~/projects/llama.cpp/build/bin/llama-server \
    -m /path/to/model.gguf \
    --mmproj /path/to/mmproj.gguf \
    --port 8081 -ngl 99 -fa on -c 32768 \
    --host 0.0.0.0 --jinja --parallel 1
```

## Использование из Open WebUI

Open WebUI автоматически определяет vision-возможности модели через `/v1/models` и показывает кнопку attach image, если модель multimodal. Достаточно настроить `inference.env` на хост llama-server (см. [scripts/webui/README.md](../../scripts/webui/README.md)).

## Связанные статьи

- [LLM общего назначения](llm.md)
- [Кодинг](coding.md)
- [Картинки (генерация)](images.md) -- diffusion, не vision-LLM
