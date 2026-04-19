# Claude Code: хроника обновлений и анализ нововведений

Хронология фич, релизов и архитектурных изменений Claude Code от Anthropic. Дополняет [README.md](README.md) (профиль продукта) детальной динамикой. Источник: [официальный changelog](https://code.claude.com/docs/en/changelog), анализы community.

Эта страница -- для разработчика, следящего за эволюцией инструмента: что появилось нового, какие паттерны использования изменились, что стоит включить в свой workflow.

## Архитектура полного стека Claude Code (состояние на апрель 2026)

Claude Code к 2026 году превратился из "CLI-чата с моделью" в **многослойный agentic-стек**. Шесть ключевых механизмов расширения работают вместе:

```
+-----------------------------------------------------------+
|                  Claude Code Session                        |
+-----------------------------------------------------------+
          |              |              |              |
          v              v              v              v
     +---------+    +---------+    +---------+    +---------+
     | Skills  |    |Subagents|    |  Hooks  |    |  MCP    |
     +---------+    +---------+    +---------+    +---------+
          |              |              |              |
          +------+-------+------+-------+------+-------+
                                |
                                v
                      +------------------+
                      |   Plugins        |  <- упаковка всего вместе
                      +------------------+
                                |
                                v
                      +------------------+
                      |  Agent Teams     |  <- координация нескольких сессий
                      +------------------+
```

Какой механизм для чего:

| Механизм | Что делает | Когда использовать |
|----------|-----------|---------------------|
| **Skills** | Переиспользуемые "навыки" (промпты + инструменты). Имеют slash-command интерфейс (`/skill-name`) | Часто повторяющаяся задача с известными параметрами (code review, write-a-prd, migrate-db) |
| **Subagents** | Делегирование подзадачи в отдельный контекст с ограниченным tool set | Изоляция контекста, параллельные независимые задачи внутри одной сессии |
| **Hooks** | Гарантированное выполнение shell-команд на event'ы (pre/post action) | Enforce стандартов: форматирование, валидация, линтеры, блокировка опасных команд |
| **MCP** | Внешние сервисы через Model Context Protocol (БД, GitHub, Sentry, Slack) | Интеграция с внешними системами без кастомного кода |
| **Plugins** | Упаковка skills + hooks + MCP в единый deliverable | Shared team configs, marketplace-дистрибуция, enterprise-standards |
| **Agent Teams** | Несколько независимых Claude Code сессий координируются (планер + исполнители) | Крупные задачи требующие параллелизма (refactor большого monorepo, multi-service изменения) |

Этот "mental model" -- то, что отличает Claude Code 2026 от Claude Code 2025. Все шесть механизмов были опубликованы или существенно переработаны в течение последнего года.

## 2026-Q2 (актуально)

### Apr 16 -- Claude Opus 4.7

Релиз новой backend-модели для Claude Code. Ключевые изменения:

- **Model ID**: `claude-opus-4-7`, контекст 1M tokens, max output 128K
- **SWE-bench Verified**: 87.6% (Opus 4.6 было 80.8%, +6.8 п.п.), **SWE-bench Pro**: 64.3% (было 53.4%, +10.9 п.п.)
- **Vision**: разрешение увеличено с 1,568px (1.15 MP) до 2,576px (3.75 MP) -- 3x больше пикселей, screenshot-to-code точнее
- **xhigh effort level**: промежуточный уровень между high и max, даёт больше reasoning без полной стоимости max
- **Task budgets (public beta)**: контроль расхода токенов на задачу, бюджетирование agentic-сессий
- **`/ultrareview` command**: глубокий code review с reasoning на уровне xhigh
- **Rebuilt tokenizer**: изменена токенизация (улучшение для code и non-Latin languages)
- **Цена без изменений**: $5/$25 per M tokens (input/output)
- **Claude Design**: Anthropic Labs sub-brand, анонсирован 17 апреля
- **Доступ**: Claude Platform, Amazon Bedrock, Google Vertex AI, Microsoft Foundry

Opus 4.7 заменяет Opus 4.5 как основную coding-модель в Claude Code Max plan. Opus 4.6 остаётся текущей моделью для 1M context сессий до обновления конфигурации.

### Apr 2026 -- версии 2.1.69 → 2.1.101 (30+ итераций за месяц)

Апрель выдался очень активным -- **30+ версий** Claude Code CLI. Ключевые темы:

**Code Kit v5.0 для Agent Teams** -- публикация официального SDK/шаблонов для создания teams. Ранее конфигурация team требовала ручного составления JSON, теперь есть декларативный DSL.

**Amazon Bedrock via Mantle** -- поддержка запуска Claude Code через Mantle (AWS Bedrock proxy). Важно для enterprise-пользователей в AWS-экосистеме: теперь можно пройти compliance-audit с полным cloud-native трейсингом.

**Default effort изменён с `medium` на `high`** для API-key, Bedrock/Vertex/Foundry, Team, Enterprise пользователей. На практике это значит: больше reasoning на сложных задачах "из коробки", без явного указания `--effort high`. Для простых запросов -- можно снизить через `--effort low`.

**`--bare` флаг** -- облегчённый режим для scripted calls, пропускает hooks, LSP, plugin sync, skill directory walks. Полезно для CI pipelines где нужен чистый Claude Code без side-effects.

**`--channels` permission relay** -- теперь channel-серверы (Telegram, Discord, Slack) могут пересылать tool approval prompts на телефон разработчика. Значит: можно отпустить Claude Code работать ночью, получать push-уведомления на согласование деструктивных операций, тапать "approve" в Telegram.

**Slack MCP**: compact `#channel` header с кликабельной ссылкой в сообщениях. Мелкая но полезная UX-правка -- проще навигироваться между Slack-беседами и Claude-результатами.

**Stable skill naming**: skill, у которого в манифесте плагина указано поле `skills` со значением текущей директории, теперь использует `name` из frontmatter для invocation, а не basename директории. Устраняет проблему когда plugin устанавливается в разные директории и slash-команды разъезжаются.

**Багфиксы**: исправлены Bedrock 403 с AWS_BEARER_TOKEN_BEDROCK, race condition в polling background agent tasks (task мог "зависать" если завершался между poll-циклами), `/btw` пропускал pasted text во время активного ответа, `--channels` bypass для Team/Enterprise.

Источник: [Claude Code Changelog](https://code.claude.com/docs/en/changelog), детальный разбор -- [apiyi.com blog](https://help.apiyi.com/en/claude-code-changelog-2026-april-updates-en.html).

## 2026-Q1 (январь-март 2026)

Q1 2026 -- **самый значимый квартал** в истории Claude Code. Шесть features radically изменили позиционирование инструмента:

### 5 февраля 2026 -- Agent Teams

Главный релиз Q1. **Agent Teams** -- механизм координации нескольких Claude Code сессий:
- Общий **shared task list**
- **Inter-agent messaging** (сессии общаются напрямую)
- **Team lead** orchestrates whole thing
- Параллельное распределение работы

Включается через `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=true`. На практике выглядит так: пользователь даёт крупную задачу team lead'у, он разбивает её на подзадачи, делегирует independent Claude Code сессиям (каждая -- изолированный контекст), те работают параллельно, возвращают результаты, team lead синтезирует.

Выпущен одновременно с **Claude Opus 4.6** -- именно 1M-контекст и hybrid reasoning в 4.6 делают Team mode практически полезным (одной модели нужно держать весь task list в голове).

Для разработчика: подходит для "refactor всего monorepo", "обновить зависимости во всех сервисах", "провести security audit по всем endpoint'ам". Но требует навыка декомпозиции -- не все задачи масштабируются на команду из LLM-сессий.

Источник: [alexop.dev](https://alexop.dev/posts/from-tasks-to-swarms-agent-teams-in-claude-code/), [docs](https://code.claude.com/docs/en/agent-teams).

### Q1 2026 -- Remote Control + Dispatch

**Remote Control** -- самый значимый архитектурный сдвиг Q1. Позволяет запускать Claude Code на **сервере или CI без local terminal session**. Взаимодействие -- через:
- API calls
- Webhooks
- Thin client

Раньше Claude Code жил в терминале разработчика. Remote Control -- делает его **managed service**. Можно поднять Claude Code на своём инфраструктурном сервере (например рядом с CI), отправлять задачи через HTTP, получать результаты в webhook.

**Dispatch** -- task-aware queue. Понимает Claude Code capability model, поддерживает dependency chaining между agent tasks, роутит работу по permission-профилям. Это не просто "очередь задач" -- это знает что "agent X не может писать в prod", "agent Y только для Python-задач".

Вместе они дают пайплайн: user submits task → Dispatch analyzes → Dispatch routes to appropriate Remote Control instance → Remote Control executes → results back via webhook.

Для разработчика: можно собрать внутренний "Claude Code-as-a-Service" для команды. Использование: background tasks, batch-рефакторинги, night builds.

### Q1 2026 -- Channels

**Channels** -- связь между Claude Code сессиями или между Claude Code и человеком через API. Реализации на момент апреля 2026:
- Telegram (официальный канал Anthropic)
- Discord
- Slack (через MCP)

Use case: Claude Code работает автономно (например background task на Remote Control), достигает точки где нужно approval. Отправляет запрос в Channel, оператор видит на телефоне, тапает approve/deny, Claude Code продолжает. Или: два Claude Code инстанса на разных серверах общаются между собой через Channel.

Это своего рода **Claude-native заменитель OpenClaw** (третьесторонний инструмент, который проксировал Claude Pro subscription в Telegram). OpenClaw был заблокирован Anthropic 4 апреля 2026 -- Channels вышел раньше как native альтернатива.

### Q1 2026 -- Computer Use (improvements)

Computer Use существовал с 2024, но в Q1 2026 получил ряд improvements:
- Лучшее распознавание элементов UI (bounding box prediction через Mythos preview)
- Reliable browser automation (не "ломается" на JavaScript-heavy страницах)
- File upload/download в браузере
- Stable cursor positioning

Для разработчика: автоматизация web-задач которые не имеют API (legacy-системы, third-party admin panels), QA-тестирование, scraping.

### Q1 2026 -- Auto Mode

**Auto Mode** -- режим максимальной автономности. Claude Code принимает решения без approval prompts (в пределах настроенных permissions). Подходит для **safe automation** -- задачи где последствия ограничены (dev-окружение, sandbox'ы).

Активируется через `--auto-mode` флаг или в конфиге. Умеет:
- Автоматически применять file edits без подтверждения
- Запускать тесты
- Коммитить (если permission позволяет)
- Создавать PR

Но **НЕ** будет: push в main, drop database tables, удаление файлов без backup -- эти операции всё равно require explicit approval, даже в auto mode. Это bounded autonomy (см. [../../trends.md](../../trends.md#2-bounded-autonomy)).

### Q1 2026 -- AutoDream

**AutoDream** -- экспериментальный режим "overnight development". Claude Code получает high-level goal перед сном разработчика, работает всю ночь в Auto Mode + Remote Control + Agent Teams combo, утром презентует результат.

В апреле 2026 это ещё marketing-term чем stable feature. Но показывает направление: **8-часовые автономные сессии разработки** (что совпадает с трендами GLM-5.1 "long-horizon agentic").

Источник: [MindStudio Q1 2026 Update Roundup](https://www.mindstudio.ai/blog/claude-code-q1-2026-update-roundup).

## 2025-Q4

### Ноябрь 2025 -- Claude Opus 4.5

Opus 4.5 стал default для Max plan ($200/мес). SWE-bench Verified 80.9%, лучший frontend score в индустрии (95% Faros). Ключевое для Claude Code: модель **заметно лучше держит long-context coding sessions** без деградации качества (sub-agent дисциплина, tool use стабильнее).

### Октябрь 2025 -- Skills как стандарт

Skills (изначально появились в 2024 как экспериментальные) официально стали **первым классом citizen**. Переход от `.claude/commands/*.md` к `.claude/skills/*.md` с frontmatter. Каждый skill получил slash-command интерфейс.

Для разработчика это сменило подход: раньше CLAUDE.md накапливал набор инструкций; теперь эти инструкции оформляются как **модульные skills**, которые можно переиспользовать между проектами и шарить через plugins.

### Октябрь 2025 -- Plugins marketplace

Запуск community-каталогов plugins. Один plugin может включать: skills + hooks + MCP-серверы. Distribute через git-репозитории. Популярные на момент апреля 2026: feature-dev, code-review, frontend-design, Context7, Context Hub.

## 2025-Q3

### Сентябрь 2025 -- Hooks made public

Hooks существовали как internal механизм, в сентябре 2025 стали **официальной public API**. Гарантируют выполнение shell-команд на event'ы (pre-tool-use, post-tool-use, stop, user-prompt-submit).

Ключевой use case для разработчика -- **enforce стандартов**: блокировка `rm -rf`, автоформат кода после редактирования, запуск тестов перед commit, очистка временных файлов.

### Q3 2025 -- Subagents

Формализация subagent-механизма. Делегирование подзадачи в отдельный Claude-сессионный контекст с:
- Собственным tool set
- Ограниченными permissions
- Изолированной memory
- Контролируемым `maxTurns`

Упростило создание "specialized workers" внутри одной main-сессии.

### Q3 2025 -- MCP экспоненциальный рост

Начало взрывного роста MCP. К апрелю 2026 -- **97 миллионов установок** MCP-серверов в мире (см. [ai-agents/news.md](../../news.md#apr-2026----mcp-97-млн-установок-де-факто-стандарт)).

## 2025-Q2 и ранее

### Май 2025 -- Релиз Claude Code

Первый публичный релиз. На момент апреля 2026 продукт существует **11 месяцев**. За это время:
- Захватил 41% профессиональных разработчиков (Pragmatic Engineer survey февраль 2026)
- 46% "most loved" dev tool
- $1B+ ARR (декабрь 2025)
- Стал default CLI-инструментом для работы с Claude

## Анализ: что это значит для разработчика

### Что включить в свой workflow в 2026

**Обязательно** (базовый setup):
1. **CLAUDE.md** в каждом проекте -- project-specific инструкции (tech stack, naming conventions, testing approach)
2. **MCP Context7** -- для актуальной документации библиотек (не полагаться на training data)
3. **Hooks для git-safety** -- блокировка `git push --force` в main, `git reset --hard`, и других destructive операций
4. **2-3 skills для повторяющихся задач** -- code review, commit message, PR description

**Продвинутый setup** (для регулярных больших задач):
5. **Subagents для параллельной работы** -- research + implementation + testing в отдельных контекстах
6. **Custom plugins** -- упаковка team-standards в shareable формат
7. **Channels** -- если часто работаешь с long-running задачами

**Экспериментальный** (watching):
8. **Agent Teams** для monorepo-refactor'ов
9. **Remote Control + Dispatch** для собственного "Claude-as-a-Service"
10. **AutoDream** -- для overnight tasks (когда задача well-defined)

### Эволюция паттернов использования

Было **весна 2025**: "Запускаю Claude Code, задаю вопрос, копипастю ответ".

Стало **весна 2026**: "У меня 10 skills в .claude/, CLAUDE.md на 200 строк с guard-rails, hooks блокируют опасные операции, subagent делает research параллельно с моим редактированием, MCP Context7 даёт свежие доки. Agent Team рефакторит legacy-сервис ночью через Remote Control, утром я ревьюю PR".

Это качественный сдвиг: **Claude Code стал инфраструктурой**, не просто инструментом. Каждый новый механизм (Skills, Subagents, Hooks, MCP, Plugins, Agent Teams) -- это ещё один слой, позволяющий строить сложнее workflow'ы.

### Что следить дальше

- **Q2 2026** -- стабилизация Agent Teams, предположительно выход из experimental
- **Q2-Q3 2026** -- MCP 2.0 (обсуждается стандартизация версионирования)
- **Q3 2026** -- ожидается более глубокая IDE-интеграция (не только CLI-мост), фокус на debugger/profiler integration
- **Конец 2026** -- Mythos Preview (93.9% SWE-bench) может стать доступен в Claude Code Max plan

## Ссылки на официальные источники

- [Changelog Claude Code](https://code.claude.com/docs/en/changelog) -- авторитетный источник апдейтов
- [GitHub releases](https://github.com/anthropics/claude-code/releases) -- релизы CLI
- [Agent Teams docs](https://code.claude.com/docs/en/agent-teams) -- официальная документация
- [Subagents docs](https://code.claude.com/docs/en/sub-agents)
- [Skills docs](https://code.claude.com/docs/en/skills)

## Анализы и guides от community

- [Understanding Claude Code's Full Stack: MCP, Skills, Subagents, and Hooks (alexop.dev)](https://alexop.dev/posts/understanding-claude-code-full-stack/)
- [Q1 2026 Update Roundup (MindStudio)](https://www.mindstudio.ai/blog/claude-code-q1-2026-update-roundup)
- [April 2026 Changelog Overview (apiyi.com)](https://help.apiyi.com/en/claude-code-changelog-2026-april-updates-en.html)
- [Agent Skills: The Cheat Codes (Medium)](https://medium.com/jonathans-musings/agent-skills-the-cheat-codes-for-claude-code-b8679f0c3c4d)
- [From Tasks to Swarms: Agent Teams (alexop.dev)](https://alexop.dev/posts/from-tasks-to-swarms-agent-teams-in-claude-code/)
- [Awesome Claude Code (GitHub)](https://github.com/hesreallyhim/awesome-claude-code) -- curated list skills/hooks/plugins
- [OpenClaw vs Claude Code Channels vs Managed Agents (MindStudio)](https://www.mindstudio.ai/blog/openclaw-vs-claude-code-channels-vs-managed-agents-2026)

## Связано

- [README.md](README.md) -- профиль продукта (фичи, цены, сравнение)
- [../../news.md](../../news.md) -- общая хроника AI-агентов
- [../../trends.md](../../trends.md) -- долгосрочные тренды (bounded autonomy, multi-agent, context race)
- [../../commercial.md](../../commercial.md) -- Claude Code в ряду платных агентов
- [../../comparison.md](../../comparison.md) -- сравнительная таблица
- [../../../models/closed-source-coding.md](../../../models/closed-source-coding.md) -- Claude Opus/Sonnet/Mythos как модели под Claude Code
