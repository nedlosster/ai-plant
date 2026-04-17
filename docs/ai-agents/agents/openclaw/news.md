# OpenClaw: хроника событий и анализ

Хронология ключевых событий, конфликтов и архитектурных изменений OpenClaw. Дополняет [README.md](README.md) (профиль продукта) анализом динамики проекта. Narrative arc: подъём community-проекта, кризис вендорозависимости, pivot на open models.

Контекст: OpenClaw -- open-source personal AI assistant с gateway-архитектурой. Проект прошёл три переименования (Clawdbot -> Moltbot -> OpenClaw), пережил блокировку основного backend-провайдера и уход создателя к конкуренту. На апрель 2026 -- в стадии адаптации к новой реальности без Claude revenue.

## Архитектура OpenClaw (состояние на апрель 2026)

OpenClaw построен как **gateway-агент**: always-on daemon принимает сообщения из 25+ каналов, роутит их через LLM, исполняет инструменты, возвращает ответ в канал.

```
+-----------------------------------------------------------+
|                  OpenClaw Gateway                          |
|               (daemon, порт 18789)                        |
+-----------------------------------------------------------+
        |              |              |              |
        v              v              v              v
  +-----------+  +-----------+  +-----------+  +-----------+
  |  Channel  |  |  Agent    |  |  Provider |  |  Tool     |
  |  Adapters |  |  Sessions |  |  Layer    |  |  Layer    |
  +-----------+  +-----------+  +-----------+  +-----------+
  | WhatsApp  |  | session   |  | Anthropic |  | MCP       |
  | Telegram  |  | context   |  | OpenAI    |  | servers   |
  | Slack     |  | memory    |  | Kimi 2.5  |  | native    |
  | Discord   |  | routing   |  | Qwen 3.6  |  | tools     |
  | WebChat   |  |           |  | llama.cpp |  |           |
  | 20+ more  |  |           |  | (local)   |  |           |
  +-----------+  +-----------+  +-----------+  +-----------+
        |              |              |              |
        +------+-------+------+------+-------+------+
                              |
                              v
                    +------------------+
                    |  Computer Use    |
                    | (xdotool, scrot, |
                    |  wmctrl, dogtail)|
                    +------------------+
                              |
                              v
                    +------------------+
                    |  Active Memory   |
                    |  Plugin (opt.)   |
                    +------------------+
```

Ключевые компоненты:

| Компонент | Назначение |
|-----------|-----------|
| **Gateway** | Always-on daemon (systemd unit), порт 18789. Control UI + WebChat |
| **Channel Adapters** | 25+ каналов: WhatsApp, Telegram, Slack, Discord, Email, SMS и др. |
| **Agent Sessions** | Контексты сессий, маршрутизация inbound messages через LLM |
| **Provider Layer** | Model-agnostic: Anthropic, OpenAI, Kimi, Qwen, локальные (OpenAI-compatible API) |
| **Tool Layer** | MCP-серверы + native tools (file system, shell, git) |
| **Computer Use** | X11 automation: xdotool + scrot (скриншоты), wmctrl (окна), dogtail (accessibility) |
| **Active Memory** | Опциональный plugin для persistent memory между сессиями |

Архитектурное отличие от Claude Code: OpenClaw -- **gateway** (always-on daemon, принимает входящие сообщения), Claude Code -- **CLI/session** (запускается пользователем, живёт в контексте terminal session). Gateway-архитектура даёт преимущество в multi-channel сценариях, но создаёт проблемы с security (постоянно открытый порт, WebSocket endpoint).

Routing pipeline: inbound message --> channel adapter --> agent session (контекст + память) --> provider layer (выбор LLM) --> tool dispatch (MCP / native / Computer Use) --> response --> channel adapter --> outbound message.

## 2026-Q2 (актуально)

### Apr 14, 2026 -- версия 2026.4.14

