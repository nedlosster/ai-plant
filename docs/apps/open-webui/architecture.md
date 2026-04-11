# Open WebUI: архитектура

Внутреннее устройство Open WebUI: трёхуровневая архитектура (frontend / backend / inference), data flow при chat-запросе, RAG-движок, Functions vs Pipelines, модели авторизации.

## Общая схема

Open WebUI -- **трёхуровневое приложение**:

```
+------------------------------------------+
|  Frontend (SvelteKit SPA)                 |
|  - Svelte 5 + TypeScript                  |
|  - Tailwind CSS                           |
|  - Vite build                             |
|  - Single Page Application                |
|  - WebSocket client для streaming         |
+-----------------+------------------------+
                  |
                  |  HTTP + WebSocket
                  |  :8080 (или :3210 в скриптах платформы)
                  |
+-----------------v------------------------+
|  Backend (Python FastAPI)                 |
|  - REST endpoints                         |
|  - WebSocket manager                      |
|  - Auth (JWT + OAuth + LDAP)              |
|  - Chat engine                            |
|  - RAG engine                             |
|  - Functions / Tools runtime              |
|  - Pipelines forwarding                   |
|  - SQLAlchemy ORM                         |
+-------+---------+--------------+---------+
        |         |              |
        v         v              v
+-----------+ +--------+ +------------------+
| SQLite /  | | Redis  | | Vector store    |
| Postgres  | | (opt)  | | (Chroma default,|
| via       | | cache  | |  Qdrant/Milvus  |
| SQLAlchemy| | WS     | |  optional)      |
+-----------+ +--------+ +------------------+
        |
        |  Inference (external)
        v
+------------------------------------------+
|  Inference providers                      |
|  - Ollama API (/api/chat)                 |
|  - OpenAI-compat API (/v1/chat/...)       |
|     → llama-server, LM Studio, vLLM, ...  |
|  - Cloud (OpenAI, Anthropic via proxy)    |
+------------------------------------------+
```

## Frontend: SvelteKit SPA

Frontend -- single-page application на SvelteKit с Svelte 5 reactivity. Ключевые технологические решения:

- **SvelteKit в SPA-режиме**: не использует server-side rendering для страниц, вместо этого backend FastAPI просто отдаёт скомпилированный SPA-бандл. SvelteKit используется как build system и router, но runtime -- чистый SPA
- **Svelte 5 runes**: new reactivity model (`$state`, `$derived`, `$effect`). Компоненты становятся более предсказуемыми
- **Tailwind CSS**: utility-first styling, быстрые итерации UI без CSS-файлов
- **Vite build**: быстрая HMR в dev, оптимизированная production-сборка
- **i18n**: 30+ языков через `svelte-i18n`

Frontend общается с backend через:
- **HTTP REST** с `Authorization: Bearer <JWT>` header
- **WebSocket** для streaming ответов модели и server-sent events

## Backend: FastAPI + SQLAlchemy

### FastAPI почему

- **Asyncio**: работа с inference providers -- async I/O. FastAPI нативно это умеет через `async def` endpoints
- **OpenAPI spec**: автоматическая Swagger UI документация API на `/docs` -- полезно для разработки интеграций и тестов
- **Pydantic validation**: типы входов/выходов проверяются автоматически
- **Middleware stack**: auth, CORS, logging -- стандартные FastAPI middleware

### SQLAlchemy ORM и БД

Данные хранятся через **SQLAlchemy**, что даёт choice of DB:
- **SQLite** (default) -- один файл, подходит для single-instance, небольших команд, разработки
- **PostgreSQL** -- production, multi-replica, поддержка SCRAM-SHA-256 auth, горизонтальное масштабирование через read replicas
- **SQLCipher** -- опция для encrypted SQLite (для compliance sensitive deployments)

Схема данных включает:
- **users** -- пользователи, роли, profile
- **chats** -- сессии чатов, связанные с users
- **messages** -- отдельные сообщения внутри chats, JSON с content, role, metadata
- **models** -- список доступных моделей, их параметры и ссылки на inference providers
- **functions** -- код пользовательских функций (Python как text + metadata)
- **tools** -- подмножество functions для tool calling
- **pipelines** -- конфигурация подключённых Pipelines-серверов
- **documents** -- загруженные документы для RAG (с chunks в отдельной таблице)
- **files** -- связанные файлы (attachments в chats)
- **prompts** -- сохранённые prompt-шаблоны

### Redis (опционально)

