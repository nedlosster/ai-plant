# Open WebUI: введение

## Что это

**Open WebUI** -- self-hosted AI-платформа с rich chat UI, встроенным RAG-движком, системой функций и Pipelines-плагинов. Изначально был простой WebUI для Ollama (2023), к 2026 -- универсальный frontend для любых OpenAI-совместимых backend'ов с фокусом на privacy, extensibility и multi-user deployments.

Пользователь видит чат-интерфейс в стиле ChatGPT, но за ним -- полный контроль: локальные модели, локальные документы, локальное хранение истории, локальные функции, никакой телеметрии. Всё может работать офлайн. При этом фичи не уступают commercial платформам: RAG, web search, image generation, voice, multi-user с RBAC.

## Краткая история

- **Октябрь 2023** -- проект стартовал как [**Ollama WebUI**](https://github.com/open-webui/open-webui) от [Tim Jaeryang Baek](https://github.com/tjbck). Цель -- дать Ollama приличный GUI вместо сырого CLI
- **Начало 2024** -- быстрый рост звёзд (~500/неделя на пике). Community активно контрибьютит фичи: RAG, document uploads, image gen
- **Середина 2024** -- ребрендинг в **Open WebUI**, чтобы отразить support не только Ollama, но и любых OpenAI-compat API (llama-server, LM Studio, vLLM, OpenAI cloud, Anthropic cloud через proxy)
- **Конец 2024** -- релиз **Functions** (Python-функции для tool calling) и **Pipelines** (отдельный OpenAI-compat proxy для custom логики)
- **2025** -- корпоративные фичи: RBAC, groups, SSO (OIDC, LDAP), audit logs, multi-tenancy. Open WebUI начинает использоваться в enterprise
- **2025** -- лицензия меняется с MIT (до v0.6) на **BSD-3-Clause Plus** (с v0.6.19) -- добавлены условия для брендирования в enterprise-deployments
- **2026** -- **MCP (Model Context Protocol)** support как расширение Functions. Integration с тысячами MCP-серверов, унификация с ecosystem'ом Claude Code / AI-агентов
- **2026** -- крупные community deployments в школах, университетах, корпоративных teams

## Философия

### 1. Privacy by default

Open WebUI разработан так, чтобы **не требовать никакого внешнего интернет-трафика**, если пользователь этого не хочет:
- Можно использовать **только** локальные модели через llama-server / Ollama
- История чатов -- в локальной SQLite или PostgreSQL
- Документы для RAG -- в локальном vector store (Chroma / Qdrant)
- Поисковые провайдеры (SearxNG) -- можно развернуть локально
- Никакой телеметрии по умолчанию

Это противоположность ChatGPT / Claude web app, где всё идёт через облако. Open WebUI -- выбор для тех, кто не хочет делиться промптами и документами с vendor'ом.

### 2. All-in-one AI platform

Один интерфейс покрывает множество задач:
- Chat с любыми моделями (переключение моделей в одном окне)
- RAG по загруженным документам (PDF, DOCX, MD, txt, код)
- Web search через SearxNG / Google / Bing / DuckDuckGo
- Image generation через Automatic1111 / ComfyUI integration
- Voice input (Whisper) и output (TTS)
- Code execution (Jupyter-стиль)
- Multi-modal (vision models, image upload)

Не нужно ходить между 5 приложениями -- всё в одном URL.

### 3. Extensibility через Python

Три уровня расширения:
- **Functions**: Python-функции внутри пользовательского workspace. Writes tool calling code, загружает зависимости, вызывает сторонние API. Функции хранятся как текст, редактируются в веб-UI
- **Pipelines**: отдельный OpenAI-compat server, который обрабатывает запросы ДО того как они попадут в LLM. Может интеркептить, модифицировать, логировать, rate-limit'ить, фильтровать. Используется для enterprise-интеграций
- **Tools**: подмножество Functions для простого tool calling без дополнительной логики

Всё на Python -- массовый язык, низкий barrier для новых разработчиков. Не нужно писать JS или TypeScript.

### 4. Self-hostable, батарейки-в-комплекте

Один Docker-контейнер запускает всё необходимое:
- Frontend (SvelteKit SPA)
- Backend (FastAPI)
- SQLite (history, users, settings)
- Chroma (vector store для RAG)
- Document processing (PyPDF, docx parsing)
- Whisper STT (локально)

Не нужно настраивать Postgres, Redis, отдельный vector DB -- всё готово из коробки. Для production можно отключить встроенные и подключить внешние (PostgreSQL, Redis, Qdrant).

## Позиционирование против альтернатив

| Продукт | Философия | Кому |
|---------|-----------|------|
| **Open WebUI** | All-in-one, privacy-first, extensible через Python | Privacy-focused, team deployments, power users |
| **LobeChat** | Markdown-first, plugin marketplace, multi-deployment | UX-conscious users, ценят plugin ecosystem |
| **ChatGPT (web)** | Cloud, subscription, vendor control | Casual users, trust OpenAI |
| **Claude web** | Cloud, чистый UI, Anthropic ecosystem | Claude-loyal users |
| **AnythingLLM** | Docker-focused, RAG-first, workspaces | Teams с фокусом на документы |
| **LibreChat** | ChatGPT-clone в open-source, multi-provider | Direct замена ChatGPT UI |
| **HuggingChat** | HF-hosted, free, limited models | Casual testing HF moделей |

Open WebUI выделяется тем, что **одновременно**:
- Имеет enterprise-готовые фичи (RBAC, SSO, Pipelines)
- Остаётся простым для self-host (один Docker)
- Расширяется через массовый Python (vs TypeScript в большинстве конкурентов)

## Что это даёт на Strix Halo

На нашей платформе Open WebUI покрывает:

- **Chat UI поверх llama-server**: всё что можно запустить через [llama.cpp](../../inference/llama-cpp.md) (а это почти всё) -- доступно через красивый веб-интерфейс
- **Локальный RAG по документам**: без облака, без телеметрии. Документы остаются на сервере
- **Multi-model deployment**: одновременно подключены Qwen3-Coder Next (coding), Qwen3.5-122B (general), Gemma 4 (vision) -- переключение в одном окне
- **Team access**: несколько пользователей с RBAC и quota
- **Production-ready**: healthchecks, metrics, backup chat-history

Установка на Strix Halo -- через Docker, см. [`scripts/webui/open-webui/`](../../../scripts/webui/open-webui/):

```bash
./scripts/webui/open-webui/install.sh
./scripts/webui/open-webui/start.sh
# http://<SERVER_IP>:3210
```

Требуется запущенный inference backend (llama-server) на `localhost:8081`. Конфигурация подключения -- через `~/.config/ai-plant/inference.env`.

## Экосистема

| Компонент | Что это |
|-----------|---------|
| **[open-webui/open-webui](https://github.com/open-webui/open-webui)** | Основной репозиторий |
| **[open-webui/pipelines](https://github.com/open-webui/pipelines)** | Plugin framework: отдельный proxy-сервер для custom логики |
| **[Open WebUI Community](https://openwebui.com/models)** | Hub для sharing моделей, функций, промптов |
| **pip install open-webui** | PyPI package для установки без Docker |
| **Docker image `ghcr.io/open-webui/open-webui`** | Основной способ deployment'а |

## Связанные статьи

- [README.md](README.md) -- обзор профиля
- [architecture.md](architecture.md) -- внутреннее устройство
- [simple-use-cases.md](simple-use-cases.md) -- базовые сценарии
- [advanced-use-cases.md](advanced-use-cases.md) -- RAG, Functions, Pipelines, multi-user
- [../lobe-chat/introduction.md](../lobe-chat/introduction.md) -- альтернативная философия (Plugin Market)
- [../../inference/llama-cpp.md](../../inference/llama-cpp.md) -- backend для Open WebUI
- [../../inference/ollama.md](../../inference/ollama.md) -- другой поддерживаемый backend
