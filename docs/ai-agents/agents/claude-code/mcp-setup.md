# MCP: настройка и разработка серверов

Руководство по Model Context Protocol (MCP) в Claude Code: что это, как устанавливать готовые MCP-серверы, как разрабатывать свои, популярные серверы 2026 года.

MCP стал де-факто стандартом tool-integration для AI-агентов. К апрелю 2026 -- **97 миллионов установок** MCP-серверов в мире. Контекст в [news.md](news.md#q3-2025----mcp-экспоненциальный-рост).

## Что такое MCP

**Model Context Protocol (MCP)** -- открытый стандарт от Anthropic (2024) для интеграции AI-агентов с внешними инструментами и данными. Как USB для AI: один протокол, тысячи совместимых серверов.

Что MCP-сервер экспонирует агенту:
- **Tools** -- функции, которые агент может вызывать (GET github issues, INSERT row в postgres, web search)
- **Resources** -- данные, которые агент может читать (содержимое файла, API-ответ, snapshot БД)
- **Prompts** -- переиспользуемые prompt-шаблоны от сервера

Архитектура:

```
+----------------------+         MCP Protocol        +-----------------------+
|  Claude Code         |<----stdio / SSE / WS------->|  MCP Server           |
|  (client)            |                             |  (process)            |
+----------------------+                             +-----------------------+
         |                                                    |
         |                                                    |
         v                                                    v
     user chat                                        external system
                                                     (GitHub, Postgres, etc)
```

MCP decouples модель от конкретных integrations. Тот же `github-mcp-server` работает с Claude Code, Open WebUI, Ollama, Cursor -- без переписывания.

## Transport методы

MCP-серверы общаются с клиентом через один из трёх транспортов:

| Transport | Когда использовать | Плюсы | Минусы |
|-----------|--------------------|-------|--------|
| **stdio** (stdin/stdout) | Локальные серверы | Просто, безопасно (процесс запускает client) | Только local |
| **SSE** (HTTP streaming) | Remote или shared серверы | Работает через firewall (HTTP/HTTPS) | Медленнее чем stdio |
| **WebSocket** | Real-time bi-directional | Low-latency | Сложнее настройка, не все клиенты поддерживают |

Стандарт для начала -- **stdio**. Почти все community-серверы используют его.

## Установка MCP-серверов

### Метод 1: через `claude mcp add` (CLI helper)

Claude Code имеет встроенный helper:

```bash
# Установить готовый MCP-сервер
claude mcp add github \
  --transport stdio \
  --command "npx" \
  --args "-y" "@modelcontextprotocol/server-github" \
  --env "GITHUB_PERSONAL_ACCESS_TOKEN=ghp_..."

# Список установленных
claude mcp list

# Удалить
claude mcp remove github
```

Под капотом это редактирует `~/.claude/settings.json`.

### Метод 2: manual edit settings.json

Редактировать `~/.claude/settings.json` (глобально) или `<project>/.claude/settings.json` (проект):

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_..."
      }
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres",
               "postgresql://user:pass@localhost/mydb"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    }
  }
}
```

После правки -- перезапустить Claude Code.

### Метод 3: через plugins

Если MCP-сервер упакован в plugin:

```bash
claude plugin install @myorg/team-mcp-bundle
# устанавливает несколько MCP серверов + skills + hooks
```

## Популярные MCP-серверы 2026

### Разработка и DevOps

| Сервер | Tools | Кому полезно |
|--------|-------|--------------|
| **[@modelcontextprotocol/server-filesystem](https://github.com/modelcontextprotocol/servers)** | read/write локальные файлы (sandboxed path) | Safe file access с whitelisted директориями |
| **@modelcontextprotocol/server-github** | issues, PRs, files, commits, releases | Работа с GitHub из Claude Code |
| **@modelcontextprotocol/server-gitlab** | аналогично для GitLab | GitLab users |
| **@modelcontextprotocol/server-git** | git status, log, branches, diff | Глубокие git-операции |
| **@playwright/mcp** | browser automation | Web-scraping, E2E testing |
| **@modelcontextprotocol/server-sequential-thinking** | structured reasoning steps | Сложные multi-step задачи |

### Базы данных

| Сервер | Tools |
|--------|-------|
| **@modelcontextprotocol/server-postgres** | SELECT queries, schema inspection |
| **@modelcontextprotocol/server-sqlite** | SELECT/INSERT для SQLite файла |
| **@modelcontextprotocol/server-redis** | Redis GET/SET/LIST |
| **@benborla29/mcp-server-mysql** | MySQL queries |

### Observability & monitoring

| Сервер | Tools |
|--------|-------|
| **@modelcontextprotocol/server-sentry** | errors, issues, releases |
| **@grafana/mcp-server** | dashboards, alerts, datasources |
| **@datadog/mcp-server** | metrics, traces, logs |

### Communication

| Сервер | Tools |
|--------|-------|
| **@modelcontextprotocol/server-slack** | post message, read channels, users |
| **@discordjs/mcp-server** | post to Discord channels |
| **@telegram/mcp-bot-server** | Telegram bot API |

### Documentation / knowledge

| Сервер | Tools |
|--------|-------|
| **[@context7/mcp-server](https://context7.com)** | актуальная документация библиотек (альтернатива устаревшим training data) |
| **@modelcontextprotocol/server-memory** | long-term memory для сессий |
| **@notion/mcp-server** | Notion pages, databases |
| **@confluence/mcp-server** | Confluence spaces |

### Task management

| Сервер | Tools |
|--------|-------|
| **@linear/mcp-server** | issues, projects, cycles |
| **@atlassian/mcp-jira** | Jira issues, sprints |
| **@github/mcp-projects** | GitHub Projects v2 |

### Web search

| Сервер | Tools |
|--------|-------|
| **@perplexity/mcp-server** | perplexity_search, perplexity_ask |
| **@modelcontextprotocol/server-brave-search** | Brave Web Search API |
| **@tavily/mcp-server** | Tavily Search API |

### Cloud providers

| Сервер | Tools |
|--------|-------|
| **@aws/mcp-server** | EC2, S3, Lambda, IAM |
| **@google-cloud/mcp-server** | GCS, Compute Engine, BigQuery |
| **@azure/mcp-server** | Blob storage, Functions, Cosmos DB |

## Пример установки: Context7 + GitHub + Postgres

Типовой setup для разработчика:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_YOUR_TOKEN"
      }
    },
    "postgres-dev": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres",
               "postgresql://localhost/dev"]
    }
  }
}
```

