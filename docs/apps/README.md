# Приложения (apps/)

Профили end-user приложений через которые пользователь работает с моделями на платформе Strix Halo. В отличие от [моделей](../models/README.md) (веса), [inference-бэкендов](../inference/README.md) (движки) и [use-cases](../use-cases/README.md) (рецепты задач), этот раздел описывает **сами приложения** как продукты: архитектуру, внутреннее устройство, простые и сложные сценарии использования.

## Что такое "приложение" в этом разделе

"Приложение" -- верхнеуровневый продукт с собственным UX и workflow-моделью, который пользователь запускает и с которым взаимодействует напрямую. Отличие от других категорий:

| Категория | Описывает |
|-----------|-----------|
| [`platform/`](../platform/README.md) | Аппаратная часть (CPU, BIOS, ядро, драйверы) |
| [`inference/`](../inference/README.md) | Backend-движки (llama.cpp, Ollama, Lemonade) |
| [`models/families/`](../models/families/README.md) | Веса и архитектуры моделей |
| [`use-cases/`](../use-cases/README.md) | Операционные задачи ("как сделать X") |
| **`apps/` (этот раздел)** | **End-user приложения**: UI, workflow-движки, studios, chat-интерфейсы |

Пример: [`docs/models/families/flux.md`](../models/families/flux.md) -- про веса FLUX.1. [`docs/use-cases/images/workflows.md`](../use-cases/images/workflows.md) -- про конкретный txt2img workflow. **Этот раздел** -- про ComfyUI как программу: node graph engine, execution model, ecosystem плагинов.

## Подразделы

| Приложение | Категория | Backend inference | Формат данных | Статус на платформе |
|------------|-----------|-------------------|---------------|---------------------|
| [**ComfyUI**](comfyui/README.md) | Node-based workflow engine | ggml Vulkan, PyTorch ROCm | JSON workflow + custom_nodes | работает через ComfyUI-GGUF |
| [**Open WebUI**](open-webui/README.md) | RAG chat frontend | llama-server, Ollama, OpenAI | REST + Functions/Pipelines | через Docker |
| [**LobeChat**](lobe-chat/README.md) | Markdown chat с plugins | llama-server, Ollama, OpenAI | REST + Plugin Market | через Docker |
| [**ACE-Step**](ace-step/README.md) | Music generation studio | PyTorch (CPU/ROCm) | Gradio UI + LoRA trainer | CPU-only из-за KFD VRAM issue |

## Матрица выбора

| Задача | Приложение |
|--------|------------|
| Генерация картинок / видео с контролем каждого шага | [ComfyUI](comfyui/README.md) |
| Chat с локальными моделями через браузер | [Open WebUI](open-webui/README.md) или [LobeChat](lobe-chat/README.md) |
| Chat с RAG по локальным документам | [Open WebUI](open-webui/README.md) (нативная поддержка) |
| Chat с plugins экосистемой и assistants | [LobeChat](lobe-chat/README.md) (Plugin Market) |
| **Голосовой диалог с LLM (TTS+STT)** | [Open WebUI TTS](open-webui/tts-integration.md) или [LobeChat Voice Mode](lobe-chat/tts-integration.md) |
| Генерация песен с вокалом | [ACE-Step](ace-step/README.md) |
| Автоматизация diffusion-pipeline через API | [ComfyUI](comfyui/README.md) в API-mode |
| Multi-user chat-deployment с SSO | [Open WebUI](open-webui/README.md) (Pipelines, RBAC) |

## Когда что выбрать: Open WebUI vs LobeChat

| Критерий | Open WebUI | LobeChat |
|----------|------------|----------|
| **Философия** | All-in-one AI platform с RAG и Functions | Markdown-first chat с plugin ecosystem |
| **Frontend** | SvelteKit + FastAPI | Next.js (SSR + SPA hybrid) |
| **Расширения** | Pipelines (Python), Functions (Python) | Plugin Market, Agents Market |
| **RAG** | Встроенный, нативный | Через плагины |
| **Voice / image gen** | Есть, через Functions | Есть, через плагины |
| **Multi-user** | Native RBAC, SSO, groups | Cloud-deployment или self-host |
| **Кто выбирает** | Power users, teams, privacy-focused | Users ценящие UX и plugin marketplace |

Подробнее -- в [open-webui/README.md](open-webui/README.md) и [lobe-chat/README.md](lobe-chat/README.md).

## Структура каждого подраздела

Каждая папка `docs/apps/<name>/` содержит 5 обязательных файлов:

- `README.md` -- индекс, краткая сводка, когда использовать, статус на платформе
- `introduction.md` -- что это, история, философия, позиционирование
- `architecture.md` -- внутреннее устройство: компоненты, data flow, форматы
- `simple-use-cases.md` -- 3-5 базовых сценариев
- `advanced-use-cases.md` -- сложные сценарии, API, автоматизация, custom extensions

Опционально могут быть `ecosystem.md`, `integration.md`, `troubleshooting.md`.

## Связанные разделы

- [../models/README.md](../models/README.md) -- каталог моделей (что можно запускать через эти приложения)
- [../inference/README.md](../inference/README.md) -- backend-движки (ниже уровнем чем приложения)
- [../use-cases/README.md](../use-cases/README.md) -- операционные задачи (рецепты)
- [../../scripts/comfyui/README.md](../../scripts/comfyui/README.md) -- скрипты запуска ComfyUI на платформе
- [../../scripts/webui/README.md](../../scripts/webui/README.md) -- скрипты запуска web-интерфейсов
- [../../scripts/music/ace-step/README.md](../../scripts/music/ace-step/README.md) -- скрипты запуска ACE-Step
