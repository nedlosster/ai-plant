# opencode MCP setup

opencode реализует [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) -- открытый стандарт от Anthropic (ноябрь 2024) для расширения агентов через внешние серверы. Использует тот же протокол что Claude Code, поэтому вся MCP-экосистема (97 миллионов установок на март 2026) работает в opencode без переделки.

База о MCP -- в [claude-code/mcp-setup.md](../claude-code/mcp-setup.md). Здесь -- opencode-специфика: конфигурация, готовые серверы, написание собственного, debug, performance.

## Конфигурация в opencode.json

MCP-серверы регистрируются в секции `mcp_servers`:

```json
{
  "mcp_servers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "github": {
      "command": "uvx",
      "args": ["mcp-server-github"],
      "env": { "GITHUB_TOKEN": "{env:GITHUB_TOKEN}" }
    },
    "postgres": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-postgres"],
      "env": { "POSTGRES_URL": "{env:DATABASE_URL}" }
    }
  }
}
```

Поля:

| Поле | Назначение |
|------|-----------|
| `command` | Бинарь для запуска (npx / uvx / python / node / абсолютный путь) |
| `args` | Аргументы CLI |
| `env` | Переменные окружения для процесса (поддерживает `{env:VAR}` template) |
| `cwd` | Рабочая директория (опционально) |

opencode запускает MCP-сервер как subprocess при старте сессии и общается с ним через stdio (stdin/stdout JSON-RPC).

## Готовые MCP-серверы (проверенные)

### filesystem -- safe file operations

```json
"filesystem": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/project"]
}
```

Что даёт:
- `read_file(path)` -- безопасное чтение
- `write_file(path, content)` -- запись с rate-limit
- `list_directory(path)` -- ls с фильтрами
- `move_file(source, dest)` -- атомарный move
- `search_files(query, path)` -- grep с context lines

**Когда полезно**: ограничение filesystem операций scope'ом проекта (sandbox vs default opencode bash). Особенно для reviewer-агентов с denied bash.

### github -- gh CLI integration

```json
"github": {
  "command": "uvx",
  "args": ["mcp-server-github"],
  "env": { "GITHUB_TOKEN": "{env:GITHUB_TOKEN}" }
}
```

Что даёт:
- `create_issue(repo, title, body)` -- создание issues
- `list_pull_requests(repo, state)` -- список PR с фильтрами
- `get_pull_request(repo, number)` -- детали PR (description, files, comments)
- `add_comment(repo, issue, body)` -- комментарии
- `merge_pull_request(repo, number)` -- merge с разными strategies

**Когда полезно**: PR review агенты, automated triage, codereview workflows.

### postgres -- DB queries

```json
"postgres": {
  "command": "npx",
  "args": ["@modelcontextprotocol/server-postgres"],
  "env": { "POSTGRES_URL": "{env:DATABASE_URL}" }
}
```

Что даёт:
- `query(sql)` -- SELECT queries (read-only по умолчанию)
- `list_schemas()` -- список схем
- `describe_table(schema, table)` -- structure with column types
- `explain(sql)` -- query plan

**Когда полезно**: дебаггинг прода ("найди медленные queries"), schema migration анализ, data exploration.

**Внимание**: дефолт read-only -- mutations требуют explicit разрешения через config server'а. Никогда не подключать с правами на write к production без двойной защиты.

### context7 -- up-to-date library docs

```json
"context7": {
  "command": "npx",
  "args": ["-y", "@upstash/context7-mcp@latest"]
}
```

Что даёт:
- `resolve_library_id(query)` -- "react@18" → официальный repo ID
- `get_library_docs(library_id, topic)` -- свежая документация (не из training data)

**Когда полезно**: работа с библиотеками после knowledge cutoff модели. Например, Qwen3-Coder Next training cutoff 2025-Q3, для актуальной документации по React 19/20 use Context7.

**Пример**:

```bash
opencode "implement form with React 20 useActionState hook"
# Агент сам вызовет context7.get_library_docs("react", "useActionState")
# и получит актуальный API
```

### playwright -- browser automation

```json
"playwright": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-playwright"]
}
```

Что даёт:
- `browser.navigate(url)` -- открыть страницу
- `browser.click(selector)` -- клик по элементу
- `browser.fill(selector, value)` -- ввод
- `browser.screenshot()` -- скриншот текущей страницы (с base64 для multimodal моделей)

**Когда полезно**: e2e testing automation, web scraping для исследований, UI debugging.

**Внимание**: opencode сейчас не имеет vision (text-only с Qwen3-Coder Next). Для screenshot-задач лучше связка с multimodal моделью через [openclaw](../openclaw/README.md) или [Cline](../cline.md).

## Написание собственного MCP-сервера

Если готовых нет, можно написать свой. Минимальный пример на Node.js:

