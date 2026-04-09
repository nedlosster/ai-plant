# OpenClaw (community, 2026)

> Open-source AI assistant как "Life OS" -- работает с кодом, файлами, мессенджерами. Не привязан к Anthropic, model-agnostic.

**Тип**: Self-hosted desktop / cloud
**Лицензия**: Open source
**Backend**: Model-agnostic (Anthropic / OpenAI / Kimi / Qwen / локальные)
**Совместим с локальным llama-server**: **да** (OpenAI-compatible)
**Цена**: Free open-source

## Обзор

OpenClaw -- open-source personal AI assistant который запускается на твоём устройстве (локально) или хостится в облаке. В отличие от Claude Code и opencode, которые сфокусированы на коде, OpenClaw позиционируется как "**Life OS**" -- подключается к WhatsApp, Slack, локальной файловой системе, может выполнять задачи в нескольких приложениях.

Имел сложную историю с переименованиями: **Clawdbot → Moltbot → OpenClaw** -- последнее переименование 29 января 2026 из-за trademark complaints от Anthropic.

В апреле 2026 произошёл громкий конфликт: **4 апреля Anthropic заблокировал использование Claude Pro/Max подписок в OpenClaw** -- пользователи массово переключились на open-source модели (Kimi 2.5 особенно популярна) и Qwen3.6.

## Возможности

- **Code editing** -- multi-file edits, agentic loop, как у Claude Code
- **Computer use** -- управление экраном, мышью, клавиатурой
- **File system access** -- работа с локальными файлами
- **Messenger integration** -- WhatsApp, Slack, Discord, Telegram
- **Model agnostic** -- Anthropic, OpenAI, Google, Kimi, локальные
- **Self-hosted или cloud** -- выбор пользователя
- **MCP support** -- расширение через MCP-серверы (стандарт от Anthropic)
- **Cross-application workflows** -- "напиши код, отправь PR, уведоми в Slack"

## Сильные стороны

- **Полная независимость от вендора** -- любая модель, любой провайдер
- **"Life OS" подход** -- единая точка для разных задач, не только код
- **Computer Use** -- может управлять любым приложением через GUI
- **Apache-style лицензия** -- self-hosting без ограничений
- **Поддержка Kimi 2.5** -- сильная open модель в reasoning по цене дешевле закрытых
- **MCP экосистема** -- совместимость с растущим набором серверов

## Слабые стороны / ограничения

- **Сложная история переименований** -- путаница в документации и форумах
- **Заблокирован для Claude подписок** (с 4 апреля 2026) -- официально нельзя через Pro/Max
- **Сырая документация** -- проект молодой, инструкции часто устаревают
- **Computer Use требует осторожности** -- агент может непреднамеренно повредить систему
- **Меньше специализирован** на коде чем Claude Code или opencode -- генералист
- **Conflict с Anthropic** -- неопределённое будущее для Anthropic-API доступа

## Базовые сценарии

- "Прочитай мои недавние сообщения в Slack и составь дайджест"
- "Найди файл в Documents похожий на X"
- "Открой Chrome и проверь, доступен ли мой сайт"
- "Сгенерируй код для функции Y в проекте Z"

## Сложные сценарии

- **End-to-end automation**: задача из Slack → код в репо → PR на GitHub → уведомление в канал → закрытие задачи
- **Cross-app workflow**: получить файл из почты → обработать локально → загрузить в облако → отправить ссылку коллеге
- **Local data processing с приватностью** -- работа с файлами без отправки в облако (с локальной моделью)
- **Multi-modal анализ** -- скриншот + кодбейз + история чата для понимания задачи
- **Computer Use для тестирования UI** -- агент проходит сценарий пользователя в браузере

## Установка / запуск

```bash
# Self-hosted (примерно)
git clone https://github.com/openclaw/openclaw  # точное имя репо см. на сайте
cd openclaw
docker-compose up -d

# Открыть UI
xdg-open http://localhost:3000

# Подключение к локальному llama-server
# Settings → Provider → OpenAI Compatible
# Base URL: http://192.168.1.77:8081/v1
# Model: qwen3-coder-next
```

## Конфигурация

В Settings UI:
- **Providers**: подключить нужные API (Anthropic / OpenAI / Kimi / OpenAI-compatible local)
- **Integrations**: WhatsApp, Slack, Discord, GitHub
- **Permissions**: что агент может делать без подтверждения
- **MCP servers**: подключить нужные расширения

## Анонсы и открытия

- **2026-04-04** -- Anthropic заблокировал использование Claude Pro/Max в OpenClaw. Большой конфликт, миграция на open модели
- **2026-04** -- Anthropic выпустил **Claude Code Channels** (Telegram/Discord интеграция) как ответ
- **2026-03** -- OpenClaw гремит как "Claude Code killer" в технических медиа
- **2026-01-29** -- переименование Moltbot → OpenClaw из-за trademark complaints от Anthropic
- **2026-01** -- быстрый рост популярности благодаря интеграции с Kimi 2.5 (дешёвая reasoning модель)
- **2025** -- первый релиз как Clawdbot

## Ссылки

- [Документация OpenClaw](https://docs.openclaw.ai/)
- [Anthropic provider docs](https://docs.openclaw.ai/providers/anthropic)
- [DataCamp: OpenClaw vs Claude Code](https://www.datacamp.com/blog/openclaw-vs-claude-code)
- [Eigent.ai: comparison](https://www.eigent.ai/blog/openclaw-vs-claude-code)
- [VentureBeat: Claude Code Channels response](https://venturebeat.com/orchestration/anthropic-just-shipped-an-openclaw-killer-called-claude-code-channels)
- [Axios: Anthropic blocks third-party tools](https://www.axios.com/2026/04/06/anthropic-openclaw-subscription-openai)
- [Cryptopolitan: safer alternative](https://www.cryptopolitan.com/claude-safer-openclaw-alternative-agent-race/)

## Связано

- **Альтернативы**: [claude-code](claude-code.md) (узко-фокус на коде), [opencode](opencode.md) (CLI-only)
- **Подходящие модели**: Kimi 2.5 (через cloud API), [qwen36](../../models/families/qwen36.md), [qwen3-coder](../../models/families/qwen3-coder.md)
- **Тренды**: [../trends.md](../trends.md), [../news.md](../news.md)
- **Концепты**: [../README.md](../README.md)
