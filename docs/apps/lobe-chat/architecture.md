# LobeChat: архитектура

Внутреннее устройство LobeChat: Next.js SSR + SPA hybrid, Edge Runtime API, Plugin Market SDK, Agents Market, self-hosted market server, data model, deployment paradigms.

## Общая схема

LobeChat -- **Next.js application** с гибридной routing-моделью:

```
+------------------------------------------+
|  Client (Browser / Desktop / Mobile)      |
|  - Next.js SSR страницы (auth, landing)   |
|  - React Router DOM SPA (основной chat)   |
|  - Zustand store (state management)       |
|  - Dexie.js (IndexedDB для local)         |
+-----------------+------------------------+
                  |
                  |  HTTP / tRPC
                  |
+-----------------v------------------------+
|  Next.js Server                           |
|  - API Routes (Node.js runtime)           |
|  - Edge Runtime API (edge functions)      |
|  - SSR для auth/settings pages            |
+-------+---------+---------+---------+----+
        |         |         |         |
        v         v         v         v
+----------+ +--------+ +------+ +---------+
| Inference| | Market | | DB   | | Plugin  |
| providers| | server | | SQL/ | | runtime |
| (OpenAI/ | | (@lobe | | NoSQL| | (sandbox|
|  Ollama/ | |  hub/  | |      | | per     |
|  ...)    | |  market| |      | | plugin) |
|          | |  -sdk) | |      | |         |
+----------+ +--------+ +------+ +---------+
```

Ключевые компоненты:

| Компонент | Что делает |
|-----------|------------|
| **Next.js SSR pages** | Server-rendered страницы: login, landing, settings |
| **React Router DOM SPA** | Основной chat-интерфейс, client-side navigation |
| **Zustand** | Global state management (messages, settings, user) |
| **Dexie.js / IndexedDB** | Local storage для chat history в client-mode |
| **Edge Runtime API** | Легковесные API endpoints на edge (Vercel Edge / Cloudflare Workers) |
| **Node.js API routes** | Тяжёлые operations (image processing, plugin execution) |
| **Database** | PostgreSQL для server-mode, IndexedDB для client-mode |
| **Market SDK** | Клиент для Plugin/Agents market server (online или self-hosted) |

## Почему Next.js SSR + SPA hybrid

Это ключевое инженерное решение. Обычно приложения выбирают **или** SSR (Next.js), **или** SPA (React Router). LobeChat использует **оба подхода одновременно**:

### SSR для static pages