```javascript
// my-mcp-server/index.js
const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');

const server = new Server(
  { name: 'my-mcp', version: '1.0.0' },
  { capabilities: { tools: {} } }
);

server.setRequestHandler('tools/list', async () => ({
  tools: [{
    name: 'fetch_jira_ticket',
    description: 'Get Jira ticket details by ID',
    inputSchema: {
      type: 'object',
      properties: { ticket_id: { type: 'string' } },
      required: ['ticket_id']
    }
  }]
}));

server.setRequestHandler('tools/call', async (request) => {
  if (request.params.name === 'fetch_jira_ticket') {
    const { ticket_id } = request.params.arguments;
    const response = await fetch(`https://jira/rest/api/2/issue/${ticket_id}`, {
      headers: { Authorization: `Bearer ${process.env.JIRA_TOKEN}` }
    });
    const data = await response.json();
    return {
      content: [{ type: 'text', text: JSON.stringify(data, null, 2) }]
    };
  }
  throw new Error(`Unknown tool: ${request.params.name}`);
});

const transport = new StdioServerTransport();
server.connect(transport);
```

Регистрация в `opencode.json`:

```json
"mcp_servers": {
  "jira": {
    "command": "node",
    "args": ["/absolute/path/to/my-mcp-server/index.js"],
    "env": { "JIRA_TOKEN": "{env:JIRA_TOKEN}" }
  }
}
```

Минимальный пример на Python (через `mcp` SDK):

```python
# my_mcp_server.py
from mcp.server import Server
from mcp.server.stdio import stdio_server
import os, requests

server = Server("my-mcp")

@server.list_tools()
async def list_tools():
    return [{"name": "fetch_jira_ticket", "description": "...", "inputSchema": {...}}]

@server.call_tool()
async def call_tool(name, arguments):
    if name == "fetch_jira_ticket":
        ticket_id = arguments["ticket_id"]
        r = requests.get(f"https://jira/rest/api/2/issue/{ticket_id}",
                         headers={"Authorization": f"Bearer {os.environ['JIRA_TOKEN']}"})
        return [{"type": "text", "text": r.text}]

if __name__ == "__main__":
    stdio_server(server)
```

```json
"jira": {
  "command": "uvx",
  "args": ["python", "/path/to/my_mcp_server.py"]
}
```

## Debug MCP

### Симптом: agent не вызывает MCP-сервер

**Причина 1**: сервер не запустился. Запустить вручную:

```bash
npx -y @upstash/context7-mcp@latest
# Должен ждать stdin (JSON-RPC сообщения), не падать
```

**Причина 2**: агент не знает что tool существует. Проверить `opencode --verbose` -- должна быть строка `Loaded MCP server: <name>` со списком tools.

**Причина 3**: model не понимает когда вызывать tool. Решение: добавить hint в system prompt: "Use context7 for any library documentation queries".

### Симптом: server crash при tool call

Включить debug logs у MCP-сервера. Большинство серверов поддерживают `MCP_LOG_LEVEL=debug`:

```json
"context7": {
  "command": "npx",
  "args": ["-y", "@upstash/context7-mcp@latest"],
  "env": { "MCP_LOG_LEVEL": "debug" }
}
```

Логи появятся в stderr -- opencode пишет их в `~/.opencode/logs/<session>.log`.

### Симптом: high latency на tool calls

Некоторые MCP-серверы делают cold start (npx скачивает пакет каждый раз). Решение: pre-install:

```bash
npm install -g @upstash/context7-mcp
```

Тогда в config:

```json
"context7": { "command": "context7-mcp" }
```

Без `npx` overhead на каждый запуск opencode.

## Performance

| MCP-сервер | Cold start | Memory | Когда тяжёлый |
|------------|-----------|--------|----------------|
| filesystem | <100ms | ~30 MB | Безопасно держать всегда |
| github | ~500ms (gh CLI subprocess) | ~50 MB | Включать только когда работаешь с PR |
| postgres | ~1s (driver init) | ~50 MB | Включать только при DB-задачах |
| context7 | ~2s (npx download если не pre-install) | ~80 MB | Включать только когда нужна документация |
| playwright | ~3s (browser launch) | ~200 MB | Heavy -- включать только для e2e |

**Рекомендация**: не подключать **все** MCP-серверы во все проекты. Делать **per-project `opencode.json`** с минимально необходимыми. Для глобальных tools -- `~/.opencode/config.json`.

## Security

MCP-серверы исполняются как **отдельные процессы с правами текущего пользователя**. Это значит:

1. **Не подключать MCP-серверы из непроверенных источников** -- они могут читать ваш filesystem
2. **Использовать env-templates для secrets** -- не hardcode tokens в `opencode.json` (он часто в VCS)
3. **postgres MCP подключать к read-replica** -- никогда к prod write
4. **github MCP с минимальным token scope** -- read-only для аудита, не admin

Permission system opencode применяется **поверх** MCP -- если permission `edit: deny` для агента, MCP не сможет вызвать `write_file` через filesystem-сервер. Это double-защита.

## Связано

- [README.md](README.md) -- обзор opencode
- [custom-agents-guide.md](custom-agents-guide.md) -- per-agent permissions для MCP tools
- [migration-guide.md](migration-guide.md) -- mapping Claude Code Plugins → opencode MCP
- [../claude-code/mcp-setup.md](../claude-code/mcp-setup.md) -- база MCP в Claude Code (тот же протокол)
- [Model Context Protocol официально](https://modelcontextprotocol.io/) -- спецификация
- [MCP servers registry](https://github.com/modelcontextprotocol/servers) -- готовые серверы
