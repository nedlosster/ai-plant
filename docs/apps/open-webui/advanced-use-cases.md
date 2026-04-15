# Open WebUI: сложные сценарии

Продвинутые use-cases: RAG pipelines, Functions для tool calling, Pipelines как middleware, multi-user с RBAC, MCP servers, кастомные модели.

## 1. Продвинутый RAG: несколько коллекций документов

**Задача**: организовать документы по темам (коллекции), чтобы при запросе искалось только в релевантной коллекции.

### Создание коллекций

1. Admin Panel → Documents → "+ New Collection"
2. Name: "HR policies"
3. Description: "Корпоративные политики и регламенты"
4. Выбрать embedding model (по умолчанию `all-MiniLM-L6-v2`, но для production лучше `bge-m3` или `snowflake-arctic-embed-l`)
5. Upload документов в коллекцию (PDF, DOCX, MD, TXT)
6. Повторить для других коллекций: "Engineering docs", "Product specs", "Customer feedback"

### Использование

В чате через команду `#`:
- `#hr_policies Can you summarize vacation rules?` -- поиск только в HR коллекции
- `#engineering_docs #product_specs How does feature X interact with Y?` -- поиск в двух коллекциях одновременно

### Типы документов и chunking

Для разных типов документов нужны разные стратегии chunk'инга:

| Тип | Chunk size | Overlap | Splitter |
|-----|-----------|---------|----------|
| **Markdown** | 512 | 50 | Markdown-aware (по заголовкам) |
| **Code** | 1024 | 100 | Language-aware (AST splitter) |
| **PDF tech-docs** | 800 | 100 | Sentence-aware |
| **Conversational** | 256 | 32 | Sentence-aware |

Настраивается в Admin Panel → Settings → Documents → Chunking.

### Embedding model выбор

Качество RAG сильно зависит от embedding модели:

| Модель | Размер | Качество | Скорость | Use-case |
|--------|--------|----------|----------|----------|
| `sentence-transformers/all-MiniLM-L6-v2` | 22M | базовый | очень быстро | default, лёгкие задачи |
| `BAAI/bge-m3` | 568M | очень хорошо | умеренно | многоязычный RAG |
| `nomic-embed-text` | 137M | хорошо | быстро | англ. general RAG |
| `snowflake-arctic-embed-l` | 335M | отлично | умеренно | long-context documents |
| `Snowflake/arctic-embed-m` | 109M | хорошо | быстро | баланс |

Для русскоязычных документов -- рекомендуется `bge-m3` (отличная multilingual поддержка).

### Reranking для повышения качества

1. Admin Panel → Settings → Documents → Reranking Model: выбрать `BAAI/bge-reranker-v2-m3`
2. Top-K retrieval: увеличить до 20 (больше candidates)
3. Top-K rerank: 5 (финальные документы для контекста)

Процесс:
1. Vector search находит top-20 chunks по similarity
2. Cross-encoder reranker переоценивает эти 20 → top-5
3. Top-5 идут в контекст

Это медленнее (добавляет ~1-2 сек latency) но даёт заметно лучше recall, особенно на сложных вопросах.

## 2. Functions для tool calling

**Задача**: позволить LLM вызывать Python-функции для реальных действий (поиск в базе, API-calls, вычисления).

### Создание Function

1. Workspace → Tools → "+ Create new tool"
2. Name: `database_query`
3. Description: "Query the internal customer database"
4. Code:

