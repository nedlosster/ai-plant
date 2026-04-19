# Документация ai-plant

Inference-сервер на AMD Ryzen AI MAX+ 395 (Strix Halo, 96 GiB VRAM).

## Платформа ([platform/](platform/README.md))

| Документ | Описание |
|----------|----------|
| [Обзор](platform/README.md) | Сводка, текущая конфигурация |
| [Процессор](platform/processor.md) | Zen 5, RDNA 3.5, XDNA 2, бенчмарки, сравнение |
| [Спецификация](platform/server-spec.md) | CPU, GPU, NPU, память, сеть, доступ |
| [Ядро](platform/gpu-kernel-setup.md) | GRUB, mainline-ядро, DCN 3.5.1, X11 |
| [BIOS](platform/bios-setup.md) | UMA/VRAM, C-states, governor, энергосбережение |
| [Драйвер amdgpu](platform/amdgpu-driver.md) | IP-блоки, firmware, sysfs, мониторинг |

## Inference ([inference/](inference/README.md))

| Документ | Описание |
|----------|----------|
| [Обзор](inference/README.md) | Бэкенды (Vulkan/ROCm/CPU), архитектура |
| [llama.cpp (профиль проекта)](inference/llama-cpp.md) | История, GGML, GGUF, квантизации, бэкенды, llama-server, spec decoding |
| [Ollama (профиль проекта)](inference/ollama.md) | Docker-подход, Modelfile, OCI-registry, content-addressed storage, экосистема |
| [Lemonade (профиль проекта)](inference/lemonade.md) | NPU-ускорение для Ryzen AI, hybrid prefill/decode, ONNX RT GenAI, Quark/AWQ |
| [Выбор моделей](inference/model-selection.md) | GGUF, safetensors, квантизация, VRAM |
| [llama.cpp + Vulkan](inference/vulkan-llama-cpp.md) | Сборка, запуск, скрипты |
| [Установка ROCm](inference/rocm-setup.md) | ROCm 6.4, HSA_OVERRIDE, скрипты |
| [llama.cpp + ROCm](inference/rocm-llama-cpp.md) | HIP backend, сравнение с Vulkan |
| [LM Studio](inference/lm-studio.md) | GUI, Vulkan, API |
| [CPU-инференс](inference/cpu-inference.md) | AVX-512 BF16/VNNI |
| [GPUStack](inference/gpustack.md) | Web UI, кластер, оркестрация |
| [Бенчмарки](inference/benchmarking.md) | Метрики, bandwidth, мониторинг |
| [Диагностика](inference/troubleshooting.md) | Ошибки Vulkan/ROCm/память |

## Модели ([models/](models/README.md))

| Документ | Описание |
|----------|----------|
| [LLM общего назначения](models/llm.md) | Qwen3.5, Llama 3.3/4, DeepSeek-R1, Phi-4, QwQ |
| [Российские LLM](models/russian-llm.md) | Saiga, T-pro, Vikhr, ruGPT, FRED-T5 |
| [Кодинг](models/coding.md) | Qwen3-Coder, Devstral 2, FIM-модели |
| [Музыка](models/music.md) | ACE-Step, MusicGen, YuE |
| [Русский вокал](models/russian-vocals.md) | Русскоязычные песни, сравнение |
| [Картинки](models/images.md) | FLUX.1, SD 3.5, HiDream, ComfyUI |
| [Видео](models/video.md) | Wan2.1, CogVideoX, AnimateDiff |

## Основы LLM ([llm-guide/](llm-guide/README.md))

| Документ | Уровень |
|----------|---------|
| [Что такое LLM](llm-guide/what-is-llm.md) | основы |
| [Transformer](llm-guide/transformer.md) | основы |
| [Токенизация](llm-guide/tokenization.md) | основы |
| [Генерация текста](llm-guide/generation.md) | основы |
| [Сэмплирование](llm-guide/sampling.md) | основы |
| [Анатомия LLM](llm-guide/model-anatomy.md) | основы |
| [HuggingFace](llm-guide/huggingface.md) | основы |
| [Контекстное окно](llm-guide/context-window.md) | практика |
| [Архитектуры](llm-guide/architectures.md) | практика |
| [Квантизация](llm-guide/quantization.md) | практика |
| [Системные промпты](llm-guide/system-prompts.md) | практика |
| [Prompt engineering](llm-guide/prompt-engineering.md) | практика |
| [RAG](llm-guide/rag/README.md) | продвинутый |
| [Function calling](llm-guide/function-calling.md) | продвинутый |
| [Мультимодальные модели](llm-guide/multimodal.md) | продвинутый |
| [Локальный vs API](llm-guide/local-vs-api.md) | продвинутый |

## Training ([training/](training/README.md))