Broad quality release:
- Explicit turn improvements для GPT-5 family -- корректная обработка multi-turn диалогов с новыми моделями OpenAI
- Channel provider bugfixes -- устранение race conditions при одновременных сообщениях из нескольких каналов
- Рефакторинг core codebase -- вынесение provider-specific логики из gateway core

Релиз вышел на фоне продолжающегося оттока пользователей Claude-бэкенда. Основной фокус -- стабилизация работы с GPT-5 и Kimi 2.5 как primary providers.

Versioning scheme OpenClaw (date-based: YYYY.M.DD) отличается от Claude Code (semver: 2.1.x). Date-based versioning типичен для проектов с continuous delivery, но затрудняет отслеживание breaking changes.

### Apr 10, 2026 -- временный бан создателя

Anthropic временно заблокировал аккаунт Peter Steinberger'а (создатель OpenClaw). Steinberger опубликовал пост в X, который быстро завирусился в tech-community. Аккаунт восстановлен через несколько часов.

Контекст: бан произошёл через 6 дней после блокировки Claude подписок для OpenClaw. Community расценило это как retaliatory action, хотя Anthropic заявил о "routine compliance review".

Инцидент показателен для отношений между open-source community и cloud-провайдерами: ban аккаунта разработчика open-source инструмента, использующего API вендора через легитимную подписку, воспринимается community как враждебный акт вне зависимости от формальных причин.