```python
"""
title: Database Query
author: admin
version: 0.1.0
"""

from pydantic import BaseModel, Field
import sqlite3


class Tools:
    def __init__(self):
        pass

    def query_customer(self, customer_id: int) -> str:
        """
        Query customer information from the internal database.

        :param customer_id: ID of the customer to lookup
        :return: Customer information as JSON string
        """
        conn = sqlite3.connect('/data/customers.db')
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, name, email, status FROM customers WHERE id = ?",
            (customer_id,)
        )
        row = cursor.fetchone()
        conn.close()

        if row:
            return f'{{"id": {row[0]}, "name": "{row[1]}", "email": "{row[2]}", "status": "{row[3]}"}}'
        return '{"error": "not found"}'

    def list_recent_orders(self, days: int = 7) -> str:
        """
        List recent orders from the last N days.

        :param days: Number of days to look back (default 7)
        :return: List of orders as JSON
        """
        conn = sqlite3.connect('/data/customers.db')
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, customer_id, amount, created_at FROM orders "
            "WHERE created_at >= date('now', ?) ORDER BY created_at DESC",
            (f'-{days} days',)
        )
        rows = cursor.fetchall()
        conn.close()

        return str([dict(zip(['id', 'customer_id', 'amount', 'created_at'], r)) for r in rows])
```

5. Save

### Активация

В чате:
1. Settings (иконка шестерёнки в поле ввода) → Tools → активировать `database_query`
2. Промпт: "Какие были заказы за последнюю неделю?"
3. Модель (которая поддерживает tool calling -- Qwen3, Llama 3.2, Mistral Nemo) увидит описание tool, вызовет `list_recent_orders(days=7)`, получит результат, оформит финальный ответ

### Ограничения

- **Sandbox**: Functions выполняются в backend-процессе Open WebUI, имеют доступ к файловой системе контейнера. Это **не sandbox**, поэтому не давать untrusted users writable доступ к Functions
- **Dependencies**: можно `import`-ить только то что установлено в backend-контейнере. Для внешних зависимостей -- установить через custom Dockerfile или использовать Pipelines
- **Model support**: модели без native tool calling (старые Llama 2, GPT-3.5) не умеют. На Strix Halo Qwen3-Coder Next и Gemma 4 отлично поддерживают

## 3. Pipelines: proxy middleware с custom логикой

**Задача**: перехватить все запросы к LLM и добавить общую логику -- логирование в Langfuse, rate limiting, content filtering.

### Архитектура Pipelines

Pipelines -- **отдельный сервер** на Python, который представляется как OpenAI-compat API:

```
Open WebUI ----POST /v1/chat/completions----> Pipelines :9099
                                                   |
                                                   | (custom Python)
                                                   |
                                                   v
                                              llama-server :8081
```

Pipelines-сервер запускается отдельно от Open WebUI.

### Установка

```bash
# Отдельный контейнер для Pipelines
docker run -d \
  -p 9099:9099 \
  -v pipelines-data:/app/pipelines \
  ghcr.io/open-webui/pipelines:main
```

### Создание pipeline

Pipeline -- это Python-модуль в `/app/pipelines/`. Минимальный пример (`langfuse_filter.py`):

```python
"""
title: Langfuse Logger
author: admin
description: Logs all chat messages to Langfuse for observability
"""

from typing import List, Union, Generator, Iterator
from langfuse import Langfuse


class Pipeline:
    def __init__(self):
        self.langfuse = Langfuse(
            public_key="pk_...",
            secret_key="sk_...",
            host="http://langfuse:3000"
        )

    async def inlet(self, body: dict, user: dict) -> dict:
        """Called BEFORE message is sent to LLM. Can modify the request."""
        trace = self.langfuse.trace(
            name="chat",
            user_id=user.get("id"),
            input=body.get("messages")
        )
        body["__trace_id__"] = trace.id
        return body

    async def outlet(self, body: dict, user: dict) -> dict:
        """Called AFTER LLM response. Can modify the response."""
        trace_id = body.pop("__trace_id__", None)
        if trace_id:
            self.langfuse.trace(id=trace_id).update(
                output=body.get("choices", [])
            )
        return body
```

### Подключение в Open WebUI

1. Admin Panel → Settings → Connections → Add Connection
2. Base URL: `http://pipelines:9099`
3. API Key: `0p3n-w3bu!` (default)
4. Теперь модели из Pipelines доступны в UI

### Популярные готовые Pipelines

