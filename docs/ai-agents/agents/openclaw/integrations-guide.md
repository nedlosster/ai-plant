# Multi-app интеграции: мессенджеры, GitHub, файловая система

Контекст: [README.md](README.md). OpenClaw как "Life OS" -- суть в интеграциях с внешним миром.

---

## Обзор интеграций

OpenClaw позиционируется как универсальный агент, способный взаимодействовать
с пользователем через любой канал. На апрель 2026 поддерживается 25+ каналов
из коробки, плюс произвольные через MCP-серверы.

### Полный список каналов

| Канал | Тип | Протокол | Статус |
|-------|-----|----------|--------|
| WhatsApp | Мессенджер | Business API / Web bridge | Stable |
| Telegram | Мессенджер | Bot API | Stable |
| Signal | Мессенджер | signal-cli bridge | Stable |
| iMessage | Мессенджер | BlueBubbles bridge | Beta |
| BlueBubbles | Мессенджер | Native API | Beta |
| Slack | Корп. чат | OAuth / Bot token | Stable |
| Discord | Корп. чат | Bot token | Stable |
| Microsoft Teams | Корп. чат | Azure AD app | Stable |
| Google Chat | Корп. чат | Workspace API | Stable |
| Matrix | Корп. чат | Matrix protocol | Stable |
| Mattermost | Корп. чат | Bot API | Stable |
| Feishu (Lark) | Корп. чат | Feishu API | Stable |
| LINE | Мессенджер | Messaging API | Stable |
| IRC | Чат | IRC protocol | Stable |
| Nextcloud Talk | Корп. чат | Nextcloud API | Beta |
| Nostr | Децентрализованный | NIP relay | Beta |
| Synology Chat | Корп. чат | Synology API | Beta |
| Tlon | Децентрализованный | Urbit API | Experimental |
| Twitch | Стриминг | Bot API | Stable |
| Zalo | Мессенджер | Zalo API | Beta |
| WeChat | Мессенджер | Web bridge | Beta |
| QQ | Мессенджер | QQ bot API | Beta |
| WebChat | Веб-интерфейс | Built-in (порт 18789) | Stable |
| GitHub | Dev tools | API / MCP | Stable |
| Файловая система | Dev tools | Native / MCP | Stable |

---

## Мессенджеры

### WhatsApp

Подключение через WhatsApp Business API (Meta Business Suite) или web bridge.

```yaml
channels:
  whatsapp:
    type: whatsapp-business
    phone_number_id: "123456789"
    access_token: "${WHATSAPP_TOKEN}"
```

Возможности: текст, media, реакции, шаблонные сообщения.
Ограничения: rate limits (80 msg/sec tier 1), стоимость $0.005-0.08/conversation.

Сценарий: входящее сообщение от клиента -- OpenClaw классифицирует тему --
предлагает ответ -- отправляет после подтверждения.

### Telegram

Подключение через BotFather token.

```yaml
channels:
  telegram:
    type: telegram
    bot_token: "${TELEGRAM_BOT_TOKEN}"
```

Возможности: текст, media, inline keyboards, bot commands, groups, threads.

Сценарий: `/task создать PR для fix-123` -- OpenClaw парсит задачу --
создаёт PR на GitHub -- отправляет ссылку обратно в Telegram.

### Signal

Подключение через signal-cli bridge. E2E encrypted -- максимальная приватность.

```yaml
channels:
  signal:
    type: signal
    signal_cli_path: /usr/local/bin/signal-cli
    phone_number: "+1234567890"
```

Ограничения: требует Java runtime, нет inline keyboards

---

## Корпоративные чаты

### Slack

Создать Slack App (api.slack.com/apps), добавить Bot Token Scopes:
`chat:write`, `channels:history`, `channels:read`, `files:write`, `reactions:read`.

```yaml
channels:
  slack:
    type: slack
    bot_token: "${SLACK_BOT_TOKEN}"
    app_token: "${SLACK_APP_TOKEN}"  # для Socket Mode
```

Возможности: channels, DM, threads, reactions, file upload, slash commands,
interactive messages, Socket Mode (не требует публичного URL).