После перезапуска Claude Code можно говорить:
- "Посмотри актуальную документацию React по hooks" → Context7 отдаёт свежие доки
- "Создай issue в myorg/repo о баге X" → GitHub MCP создаёт issue
- "Какие таблицы в dev БД и сколько строк?" → Postgres MCP выполняет query

## Разработка своего MCP-сервера

Когда готовых серверов не хватает -- можно написать свой. Два SDK:

### Python SDK

```bash
pip install mcp
```

Минимальный пример:

```python
# my_mcp_server.py
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

app = Server("my-company-tools")

@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="get_user_by_id",
            description="Получить информацию о пользователе из internal database по ID",
            inputSchema={
                "type": "object",
                "properties": {
                    "user_id": {"type": "integer"}
                },
                "required": ["user_id"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "get_user_by_id":
        user_id = arguments["user_id"]
        # ... логика работы с БД ...
        user = fetch_user(user_id)
        return [TextContent(type="text", text=str(user))]

if __name__ == "__main__":
    import asyncio
    asyncio.run(stdio_server(app))
```

Регистрация в `settings.json`:

```json
{
  "mcpServers": {
    "my-company": {
      "command": "python",
      "args": ["/path/to/my_mcp_server.py"]
    }
  }
}
```

### TypeScript SDK

```bash
npm install @modelcontextprotocol/sdk
```

