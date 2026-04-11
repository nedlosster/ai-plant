# Open WebUI

Самоуправляемое AI-приложение с RAG, Functions и Pipelines поверх OpenAI-совместимого API. Изначально был Ollama WebUI (2023), к 2026 -- полностью универсальный frontend с встроенным RAG-движком и rich plugin системой. Работает полностью офлайн.

**Тип**: SPA frontend (SvelteKit) + Python backend (FastAPI) + встроенный inference engine для RAG
**Лицензия**: MIT (до v0.6), BSD-3-Clause Plus (c 2025)
**Статус на платформе**: устанавливается через Docker, подключается к локальному llama-server
**Порт по умолчанию**: 3210 (в скриптах платформы) / 8080 (официальный default)

## Когда использовать

- Chat с локальными моделями через браузер с персистентным history
- RAG по локальным документам, PDF, markdown, веб-страницам
- Multi-user deployment с RBAC, groups, SSO
- Расширение через custom Python-функции (Functions) и Pipelines-плагины
- Privacy-sensitive сценарии (всё офлайн, никаких внешних API)

**Не для**: node-based workflow для картинок (см. [ComfyUI](../comfyui/README.md)), coding в IDE (см. [AI-агенты](../../ai-agents/README.md)), music-генерация (см. [ACE-Step](../ace-step/README.md)).

## Файлы раздела

| Файл | О чём |
|------|-------|
| [introduction.md](introduction.md) | От Ollama WebUI к self-hosted платформе, философия, экосистема |
| [architecture.md](architecture.md) | SvelteKit frontend + FastAPI backend, SQLite/PostgreSQL, Redis, встроенный RAG, OpenAI-compat layer |
| [simple-use-cases.md](simple-use-cases.md) | Базовый чат, подключение к llama-server, выбор модели, темы, history |
| [advanced-use-cases.md](advanced-use-cases.md) | RAG pipeline, Functions, Pipelines, multi-user с RBAC, MCP servers, кастомные модели |
| [tts-integration.md](tts-integration.md) | Подключение TTS backends (Kokoro, Chatterbox, XTTS), voice cloning, auto-play, streaming TTS, STT через Whisper, полный голосовой workflow |

## Статус на Strix Halo

| Компонент | Состояние |
|-----------|-----------|
| Open WebUI Docker | устанавливается через `scripts/webui/open-webui/install.sh` |
| Backend подключения | llama-server на :8081 через OpenAI-compat API |
| Модели | любые GGUF, запущенные через `scripts/inference/start-server.sh` |
| RAG | встроенный (Chroma/Qdrant в Docker) |
| Функции | Python workspace в веб-UI |

## Быстрый старт

```bash
# 1. Запустить inference backend (обязательно)
cd ~/projects/ai-plant
./scripts/inference/start-server.sh model.gguf --daemon

# 2. Установить Open WebUI (Docker)
./scripts/webui/open-webui/install.sh

# 3. Запустить
./scripts/webui/open-webui/start.sh

# 4. Открыть http://<SERVER_IP>:3210
```

Конфигурация подключения к inference backend -- через `~/.config/ai-plant/inference.env`, см. [scripts/webui/README.md](../../../scripts/webui/README.md).

## Ссылки

- Официальный GitHub: [open-webui/open-webui](https://github.com/open-webui/open-webui)
- Официальная документация: [docs.openwebui.com](https://docs.openwebui.com)
- Pipelines (plugin framework): [open-webui/pipelines](https://github.com/open-webui/pipelines)
- Discord community, PyPI package: `pip install open-webui`

## Связанные статьи

- [introduction.md](introduction.md) -- история и позиционирование
- [../lobe-chat/README.md](../lobe-chat/README.md) -- альтернатива с другим подходом (Plugin Market)
- [../../inference/llama-cpp.md](../../inference/llama-cpp.md) -- backend для Open WebUI на платформе
- [../../inference/ollama.md](../../inference/ollama.md) -- другой поддерживаемый backend
- [../../../scripts/webui/README.md](../../../scripts/webui/README.md) -- скрипты управления
