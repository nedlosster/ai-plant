# Каталог моделей

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти), Vulkan + ROCm 7.2.1.

**Структура**:
- Этот файл -- общий каталог-таблица всех моделей с ссылками на семейства
- [`families/`](families/README.md) -- по одному файлу на серию модели, единственный источник правды для описания
- Статьи направлений -- сравнительные таблицы и "выбор под задачу" со ссылками сюда

Управление каталогом: skill `/models-catalog`.

## Направления

| Задача | Документ |
|--------|----------|
| [LLM общего назначения](llm.md) | универсальные текстовые LLM |
| [Кодинг](coding.md) | код, FIM, agents |
| [Vision LLM](vision.md) | multimodal: текст + изображения |
| [TTS с клонированием голоса](tts.md) | voice cloning по референсу |
| [Музыка и вокал](music.md) | генерация музыки и песен |
| [Русский вокал](russian-vocals.md) | русскоязычные песни через AI |
| [Картинки](images.md) | generation diffusion |
| [Видео](video.md) | text-to-video, image-to-video |
| [Российские LLM](russian-llm.md) | finetune'ы под русский язык |

## Скачано на сервере

| Тип | Параметры | Модель | Семейство | Направления | Пресет/инструмент | VRAM |
|-----|-----------|--------|-----------|-------------|--------------------|------|
| MoE 3B/80B | 80B A3B | Qwen3-Coder-Next | [qwen3-coder](families/qwen3-coder.md#next-80b-a3b) | [coding](coding.md), [llm](llm.md) | `vulkan/preset/qwen-coder-next.sh` | 45 GiB |
| MoE 3B/30B | 30B A3B | Qwen3-Coder-30B-A3B | [qwen3-coder](families/qwen3-coder.md#30b-a3b) | [coding](coding.md) | `vulkan/preset/qwen3-coder-30b.sh` | 18 GiB |
| dense | 1.5B Q8 | Qwen2.5-Coder-1.5B | [qwen25-coder](families/qwen25-coder.md#1-5b) | [coding](coding.md) | `vulkan/preset/qwen2.5-coder-1.5b.sh` | 2 GiB |
| dense | 27B | Qwen3.5-27B | [qwen35](families/qwen35.md#27b) | [llm](llm.md), [vision](vision.md) | `vulkan/preset/qwen3.5-27b.sh` | 17 GiB |
| MoE 10B/122B | 122B A10B | Qwen3.5-122B-A10B | [qwen35](families/qwen35.md#122b-a10b) | [llm](llm.md), [vision](vision.md) | `vulkan/preset/qwen3.5-122b.sh` | 71 GiB |
| MoE 4B/26B | 26B A4B | Gemma 4 26B-A4B | [gemma4](families/gemma4.md) | [llm](llm.md), [vision](vision.md) | `vulkan/preset/gemma4.sh` | 22 GiB + 1.2 mmproj |
| MoE 3B/30B | 30B A3B | Qwen3-VL 30B-A3B | [qwen3-vl](families/qwen3-vl.md#30b-a3b) | [vision](vision.md) | -- (нужен пресет) | 18 GiB + 1 mmproj |
| dense | 7B | Qwen2.5-Omni 7B | [qwen25-omni](families/qwen25-omni.md) | [vision](vision.md), [tts](tts.md) | -- (нужен пресет) | 5 GiB + 1.5 mmproj |
| diffusion | 12B | FLUX.1-schnell Q4_K_S | [flux](families/flux.md#schnell) | [images](images.md) | `comfyui/start.sh` | ~7 GiB |
| encoder | -- | T5-XXL Q8_0 | [flux](families/flux.md) | [images](images.md) | `comfyui/start.sh` | ~5 GiB |
| encoder | -- | CLIP-L | [flux](families/flux.md) | [images](images.md) | `comfyui/start.sh` | 0.25 GiB |
| diffusion audio | 1.5B | ACE-Step 1.5 | [ace-step](families/ace-step.md) | [music](music.md), [russian-vocals](russian-vocals.md) | `music/ace-step/start.sh` | <4 GiB |

## Ожидается open weights

Модели уровня флагмана, которые сейчас доступны только через API, но ожидается публикация open-вариантов.

| Тип | Модель | Семейство | Направления | Статус |
|-----|--------|-----------|-------------|--------|
| -- | Qwen3.6-Plus | [qwen36](families/qwen36.md) | [coding](coding.md), [llm](llm.md), [vision](vision.md) | API-only (Alibaba), open ожидается |

## Стоит обратить внимание

Приоритетные модели для скачивания. По мере наполнения семейств таблица будет расти.

| Тип | Параметры | Модель | Семейство | Направления | Почему |
|-----|-----------|--------|-----------|-------------|--------|
| dense | 24B | Devstral 2 | *(скоро)* devstral | [coding](coding.md) | 72.2% SWE-V, FIM+agent в одной модели |
| dense | 22B | Codestral 25.08 | *(скоро)* codestral | [coding](coding.md) | Лидер LMsys copilot arena по FIM |
| MoE 39B/141B | 141B | Mixtral 8x22B | *(скоро)* mixtral | [llm](llm.md) | Быстрый большой MoE, 64K контекст |
| dense | 111B | Command A | *(скоро)* command-a | [llm](llm.md) | RAG, tool use, 256K |
| MoE 17B/109B | 109B | Llama 4 Scout | *(скоро)* llama | [llm](llm.md), [vision](vision.md) | Контекст 10M, vision |
| MoE 3B/30B | 30B | Qwen3-VL 30B-A3B | *(скоро)* qwen3-vl | [vision](vision.md) | Лучший OCR, document understanding, video |
| MoE 22B/235B | 235B | Qwen3-VL 235B-A22B | *(скоро)* qwen3-vl | [vision](vision.md) | Уровень Gemini-2.5/GPT-5 на vision |
| dense | 7B | Qwen2.5-Omni | *(скоро)* qwen25-omni | [vision](vision.md), [tts](tts.md) | vision + audio + text |
| dense | 12B | Pixtral 12B | *(скоро)* pixtral | [vision](vision.md) | Apache 2.0, лучший instruction following |
| dense | 14B | InternVL3-14B | *(скоро)* internvl | [vision](vision.md) | Reasoning по диаграммам, math |
| dense | ~7B | Qwen3-TTS | *(скоро)* qwen3-tts | [tts](tts.md) | Нативный русский, voice cloning, free-form voice design |
| dense | 330M | F5-TTS (RU) | *(скоро)* f5-tts | [tts](tts.md) | Эталон voice cloning, MIT, RU-форки |
| MoE 14B | 14B | Wan 2.6/2.7 | *(скоро)* wan | [video](video.md) | Cinematic, multi-shot, native audio |

## Где брать модели

### HuggingFace (huggingface.co)

Основной источник open-source моделей. Авторы GGUF-квантизаций:

| Автор | Специализация |
|-------|--------------|
| **bartowski** | LLM, широкий выбор квантизаций |
| **unsloth** | LLM, оптимизированные квантизации, mmproj |
| **city96** | Diffusion-модели (FLUX, SD3) в GGUF-формате |
| **ggml-org** | Multimodal GGUFs (Pixtral, Qwen2.5-Omni, SmolVLM2) |
| **Qwen** (official) | Qwen-серия, включая Coder и VL |
| **mradermacher** | Community quantizations LLM |

```bash
# Установка CLI
pip install --user --break-system-packages "huggingface_hub[cli]"

# Загрузка через скрипт
./scripts/inference/download-model.sh <repo> --include "<pattern>"
```

### CivitAI (civitai.com)

Diffusion-модели, LoRA, ControlNet, стили для FLUX/SD.

### GitHub

Репозитории проектов (ACE-Step, ComfyUI, llama.cpp, TTS-WebUI) -- исходный код, инструкции, иногда веса.

## Преимущество 120 GiB GPU-памяти

Большинство consumer GPU имеют 8-24 GiB VRAM. 120 GiB GPU-доступной памяти (96 GiB carved-out UMA + GTT через `ttm.pages_limit`) позволяет:

- LLM 70B+ без агрессивной квантизации (Q8 вместо Q4)
- Diffusion в полном разрешении без tiling
- Несколько моделей одновременно (LLM + diffusion + audio)
- Длинный контекст 256K+ без OOM
- MoE-флагманы (Qwen3.5-122B-A10B, FLUX 12B одновременно)

## Общие форматы

| Формат | Применение | Инструмент |
|--------|-----------|-----------|
| GGUF | LLM, FIM, multimodal (с mmproj) | llama.cpp, LM Studio |
| GGUF (diffusion) | Картинки, T5/CLIP encoders | ComfyUI + ComfyUI-GGUF |
| safetensors | LLM, diffusion, audio | PyTorch, vLLM, ComfyUI |
| safetensors (audio) | TTS, music | PyTorch ROCm |

Для LLM на платформе **GGUF предпочтителен**: работает через Vulkan без ROCm.
Для diffusion и audio -- safetensors через ComfyUI/PyTorch ROCm.

## Связанные разделы

- [`families/`](families/README.md) -- полный каталог семейств
- [`docs/inference/`](../inference/) -- настройка llama.cpp, Vulkan, ROCm
- [`docs/llm-guide/`](../llm-guide/) -- общие статьи про LLM, квантизацию
- [`docs/use-cases/`](../use-cases/) -- сценарии применения
