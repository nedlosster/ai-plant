# LobeChat

Markdown-first AI chat с Plugin Market и Agents Market экосистемой. От команды LobeHub. Построен на Next.js (SSR + SPA hybrid), с богатой типографикой, поддержкой voice, vision и обширной plugin-системой для расширения assistant'ов.

**Тип**: Next.js приложение (SSR + React Router DOM SPA hybrid)
**Лицензия**: Apache 2.0
**Статус на платформе**: устанавливается через Docker, подключается к локальному llama-server
**Порт по умолчанию**: 3211 (в скриптах платформы) / 3210 (официальный default)

## Когда использовать

- Chat с красивой markdown-типографикой и smooth streaming
- Расширение через Plugin Market и Agents Market (тысячи готовых плагинов и ассистентов)
- Voice mode, vision input, image generation через плагины
- Interaction с third-party сервисами (Bilibili, Steam, web search, data sources) через плагины
- Cloud / self-hosted / desktop deployment (три варианта сразу)

**Не для**: сложных RAG-пайплайнов (см. [Open WebUI](../open-webui/README.md), у него встроенный RAG), node-based workflow для картинок (см. [ComfyUI](../comfyui/README.md)), coding в IDE (см. [AI-агенты](../../ai-agents/README.md)).

## Файлы раздела

| Файл | О чём |
|------|-------|
| [introduction.md](introduction.md) | История LobeHub, позиционирование против Open WebUI, философия plugin marketplace |
| [architecture.md](architecture.md) | Next.js SSR + React Router SPA hybrid, Edge Runtime API, Plugin Market SDK, Agents Market, self-hosted market server |
| [simple-use-cases.md](simple-use-cases.md) | Базовый чат, выбор assistant, markdown форматирование, smooth streaming |
| [advanced-use-cases.md](advanced-use-cases.md) | Plugin Market integration, custom assistants, voice mode, image gen plugins, background tasks |
| [tts-integration.md](tts-integration.md) | Speech Provider layer, OpenAI-compat TTS/STT backends, Voice Mode full-duplex, Browser Web Speech API, plugin-based TTS, полный голосовой workflow |

## Статус на Strix Halo

| Компонент | Состояние |
|-----------|-----------|
| LobeChat Docker | устанавливается через [`scripts/webui/lobe-chat/install.sh`](../../../scripts/webui/lobe-chat/install.sh) |
| Backend подключения | llama-server на :8081 через OpenAI-compat API |
| Plugin Market | подключается по умолчанию к lobehub.com/market |
| Assistants | доступны через Agents Market |
| Deployment | Docker container, single-user (для multi-user нужен дополнительный DB backend) |

## Быстрый старт

```bash
# 1. Запустить inference backend
cd ~/projects/ai-plant
./scripts/inference/start-server.sh model.gguf --daemon

# 2. Установить LobeChat
./scripts/webui/lobe-chat/install.sh

# 3. Запустить
./scripts/webui/lobe-chat/start.sh

# 4. Открыть http://<SERVER_IP>:3211
```

## Ссылки

- Официальный GitHub: [lobehub/lobe-chat](https://github.com/lobehub/lobe-chat)
- Новый мета-репозиторий: [lobehub/lobehub](https://github.com/lobehub/lobehub)
- Документация: [lobehub.com/docs](https://lobehub.com/docs)
- Plugin Market: [lobehub.com/plugins](https://lobehub.com/plugins)
- Agents Market: [lobehub.com/agents](https://lobehub.com/agents)
- NPM package: `@lobehub/lobehub`

## Связанные статьи

- [introduction.md](introduction.md) -- позиционирование и история
- [../open-webui/README.md](../open-webui/README.md) -- альтернатива с встроенным RAG
- [../../inference/llama-cpp.md](../../inference/llama-cpp.md) -- backend для LobeChat на платформе
- [../../../scripts/webui/README.md](../../../scripts/webui/README.md) -- скрипты управления
