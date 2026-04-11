# ComfyUI: введение

## Что это

**ComfyUI** -- node-based workflow engine для diffusion-моделей. Пользователь строит pipeline из визуальных "нод" (боксов), каждая нода выполняет одну операцию (загрузка модели, энкодинг промпта, sampling, декодирование VAE, сохранение), соединяя их линиями. Получается граф вычислений, который ComfyUI исполняет и кэширует.

На первый взгляд это сложно -- вместо "нажми generate" нужно построить граф. На втором взгляд это ценнее любой альтернативы: каждый шаг diffusion-процесса явный и настраиваемый. Можно запустить одно и то же с тремя разными samplers, сцепить генерацию с upscale и face-fix'ом, поменять местами шаги, переиспользовать промежуточные результаты. То что в Automatic1111 WebUI (A1111) было зашито в "txt2img tab" с десятком слайдеров, в ComfyUI -- набор нод, который пользователь собирает сам.

## Краткая история

- **Январь 2023** -- первый коммит ComfyUI от [comfyanonymous](https://github.com/comfyanonymous). Автор -- псевдонимный разработчик, до сих пор пишущий основную часть кода
- **Март 2023** -- релиз, первое упоминание на Reddit r/StableDiffusion. Фокус -- максимальный контроль и минимальный UI overhead
- **2023-2024** -- экспоненциальный рост community. Появляются первые крупные custom_nodes: ControlNet, AnimateDiff, IPAdapter, ComfyUI-Manager
- **2024** -- organization Comfy-Org получает корпоративный контекст. Официальные релизы, документация, структурирование
- **Декабрь 2024** -- FLUX.1 релиз поднимает ComfyUI до статуса "стандарт open-source diffusion". A1111 начинает отставать
- **2025** -- ComfyUI V3 schema для custom nodes (stateless, process isolation, dependency-safety). AMD Radeon через ROCm/Vulkan становится officially supported
- **2026** -- ComfyUI -- де-факто стандарт для всей non-LLM generative AI: картинки, видео, аудио, multi-modal. [LTX-2](../../models/families/ltx-2.md), [Wan 2.7](../../models/families/wan.md), ComfyUI-GGUF-экосистема, workflow как artifact (civitai.com с тысячами workflow'ов)

## Философия

Основные принципы, которые делают ComfyUI тем чем он есть:

### 1. Графовая модель вычислений

Вместо императивного Python-кода -- декларативный граф. Каждая нода знает свои зависимости (inputs), ComfyUI сам решает порядок выполнения. Это автоматически даёт:
- **Параллелизм**: независимые ветви графа могут выполняться параллельно
- **Кэширование**: если граф не изменился, промежуточные результаты переиспользуются
- **Воспроизводимость**: граф сериализуется в JSON и может быть импортирован на другой машине

### 2. Explicit над implicit

Где A1111 прячет shared state внутри одной кнопки "Generate", ComfyUI показывает каждый шаг: какой sampler, сколько шагов, какая schedule, какой CFG, какой condition. Это сложнее для newcomer'а, но даёт exact control над процессом. Эксперт может точно настроить каждый параметр, не ища его в 15 вкладках настроек.

### 3. Extensibility через custom_nodes

Ядро ComfyUI минималистично. Всё интересное -- в расширениях (custom_nodes). Community пишет тысячи узлов: ControlNet, IPAdapter, InstantID, AnimateDiff, LoRA loaders, video processors, samplers, schedulers, encoders, utilities. Любая новая модель или техника приходит в ComfyUI как custom_node, обычно за несколько дней после релиза.

### 4. Workflow как артефакт

Сохранённый workflow (`.json` файл) содержит **всё**: какие модели, какие промпты, какие параметры, какие custom_nodes. Любой может открыть его, увидеть граф, запустить у себя. Workflow -- это и документация, и рецепт, и reproducible pipeline. На [civitai.com](https://civitai.com) community публикует тысячи workflow'ов как самостоятельные артефакты -- вместе с моделями и LoRA.

### 5. Headless / API-режим

ComfyUI -- не только UI. Это Python server с REST API, через который можно отправить workflow в JSON и получить результат. Это делает его production-ready для автоматизации: batch-генерация тысяч изображений, интеграция в ML-пайплайны, микросервисы.

## Позиционирование против альтернатив

| Продукт | Философия | Кому |
|---------|-----------|------|
| **ComfyUI** | Граф + explicit control + extensibility | Power users, enthusiasts, production automation |
| **Automatic1111 (A1111)** | Tabs + hidden state + батарейки-включены | Newcomer'ы, classic UI lovers |
| **SwarmUI** | ComfyUI backend + A1111-like frontend | Transition path из A1111 в ComfyUI |
| **InvokeAI** | Studio-style c таймлайном и canvas | Digital artists, iterative editing |
| **Fooocus** | Minimal UI, SDXL-focused, "one-click" | Casual users, quick experiments |
| **Stable Diffusion WebUI Forge** | Fork A1111 с оптимизациями | A1111 users которым нужно больше скорости |

В 2024-2026 **тренд сместился в ComfyUI**. Причины:
1. FLUX.1 релиз декабря 2024 -- A1111 не сразу добавил поддержку, ComfyUI добавил в день релиза
2. Video-генерация (Wan, HunyuanVideo, LTX-2) вообще не имеет A1111-интеграции, только ComfyUI workflow
3. Civitai переключился на ComfyUI workflow как основной формат для обмена рецептами
4. Community размер custom_nodes -- тысячи, против сотен для A1111

A1111 всё ещё активен для classic SD 1.5 / SDXL use-cases, но для всего нового (FLUX, video, multi-modal) ComfyUI -- стандарт.

## Что получает пользователь на Strix Halo

На нашей платформе (Radeon 8060S 120 GiB) ComfyUI даёт:

- **120 GiB VRAM vs 24 GiB RTX 4090** -- помещается FLUX fp16 (полные веса), LTX-2 в Q8_0, Wan 2.7 в fp16. На большинстве consumer GPU это недоступно
- **ggml Vulkan backend через [ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF)** -- запуск GGUF-моделей без ROCm (работает нативно через Mesa RADV)
- **Альтернативный ROCm backend** -- через PyTorch ROCm 7.2.1 (см. [../../inference/rocm-setup.md](../../inference/rocm-setup.md))
- **Cross-product параллелизм** -- можно одновременно держать ComfyUI + llama-server + Open WebUI без VRAM-конфликтов

Детали установки -- в [../../use-cases/images/comfyui-setup.md](../../use-cases/images/comfyui-setup.md). Детали архитектуры -- в [architecture.md](architecture.md).

## Связанные статьи

- [README.md](README.md) -- обзор профиля
- [architecture.md](architecture.md) -- внутреннее устройство
- [../../use-cases/images/comfyui-setup.md](../../use-cases/images/comfyui-setup.md) -- установка на платформе
- [../../use-cases/images/workflows.md](../../use-cases/images/workflows.md) -- готовые workflow
- [../../models/families/flux.md](../../models/families/flux.md) -- модели FLUX для ComfyUI