Страницы, которые нужны для **первой загрузки** и SEO:
- `/` -- landing page (Next.js SSR)
- `/login`, `/register` -- auth (SSR, чтобы форму можно было submit'ить без JS)
- `/settings/*` -- настройки (SSR с server-side user data)
- `/docs/*` -- встроенная документация

Эти страницы рендерятся на сервере, передаются как HTML, гидрируются React'ом.

### SPA для main chat

Основной chat-интерфейс (`/chat`) работает как **single-page application**:
- React Router DOM для client-side routing между чатами
- Нет перезагрузки при переключении чатов
- Streaming ответов идёт без перерендера страницы
- Anchor-based deep linking в отдельные сообщения

### Почему hybrid

- **Performance**: первая загрузка быстрая (SSR отдаёт готовый HTML), но interaction внутри чата -- instant (SPA)
- **SEO**: landing и docs индексируются Google
- **JS-degradation**: auth и settings работают даже при отключенном JS
- **Deployment flexibility**: SSR страницы можно cache'ить, SPA часть -- работать offline (через service workers)

Это сложнее чем чистый SSR или чистый SPA, но даёт best of both worlds.

## Edge Runtime API

Next.js позволяет отдельные API endpoints писать под **Edge Runtime** (облегчённая runtime без Node.js, работает на V8 isolates). LobeChat активно использует это для:

- `/api/chat` -- streaming chat endpoint (проксирует к LLM provider). Edge runtime даёт ultra-low latency и может deployment'иться на edge locations
- `/api/plugin/*` -- plugin execution proxies
- `/api/auth/*` -- некоторые auth callbacks

Edge runtime limitations:
- Нет Node.js APIs (fs, child_process, net)
- Нет нативных dependencies
- Ограниченный bundle size

Где нужны Node.js возможности -- используется обычная Node.js runtime (например, для image processing через sharp).

## Data model

### Client-mode (default для self-host без database)

По умолчанию LobeChat работает в **client-mode**: все данные (чаты, настройки, history, uploaded files, agent definitions) хранятся **локально в браузере** через IndexedDB (wrapper Dexie.js).

Плюсы:
- Ноль serverside state
- Privacy -- ничего не уходит на server
- Простой deployment (Docker-контейнер = frontend, all state client-side)

Минусы:
- История привязана к browser (удалил cookies -- потерял)
- Нет sync между устройствами
- Нет multi-user в одном инстансе

### Server-mode (с database)

Для team/enterprise -- включается **server-mode** с PostgreSQL:
- Установка `DATABASE_URL=postgresql://...`
- Миграции запускаются автоматически на старте
- Данные хранятся в Postgres, доступны из любого браузера после login
- Multi-user с аккаунтами и session

Схема server-mode включает:
- `users` -- аккаунты
- `sessions` -- текущие чат-сессии
- `messages` -- сообщения
- `agents` -- сохранённые custom agents
- `files` -- uploaded files
- `knowledge_bases` -- векторные stores для RAG (если включено)
- `plugin_installations` -- какие плагины установлены per-user

## Plugin Market и Plugin SDK

Это одна из главных уникальных черт LobeChat.

### Что такое plugin в LobeChat

Plugin -- это **JavaScript/TypeScript module**, который расширяет возможности LLM:
- Предоставляет tools (function calling)
- Модифицирует UI (custom renderers для plugin outputs)
- Интегрирует внешние APIs (web search, Wikipedia, Bilibili, Steam и т.д.)

Plugin состоит из:
- **Manifest** (`lobe-plugin.json`) -- metadata, описание tools, settings schema
- **API endpoints** -- где тулы выполняются (обычно serverless function на Vercel)
- **UI components** (опционально) -- custom React компоненты для отображения результатов

### Manifest пример

```json
{
  "identifier": "weather-plugin",
  "version": "1.0.0",
  "author": "john.doe",
  "homepage": "https://github.com/.../weather-plugin",
  "api": [
    {
      "name": "getCurrentWeather",
      "description": "Get current weather for a location",
      "url": "https://my-plugin.vercel.app/api/weather",
      "parameters": {
        "type": "object",
        "properties": {
          "location": {
            "type": "string",
            "description": "City name"
          }
        },
        "required": ["location"]
      }
    }
  ],
  "meta": {
    "avatar": "🌤",
    "title": "Weather",
    "description": "Get current weather information"
  }
}
```

LobeChat читает manifest, регистрирует `getCurrentWeather` как tool, экспонирует его LLM.

### Plugin Market SDK

**[@lobehub/market-sdk](https://www.npmjs.com/package/@lobehub/market-sdk)** -- TypeScript SDK для работы с Plugin Market. Реализует:

- **Fetch plugin list** -- получить список плагинов из marketplace
- **Plugin details** -- manifest, readme, icons, author info
- **Search / filter** -- по категориям, тегам, popularity
- **Install** -- скачать plugin manifest, зарегистрировать в локальной БД

LobeChat использует SDK для подключения к дефолтному marketplace ([lobehub.com/plugins](https://lobehub.com/plugins)). В Plugin Market -- curated плагины, прошедшие модерацию.

### Self-hosted market server

Для enterprise / privacy-sensitive setup'ов -- можно поднять **свой marketplace**. Архитектура:

```
LobeChat client
    ↓
Читает NEXT_PUBLIC_MARKET_BASE_URL
    ↓
Вместо lobehub.com/market → ваш http://market.company.local
    ↓
Market server экспонирует API совместимый с @lobehub/market-sdk
    ↓
Отдаёт curated список плагинов/агентов вашей организации
```

Self-hosted market server -- это **отдельное приложение**, которое хостит plugin manifests и обслуживает API. LobeChat team работает над reference implementation (см. [discussion #10763](https://github.com/lobehub/lobehub/discussions/10763)).

## Agents Market

**Agents** в LobeChat -- это **готовые prompt-конфигурации**:
- System prompt
- Описание роли
- Примеры взаимодействия
- Рекомендованная модель и параметры (temperature, max_tokens, top_p)
- Привязанные плагины

Agent = "AI-ассистент с фиксированной ролью и персональностью".

### Примеры агентов из маркета

- **"Writing improver"** -- улучшает текст, делает его более естественным
- **"Code reviewer"** -- проводит code review (как "модель" `code-reviewer` в Open WebUI, см. [../open-webui/advanced-use-cases.md](../open-webui/advanced-use-cases.md))
- **"SQL expert"** -- помогает писать SQL запросы
- **"Historical figure: Einstein"** -- отвечает как Эйнштейн
- **"UX designer mentor"** -- помогает с design-решениями
- **"Russian-English tutor"** -- двуязычный учитель

В marketplace -- десятки тысяч агентов, частично вручную курируемых, частично submitted from community.

### Создание своего агента

1. Settings → Agents → "+ New Agent"
2. Заполнить:
   - Avatar, name, description
   - System prompt
   - Opening message
   - Recommended model
   - Parameters (temperature, etc)
3. Save локально
4. (опционально) Share в маркетплейс через PR в [awesome-chat-prompts](https://github.com/lobehub/awesome-chat-prompts)

## Inference providers abstraction

LobeChat поддерживает 30+ inference providers через абстрактный layer:

| Тип | Провайдеры |
|-----|-----------|
| **Cloud closed-source** | OpenAI, Anthropic, Google Gemini, Azure OpenAI, AWS Bedrock, Groq, Together, Fireworks, DeepSeek, Moonshot, Zhipu, Baichuan, Minimax, Perplexity |
| **Self-hosted open** | **Ollama**, **llama-server (OpenAI-compat)**, **LM Studio**, vLLM, Xinference |
| **HF-hosted** | HuggingFace Inference Endpoints, Together |
| **Edge** | Cloudflare Workers AI, Vercel AI Gateway |

Для каждого провайдера -- свой adapter. Они нормализуют форматы запросов/ответов под единый внутренний format. Пользователь в UI выбирает `provider + model`, LobeChat строит правильный запрос.

### Подключение llama-server на Strix Halo

Settings → Provider → OpenAI-compatible (или просто "OpenAI"):
- API Base URL: `http://<SERVER_IP>:8081/v1`
- API Key: `dummy` (llama-server не требует, но SDK требует что-то ненулевое)
- Models: можно указать список вручную или положиться на `/v1/models` endpoint

После этого Qwen3-Coder Next / Qwen3.5-122B / др. локальные модели появятся в dropdown провайдеров.

## Deployment paradigms

### 1. Cloud (managed)

[chat.lobehub.com](https://chat.lobehub.com) -- managed версия. LobeHub хостит LobeChat, пользователь регистрируется и подключает свои API-keys (bring-your-own-key). LobeHub не видит содержимое чатов (всё проксируется в client-mode).

Плюсы: ноль setup, доступ отовсюду
Минусы: привязка к LobeHub infrastructure, требуется интернет

### 2. Self-hosted Docker

Основной способ для нашей платформы:

```bash
docker run -d \
  -p 3211:3210 \
  -e OPENAI_API_KEY=dummy \
  -e OPENAI_PROXY_URL=http://host.docker.internal:8081/v1 \
  lobehub/lobe-chat:latest
```

Доступ через `http://<SERVER_IP>:3211`. Все данные в IndexedDB браузера.

Для **multi-user с server-mode** -- добавить `DATABASE_URL` и `NEXTAUTH_SECRET`.

### 3. Desktop (Electron)

**LobeHub Desktop** -- Electron-приложение для macOS/Windows/Linux. Устанавливается как обычная программа, запускает LobeChat локально. Под капотом -- тот же Next.js, упакованный в Electron.

Плюсы:
- Нет Docker overhead
- Native OS integration (menu bar, shortcuts)
- Offline-first (local storage)

Подходит для personal use. На Strix Halo можно установить Desktop app как **клиент**, который подключается к локальному llama-server через LAN.

## Background tasks (2026)

Новая фича 2026 года -- **background tasks**. Агенты могут выполнять долгие операции (поиск по большому corpus, обработка файлов, сложные вычисления) **не блокируя текущий chat**:

- Пользователь запускает задачу: "Проанализируй все мои PDF за последний год и сделай отчёт"
- Agent уходит в background, показывает task-ID и progress indicator
- Пользователь продолжает другие разговоры
- Через несколько минут прилетает notification: "Task completed"
- Результат доступен в отдельной вкладке

Технически это реализовано через:
- Task queue (Redis или SQLite)
- Worker процессы (отдельные Node.js workers)
- WebSocket push updates в UI

Это приближает LobeChat к концепции "agent as teammate, not tool".

## Связанные статьи

- [README.md](README.md) -- обзор профиля
- [introduction.md](introduction.md) -- история и философия
- [simple-use-cases.md](simple-use-cases.md) -- базовые сценарии
- [advanced-use-cases.md](advanced-use-cases.md) -- Plugin Market, custom agents, voice mode
- [../open-webui/architecture.md](../open-webui/architecture.md) -- для сравнения архитектур
- [../../inference/llama-cpp.md](../../inference/llama-cpp.md) -- backend