```typescript
// my_mcp_server.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const server = new Server({
  name: "my-company-tools",
  version: "1.0.0",
}, {
  capabilities: { tools: {} }
});

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [{
    name: "get_user_by_id",
    description: "Получить пользователя по ID",
    inputSchema: {
      type: "object",
      properties: { user_id: { type: "integer" }},
      required: ["user_id"]
    }
  }]
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "get_user_by_id") {
    const userId = request.params.arguments.user_id;
    const user = await fetchUser(userId);
    return {
      content: [{ type: "text", text: JSON.stringify(user) }]
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

## Handlers: tools, resources, prompts

Три типа handler'ов в MCP:

### Tools (функции)

Уже показано выше. Модель **вызывает** tool с аргументами, получает результат.

### Resources (данные)

Сервер предоставляет read-only данные. Модель **читает** ресурс как context.

```python
@app.list_resources()
async def list_resources():
    return [
        Resource(
            uri="mycompany://config/latest",
            name="Latest company config",
            mimeType="application/json"
        )
    ]

@app.read_resource()
async def read_resource(uri: str):
    if uri == "mycompany://config/latest":
        config = get_latest_config()
        return str(config)
```

Модель может попросить: "покажи latest config" -- MCP вернёт содержимое.

### Prompts (шаблоны)

Сервер предоставляет готовые prompt templates с переменными:

```python
@app.list_prompts()
async def list_prompts():
    return [
        Prompt(
            name="onboard-new-engineer",
            description="Prompt для онбоардинга нового инженера",
            arguments=[
                PromptArgument(name="team", required=True),
                PromptArgument(name="role", required=True)
            ]
        )
    ]

@app.get_prompt()
async def get_prompt(name, arguments):
    if name == "onboard-new-engineer":
        return PromptMessage(
            role="system",
            content=f"Welcome to {arguments['team']} team as {arguments['role']}. "
                    f"First week tasks: ..."
        )
```

Prompts реже используются чем tools/resources, но полезны для standardized workflows.

## Troubleshooting

### "MCP server не запускается"

**Симптом**: Claude Code пишет "Failed to start MCP server 'X'".

**Диагностика**:
```bash
# Проверить что команда работает вручную
npx -y @modelcontextprotocol/server-github
# или
python /path/to/my_mcp_server.py
```

Если там ошибка -- это проблема сервера, не Claude Code.

**Частые причины**:
- Не установлены зависимости (`npm install` не выполнен)
- Неправильный path в `command:`
- Отсутствует ENV variable (GITHUB_TOKEN, etc)

### "Timeout issues"

**Симптом**: MCP call hangs, Claude Code eventually times out.

**Причины**:
- Сервер не отвечает на initialize request
- Deadlock в обработке tool call
- Сеть (для SSE/WebSocket transports)

**Решение**:
```json
{
  "mcpServers": {
    "slow-server": {
      "command": "...",
      "timeout": 30000  // 30 секунд вместо default
    }
  }
}
```

### Debugging через MCP Inspector

Официальный tool для отладки:

```bash
npm install -g @modelcontextprotocol/inspector

# Запустить inspector для конкретного сервера
mcp-inspector \
  --command "npx" \
  --args "-y" "@modelcontextprotocol/server-github" \
  --env "GITHUB_TOKEN=ghp_..."
```

Inspector показывает:
- Список tools/resources/prompts сервера
- Ручной вызов с произвольными args
- Логи всех JSON-RPC messages
- Ошибки и timing

### "Permission denied" при запуске сервера

Для stdio transports -- Claude Code запускает процесс от имени пользователя. Убедиться что:
- Исполняемый файл имеет права `+x`
- Python/node версии совпадают (используй absolute path к interpreter)
- Working directory корректный (через `cwd:` в settings)

## Security

MCP-серверы получают определённый trust. Правила безопасности:

### 1. Audit перед установкой

Не устанавливать MCP-сервер из неизвестного источника без проверки. Community-серверы с большим числом installs и активным репо обычно безопасны; случайные -- под вопросом.

### 2. Whitelisting путей

Для filesystem server -- всегда указывать **allowed paths**:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem",
               "/Users/me/projects", "/Users/me/Documents"]
    }
  }
}
```

Без явных paths -- сервер может читать весь home directory.

### 3. Read-only режимы

Для БД-серверов -- использовать read-only connections:

