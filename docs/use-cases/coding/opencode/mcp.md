# MCP-серверы для OpenCode

Model Context Protocol (MCP) -- открытый протокол от Anthropic для расширения возможностей AI-агентов через внешние серверы. MCP-сервер предоставляет агенту дополнительные инструменты (tools), ресурсы (resources) и промпты (prompts), которых нет в базовом наборе.

## Архитектура

```
OpenCode (клиент)
    |
    +-- встроенные tools (bash, read, write, edit)
    |
    +-- MCP Protocol (JSON-RPC через stdio/HTTP)
         |
         +-- MCP Server: filesystem
         +-- MCP Server: github
         +-- MCP Server: postgres
         +-- MCP Server: ...
```

MCP-сервер -- отдельный процесс. OpenCode запускает его как дочерний (через `command`) или подключается к удалённому (через URL). Сервер объявляет свои tools, и агент может их вызывать как встроенные.

## Зачем нужен MCP

Встроенные инструменты OpenCode ограничены: bash, read, write, edit. Через MCP можно добавить:

| Возможность | Без MCP | С MCP |
|-------------|---------|-------|
| Работа с GitHub | `bash(gh pr list)` | прямой API: создание PR, чтение issues |
| Работа с БД | `bash(psql -c ...)` | SQL-запросы как tool calls |
| Поиск в интернете | невозможно | web search tool |
| Работа с Docker | `bash(docker ...)` | управление контейнерами |
| Файловая система | только read/write | расширенный доступ, поиск, метаданные |

MCP превращает OpenCode из "агента с bash" в "агента с экосистемой инструментов".

## Подключение к OpenCode

### Локальный сервер (command)

OpenCode запускает сервер как дочерний процесс и общается через stdin/stdout.

```json
{
  "mcp": {
    "server-name": {
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "/path/to/dir"],
      "env": {}
    }
  }
}
```

### Удалённый сервер (URL)

Подключение к уже запущенному серверу по HTTP.

```json
{
  "mcp": {
    "remote-server": {
      "url": "http://localhost:3100/mcp"
    }
  }
}
```

### Глобальная конфигурация

Серверы, нужные во всех проектах -- в глобальном конфиге:

```
~/.config/opencode/opencode.json
```

Проектные серверы -- в `opencode.json` в корне проекта. Конфиги мержатся.

## Каталог полезных серверов

### Файловая система

Расширенный доступ к файлам: поиск, метаданные, glob-паттерны.

```json
{
  "mcp": {
    "filesystem": {
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "~/projects"]
    }
  }
}
```

Предоставляет: `read_file`, `write_file`, `list_directory`, `search_files`, `get_file_info`.

Пакет: `@modelcontextprotocol/server-filesystem`

### GitHub

Работа с GitHub API: issues, PR, reviews, файлы репозитория.

```json
{
  "mcp": {
    "github": {
      "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "{env:GITHUB_TOKEN}"
      }
    }
  }
}
```

Предоставляет: `create_issue`, `list_issues`, `create_pull_request`, `get_file_contents`, `search_repositories`, `create_review`.

Пакет: `@modelcontextprotocol/server-github`

Требует: `GITHUB_TOKEN` (Personal Access Token с правами на репозитории).

### Git

Работа с локальным git-репозиторием: история, diff, blame, branches.

```json
{
  "mcp": {
    "git": {
      "command": ["uvx", "mcp-server-git"]
    }
  }
}
```

Предоставляет: `git_log`, `git_diff`, `git_blame`, `git_branch_list`, `git_status`.

Пакет: `mcp-server-git` (Python, через uvx)

### PostgreSQL

SQL-запросы к PostgreSQL.

```json
{
  "mcp": {
    "postgres": {
      "command": ["npx", "-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_CONNECTION_STRING": "postgresql://user:pass@localhost:5432/dbname"
      }
    }
  }
}
```

Предоставляет: `query` (SELECT), `execute` (INSERT/UPDATE/DELETE), `list_tables`, `describe_table`.

Пакет: `@modelcontextprotocol/server-postgres`

### Docker

Управление Docker-контейнерами.

```json
{
  "mcp": {
    "docker": {
      "command": ["npx", "-y", "@modelcontextprotocol/server-docker"]
    }
  }
}
```

Предоставляет: `list_containers`, `start_container`, `stop_container`, `container_logs`, `list_images`.

### Web Search (Brave)

Поиск в интернете через Brave Search API.

```json
{
  "mcp": {
    "brave-search": {
      "command": ["npx", "-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "{env:BRAVE_API_KEY}"
      }
    }
  }
}
```

