# OpenClaw (community, 2025-2026)

> Open-source "Life OS" AI-агент: управление кодом, файлами, мессенджерами, desktop. Model-agnostic, self-hosted, 25+ каналов интеграции.

**Тип**: Self-hosted desktop / cloud
**Лицензия**: Open source (Apache-style)
**Backend**: Model-agnostic (Anthropic / OpenAI / Kimi / Qwen / локальные)
**Совместим с локальным llama-server**: **да** (OpenAI-compatible endpoint)
**Цена**: Free open-source
**Создатель**: Peter Steinberger (перешёл в OpenAI, февраль 2026)
**GitHub**: [openclaw/openclaw](https://github.com/openclaw/openclaw)
**Последняя версия**: 2026.4.14 (апрель 2026)
**Gateway порт**: 18789 (Control UI + WebChat + API)

## Файлы раздела

| Файл | О чём |
|------|-------|
| [news.md](news.md) | Хроника событий: Clawdbot -> Moltbot -> OpenClaw, блокировка Anthropic, CVE, narrative arc |
| [computer-use-guide.md](computer-use-guide.md) | Computer Use: xdotool + scrot, desktop control, safety, sandbox, CVE-2026-25253 |
| [integrations-guide.md](integrations-guide.md) | 25+ каналов: WhatsApp, Slack, Discord, Telegram, GitHub, filesystem, MCP, cross-app workflows |
| [models-providers.md](models-providers.md) | Провайдеры: Anthropic (статус блокировки), OpenAI, Kimi K2.5, Qwen, локальные. Миграция с Claude Code |
| [deployment-guide.md](deployment-guide.md) | Docker Compose, security, production, deployment на ai-plant сервере (Strix Halo) |

## Обзор

OpenClaw -- open-source personal AI assistant который запускается локально (Docker) или хостится в облаке. В отличие от [Claude Code](../claude-code/README.md) и [opencode](../opencode/README.md), сфокусированных на коде, OpenClaw позиционируется как "**Life OS**" -- подключается к 25+ каналам (WhatsApp, Slack, Telegram, Discord, GitHub), управляет desktop через Computer Use (xdotool + scrot), работает с локальной файловой системой.

Архитектурный центр -- **Gateway**: always-on daemon на порту 18789, маршрутизирует входящие сообщения из каналов в agent sessions, вызывает LLM, tools/skills, возвращает ответ в канал-источник. Работает как systemd service или Docker container.

История ребрендинга: **Clawdbot -> Moltbot -> OpenClaw** -- последнее переименование 29 января 2026 из-за trademark complaints от Anthropic.

Ключевое событие: **4 апреля 2026 Anthropic заблокировал Claude Pro/Max подписки** для third-party tools. ~60% активных сессий OpenClaw работали через subscription credits. Массовая миграция на Kimi K2.5 и Qwen 3.6. Подробнее -- [news.md](news.md).

## Возможности

- **Code editing** -- multi-file edits, agentic loop
- **Computer Use** -- управление экраном, мышью, клавиатурой через xdotool + scrot ([guide](computer-use-guide.md))
- **25+ каналов** -- WhatsApp, Telegram, Slack, Discord, Signal, iMessage, Teams, Matrix, и др. ([guide](integrations-guide.md))
- **File system access** -- CRUD, search, watch файлов
- **Model agnostic** -- Anthropic, OpenAI, Kimi, Qwen, Google, локальные ([guide](models-providers.md))
- **Self-hosted** -- Docker Compose, full control ([guide](deployment-guide.md))
- **MCP support** -- стандартный MCP protocol, совместимость с Claude Code MCP экосистемой
- **Cross-application workflows** -- "задача из Slack -> код в репо -> PR на GitHub -> уведомление"
- **Cron jobs и webhooks** -- автоматизация по расписанию и событиям
- **Active Memory** -- опциональный плагин памяти (configurable: message/recent/full context)
- **Voice** -- поддержка на macOS/iOS/Android
- **Canvas** -- live Canvas для совместной работы

## Сильные стороны

- **Полная независимость от вендора** -- любая модель, любой провайдер; hot-switch между ними
- **"Life OS" подход** -- единая точка для кода, мессенджеров, файлов, desktop
- **Computer Use** -- управление любым приложением через GUI (уникально среди open-source)
- **25+ каналов** -- от WhatsApp до Twitch, от iMessage до Nostr
- **Apache-style лицензия** -- self-hosting без ограничений
- **MCP экосистема** -- полная совместимость с растущим набором серверов
- **Continuous operation** -- Gateway работает как daemon, мониторит каналы 24/7
- **Sandboxing** -- first-class feature: agent execution в isolated environments

## Слабые стороны / ограничения

- **Заблокирован для Claude подписок** (с 4 апреля 2026) -- только pay-as-you-go API
- **CVE-2026-25253** -- critical RCE уязвимость (CVSS 8.8) через WebSocket; исправлена, но показывает security риски self-hosted agent'а
- **Сырая документация** -- проект молодой, инструкции устаревают быстро
- **Computer Use требует осторожности** -- агент может непреднамеренно повредить систему
- **Менее специализирован на коде** чем Claude Code -- генералист, не specialist
- **Создатель ушёл в OpenAI** -- вопросы долгосрочной governance
- **Сложная история переименований** -- путаница в документации и форумах (Clawdbot/Moltbot/OpenClaw)
- **Конфликт с Anthropic** -- неопределённое будущее для Anthropic-API доступа

## Базовые сценарии

- "Прочитай мои недавние сообщения в Slack и составь дайджест"
- "Найди файл в Documents похожий на X"
- "Открой Chrome и проверь, доступен ли мой сайт" (Computer Use)
- "Сгенерируй код для функции Y в проекте Z"
- "Пришло сообщение от клиента в WhatsApp -- предложи ответ"
- "Запусти тесты каждый час и уведомляй в Telegram если падают" (cron)

## Сложные сценарии

- **End-to-end automation**: задача из Slack -> код в репо -> PR на GitHub -> уведомление в канал -> закрытие задачи
- **Cross-app workflow**: получить файл из почты -> обработать локально -> загрузить в облако -> отправить ссылку коллеге
- **Local data processing с приватностью** -- работа с файлами без отправки в облако (с локальной моделью на [ai-plant сервере](deployment-guide.md#deployment-на-ai-plant-сервере-strix-halo))
- **Multi-modal анализ** -- скриншот + кодбейз + история чата для понимания задачи
- **Computer Use для тестирования UI** -- агент проходит user flow в браузере ([guide](computer-use-guide.md))
- **24/7 мониторинг** -- Gateway daemon следит за каналами, реагирует на events

## OpenClaw vs Claude Code

| Критерий | OpenClaw | [Claude Code](../claude-code/README.md) |
|----------|----------|-------------|
| Тип | Self-hosted daemon, 25+ channels | CLI/IDE agent, terminal-native |
| Фокус | "Life OS" -- код + мессенджеры + desktop | Код и software engineering |
| Модели | Model-agnostic (любой провайдер) | Claude only (Anthropic) |
| Computer Use | да (xdotool, full desktop) | да (Anthropic API) |
| Каналы | 25+ (WhatsApp, Slack, Telegram, ...) | Terminal + IDE |
| MCP | да (стандартный protocol) | да (стандартный protocol) |
| Skills/Hooks | Skills (yaml/natural language) | Skills + Hooks (markdown + shell) |
| Agent Teams | нет | да (experimental) |
| Цена | Free (+ API costs) | $20/мес Max ($200 Teams) |
| Лицензия | Open source (Apache) | Proprietary |
| Continuous | да (daemon 24/7) | нет (per-session) |
| SWE-bench | зависит от модели | 72.7% (Opus 4.6) |
| Security | CVE history, self-maintained | Anthropic-maintained |

### Когда OpenClaw

- Нужна интеграция с мессенджерами (WhatsApp, Slack, Telegram)
- Нужен desktop control (Computer Use)
- Нужна vendor independence (не привязываться к Anthropic)
- Нужен 24/7 daemon (мониторинг, auto-response)
- Приватность: все данные on-premise

### Когда Claude Code

- Фокус на software engineering (SWE-bench лидер)
- Нужны Agent Teams для параллельной работы
- Нужна mature Skills/Hooks экосистема
- Не хочется заниматься self-hosting
- Бюджет на подписку есть

## Установка / запуск

```bash
# Docker Compose (рекомендуемый)
git clone https://github.com/openclaw/openclaw
cd openclaw
docker compose up -d

# Или pre-built image
export OPENCLAW_IMAGE="ghcr.io/openclaw/openclaw:latest"
docker compose up -d

# Открыть WebChat
xdg-open http://localhost:18789
```

Подключение к локальному llama-server на ai-plant: Settings -> Provider -> OpenAI Compatible, Base URL: `http://192.168.1.77:8081/v1`.

Подробнее: [deployment-guide.md](deployment-guide.md).

## Конфигурация

В Control UI (http://localhost:18789):
- **Providers** -- подключить API (Anthropic / OpenAI / Kimi / OpenAI-compatible local). См. [models-providers.md](models-providers.md)
- **Channels** -- WhatsApp, Slack, Discord, Telegram, GitHub. См. [integrations-guide.md](integrations-guide.md)
- **Skills** -- Desktop Control, Claw Mouse, custom skills
- **Permissions** -- что агент может делать без подтверждения
- **MCP servers** -- стандартные MCP server definitions

## Ссылки

- [GitHub: openclaw/openclaw](https://github.com/openclaw/openclaw)
- [Документация OpenClaw](https://docs.openclaw.ai/)
- [Docker install guide](https://docs.openclaw.ai/install/docker)
- [DataCamp: OpenClaw vs Claude Code](https://www.datacamp.com/blog/openclaw-vs-claude-code)
- [MindStudio: OpenClaw vs Claude Code Channels vs Managed Agents](https://www.mindstudio.ai/blog/openclaw-vs-claude-code-channels-vs-managed-agents-2026)
- [TechCrunch: Anthropic banned creator](https://techcrunch.com/2026/04/10/anthropic-temporarily-banned-openclaws-creator-from-accessing-claude/)
- [Axios: Anthropic blocks third-party tools](https://www.axios.com/2026/04/06/anthropic-openclaw-subscription-openai)
- [DigitalOcean: What is OpenClaw](https://www.digitalocean.com/resources/articles/what-is-openclaw)
- [Petronella: OpenClaw guide](https://petronellatech.com/blog/openclaw-ai-agent-guide-2026)

## Связанные статьи

- [Claude Code](../claude-code/README.md) -- главный конкурент (узкий фокус на коде)
- [opencode](../opencode/README.md) -- CLI-only open-source альтернатива
- [Сравнение агентов](../../comparison.md) -- сводная таблица всех агентов
- [Open-source агенты](../../open-source.md) -- каталог open-source
- [Тренды AI-агентов](../../trends.md) -- контекст индустрии
- [Kimi K2.5](../../../models/families/kimi-k25.md) -- рекомендуемый default провайдер после блокировки
- [Qwen3-Coder](../../../models/families/qwen3-coder.md) -- локальная coding модель для ai-plant