```json
{
  "mcpServers": {
    "postgres-readonly": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres",
               "postgresql://readonly_user:pass@db/prod?sslmode=require"]
    }
  }
}
```

### 4. Sensitive ENV variables

Не хранить secrets в `settings.json` (может попасть в git). Использовать ENV variables или keychain:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

ENV variable `GITHUB_TOKEN` должен быть задан в shell, не в `settings.json`.

### 5. Hooks для MCP-ограничений

Блокировать destructive MCP-операции через [hooks](hooks-guide.md):

```bash
#!/bin/bash
# Block MCP tools с опасными паттернами
TOOL_NAME=$CLAUDE_TOOL_NAME
TOOL_ARGS=$(cat)

# Блокировать DROP/TRUNCATE в postgres MCP
if [[ "$TOOL_NAME" == "mcp__postgres__query" ]]; then
  SQL=$(echo "$TOOL_ARGS" | jq -r '.query')
  if echo "$SQL" | grep -iqE "DROP|TRUNCATE|DELETE FROM"; then
    echo "BLOCKED: destructive SQL через MCP -- запрет" >&2
    exit 1
  fi
fi

exit 0
```

## MCP vs Skills vs Hooks: когда что

| Критерий | MCP | Skills | Hooks |
|----------|-----|--------|-------|
| **Типичный use case** | Интеграция с внешним сервисом (GitHub, DB, API) | Переиспользуемая задача с prompt+tools | Safety guardrails, auto-format |
| **Написан на** | Python/TypeScript | Markdown + frontmatter | Shell/Python |
| **Сложность разработки** | Средняя (нужен SDK) | Низкая (просто markdown) | Низкая (shell-скрипт) |
| **Требует перезапуска** | Да (перезапуск MCP server) | Да (reload skills) | Нет (exec-time) |
| **Распространение** | PyPI, npm, plugins | Plugins, git | Skills installers |
| **Изолированность** | Отдельный процесс | Markdown-файл в session | Shell-скрипт |
| **Производительность** | Network/IPC overhead | Загружается в prompt | Sync block (быстрый) |
| **Ресурсы** | Tools, resources, prompts | Prompts + tool choice | Только shell execution |

**Правило выбора**:
- Нужно **соединиться** с внешней системой -- MCP
- Нужно **зафиксировать паттерн** (задачу + инструкции) -- Skill
- Нужно **гарантированно** что-то выполнить на event -- Hook

Часто используются **вместе**: например `git-guardrails-claude-code` это **skill**, который устанавливает **hooks**. И там может быть **MCP** для GitHub интеграции.

## Enterprise MCP

Для команды -- можно поднять **shared internal MCP-серверы**:

```
+--------------------+         HTTP/SSE         +------------------------+
|  Developer Machine |<------------------------>|  Internal MCP servers  |
|  (Claude Code)     |                          |  - company-db          |
+--------------------+                          |  - company-linear      |
                                                |  - company-vault       |
                                                +------------------------+
```

Enterprise-паттерны:
- **Auth through SSO** (Okta, Auth0) на MCP-уровне
- **RBAC** -- user видит только разрешённые tools
- **Audit log** всех MCP calls
- **Rate limiting** на per-user basis
- **Deployment** через Kubernetes (MCP server as microservice)

SDK для этого: `@modelcontextprotocol/sdk-enterprise` (коммерческая версия), или писать свой auth layer поверх HTTP SSE transport.

## Связанные статьи

- [README.md](README.md) -- профиль Claude Code
- [news.md](news.md) -- MCP в контексте экосистемы (97M установок)
- [skills-guide.md](skills-guide.md) -- Skills (альтернативный способ расширения)
- [hooks-guide.md](hooks-guide.md) -- Hooks (для MCP-safety)
- [agent-teams.md](agent-teams.md) -- Teams могут делить общие MCP-серверы
- [Официальная документация MCP](https://modelcontextprotocol.io/)
- [MCP servers catalog](https://github.com/modelcontextprotocol/servers)
- [Context7](https://context7.com) -- уже используется в проекте ai-plant