Предоставляет: `brave_web_search`, `brave_local_search`.

Требует: API-ключ Brave Search (бесплатный тариф: 2000 запросов/мес).

### Fetch (HTTP)

Загрузка веб-страниц и API-ответов.

```json
{
  "mcp": {
    "fetch": {
      "command": ["uvx", "mcp-server-fetch"]
    }
  }
}
```

Предоставляет: `fetch` (GET/POST/PUT/DELETE с заголовками и телом).

Пакет: `mcp-server-fetch` (Python)

### Memory (файловая память)

Персистентная память для агента между сессиями.

```json
{
  "mcp": {
    "memory": {
      "command": ["npx", "-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

Предоставляет: `create_memory`, `search_memories`, `delete_memory`.

Аналог `.claude/memory/` в Claude Code, но через MCP.

## Рекомендуемая конфигурация

Для разработки на нашей платформе:

```json
{
  "mcp": {
    "github": {
      "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "{env:GITHUB_TOKEN}" }
    },
    "git": {
      "command": ["uvx", "mcp-server-git"]
    },
    "fetch": {
      "command": ["uvx", "mcp-server-fetch"]
    }
  }
}
```

Минимальный набор: GitHub (PR, issues) + git (история, diff) + fetch (документация, API).

## Примеры использования

### Создание PR через MCP

Без MCP:
```
Выполни: gh pr create --title "fix: auth bug" --body "..."
```

С MCP (GitHub server):
```
Создай pull request с описанием исправления бага авторизации
```

Агент вызовет `create_pull_request` tool напрямую, без bash.

### Анализ базы данных

```
Покажи структуру таблицы users и последние 10 записей с ошибками авторизации
```

Агент вызовет `describe_table("users")` и `query("SELECT * FROM auth_log WHERE status='error' ORDER BY created_at DESC LIMIT 10")`.

### Поиск документации

```
Найди в интернете документацию по FastAPI middleware и покажи примеры
```

Агент вызовет `brave_web_search("FastAPI middleware documentation examples")` и `fetch` для загрузки страницы.

## Создание собственного MCP-сервера

MCP-сервер можно написать на любом языке. Минимальный пример на Python:

```python
# my_server.py
from mcp.server import Server
from mcp.types import Tool, TextContent

app = Server("my-tools")

@app.list_tools()
async def list_tools():
    return [
        Tool(
            name="check_service",
            description="Проверить статус сервиса",
            inputSchema={
                "type": "object",
                "properties": {
                    "service": {"type": "string", "description": "Имя сервиса"}
                },
                "required": ["service"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name, arguments):
    if name == "check_service":
        # ... логика проверки ...
        return [TextContent(type="text", text=f"Сервис {arguments['service']}: OK")]

if __name__ == "__main__":
    import asyncio
    from mcp.server.stdio import stdio_server
    asyncio.run(stdio_server(app))
```

Подключение:
```json
{
  "mcp": {
    "my-tools": {
      "command": ["python", "/path/to/my_server.py"]
    }
  }
}
```

Библиотеки для реализации:
- Python: `pip install mcp` (официальный SDK)
- TypeScript: `npm install @modelcontextprotocol/sdk`
- Go, Rust, Java -- community-реализации

## MCP в Claude Code vs OpenCode

| Аспект | Claude Code | OpenCode |
|--------|-------------|----------|
| Конфигурация | `settings.json` -> `mcpServers` | `opencode.json` -> `mcp` |
| Формат command | `{"command": "npx", "args": [...]}` | `{"command": ["npx", ...]}` |
| Удалённые серверы | нет (только локальные) | да (через `url`) |
| Автообнаружение | нет | нет |
| Перезагрузка | перезапуск Claude Code | перезапуск OpenCode |

Серверы совместимы -- один и тот же MCP-сервер работает и с Claude Code, и с OpenCode. Различается только формат конфигурации.

## Ресурсы

- Спецификация: https://spec.modelcontextprotocol.io/
- Каталог серверов: https://github.com/modelcontextprotocol/servers
- SDK (Python): https://github.com/modelcontextprotocol/python-sdk
- SDK (TypeScript): https://github.com/modelcontextprotocol/typescript-sdk

## Связанные статьи

- [Кастомизация OpenCode](customization.md) -- правила, permissions, агенты
- [Конфигурация](configuration.md) -- провайдеры, модели
- [Сравнение с Claude Code](comparison.md) -- MCP и другие механизмы