| Документ | Описание |
|----------|----------|
| [Обзор методов](training/methods.md) | Full FT, LoRA, QLoRA, DPO/GRPO |
| [Окружение](training/environment.md) | PyTorch + ROCm, Docker |
| [Данные](training/datasets.md) | Alpaca, ShareGPT, ChatML |
| [Fine-tuning LLM](training/llm-finetuning.md) | Unsloth, LLaMA-Factory, Axolotl |
| [Fine-tuning Diffusion](training/diffusion-finetuning.md) | kohya_ss, SimpleTuner |
| [Alignment](training/alignment.md) | DPO, GRPO, ORPO |
| [Проблемы](training/known-issues.md) | hipMemcpy, NaN, workarounds |

## AI-агенты ([ai-agents/](ai-agents/README.md))

| Документ | Описание |
|----------|----------|
| [Обзор](ai-agents/README.md) | Что такое AI-агенты, эволюция, концепции, рынок |
| [Платные агенты](ai-agents/commercial.md) | Claude Code, Codex, Cursor, Windsurf, Devin, Junie, Copilot, Amazon Q, Gemini |
| [Открытые агенты](ai-agents/open-source.md) | Aider, OpenCode, Hermes, Cline, Roo Code, Continue, OpenHands |
| [Сравнение](ai-agents/comparison.md) | Таблица, бенчмарки, матрица выбора |
| [Тренды](ai-agents/trends.md) | Multi-agent, bounded autonomy, context race, прогнозы |

## AI-кодинг ([coding/](coding/README.md))

Центральный раздел для AI-assisted разработки: coding LLM, agents, workflow'ы, ресурсы community. Обновление: `/refresh-news coding`.

| Статья | Описание |
|--------|----------|
| [Хроника](coding/news.md) | Релизы coding моделей, обновления агентов, SWE-bench лидерборд, блог-посты |
| [Workflow'ы](coding/workflows.md) | FIM + CLI agent, multi-agent, code review, TDD с AI |
| [Ресурсы](coding/resources.md) | Блоги, рассылки, YouTube, leaderboard-сайты, community |

## Прикладные задачи ([use-cases/](use-cases/README.md))

| Раздел | Описание |
|--------|----------|
| [Музыка](use-cases/music/README.md) | ACE-Step 1.5: генерация песен, промпты, LoRA |
| [Кодинг](use-cases/coding/README.md) | AI-агенты, IDE, автодополнение |
| [Картинки](use-cases/images/README.md) | ComfyUI + FLUX/SD: workflows, LoRA |
| [Видео](use-cases/video/README.md) | Wan2.1, CogVideoX: text-to-video |

## Приложения ([apps/](apps/README.md))

End-user приложения через которые пользователь работает с моделями. Отличие от use-cases: здесь профили **самих приложений** (архитектура, внутреннее устройство), не рецепты задач.

| Приложение | Описание |
|------------|----------|
| [ComfyUI](apps/comfyui/README.md) | Node-based workflow engine: diffusion, видео, multi-modal (через ggml Vulkan и PyTorch ROCm) |
| [Open WebUI](apps/open-webui/README.md) | RAG chat frontend поверх llama-server: Functions, Pipelines, multi-user |
| [LobeChat](apps/lobe-chat/README.md) | Markdown chat с Plugin Market и Agents Market, Next.js SSR hybrid |
| [ACE-Step](apps/ace-step/README.md) | Music generation studio: DiT + LM dual-component, Gradio UI, LoRA trainer |

## Скрипты

| Папка | Описание |
|-------|----------|
| [scripts/status.sh](../scripts/status.sh) | Общий статус: GPU, inference, веб-интерфейсы, модели |
| [scripts/inference/](../scripts/inference/) | llama.cpp: запуск серверов, модели, бенчмарк, мониторинг |
| [scripts/inference/vulkan/](../scripts/inference/vulkan/README.md) | Vulkan backend: сборка, проверка |
| [scripts/inference/rocm/](../scripts/inference/rocm/README.md) | ROCm/HIP backend: установка, проверка, сборка |
| [scripts/webui/](../scripts/webui/README.md) | Веб-интерфейсы: Open WebUI, Lobe Chat |
| [scripts/music/ace-step/](../scripts/music/ace-step/README.md) | ACE-Step 1.5: генерация песен |
| [scripts/power/](../scripts/power/) | Режимы энергосбережения |
| [scripts/docs/](../scripts/docs/) | Валидация документации |

## Справочное

| Документ | Описание |
|----------|----------|
| [Глоссарий](glossary.md) | Термины AI/ML |
| [Changelog](changelog.md) | Хроника изменений в документации и инфраструктуре, курируется из git history |

## Быстрый старт

1. Платформа настроена: ядро 6.19.8, BIOS оптимизирован, Vulkan + ROCm 6.4
2. llama.cpp собран с Vulkan, модели в `~/models`
3. Запуск: [`./scripts/inference/start-server.sh`](../scripts/inference/start-server.sh) `model.gguf --daemon`
4. Загрузка моделей: [`./scripts/inference/download-model.sh`](../scripts/inference/download-model.sh) `repo --include "*Q4_K_M*"`