Для **multi-instance deployment**:
- WebSocket pubsub между инстансами (чтобы streaming ответа шёл из любого backend'а)
- Кэш для tokens, rate limits, session
- Distributed locks для concurrent resource access

Для single-instance не требуется.

## Chat engine: data flow при запросе

Пример запроса: пользователь отправляет "Hello, what's the weather?" в чат.

### 1. Frontend → Backend

```http
POST /api/chat HTTP/1.1
Authorization: Bearer eyJ0eXAi...
Content-Type: application/json

{
  "messages": [
    {"role": "user", "content": "Hello, what's the weather?"}
  ],
  "model": "qwen3-coder-next:latest",
  "stream": true
}
```

### 2. Backend: authentication

FastAPI middleware:
1. Валидирует JWT → user_id
2. Проверяет quota (если настроено): сколько сообщений пользователь отправил за последний час
3. Проверяет RBAC: имеет ли user доступ к модели `qwen3-coder-next`
4. Логирует запрос (audit log, если включён)

### 3. Backend: middleware pipeline

Если настроены **Pipelines** (см. ниже), запрос может пройти через них **ДО** отправки в LLM. Pipeline может:
- Отфильтровать сообщение на toxic content
- Переписать промпт (system prompt injection)
- Применить rate limiting
- Логировать в observability (Langfuse, Helicone)

### 4. Backend: RAG retrieval (если нужно)

Если к чату подключены документы (`Attached Files`), backend:
1. Векторизует текущее сообщение (через embedding model)
2. Ищет top-K похожих chunks в vector store (Chroma/Qdrant)
3. Добавляет найденные chunks к системному промпту как context

### 5. Backend: function calling (если модель умеет)

Если модель поддерживает tool calling и пользователь включил tools:
1. Backend загружает список активных tools из БД
2. Добавляет их описание (JSON Schema) в запрос как `tools` массив
3. Отправляет в inference provider

### 6. Backend → Inference provider

```http
POST /v1/chat/completions HTTP/1.1
Host: llama-server:8081
Content-Type: application/json

{
  "model": "qwen3-coder-next",
  "messages": [
    {"role": "system", "content": "You are... [+RAG context]"},
    {"role": "user", "content": "Hello, what's the weather?"}
  ],
  "tools": [...],
  "stream": true
}
```

llama-server обрабатывает, возвращает SSE (Server-Sent Events) stream.

### 7. Backend: streaming response

Backend читает SSE chunks, пересылает их в WebSocket к frontend:
```
data: {"choices": [{"delta": {"content": "I don"}}]}
data: {"choices": [{"delta": {"content": "'t know"}}]}
...
```

Frontend инкрементально дорисовывает текст в UI.

### 8. Backend: tool calling execution (если модель запросила tool)

Если в stream пришёл `finish_reason: tool_calls`:
1. Backend парсит tool calls из ответа
2. Находит соответствующие Functions/Tools в БД
3. Выполняет их Python-код в sandbox
4. Возвращает результат обратно в inference провайдер как `role: tool` message
5. Получает финальный ответ модели с tool results

### 9. Backend: persistence

После завершения ответа:
- Пара `user message + assistant response` сохраняется в БД (`messages` table)
- Chat metadata обновляется (`updated_at`, `message_count`)
- Audit log пишется (если включён)

### 10. Frontend: UI update

Frontend получает событие "chat completed", сохраняет финальное сообщение, обновляет sidebar (chat history), ждёт следующего ввода.

## RAG engine

Open WebUI имеет **встроенный RAG-движок**, это одна из killer-features платформы.

### Document processing pipeline

```
Пользователь загружает документ (PDF / DOCX / MD / TXT / код)
    ↓
Extractor (PyPDF, python-docx, markdown parser, ...)
    ↓
Text splitting (chunks по ~500-1000 токенов с overlap)
    ↓
Embedding model (выбирается в настройках: sentence-transformers,
                  bge-m3, snowflake-arctic-embed, nomic-embed-text)
    ↓
Vector store (Chroma default, or Qdrant/Milvus/PgVector/LanceDB)
    ↓
Documents table в SQL (chunk_id, content, metadata, file_id)
```

### Query pipeline

Когда пользователь пишет вопрос:
1. Embedder векторизует вопрос
2. Vector search возвращает top-K (default K=5) похожих chunks
3. Chunks добавляются в system prompt как "Context:"
4. LLM получает вопрос + контекст, отвечает
5. Ответ может цитировать chunks (если модель хорошо следует инструкциям)

### Гибридный поиск (hybrid search)

Новая фича 2025-2026: **BM25 + embedding fusion**. BM25 (lexical search) находит chunks с точным совпадением слов, embedding находит semantic similarity. Результаты объединяются через reciprocal rank fusion (RRF). Это повышает recall для специфичной терминологии (названия файлов, технические термины, код).

### Reranking

Опционально -- после retrieve'а применяется cross-encoder reranker (типа `bge-reranker-v2-m3`), который переоценивает top-20 chunks и выбирает top-5 для контекста. Это даёт лучшее качество, но добавляет latency.

## Functions vs Pipelines vs Tools

Три похожих концепта расширения, но с разными use-cases.

### Functions (in-workspace Python)

**Что**: Python-функции, которые пишутся прямо в веб-UI (Tools workspace). Хранятся в БД как текст, выполняются в Python-субпроцессе backend'а при tool calling.

**Use-case**: простое tool calling для текущего пользователя или команды.

**Пример**:
```python
def get_current_weather(location: str) -> str:
    """Get the current weather for a location.

    :param location: City name
    """
    import requests
    resp = requests.get(f"https://api.weather.com/v1/{location}")
    return resp.json()["summary"]
```

Function автоматически экспонируется как tool при включении в настройках модели.

### Pipelines (separate OpenAI-compat proxy)

**Что**: отдельный **процесс-сервер** (не в backend Open WebUI), который представляется как OpenAI-compat API. Open WebUI отправляет запросы не напрямую в LLM, а в Pipelines-сервер, тот обрабатывает (с custom логикой) и дальше проксирует в реальный LLM.

**Use-case**:
- Enterprise integrations (корпоративные системы)
- Rate limiting
- Token-counting и quota management
- Langfuse observability
- Live translation
- Toxic content filtering
- Load balancing между несколькими моделями
- Caching

**Архитектура**:
```
Open WebUI → Pipelines server (:9099) → llama-server
                      ↑
                      │
                Custom Python
                logic here
```

Pipelines -- отдельный репозиторий [`open-webui/pipelines`](https://github.com/open-webui/pipelines). Плагины -- Python-модули с стандартным интерфейсом (`pipe` function, `inlet`/`outlet` hooks).

### Tools (подмножество Functions)

**Tools** -- это Functions, которые экспонируются как `tools` в OpenAI API запросах. Фактически Tools = Functions, но UI их показывает отдельно потому что не все Functions должны быть tool-callable. Некоторые Functions -- это Filters (обрабатывают запрос без вызова как tool).

## Authentication и RBAC

### Поддерживаемые auth-механизмы

| Механизм | Настройка |
|----------|-----------|
| **Local accounts** | Email + password, храним в БД (bcrypt) |
| **OAuth (OIDC)** | Google, Microsoft, Auth0, Keycloak, Ory Hydra |
| **LDAP** | Active Directory, OpenLDAP |
| **SAML 2.0** | Enterprise SSO |
| **Trusted headers** | Reverse proxy auth (e.g., nginx с auth_request) |
| **API keys** | Для программного доступа |

### RBAC

Роли:
- **Admin**: всё (управление users, моделями, Functions, системными настройками)
- **User**: обычный пользователь (чат, свои документы, свои Functions если разрешено)
- **Pending**: регистрация ожидает одобрения admin

**Groups**: пользователи объединяются в группы, группам привязываются:
- Разрешённые модели (модель X доступна только group "research")
- Document collections (документы команды видят только члены команды)
- Function access

**Quotas**: max messages per day, max tokens per request, max concurrent chats -- настраиваются на уровне user/group.

## Deployment-стратегии

### Single-instance (default)

Один Docker-контейнер с встроенным SQLite + Chroma. Подходит для:
- Self-hosted personal
- Small teams (до ~10 пользователей)
- Development

```bash
docker run -d -p 8080:8080 \
  -v open-webui:/app/backend/data \
  ghcr.io/open-webui/open-webui:main
```

### Multi-instance (scaled)

Несколько backend-контейнеров за load balancer'ом, с **PostgreSQL + Redis + Qdrant**:
- PostgreSQL хранит shared state
- Redis координирует WebSocket между инстансами
- Qdrant -- external vector store (быстрее и масштабируется лучше чем Chroma)
- Nginx / Traefik -- reverse proxy с sticky sessions

Подходит для:
- Enterprise deployments
- 100+ users
- High availability

## Связанные статьи

- [README.md](README.md) -- обзор профиля
- [introduction.md](introduction.md) -- история и философия
- [simple-use-cases.md](simple-use-cases.md) -- базовые сценарии
- [advanced-use-cases.md](advanced-use-cases.md) -- RAG, Functions, Pipelines
- [../lobe-chat/architecture.md](../lobe-chat/architecture.md) -- для сравнения с другой chat-платформой
- [../../inference/llama-cpp.md](../../inference/llama-cpp.md) -- backend, к которому подключается Open WebUI