Источник: [TechCrunch](https://techcrunch.com/2026/04/10/anthropic-temporarily-banned-openclaws-creator-from-accessing-claude/).

### Apr 4, 2026 -- блокировка Claude подписок (ключевое событие)

Anthropic заблокировал использование Claude Pro/Max подписок в third-party tools, начиная с OpenClaw. Хронология:

1. **4 апреля**: Anthropic обновил ToS -- Claude Pro/Max credits нельзя использовать через сторонние приложения
2. **~60% активных сессий** OpenClaw работали через subscription credits -- все потеряли доступ одномоментно
3. **Pay-as-you-go billing** как единственная альтернатива: стоимость для пользователей выросла до **50x** (подписка $20/мес vs API ~$1000/мес при аналогичном объёме)
4. Peter Steinberger назвал решение "betrayal of open-source developers"
5. Dave Morin (Anthropic board member) и Steinberger пытались убедить Anthropic пересмотреть решение -- удалось задержать enforcement на неделю
6. Anthropic выпустил **Claude Code Channels** как native альтернативу (Telegram/Discord интеграция) -- фактически конкурирующий ответ на OpenClaw

Последствия:
- Массовый pivot пользователей на Kimi 2.5, GPT-5, Qwen 3.6
- OpenClaw ускорил работу над model-agnostic provider layer
- Community разделилось: часть ушла на Claude Code Channels, часть осталась ради open-source и self-hosted

Источники: [HN](https://news.ycombinator.com/item?id=47633396), [TNW](https://thenextweb.com/news/anthropic-openclaw-claude-subscription-ban-cost), [Axios](https://www.axios.com/2026/04/06/anthropic-openclaw-subscription-openai).

### CVE-2026-25253 -- критическая уязвимость (RCE)

Remote Code Execution через WebSocket origin header bypass:
- **CVSS 8.8** (High)
- Атакующий мог исполнить произвольный код на exposed OpenClaw инстансе через crafted WebSocket handshake
- Затронуты все версии до патча
- Origin validation в WebSocket upgrade handler не проверяла `null` origin (бразуеры посылают при cross-origin redirect)

Уязвимость подчеркнула системный риск: self-hosted agent с Computer Use и shell-доступом -- высокоприоритетная цель. Один RCE = полный контроль над рабочей станцией пользователя.

Рекомендация: reverse proxy с TLS + origin whitelist перед любым exposed инстансом.

Для контекста: Claude Code (managed service) не подвержен этому классу уязвимостей -- Anthropic контролирует infrastructure. OpenClaw как self-hosted решение наследует все риски self-hosted deployment: пользователь отвечает за сетевую изоляцию, patching, мониторинг.

Timeline CVE:
- Обнаружение: security researcher (bug bounty)
- Disclosure: responsible (90-дневный срок)
- Патч: выпущен в течение 48 часов после public disclosure
- Эксплуатация в дикой природе: не зафиксирована

## 2026-Q1 (январь-март)

### Март 2026 -- "Claude Code killer" хайп

Пик медийного внимания к OpenClaw. Публикации:
- DataCamp: "OpenClaw vs Claude Code -- полное сравнение"
- VentureBeat: "Open-source agent challenges Anthropic's dominance"
- AnalyticsVidhya: обзор архитектуры и use cases

Ключевое позиционирование: **"Life OS" vs "coding-only"**. OpenClaw делал ставку на то, что Claude Code -- только для кода, а OpenClaw -- для всего (мессенджеры, desktop automation, файлы, email). В реальности Claude Code Channels в апреле частично закрыл этот gap.

Метрики на пике (март 2026):
- GitHub stars: ~15k
- Active installations: оценочно 50-80k
- Поддерживаемые каналы: 25+
- Поддерживаемые LLM providers: 8+

Медийное позиционирование "Claude Code killer" было преувеличением: Claude Code к марту 2026 захватил 41% профессиональных разработчиков (Pragmatic Engineer survey), генерировал $1B+ ARR, имел backing корпорации с $10B+ funding. OpenClaw -- community-проект с одним ведущим maintainer'ом. Но хайп сработал: awareness резко вырос, contributor base расширился.

### Февраль 2026 -- создатель уходит в OpenAI

Peter Steinberger объявил о присоединении к OpenAI. Факты:

- Steinberger -- основатель PSPDFKit, затем автор OpenClaw (ex-Clawdbot)
- Переход в OpenAI создал конфликт интересов: OpenClaw активно использовал Claude через подписку Anthropic
- Community выразило concern о "vendor capture" -- создатель open-source проекта работает у конкурента основного backend-провайдера
- Steinberger заверил, что OpenClaw остаётся community-driven и model-agnostic

Ретроспективно: уход в OpenAI объясняет, почему Anthropic через 2 месяца заблокировал подписки. Формальная причина -- ToS enforcement, но timeline слишком совпадает с переходом.

Параллель: аналогичная ситуация в мире браузеров -- Brendan Eich создал Firefox/Mozilla, ушёл, основал Brave. Но в случае OpenClaw разница в масштабе: Firefox -- фундаментальный проект с десятками core contributors; OpenClaw -- проект с bus factor = 1.

### Январь 2026 -- ребрендинг Moltbot в OpenClaw

**29 января 2026**: trademark complaints от Anthropic. Имя "Clawdbot" (первое название проекта) слишком ассоциировалось с "Claude". Промежуточное "Moltbot" тоже вызвало вопросы. Окончательное переименование в **OpenClaw** -- нейтральное имя, акцент на "open".

Параллельно:
- Принятие Apache License 2.0 (ранее был MIT)
- Интеграция с **Kimi 2.5** как ключевой backend -- дешёвый reasoning API от Moonshot AI
- Быстрый рост пользовательской базы благодаря Kimi: reasoning-качество сопоставимо с Claude Sonnet, но стоимость API в 10-20x ниже

Ребрендинг оказался удачным: имя "OpenClaw" стало узнаваемым в community за 2 месяца.

Переход на Apache 2.0 -- стратегический: MIT не защищает от trademark claims, Apache 2.0 включает явный patent grant и contributor license agreement. Для проекта, пережившего trademark conflict, это логичный выбор.

## 2025 -- предыстория

### Q3-Q4 2025 -- Clawdbot и Moltbot

Предыстория проекта:

- **Первый релиз** под именем **Clawdbot** -- personal AI assistant с messenger-интеграцией
- Концепция: "Claude в твоём Telegram/WhatsApp" -- проксирование Claude Pro подписки через бот
- Рост community вокруг **desktop automation** (Computer Use): управление X11-приложениями через LLM
- Промежуточное переименование в **Moltbot** -- попытка уйти от ассоциации с "Claude"
- Формирование core-архитектуры: gateway daemon + channel adapters + provider layer
- Первые MCP-интеграции: файловая система, git, браузер
- Computer Use реализован через open-source стек (xdotool, scrot, wmctrl) -- в отличие от проприетарного API Anthropic

На этом этапе проект был тесно связан с Claude: ~90% пользователей использовали Claude через проксирование подписки. Model-agnostic layer существовал, но был вторичен.

Технический стек 2025 года:
- Python backend (FastAPI)
- WebSocket для real-time communication
- SQLite для локального state (сессии, память)
- Docker-based deployment (рекомендуемый, но не обязательный)
- Модульная система каналов (каждый канал -- отдельный adapter с unified interface)

## Анализ: уроки вендорозависимости

### Timeline рисков

Хронология демонстрирует классический паттерн platform risk:

```
2025-Q3   Clawdbot запускается на Claude subscription    [зависимость 90%]
    |
2025-Q4   Рост community, desktop automation             [зависимость 85%]
    |
2026-Jan  Ребрендинг, добавление Kimi 2.5               [зависимость 60%]
    |
2026-Feb  Steinberger уходит в OpenAI                    [сигнал конфликта]
    |
2026-Mar  Пик хайпа, "Claude Code killer"               [зависимость 55%]
    |
2026-Apr  Anthropic блокирует подписки                   [зависимость -> 0%]
    |
2026-Apr  Pivot: Kimi + GPT-5 + Qwen + local            [диверсификация]
```

Зависимость от стороннего API как бизнес-модель: удобно на старте, но хрупко при масштабировании. OpenClaw построил пользовательскую базу на Claude subscriptions -- Anthropic отключил доступ -- 60% сессий потеряны за сутки.

Урок: **model-agnostic архитектура -- не опция, а необходимость** для любого стороннего агента. Диверсификация providers должна происходить до кризиса, а не после.

Аналогии из истории: Zynga (зависимость от Facebook Platform), Heroku (зависимость от AWS Marketplace), Twitter API clients (массовое отключение в 2012). Паттерн один: платформа разрешает рост третьей стороны, затем забирает рынок или отключает доступ.

### Pivot на open models

После блокировки Claude подписок OpenClaw форсировал переход на альтернативные провайдеры:

| Provider | Роль | Стоимость vs Claude API |
|----------|------|------------------------|
| **Kimi 2.5** | Primary replacement для reasoning-задач | ~10-20x дешевле |
| **GPT-5** | Альтернатива для complex multi-turn | Сопоставимо |
| **Qwen 3.6** | Coding-задачи, code generation | ~5-10x дешевле |
| **Локальные модели** | Privacy-sensitive workflows через llama-server | Бесплатно (hardware costs) |

Kimi 2.5 от Moonshot AI стал де-факто default backend для большинства пользователей OpenClaw: приемлемое качество reasoning при минимальной стоимости API. Qwen 3.6 -- для coding-специфичных задач где нужна точность в code generation.

Локальные модели через OpenAI-compatible API (llama-server, Ollama) -- для пользователей с требованиями к privacy и air-gapped environments.

Для проекта [ai-plant](../../../../README.md): OpenClaw совместим с локальным llama-server (см. [scripts/inference/](../../../../scripts/inference/)). При наличии достаточного VRAM можно запустить Qwen 3.6 или DeepSeek через llama-server и подключить к OpenClaw как OpenAI-compatible endpoint. На текущем железе (96 GiB unified, но KFD ограничивает до 15.5 GiB) -- практически неприменимо для крупных моделей.

### Community governance после ухода Steinberger'а

Переход создателя в OpenAI поставил вопрос о governance:
- Проект формально community-driven (Apache 2.0)
- Но Steinberger оставался primary contributor и архитектор
- На апрель 2026 нет формального governance body (steering committee, foundation)
- Риск: bus factor = 1 для архитектурных решений

Для сравнения: Claude Code -- продукт Anthropic с выделенной командой. OpenClaw -- open-source проект с одним key maintainer, работающим у конкурента.

Метрики contributor activity (апрель 2026):
- Total contributors: ~40
- Active monthly contributors (3+ commits/мес): ~5-8
- Core maintainers с write access: 3
- Bus factor для архитектурных решений: 1 (Steinberger)

### Security: self-hosted agent с Computer Use

CVE-2026-25253 обнажила системную проблему: OpenClaw -- self-hosted agent с доступом к:
- Shell (произвольные команды)
- File system (чтение/запись)
- Desktop (Computer Use: xdotool, scrot)
- Мессенджерам (credentials для 25+ каналов)

Компрометация одного инстанса = полный контроль над рабочей станцией и всеми подключёнными сервисами. Для managed-сервисов (Claude Code, Cursor) этот риск несёт вендор. Для self-hosted -- пользователь.

Минимальные меры:
- Reverse proxy с TLS и origin whitelist
- Network isolation (не выставлять gateway в публичный интернет)
- Sandbox для Computer Use (отдельный X11 display или контейнер)
- Регулярное обновление (security patches)
- Минимизация scope Computer Use (ограничение доступных приложений)
- Audit log всех tool calls (встроен в OpenClaw, но требует настройки retention)

Для enterprise-deployment: OpenClaw не прошёл SOC 2 или аналогичную сертификацию. Self-hosted deployment перекладывает compliance burden на пользователя. Managed alternatives (Claude Code, Cursor) -- проще для compliance, но дороже и с vendor lock-in.

### Сравнение с Claude Code: два подхода к агентности

| Аспект | OpenClaw | Claude Code |
|--------|----------|-------------|
| **Архитектура** | Gateway (daemon, always-on) | CLI/Session (запускается пользователем) |
| **Основной use case** | "Life OS" -- мессенджеры, automation, код | Coding agent |
| **Model lock-in** | Model-agnostic (8+ providers) | Claude-only (Anthropic) |
| **Deployment** | Self-hosted | Managed (Anthropic cloud) |
| **Security model** | Пользователь отвечает за всё | Вендор обеспечивает infra security |
| **Монетизация** | Free (open-source) | Subscription / API billing |
| **Computer Use** | xdotool + scrot (X11) | Anthropic Computer Use API |
| **Multi-channel** | 25+ каналов native | Channels (Telegram, Discord, Slack) с апреля 2026 |

Claude Code Channels (апрель 2026) закрыл ключевое преимущество OpenClaw -- multi-channel доступ. Оставшиеся дифференциаторы OpenClaw: model-agnostic, self-hosted, open-source.

Для пользователей, выбирающих между OpenClaw и Claude Code:
- **Claude Code** -- если основная задача coding, есть бюджет на подписку, нужна стабильность managed-сервиса
- **OpenClaw** -- если нужен self-hosted, model-agnostic, multi-channel agent; готовность к self-maintenance и security hardening
- **Оба** -- возможно параллельное использование: Claude Code для coding, OpenClaw для automation и мессенджеров (разные ниши)

Выбор зависит от приоритетов: data sovereignty и model freedom (OpenClaw) vs stability и ecosystem depth (Claude Code). Для privacy-sensitive сценариев (медицина, финансы, government) self-hosted OpenClaw с локальными моделями -- единственный вариант из двух.

## Что следить дальше

- **Community governance** -- появится ли steering committee или foundation после ухода Steinberger'а
- **Стабильность без Claude revenue** -- OpenClaw был бесплатен для пользователей за счёт проксирования подписок; новая модель монетизации не определена
- **Security posture** -- self-hosted agent с Computer Use = повышенная attack surface; ожидать новые CVE
- **Конкуренция с Claude Code Channels** -- Anthropic выпустил native multi-channel интеграцию (Telegram, Discord, Slack); часть use cases OpenClaw закрыта официальным продуктом
- **Kimi 2.5 как primary backend** -- зависимость от Moonshot AI вместо Anthropic; диверсификация или новая вендорозависимость?
- **GPT-5 deep integration** -- Steinberger в OpenAI может ускорить оптимизацию под GPT-5 family
- **Локальные модели** -- рост quality open-source моделей (Qwen, DeepSeek, Llama) может сделать self-hosted вариант конкурентоспособным без API-зависимости
- **MCP ecosystem** -- 97 млн установок MCP-серверов (апрель 2026); OpenClaw поддерживает MCP, что даёт доступ к растущему каталогу интеграций без собственной разработки

Вероятные сценарии на конец 2026:

1. **Стабилизация** -- community формирует governance, проект находит niche (self-hosted multi-channel agent для privacy-conscious пользователей)
2. **Угасание** -- без ведущего maintainer'а и без Claude revenue проект теряет momentum, community мигрирует на Claude Code Channels и аналоги
3. **Fork / acquisition** -- крупный vendor (не Anthropic, не OpenAI) форкает или спонсирует проект для собственной экосистемы

### Итоговая оценка проекта (апрель 2026)

| Критерий | Оценка | Комментарий |
|----------|--------|-------------|
| **Техническая архитектура** | Сильная | Gateway + model-agnostic + MCP -- грамотный стек |
| **Community health** | Под вопросом | Уход создателя, отсутствие governance |
| **Security posture** | Слабая | CVE-2026-25253, self-hosted без hardening guidelines |
| **Sustainability** | Под вопросом | Нет revenue model, нет foundation backing |
| **Competitive position** | Ослабевает | Claude Code Channels закрыл multi-channel gap |
| **Innovation** | Средняя | Computer Use + 25 channels -- сильно; но нет аналога Agent Teams |

Проект остаётся технически интересным, но организационно хрупким. Ключевой вопрос ближайших месяцев: сформируется ли устойчивое community governance или проект станет ещё одним archived repository.

## Ссылки на источники

- [TechCrunch: Anthropic banned OpenClaw's creator](https://techcrunch.com/2026/04/10/anthropic-temporarily-banned-openclaws-creator-from-accessing-claude/)
- [HN: Anthropic no longer allowing Claude Code subscriptions for OpenClaw](https://news.ycombinator.com/item?id=47633396)
- [TNW: Anthropic blocks OpenClaw in cost crackdown](https://thenextweb.com/news/anthropic-openclaw-claude-subscription-ban-cost)
- [Axios: Anthropic blocks third-party tools](https://www.axios.com/2026/04/06/anthropic-openclaw-subscription-openai)
- [DataCamp: OpenClaw vs Claude Code](https://www.datacamp.com/blog/openclaw-vs-claude-code)
- [VentureBeat: Claude Code Channels response](https://venturebeat.com/orchestration/anthropic-just-shipped-an-openclaw-killer-called-claude-code-channels)
- [MindStudio: OpenClaw vs Claude Code Channels vs Managed Agents](https://www.mindstudio.ai/blog/openclaw-vs-claude-code-channels-vs-managed-agents-2026)
- [Blink: Anthropic blocks OpenClaw](https://blink.new/blog/anthropic-blocks-openclaw-claude-what-to-do-2026)
- [RoboRhythms: what now?](https://www.roborhythms.com/anthropic-blocks-openclaw-claude-subscription-2026/)

## Связанные статьи

- [README.md](README.md) -- профиль OpenClaw
- [computer-use-guide.md](computer-use-guide.md) -- Computer Use подробно
- [models-providers.md](models-providers.md) -- провайдеры и модели
- [Claude Code: news.md](../claude-code/news.md) -- хроника конкурента
- [Тренды AI-агентов](../../trends.md) -- контекст индустрии
- [Хроника AI-агентов](../../news.md) -- общая хроника
- [Коммерческие агенты](../../commercial.md) -- OpenClaw в контексте рынка
- [Сравнительная таблица](../../comparison.md) -- табличное сравнение агентов