Сценарий -- мониторинг alerts: бот слушает #alerts -- анализирует alert --
предлагает fix -- создаёт issue в GitHub -- отписывает в thread со ссылкой.

Сценарий -- ежедневный дайджест: cron 09:00 -- чтение непрочитанных --
суммаризация -- отправка в DM.

### Discord

Bot token через Discord Developer Portal.

```yaml
channels:
  discord:
    type: discord
    bot_token: "${DISCORD_BOT_TOKEN}"
    guild_id: "1234567890"
```

Возможности: text channels, DM, threads, reactions, slash commands, embeds.

### Microsoft Teams

Azure AD app registration + Bot Framework connector.

```yaml
channels:
  teams:
    type: microsoft-teams
    app_id: "${TEAMS_APP_ID}"
    app_password: "${TEAMS_APP_PASSWORD}"
    tenant_id: "${TEAMS_TENANT_ID}"
```

Возможности: messages, channels, Adaptive Cards, SharePoint file sharing.
Ограничения: сложная настройка (Azure AD, permissions), строгие rate limits

---

## Dev tools (GitHub)

### Настройка

Два варианта подключения:

**Вариант 1: Personal Access Token (PAT)**
```yaml
integrations:
  github:
    type: github
    token: "${GITHUB_TOKEN}"
    # scopes: repo, issues, pull_requests, notifications
```

**Вариант 2: MCP-сервер**
```yaml
mcp_servers:
  github:
    command: npx
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "${GITHUB_TOKEN}"
```

### Возможности

- Issues: создание, чтение, обновление, закрытие, labeling, assign
- Pull Requests: создание, review, merge, request changes
- Code search: поиск по репозиториям
- Notifications: отслеживание mentions, review requests
- Webhooks: реакция на push, PR, issue events
- Actions: запуск и мониторинг CI/CD

### Сценарии

**Auto-triage issues:**

1. Новый issue создан (webhook).
2. OpenClaw читает title и body.
3. Классифицирует: bug / feature / question / docs.
4. Назначает label и severity.
5. Если критический -- уведомляет в Slack.

**PR review:**

1. Новый PR открыт (webhook).
2. OpenClaw получает diff.
3. Анализирует: стиль кода, потенциальные баги, тесты.
4. Оставляет inline comments и общий review.
5. Approve или request changes.

**CI integration:**

1. Push в ветку (webhook).
2. OpenClaw запускает lint, тесты через MCP tools.
3. Результат отписывает в commit status или PR comment.

---

## Файловая система

### Настройка

```yaml
integrations:
  filesystem:
    type: filesystem
    allowed_paths:
      - /home/user/projects
      - /home/user/documents
    denied_paths:
      - /home/user/.ssh
      - /home/user/.env
    mode: read-write  # или read-only
```

Или через MCP-сервер:
```yaml
mcp_servers:
  filesystem:
    command: npx
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/projects"]
```

### Возможности

- CRUD файлов: создание, чтение, изменение, удаление
- Поиск по содержимому (grep-подобный)
- Навигация по директориям
- Watch: реакция на изменения файлов (inotify)
- Metadata: размер, дата модификации, permissions

### Безопасность

- **Обязательно** ограничить доступные директории -- не давать доступ к `/`
- Sensitive файлы: `.env`, `.ssh/`, `credentials.json`, `*.key` -- добавить в `denied_paths`
- Рекомендуется `read-only` по умолчанию, `read-write` только для рабочих директорий
- Логирование всех write-операций

---

## MCP-серверы в OpenClaw

### Подключение MCP-сервера

MCP (Model Context Protocol) -- стандартный протокол для расширения возможностей агента.
OpenClaw поддерживает MCP через stdio transport.

Конфигурация в `config.yaml`:
```yaml
mcp_servers:
  server_name:
    command: /path/to/server
    args: ["arg1", "arg2"]
    env:
      KEY: "value"
```

### Совместимость с Claude Code MCP экосистемой

OpenClaw поддерживает стандартный MCP protocol. Серверы, работающие с Claude Code,
работают и с OpenClaw без модификаций:

| MCP-сервер | Назначение | Transport |
|-----------|-----------|-----------|
| `@modelcontextprotocol/server-filesystem` | Файловая система | stdio |
| `@modelcontextprotocol/server-github` | GitHub API | stdio |
| `@modelcontextprotocol/server-postgres` | PostgreSQL queries | stdio |
| `@anthropic-ai/mcp-server-playwright` | Browser automation | stdio |
| `context7` | Документация библиотек | stdio |
| `perplexity-ask` | Веб-поиск | stdio |
| `@anthropic-ai/mcp-server-slack` | Slack API | stdio |
| `@modelcontextprotocol/server-brave-search` | Brave Search | stdio |
| `@modelcontextprotocol/server-fetch` | HTTP requests | stdio |
| `@modelcontextprotocol/server-memory` | Persistent memory | stdio |

### Ограничения MCP в OpenClaw

- Только stdio transport (HTTP/SSE пока не поддерживается)
- Tool call quality зависит от модели (cloud-модели лучше, локальные -- хуже)
- Нет поддержки MCP resources (только tools)

---

## Cross-app workflows

### Pipeline: Slack -- код -- GitHub -- Slack

Полный цикл разработки через агента:

1. Получить задачу из Slack-сообщения (mention бота или команда).
2. Агент анализирует задачу, определяет scope.
3. Создать ветку, внести изменения в код через filesystem tools.
4. Запустить тесты локально.
5. Создать PR на GitHub.
6. Уведомить в Slack thread со ссылкой на PR и summary изменений.

Конфигурация pipeline через Skills:
```yaml
skills:
  slack-to-pr:
    trigger: slack_mention
    steps:
      - parse_task
      - create_branch
      - implement
      - run_tests
      - create_pr
      - notify_slack
```

### Pipeline: Email -- файл -- обработка -- облако

1. Получить файл из email attachment (через email integration или MCP).
2. Сохранить локально через filesystem.
3. Обработать: парсинг CSV, трансформация данных, генерация отчёта.
4. Загрузить результат в cloud storage (S3, GCS через MCP).
5. Ответить отправителю со ссылкой.

### Построение собственных pipelines

Три механизма:

**Skills (YAML)** -- декларативное описание workflows с триггерами и шагами.

**Cron jobs** -- периодические задачи:
```yaml
cron:
  daily_digest:
    schedule: "0 9 * * *"
    action: "Прочитать непрочитанные сообщения в Slack и отправить дайджест"
```

**Webhooks** -- event-driven workflows:
```yaml
webhooks:
  github_push:
    path: /hooks/github
    secret: "${GITHUB_WEBHOOK_SECRET}"
    action: "Проанализировать push и уведомить в Slack"
```

---

## Безопасность интеграций

### Принцип минимальных привилегий

Для каждой интеграции запрашивать минимальные scopes:

| Интеграция | Минимальные scopes |
|-----------|-------------------|
| GitHub | `repo:status`, `public_repo` (для публичных) |
| Slack | `chat:write`, `channels:history` |
| Discord | Send Messages, Read Message History |
| Teams | `ChannelMessage.Send` |

Расширять scopes только при необходимости конкретного workflow.

### Хранение credentials

- Environment variables или Docker secrets
- Не хранить в config-файлах под git
- Ротация: при компрометации -- немедленная замена
- Audit log: логировать все API-вызовы к внешним сервисам

### Rate limiting

Настроить rate limits для исходящих сообщений, чтобы агент не спамил:
```yaml
rate_limits:
  slack:
    messages_per_minute: 10
  telegram:
    messages_per_minute: 20
  github:
    api_calls_per_hour: 1000
```

---

## Связанные статьи

- [README.md](README.md) -- профиль OpenClaw
- [models-providers.md](models-providers.md) -- настройка провайдеров моделей
- [deployment-guide.md](deployment-guide.md) -- Docker setup и production deployment
- [Claude Code: MCP setup](../claude-code/mcp-setup.md) -- MCP из перспективы Claude Code
- [Сравнение агентов](../../comparison.md)
