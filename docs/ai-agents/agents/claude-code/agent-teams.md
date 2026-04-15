# Agent Teams: стратегия использования

Детальное руководство по использованию Agent Teams в Claude Code. Когда включать, как декомпозировать задачу, какие модели выбирать, готовые playbooks для типовых сценариев.

Agent Teams запущены 5 февраля 2026 совместно с Claude Opus 4.6. Доступны через `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=true`. Хроника релиза и контекст -- в [news.md](news.md#5-февраля-2026----agent-teams).

## Что это

**Agent Teams** -- механизм координации нескольких независимых Claude Code сессий. В отличие от subagents (которые живут внутри одной сессии), Teams -- это **несколько параллельных сессий**, которые:

- Разделяют общий **shared task list**
- Могут **обмениваться сообщениями** напрямую (inter-agent messaging)
- Управляются **team lead** сессией, которая orchestrates работу
- Работают **параллельно**, каждая в изолированном контексте

Это качественно другой уровень автоматизации по сравнению с subagents.

## Когда включать Teams

Teams -- дорогой инструмент (N × токены одной сессии + overhead координации). Стоит использовать только когда задача соответствует всем критериям:

| Признак задачи | Почему Team помогает |
|----------------|----------------------|
| **Параллелизуется** | 3 независимых куска работы -- 3 агента параллельно, в 3x быстрее |
| **Занимает 4+ часа** одной сессии | Риск контекст-дрифта падает если каждый subagent имеет узкий фокус |
| **Разные модули/сервисы** | Изоляция контекстов: один агент не смешивает детали frontend и backend |
| **Повторяющийся паттерн** по многим единицам | "Обнови все 15 микросервисов" = 1 planner + 15 workers |

## Когда НЕ включать Teams

| Ситуация | Почему не помогает |
|----------|---------------------|
| Задача **последовательная** по природе (A зависит от B зависит от C) | Team не ускоряет, только добавляет overhead координации |
| Задача **короткая** (< 30 минут) | Setup team стоит дороже самой работы |
| **Неясные требования** | Team хорош для execution, для research/exploration -- одна сессия лучше |
| Не нужна полная координация | Subagents в одной сессии часто достаточно |

## Subagents vs Agent Teams: главный вопрос

Главная концептуальная путаница. Вот в чём разница:

| Аспект | Subagents | Agent Teams |
|--------|-----------|-------------|
| **Уровень** | Внутри **одной** сессии Claude Code | **Несколько** независимых сессий |
| **Координация** | Main agent делегирует и ждёт результата | Team lead + async messaging + shared task list |
| **Контекст** | Форкается из main, имеет родительский CLAUDE.md | Полностью изолирован, свой CLAUDE.md на каждую |
| **Параллелизм** | Ограниченный (main чаще всего ждёт subagent) | Настоящий параллелизм, все сессии работают одновременно |
| **Тулсет** | Наследует от main, может быть ограничен через `disallowedTools` | Независимый на каждую сессию, задаётся в YAML |
| **Коммуникация между единицами** | Через return value | Через messaging API (inbox/outbox) |
| **Когда использовать** | Декомпозиция в рамках одной задачи | Распределение крупной работы на параллельные потоки |

**Правило**: сначала пробуй subagents. Если нужна реальная параллельность И >1 час работы И >3 независимых потока -- тогда Teams.

## Три рабочих паттерна

### Паттерн 1: Planner + Executors (самый частый)

Один team lead декомпозирует задачу и делегирует independent executors.

```
         Team Lead (Opus 4.6)
              |
    reads repo, creates task list
              |
    +---------+---------+---------+
    |         |         |         |
  frontend  backend    db       docs
  executor  executor  executor  executor
 (Sonnet)  (Sonnet)  (Sonnet)  (Sonnet)
 /web      /api      /db       /docs
    |         |         |         |
    +---------+---------+---------+
              |
       Team Lead merges results
              |
        Integration tests
```

Каждый executor изолирован, не знает про другие модули. Lead собирает результаты. Подходит для:
- Feature-development в monorepo
- Добавление новой возможности, которая затрагивает несколько слоёв
- Рефакторинг кода с чёткой модульной структурой

### Паттерн 2: Parallel scan + single writer

Разведка параллельно, изменения последовательно.

```
         Team Lead (Opus)
              |
   +----------+----------+----------+
   |          |          |          |
scan-1    scan-2     scan-3     scan-4
/auth    /billing   /notif    /payment
(read-only)
   |          |          |          |
   +----------+----------+----------+
              |
       Lead consolidates findings
              |
          writer-agent
   (applies patch sequentially)
```

Полезно для поиска-и-исправления паттернов. Избегает merge-конфликтов -- писать может только один агент.

Подходит для:
- Security audit (scan for vulnerabilities → fix)
- Dependency upgrade (поиск всех мест использования → обновление)
- API migration (найти deprecated calls → заменить)
- Performance profiling (найти hot paths → оптимизация)

### Паттерн 3: Specialist team

Каждый агент выполняет свою роль в PDCA-цикле разработки.

```
       Architect (Opus 4.6)
              |
      designs, makes trade-offs
              |
              v
     Implementor (Sonnet 4.5)
              |
      writes code per spec
              |
              v
      Tester (Sonnet 4.5)    [параллельно с Implementor]
              |
      writes tests
              |
              v
      Reviewer (Opus 4.6)
              |
      final review before merge
              |
              v
         Team Lead
         final merge
```

Самый дорогой режим -- каждая стадия отдельная сессия. Качество выше single-agent, но стоимость ~3-5x. Для:
- Production-критичного кода
- Security-sensitive changes
- Архитектурных рефакторингов
- Long-horizon multi-week проектов

## Разбиение задачи под Team

### Хорошее разбиение

- Каждая подзадача **независима** (не требует результата другой)
- У каждой **свой скоуп файлов** (agent-A: `/frontend/**`, agent-B: `/backend/**`)
- Финальный синтез делает team lead, не executors
- **Чёткие контракты** между модулями (API schemas, type definitions)
- **Shared reference** (design doc, спецификация) доступен всем агентам

### Плохое разбиение (типичные ошибки)

| Ошибка | Почему плохо | Как исправить |
|--------|--------------|---------------|
| "Агент A пишет feature, агент B пишет тесты" | Тесты зависят от интерфейсов кода → sequential | Объединить в одного агента |
| "Агент A мигрирует БД, агент B обновляет модели" | Модели не работают без миграции | Выполнять sequentially или dispatch |
| "Несколько агентов трогают общий файл" | Merge-конфликт неизбежен | Выделить один writer на файл |
| "Агенты делают API calls к внешнему сервису параллельно" | Rate limits, race conditions | Один agent делает API, другие ждут |
| Нечёткие границы скоупа | "Кто пишет роутинг -- frontend или backend?" | Определить scope заранее |

### Decomposition checklist

Перед запуском team, ответь на вопросы:

1. Сколько независимых задач? (если 1 -- не team, 2 -- subagents, 3+ -- возможно team)
2. Есть ли зависимости между задачами? (если да -- pattern 2, если нет -- pattern 1)
3. Какой файловый скоуп у каждой задачи? (не должен пересекаться)
4. Нужен ли общий контекст? (если да -- team lead держит, передаёт executors через prompt)
5. Как будет выглядеть final synthesis? (что делает lead после завершения всех executors)

## Модели для Team

Баланс цена/качество критичен -- Team потребляет токены в 3-5x больше single-agent.

| Роль | Рекомендуемая модель | Почему |
|------|----------------------|--------|
| **Team Lead** | **Opus 4.6** | 1M контекст (держит весь task list), hybrid reasoning (стратегические решения), лучший на агентных задачах |
| **Architect** | Opus 4.6 | Design-качество критично, reasoning нужен |
| **Implementor** | **Sonnet 4.5** | Быстрее, дешевле, контекст 200K достаточен для узкого файлового скоупа |
| **Tester** | Sonnet 4.5 | Не требует reasoning, pattern-matching достаточен |
| **Reviewer** | Opus 4.6 | Final gate, поэтому стоит заплатить за качество |
| **Scanner** (read-only) | Sonnet 4.5 | Быстрый scan, простая задача |
| **Writer** (applies patches) | Sonnet 4.5 | Точность важнее скорости, но не нужен Opus |

**Бюджет**: Team из 5 агентов (1 Opus lead + 4 Sonnet executor) ≈ **5x токены single-agent**. На Opus Max plan ($200/мес) включено много -- обычно хватает на 10-20 team-задач в месяц.

## Настройка

### Включение фичи

В `settings.json` или переменной окружения:

```bash
# Вариант 1: env
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=true

# Вариант 2: settings.json
{
  "experimental": {
    "agentTeams": true
  }
}
```

### Code Kit v5.0 YAML

С апреля 2026 есть декларативный DSL для team configurations. Файлы лежат в `.claude/teams/` проекта.

**Простой feature-dev team**:

```yaml
# .claude/teams/feature-dev.yaml
name: feature-dev
description: "Feature development across monorepo"

lead:
  model: opus-4.6
  prompt: |
    You are team lead for feature development. Read the CLAUDE.md,
    understand the feature request, decompose into tasks by module,
    delegate to executors, wait for completion, run integration tests.

executors:
  - name: frontend
    model: sonnet-4.5
    scope: "src/web/**"
    tools: [edit, bash, read]
    prompt: "Implement frontend portion per task spec. Use React patterns."

  - name: backend
    model: sonnet-4.5
    scope: "src/api/**"
    tools: [edit, bash, read]
    prompt: "Implement API endpoints per task spec. Follow REST conventions."

  - name: db
    model: sonnet-4.5
    scope: "src/db/**, migrations/**"
    tools: [edit, bash, read]
    prompt: "Create migrations and models per task spec."
```

**Multi-service migration team**:

```yaml
# .claude/teams/deps-upgrade.yaml
name: deps-upgrade
description: "Upgrade dependency across all services"

lead:
  model: opus-4.6
  prompt: |
    Upgrade dependency X from vN to vN+1 across all services.
    First scan all services for usage, then dispatch workers
    to update each service. Verify tests pass.

executors:
  - name: auth-service
    model: sonnet-4.5
    scope: "services/auth/**"
  - name: billing-service
    model: sonnet-4.5
    scope: "services/billing/**"
  - name: notification-service
    model: sonnet-4.5
    scope: "services/notification/**"
  # ... ещё N сервисов
```

**Specialist team для critical refactoring**:

```yaml
# .claude/teams/critical-refactor.yaml
name: critical-refactor
description: "PDCA refactoring for production-critical code"

lead:
  model: opus-4.6
  role: project-manager

agents:
  - name: architect
    model: opus-4.6
    role: design
    prompt: "Design refactoring approach, document trade-offs."

  - name: implementor
    model: sonnet-4.5
    role: coding
    depends_on: [architect]
    prompt: "Implement per architect's spec."

  - name: tester
    model: sonnet-4.5
    role: testing
    parallel_with: [implementor]
    prompt: "Write tests per architect's spec interface."

  - name: reviewer
    model: opus-4.6
    role: review
    depends_on: [implementor, tester]
    prompt: "Final review, block merge if issues."
```

### Запуск

```bash
# По имени team из .claude/teams/
claude-code --team feature-dev "implement search UI with API endpoint"

# С override модели для lead
claude-code --team feature-dev --lead-model opus-4.6 "..."

# Dry-run -- посмотреть декомпозицию без выполнения
claude-code --team feature-dev --dry-run "..."
```

## Channels integration для long-running teams

Если Team работает >1 часа (типично для серьёзных задач) -- подключить [Channels](news.md#q1-2026----channels) на Telegram/Discord/Slack.

Сценарий: Team запущена на Remote Control сервере, работает ночью. При срабатывании approval-prompt (например, "применить миграцию в prod?") уведомление летит на телефон. Тапаешь approve/deny, Team продолжает.

Настройка в YAML:

```yaml
name: feature-dev
channels:
  - type: telegram
    chat_id: "@my-dev-channel"
    approve_on: [prod_migration, force_push, destroy_resource]
  - type: slack
    channel: "#claude-notifications"
    notify_on: [task_complete, task_error]
```

## Troubleshooting

### "Team lead hangs indefinitely"

**Симптом**: Team Lead застрял, executors ждут команды, ничего не происходит.

**Причины**:
- Lead model слишком слабая -- не справляется с декомпозицией (смени на Opus 4.6)
- Task list слишком сложный -- упрости вход
- Ошибки в YAML -- проверь `claude-code --team X --dry-run`

**Решение**: прервать (`Ctrl+C`), проверить логи в `~/.claude/logs/teams/<session-id>/`, при необходимости -- увеличить `maxTurns` для lead.

### "Executors конфликтуют на общем файле"

**Симптом**: Два executor'а одновременно редактируют `shared/config.ts`, один перезаписывает изменения другого.

**Причина**: Плохое разбиение scope.

**Решение**:
- Переопределить scope -- запретить редактирование shared файлов executors
- Либо сделать shared файл задачей team lead (merge после executors)
- Либо использовать Pattern 2 (parallel scan + single writer)

### "Agent context overflow"

**Симптом**: Executor получает "context window exceeded" error после продолжительной работы.

**Причина**: Executor Sonnet 4.5 имеет 200K контекст. На сложных файлах + multiple turns легко выбивается.

**Решение**:
- Сузить scope executor'а (меньше файлов в контексте)
- Использовать Opus 4.6 для executor (1M context)
- Разбить на более мелкие подзадачи

### "Цена улетела в небо"

**Симптом**: Один Team-run стоил $50+.

**Причины**:
- 5 executors × Opus 4.6 на длинной задаче = $$$$
- Много turns из-за плохой декомпозиции
- Circular dependencies -- executors переделывают работу друг друга

**Решение**:
- Строгий бюджет: `--max-cost-usd 20` (hard stop)
- Сменить модели executors на Sonnet 4.5
- Проверить декомпозицию на dry-run перед запуском

### "Inter-agent messaging не работает"

**Симптом**: Executor A шлёт сообщение Executor B, но B не видит.

**Причина**: Неправильно настроен inbox, либо B уже завершил работу.

**Решение**:
- Проверить `--enable-messaging` в конфиге
- Использовать `parallel_with:` вместо `depends_on:` если общение нужно в реальном времени
- Лог messaging: `~/.claude/logs/teams/<id>/messages.jsonl`

## Decision tree: одна сессия / subagents / Team

```
Задача требует >3 часов работы?
├── Нет → Одна сессия или subagents
│         │
│         └── Есть ли 2-3 независимые подзадачи?
│              ├── Нет → Одна сессия
│              └── Да → Subagents в одной сессии
│
└── Да → Можно ли разбить на независимые модули?
          │
          ├── Нет → Одна долгая сессия (context shifts)
          │
          └── Да → Есть ли >3 параллельных потока?
                    │
                    ├── Нет → Subagents
                    │
                    └── Да → Нужна ли reviewer/architect роль?
                              │
                              ├── Нет → Paттерн 1 (Planner+Executors)
                              │
                              └── Да → Паттерн 3 (Specialist team)
```

## Scenario playbook

### Playbook 1: Refactor monorepo (10+ services)

**Задача**: Миграция `axios` → `fetch` во всех микросервисах.

**Решение**:
1. Создать `.claude/teams/axios-to-fetch.yaml` по шаблону deps-upgrade
2. Executors -- по одному на сервис
3. Lead сначала scan (Pattern 2), затем dispatch writers
4. Каждый executor:
   - Найти все `axios.*` calls
   - Заменить на `fetch` с эквивалентным API
   - Запустить tests
   - Commit с сообщением `chore(<service>): migrate axios to fetch`
5. Lead собирает PR со всеми commits

**Ожидаемое время**: 2-4 часа на 10 сервисов (vs ~10-15 часов single-agent).
**Стоимость**: $15-30 (API Sonnet).

### Playbook 2: Multi-service security audit + patch

**Задача**: Audit для OWASP Top 10 + auto-patch найденных проблем.

**Решение (Pattern 2)**:
1. Parallel scanners (read-only) по services/*
2. Каждый сканер находит vulnerabilities, репортит в shared list
3. Lead приоритизирует (critical > high > medium)
4. Writer последовательно применяет patches для critical/high
5. Lead генерирует security report

**Ожидаемое время**: 4-8 часов (depends on codebase size).
**Стоимость**: $20-50.

### Playbook 3: Long-horizon feature development

**Задача**: Добавить real-time notifications (WebSocket + UI + DB migrations + tests).

**Решение (Pattern 3 Specialist team)**:
1. Architect проектирует: WebSocket protocol, schema, UI components
2. Implementor (parallel with Tester) пишет код по спеке
3. Tester пишет tests parallel
4. Reviewer проверяет security и performance
5. Lead merge, integration tests

**Ожидаемое время**: 6-12 часов (одна сессия не справилась бы -- слишком много контекста).
**Стоимость**: $40-80.

### Playbook 4: Overnight AutoDream задача

**Задача**: "Обнови все Python-зависимости до latest compatible versions, прогони тесты, создай PR".

**Решение**:
1. Запустить team с Channels integration на Telegram
2. Lead (Opus) разбивает по requirements*.txt файлам
3. Executors обновляют каждый файл, запускают тесты
4. При failing tests -- approval prompt в Telegram "Откатить обновление X или фиксить вручную?"
5. Утром -- готовый PR или список проблем для review

**Ожидаемое время**: 4-8 часов ночью.
**Стоимость**: $10-20 (большинство -- Sonnet executors).

## Антипаттерны

1. **"Team из 10 агентов для всего"** -- overhead координации съест выигрыш параллелизма. Оптимум 3-5 агентов.

2. **"Один Opus для всех agents"** -- дорого (5x стоимость Sonnet). Lead = Opus, executors = Sonnet -- правильный баланс.

3. **"Не проверять промежуточные результаты"** -- если Lead плохо спланировал, все executor'ы пойдут не туда. Team-mode требует **лучшей декомпозиции**, чем single-agent.

4. **"Team для exploration"** -- когда сам не знаешь что делать. Team хороша для **known execution**, не для research. Сначала single-agent прояснит направление.

5. **"Игнорировать merge conflicts"** -- если два executor'а трогают один файл, будет конфликт. Сначала -- корректное разбиение scope.

6. **"Без CLAUDE.md на уровне team"** -- executors не знают project conventions. Обязательно держать CLAUDE.md в репо + иметь team-level hints в YAML prompt.

7. **"Запускать на проде без sandbox"** -- Teams экспериментальная фича. Для production-задач обязательно `--sandbox` или Remote Control с ограниченными permissions.

## Note для Strix Halo платформы

Agent Teams **не работает с локальными моделями**. Это проприетарная Claude Code feature, завязанная на Anthropic API (Opus 4.6 и Sonnet 4.5). Нельзя заменить lead/executors на local Qwen3-Coder Next или Devstral 2.

Альтернативы для local setup'ов:
- **[Kilo Code Orchestrator](../kilo-code.md)** -- мульти-агентный режим с поддержкой local models
- **[opencode](../opencode.md)** + несколько параллельных instances через разные terminal sessions
- **Кастомный bash-скрипт**: несколько `llama-server` с разными моделями + общий file-based task queue

Для **hybrid setup** (local + API) можно использовать:
- Claude Code с BYOK для lead (Opus 4.6 API)
- Local llama-server как backend для несложных executors (через OpenAI-compat endpoint Sonnet-заменителя)

Такой mixed setup требует ручной интеграции, нет out-of-box поддержки.

## Связанные статьи

- [README.md](README.md) -- профиль Claude Code
- [news.md](news.md) -- хроника фич, контекст Agent Teams в 2026
- [skills-guide.md](skills-guide.md) -- как писать свои Skills
- [hooks-guide.md](hooks-guide.md) -- Hooks для safety (критично в Team-режиме)
- [mcp-setup.md](mcp-setup.md) -- MCP-серверы (Teams могут делить общие MCP)
- [../../trends.md](../../trends.md) -- multi-agent как тренд индустрии 2026
- [Официальная документация Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Statья alexop.dev: From Tasks to Swarms](https://alexop.dev/posts/from-tasks-to-swarms-agent-teams-in-claude-code/)
