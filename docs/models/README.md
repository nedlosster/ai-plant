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
| MoE 10B/122B | 122B A10B | Qwen3.5-122B-A10B | [qwen35](families/qwen35.md#122b-a10b) | [llm](llm.md), [vision](vision.md) | `vulkan/preset/qwen3.5-122b.sh` | 71 GiB |
| MoE 4B/26B | 26B A4B | Gemma 4 26B-A4B | [gemma4](families/gemma4.md) | [llm](llm.md), [vision](vision.md) | `vulkan/preset/gemma4.sh` | 22 GiB + 1.2 mmproj |
| MoE 3B/30B | 30B A3B | Qwen3-VL 30B-A3B | [qwen3-vl](families/qwen3-vl.md#30b-a3b) | [vision](vision.md) | `vulkan/preset/qwen3-vl.sh` | 18 GiB + 1 mmproj |
| dense | 24B | Devstral 2 24B Q4_K_M | [devstral](families/devstral.md) | [coding](coding.md) | -- (нет пресета) | 14 GiB |
| MoE 3B/35B | 35B A3B | Qwen3.5-35B-A3B Q4_K_M | [qwen35](families/qwen35.md#35b-a3b) | [llm](llm.md), [vision](vision.md) | -- (нет пресета) | 21 GiB |
| dense | 38B | InternVL3-38B Instruct Q4_K_M | [internvl](families/internvl.md#3-5-38b) | [vision](vision.md) | -- (нет пресета) | 19 GiB + 10.5 mmproj |
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
| MoE 32B/1T | 1T | Kimi K2.5 | [kimi-k25](families/kimi-k25.md) | [llm](llm.md), [coding](coding.md), [vision](vision.md) | Open weights, **не помещается** (240+ GiB), используется через API после блокировки Anthropic |


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

## Бенчмарки скачанных моделей

Сводная таблица по основным бенчмаркам. Подробнее про каждый бенчмарк -- в [docs/llm-guide/benchmarks/](../llm-guide/benchmarks/README.md).

### Coding-бенчмарки

| Модель | [SWE-V](../llm-guide/benchmarks/swe-bench.md) | [HumanEval](../llm-guide/benchmarks/humaneval.md) | [LiveCodeBench](../llm-guide/benchmarks/livecodebench.md) | FIM | FC | tg tok/s (Vulkan) |
|--------|-------|-----------|---------------|-----|-----|-------------------|
| [Qwen3-Coder Next 80B-A3B](families/qwen3-coder.md#next-80b-a3b) | **70.6%** | -- | ~65-70% (est.) | нет | native | 53 |
| [Devstral 2 24B](families/devstral.md) | **72.2%** | -- | ~55-60% (est.) | да | native | ~25 |
| [Qwen3-Coder 30B-A3B](families/qwen3-coder.md#30b-a3b) | ~62% | -- | -- | нет | native | 86 |
| [Qwen2.5-Coder 1.5B](families/qwen25-coder.md#1-5b) | -- | ~75% | -- | да | нет | 121 |

### Vision-бенчмарки

| Модель | [MMMU](../llm-guide/benchmarks/mmmu.md) | MMMU-Pro | Контекст | FC | tg tok/s (Vulkan) |
|--------|------|----------|----------|-----|-------------------|
| [Gemma 4 26B-A4B](families/gemma4.md) | ~72 | **76.9** | 256K | native | ~70 |
| [InternVL3-38B Instruct](families/internvl.md#3-5-38b) | **72.2** | -- | 32-64K | partial | ~15 |
| [Qwen3-VL 30B-A3B](families/qwen3-vl.md#30b-a3b) | ~70 | -- | 128K | native | ~80 |

### Universal LLM

| Модель | [LiveCodeBench](../llm-guide/benchmarks/livecodebench.md) | AIME 2026 | Codeforces ELO | tg tok/s (Vulkan) |
|--------|---------------|-----------|----------------|-------------------|
| [Gemma 4 26B-A4B](families/gemma4.md) | **77.1%** | 88.3% | 1718 | ~70 |
| [Qwen3.5 122B-A10B](families/qwen35.md#122b-a10b) | -- | -- | -- | 22 |
| [Qwen3.5 35B-A3B](families/qwen35.md#35b-a3b) | -- | -- | -- | ~80 |

### Frontier closed-source (для сравнения)

| Модель | [SWE-V](../llm-guide/benchmarks/swe-bench.md) | SWE-Pro | [LiveCodeBench](../llm-guide/benchmarks/livecodebench.md) | [MMMU](../llm-guide/benchmarks/mmmu.md) | $/1M input |
|--------|-------|---------|---------------|------|-----------|
| Claude Mythos Preview | **93.9%** | -- | -- | -- | preview |
| GPT-5.3 Codex | 85.0% | ~57% | -- | -- | $10 |
| Claude Opus 4.5 | 80.9% | 45.9% | -- | -- | $15 |
| Gemini 3.1 Pro Preview | 78.8% | -- | -- | 80%+ | $1.25 |
| Kimi K2.5 (1T MoE) | 76.8% | -- | -- | 78.5 (Pro) | $0.45 |
| **Qwen3-Coder Next** ⭐ | **70.6%** | -- | ~65-70% | -- | **$0 (локально)** |
| **Devstral 2 24B** ⭐ | **72.2%** | -- | ~55-60% | -- | **$0 (локально)** |
| **Gemma 4 26B-A4B** ⭐ | -- | -- | **77.1%** | **76.9 (Pro)** | **$0 (локально)** |

⭐ Скачаны на платформе. Отставание от frontier closed на 8-13 пунктов SWE-V при нулевой стоимости inference.

**Замечания**:
- SWE-bench Verified [частично загрязнён](../llm-guide/benchmarks/swe-bench.md#критика-и-ограничения) (OpenAI audit, февраль 2026). Цифры выше 85% -- с поправкой на contamination.
- [HumanEval насыщен](../llm-guide/benchmarks/humaneval.md#критика-и-ограничения) (95%+ у frontier), для выбора coding-моделей предпочтителен SWE-bench + LiveCodeBench.
- Qwen3-Coder и Devstral 2 не публикуют HumanEval -- оптимизированы под agentic (SWE-bench), не синтетические задачи.
- `est.` -- оценочные значения по корреляции с другими бенчмарками, точные цифры не опубликованы.

## Связанные разделы

- [`families/`](families/README.md) -- полный каталог семейств
- [`docs/inference/`](../inference/) -- настройка llama.cpp, Vulkan, ROCm
- [`docs/llm-guide/`](../llm-guide/) -- общие статьи про LLM, квантизацию
- [`docs/use-cases/`](../use-cases/) -- сценарии применения