В репозитории [`open-webui/pipelines/examples`](https://github.com/open-webui/pipelines/tree/main/examples):

| Pipeline | Что делает |
|----------|------------|
| `rate_limit` | Ограничивает частоту запросов per-user |
| `langfuse_filter` | Observability в Langfuse |
| `toxic_message_filter` | Фильтр токсичного контента через Detoxify |
| `function_calling_filter` | Custom tool calling routing |
| `openai_compatible` | Proxy к любому OpenAI-compat endpoint с авторизацией |
| `anthropic_compatible` | Proxy к Anthropic с конверсией формата |

## 4. Multi-user deployment с RBAC и SSO

**Задача**: развернуть Open WebUI для команды из 50 человек с SSO через Keycloak и quotas.

### OIDC/OAuth настройка (Keycloak)

В `.env` файле Open WebUI:

```bash
ENABLE_OAUTH_SIGNUP=true
OAUTH_PROVIDER_NAME="Keycloak"
OAUTH_CLIENT_ID=open-webui
OAUTH_CLIENT_SECRET=...
OPENID_PROVIDER_URL=https://keycloak.company.com/realms/main/.well-known/openid-configuration
OAUTH_SCOPES=openid email profile
```

После рестарта на login-странице появляется кнопка "Sign in with Keycloak".

### RBAC настройка

Admin Panel → Users → Groups:

1. Создать группы:
   - `engineering` -- доступ к coding моделям (Qwen3-Coder Next, Devstral)
   - `marketing` -- доступ только к chat-моделям (Qwen3.5-27B)
   - `research` -- доступ ко всему + upload документов

2. Для каждой группы:
   - Permissions: Models → select allowed models
   - Permissions: Documents → can upload / read only
   - Permissions: Functions → can use / can create / none
   - Quota: max 1000 messages/day, max 10k tokens per message

3. Users при регистрации попадают в `Pending` → admin одобряет и назначает в группу

### LDAP (Active Directory)

```bash
ENABLE_LDAP=true
LDAP_SERVER_LABEL="Corporate AD"
LDAP_SERVER_HOST=ad.company.com
LDAP_SERVER_PORT=389
LDAP_APP_DN=cn=openwebui,ou=serviceaccounts,dc=company,dc=com
LDAP_APP_PASSWORD=...
LDAP_SEARCH_BASE=ou=users,dc=company,dc=com
LDAP_SEARCH_FILTER="(&(objectClass=user)(mail={{username}}))"
```

### Audit logging

Admin Panel → Settings → Audit:
- Enable audit log
- Log level: `basic` (messages) / `full` (messages + content)
- Retention: 90 days
- Export: on demand as CSV

Audit log пишет: user_id, timestamp, action (login, chat, upload), model, prompt snippet, tokens used.

## 5. MCP Server integration

**Задача**: подключить MCP-сервер (Model Context Protocol от Anthropic) к Open WebUI, чтобы модель могла вызывать инструменты через стандартный протокол.

### Что такое MCP

MCP -- протокол для tool calling, разработанный Anthropic в 2024 году. Идея: стандартизовать как AI-агенты взаимодействуют с инструментами, чтобы один и тот же "MCP server" работал с Claude, GPT, Open WebUI, Ollama и т.д.

MCP-серверы -- отдельные процессы, которые экспонируют набор tools. Клиент (Open WebUI) подключается через stdio/SSE/WebSocket, получает список tools, передаёт их LLM как OpenAI tool definitions.

### Настройка в Open WebUI

Admin Panel → Settings → MCP Servers:

```yaml
servers:
  - name: filesystem
    command: npx
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/allowed/path"]

  - name: github
    command: npx
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: ghp_...

  - name: postgres
    command: npx
    args: ["-y", "@modelcontextprotocol/server-postgres", "postgresql://user:pass@db/dbname"]
```

После рестарта Open WebUI подключается к каждому MCP-серверу, получает список tools, регистрирует их как Functions. Пользователь может включить их в настройках чата.

### Пример использования

Подключены MCP-серверы `filesystem` и `github`. Промпт:

```
Проверь файл /allowed/path/README.md и создай issue на github myorg/myrepo если в нём есть TODO
```

LLM (например Qwen3-Coder Next или Claude через API):
1. Вызывает `filesystem.read_file` с путём к README.md внутри разрешённой директории
2. Парсит текст, находит TODO
3. Вызывает `github.create_issue(repo="myorg/myrepo", title="Implement TODO in README", body="Line 42: TODO: add installation section")`
4. Отвечает пользователю с summary

## 6. Custom model с system prompt и params

**Задача**: создать "модель" `code-reviewer` которая **фактически** использует Qwen3-Coder Next, но с фиксированным system prompt и параметрами.

### Шаги

1. Admin Panel → Models → "+ New Model"
2. Name: `code-reviewer`
3. Display name: "Code Reviewer"
4. Base model: `qwen3-coder-next:latest`
5. System prompt:
   ```
   You are a senior code reviewer. For every code submission:

   1. Check for correctness issues
   2. Look for security vulnerabilities (OWASP top 10)
   3. Suggest performance improvements
   4. Verify style/readability

   Always respond in this format:
   ## Correctness
   ...
   ## Security
   ...
   ## Performance
   ...
   ## Style
   ...
   ```
6. Parameters:
   - Temperature: 0.3 (деterministic для review)
   - Top-p: 0.9
   - Context length: 32768
7. Tools: активировать нужные
8. Save

Теперь `code-reviewer` появляется в dropdown моделей. Выглядит как отдельная модель, но это тот же backend с пред-настроенным system prompt. Это удобно для:
- Переиспользования конфигураций
- Изоляции стилей общения (один и тот же Qwen, но один "помощник", другой "ревьюер")
- RBAC -- разным группам дать доступ к разным "моделям"

## 7. Production deployment на Strix Halo

**Задача**: развернуть Open WebUI как production-сервис с мониторингом и backup'ами.

### Docker Compose стек

```yaml
version: '3.8'

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    ports:
      - "3210:8080"
    environment:
      - OPENAI_API_BASE_URL=http://host.docker.internal:8081/v1
      - OPENAI_API_KEY=dummy
      - DATABASE_URL=postgresql://openwebui:pass@postgres/openwebui
      - REDIS_URL=redis://redis:6379
      - ENABLE_OAUTH_SIGNUP=true
      - OAUTH_CLIENT_ID=open-webui
      # ...
    depends_on:
      - postgres
      - redis
    volumes:
      - openwebui-data:/app/backend/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:16
    environment:
      - POSTGRES_DB=openwebui
      - POSTGRES_USER=openwebui
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    restart: unless-stopped

  pipelines:
    image: ghcr.io/open-webui/pipelines:main
    ports:
      - "9099:9099"
    volumes:
      - pipelines-data:/app/pipelines
    restart: unless-stopped

volumes:
  openwebui-data:
  postgres-data:
  pipelines-data:
```

### Backup стратегия

1. PostgreSQL: `pg_dump openwebui > backup.sql` nightly в cron
2. Uploaded documents: `rsync -av /path/to/openwebui-data/uploads /backup/`
3. Vector store: обычно регенерируется из документов, но если инкрементальный -- бэкапить Chroma/Qdrant tables
4. Environment: `.env` файл с секретами

### Monitoring

- Healthcheck endpoint: `GET /health` возвращает 200 если backend жив
- Metrics: Pipeline `rate_limit` даёт per-user counters, экспортируется в Prometheus через middleware
- Logs: Docker logs + Fluentd/Loki для агрегации

## Связанные статьи

- [README.md](README.md) -- обзор профиля
- [architecture.md](architecture.md) -- чтобы понимать где и как происходят эти сценарии
- [simple-use-cases.md](simple-use-cases.md) -- базовые паттерны
- [../lobe-chat/advanced-use-cases.md](../lobe-chat/advanced-use-cases.md) -- сравнение с другой chat-платформой
- [../../inference/llama-cpp.md](../../inference/llama-cpp.md) -- backend для Open WebUI
- [../../inference/ollama.md](../../inference/ollama.md) -- другой backend
