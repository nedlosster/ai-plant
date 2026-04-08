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

## Альтернативы (топ-3 из 2026)

Помимо Gemma 4 есть более сильные специализированные vision-модели. Все имеют GGUF-версии и работают через llama.cpp.

### 1. Qwen3-VL (Alibaba)

Флагман от Qwen. Две основные версии:
- **Qwen3-VL-30B-A3B** (MoE) -- ~17 GiB Q4_K_M, активны 3B параметров, быстрая
- **Qwen3-VL-235B-A22B** (MoE) -- ~135 GiB Q4_K_M, по бенчмаркам конкурирует с Gemini-2.5-Pro и GPT-5

Сильные стороны: structured outputs, document understanding, video, OCR на 30+ языках. Доступны Instruct и Thinking варианты.

```bash
# Qwen3-VL-30B-A3B Q4_K_M (выбор для платформы -- умещается комфортно)
./scripts/inference/download-model.sh unsloth/Qwen3-VL-30B-A3B-Instruct-GGUF \
    --include '*Q4_K_M*' --include 'mmproj*'
```

### 2. InternVL3 (OpenGVLab)

Серия open-source vision-моделей с фокусом на reasoning и сложные задачи.
- **InternVL3-78B** -- 72.2 на MMMU benchmark
- **InternVL3-14B** -- средний размер для consumer-платформ
- **InternVL3-2B** -- быстрая, для edge-устройств

Использует InternViT-6B-448px-V2_5 как vision encoder. Лучшая по математике/диаграммам в среднем сегменте.

```bash
./scripts/inference/download-model.sh bartowski/InternVL3-14B-GGUF \
    --include '*Q4_K_M*' --include 'mmproj*'
```

### 3. MiniCPM-o 2.6 (OpenBMB)

End-side multimodal с поддержкой **изображений + видео + аудио + текста**. Real-time speech, multimodal streaming. Размер ~8B параметров. Очень эффективна для своего размера.

```bash
./scripts/inference/download-model.sh openbmb/MiniCPM-o-2_6-gguf \
    --include '*Q4_K_M*' --include 'mmproj*'
```

## Сравнение для платформы (gfx1151, 120 GiB)

| Модель | Размер Q4_K_M | mmproj | tg (ожид.) | Сильные стороны |
|--------|--------------|--------|------------|-----------------|
| Gemma 4 26B-A4B | 17 GB | 1.2 GB | ~80 tok/s | function calling, reasoning, общий VLM |
| Qwen3-VL 30B-A3B | 17 GB | ~1 GB | ~80 tok/s | OCR, документы, structured output |
| InternVL3-14B | 8 GB | ~3 GB | ~25 tok/s | математика, диаграммы, reasoning |
| MiniCPM-o 2.6 | 5 GB | ~1 GB | ~40 tok/s | мультимодальность (audio/video) |

Все четыре помещаются с большим запасом. Можно держать несколько одновременно или быструю замену через пресет-скрипты.

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
