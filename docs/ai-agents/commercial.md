# Платные AI-агенты

Коммерческие агенты -- managed-решения с проприетарными моделями,
инфраструктурой и поддержкой. Обычно мощнее open-source аналогов,
но стоят $20-200+/мес.


## Содержание

- [Claude Code](#claude-code)
- [OpenAI Codex](#openai-codex)
- [Cursor](#cursor)
- [Windsurf](#windsurf)
- [Devin](#devin)
- [Junie](#junie)
- [GitHub Copilot](#github-copilot)
- [Amazon Q Developer](#amazon-q-developer)
- [Gemini Code Assist / CLI](#gemini-code-assist--cli)


## Claude Code

**Разработчик**: Anthropic
**Тип**: CLI + IDE расширения (VS Code, JetBrains) + web (claude.ai/code)

### Возможности

- Agentic search: автоматически исследует кодовую базу без ручного указания контекста
- 1M токенов контекста (Opus 4.6) -- полный monorepo в одном сеансе
- Sub-agents: специализированные агенты для параллельных подзадач
- Multi-agent (Claude Code agent team): несколько агентов работают одновременно
- Hooks: pre/post-action триггеры для enforce стандартов
- MCP (Model Context Protocol): расширяемость через внешние серверы
- CLAUDE.md: проектные инструкции, загружаемые автоматически

### Стоимость

```
План          | Цена       | Лимиты
--------------|------------|---------------------------
Pro           | $20/мес    | Ограниченное использование
Max           | $100/мес   | 5x Pro usage
Max (1M ctx)  | $200/мес   | Opus 4.6 с 1M контекстом
API (BYOK)    | По токенам | Без лимитов
```

При активном использовании (8+ часов/день): $120-220/мес.

### Бенчмарки

```
Категория | Score
----------|------
Frontend  | 95.0%
Backend   | 38.6%
Overall   | 55.5%
```

Frontend -- лучший в индустрии. Backend -- слабое место,
связано с тенденцией к verbose-решениям в серверном коде.

### Плюсы и минусы

```
+ Лучший frontend score (95%)
+ 1M контекст -- видит весь проект
+ Multi-agent для параллельных задач
+ CLI + IDE + web -- гибкость интерфейса
+ CLAUDE.md -- проектные инструкции из коробки
+ MCP -- расширяемость
- Слабый backend (38.6%)
- Стоимость при активном использовании
- Иногда избыточные правки (over-engineering)
```


## OpenAI Codex

**Разработчик**: OpenAI
**Тип**: Облачный агент (через ChatGPT или API)

### Возможности

- Облачное выполнение: каждая задача в изолированном sandbox (Docker)
- Параллельные задачи: несколько sandbox-ов одновременно
- Модель codex-1: специализирована для кодинга
- Доступ к terminal, file system, package managers внутри sandbox
- Интеграция с GitHub: создание PR, ревью

### Стоимость

```
План          | Цена      | Доступ
--------------|-----------|---------------------------
ChatGPT Pro   | $200/мес  | Codex включён
ChatGPT Team  | $30/мес   | Ограниченный доступ
API           | По токенам| codex-1 endpoint
```

### Бенчмарки

```
Категория | Score
----------|------
Frontend  | 80.0%
Backend   | 58.5%
Overall   | 67.7%
Runtime   | 426 сек (среднее)
Tokens    | 258K (среднее)
```

Лучший overall score в индустрии. Лидер по backend-задачам.

### Плюсы и минусы

```
+ Лучший overall (67.7%) и backend (58.5%) score
+ Параллельные sandbox-ы -- несколько задач одновременно
+ Детерминированность на multi-step задачах
+ GitHub интеграция из коробки
- Дорого: $200/мес (ChatGPT Pro)
- Облачный: код уходит на серверы OpenAI
- Нет локального режима
- Медленный (426 сек в среднем на задачу)
```


## Cursor

**Разработчик**: Anysphere
**Тип**: IDE (fork VS Code)

### Возможности

- Agent mode: автономное multi-file редактирование по описанию
- Background Agents: агент работает в фоне, пока разработчик занят другим
- Supermaven autocomplete: быстрое автодополнение (приобретён)
- Composer: интерфейс для multi-file задач
- Tab: контекстное автодополнение с предсказанием следующего действия

### Стоимость

```
План    | Цена      | Возможности
--------|-----------|---------------------------
Hobby   | Бесплатно | 2000 completions, 50 slow requests
Pro     | $20/мес   | Unlimited completions + agent
Team    | $40/мес   | Admin, shared settings
```

### Плюсы и минусы

```
+ $20/мес -- доступно
+ Background Agents -- параллельная работа
+ Supermaven -- быстрый autocomplete
+ Самое большое community среди AI IDE
+ Знакомый VS Code интерфейс
- Только VS Code (fork) -- нет поддержки JetBrains, vim
- Нет CLI-режима (терминальный workflow)
- Закрытый код
- Проприетарные модели для autocomplete
```


## Windsurf

**Разработчик**: Codeium (ранее OpenInterpreter)
**Тип**: IDE-плагин (40+ IDE: VS Code, JetBrains, Vim, Xcode)

### Возможности

- Cascade: agentic assistant с multi-step планированием
- SWE-grep: поиск по коду в 10x быстрее стандартного agentic search
- Codemaps: визуальные карты кодовой базы с AI-аннотациями
- Параллельные сессии Cascade (Wave 13, 2026)
- Cascade Hooks: pre/post-action триггеры (линтеры, стандарты)
- Собственные модели: SWE-1, SWE-1.5, SWE-1-mini

### Стоимость

```
План    | Цена      | Возможности
--------|-----------|---------------------------
Free    | Бесплатно | Ограничено
Pro     | $20/мес   | Полный доступ
Team    | $40/мес   | Admin, policies
Max     | $200/мес  | Максимум ресурсов
```

### Плюсы и минусы

```
+ 40+ IDE: VS Code, JetBrains, Vim, Xcode
+ SWE-grep: быстрый контекстный поиск
+ Codemaps: визуализация кодовой базы
+ Cascade Hooks: enforce стандартов
+ Собственные SWE-модели
- Менее известен, чем Cursor
- SWE-1 уступает Claude/GPT на сложных задачах
- Относительно новый продукт
```


## Devin

**Разработчик**: Cognition AI
**Тип**: Облачный автономный агент

### Возможности

- Полностью автономный: планирует, кодит, дебажит, деплоит, мониторит
- Sandboxed среда: terminal + code editor + browser
- Dynamic re-planning: при проблемах меняет стратегию без вмешательства
- Параллельные Devin-ы: несколько агентов одновременно
- Slack-интеграция: ставить задачи через Slack
- 67% PR merge rate на типовых задачах

### Стоимость

```
План          | Цена         | ACU
--------------|-------------|---------------------------
Core          | $20/мес      | ACU по $2.25 (~15 мин работы)
Team          | $500/мес     | 250 ACU включено, доп. $2/шт
Enterprise    | Индивидуально| SaaS или VPC
```

1 ACU ~ 15 минут работы Devin. Час работы ~ $8-9.

### Плюсы и минусы

```
+ Максимальная автономность: полный цикл от задачи до PR
+ Dynamic re-planning при проблемах
+ Sandbox: безопасное выполнение
+ Slack-интеграция: задачи через чат
+ Параллельные агенты
- Дорого при регулярном использовании (ACU)
- Облачный: код на серверах Cognition
- Медленнее интерактивных агентов
- Не для пары-программирования: слишком автономный
- Качество сильно зависит от формулировки задачи
```


## Junie

**Разработчик**: JetBrains
**Тип**: IDE-агент (JetBrains) + CLI (beta, март 2026)

### Возможности

- Нативная интеграция с JetBrains IDE (IntelliJ, PyCharm, WebStorm...)
- Использует IDE inspections и тесты для верификации результата
- Режимы: code mode (пишет код), ask mode (объясняет)
- Автономное выполнение: план -> код -> тесты -> итерация
- Junie CLI (март 2026, beta): LLM-agnostic, работает из терминала

### Стоимость

```
План          | Цена        | Возможности
--------------|-------------|---------------------------
AI Pro        | $100/год    | Базовый Junie
AI Ultimate   | $300/год    | Полный Junie + больше кредитов
```

Кредитная система: agentic задачи расходуют кредиты.

### Бенчмарки

```
Категория | Score
----------|------
Frontend  | 85.0%
Backend   | 54.3%
Overall   | 63.5%
```

#2 overall в индустрии. Сильный backend (уступает только Codex).

### Плюсы и минусы

```
+ #2 overall (63.5%): сбалансированный frontend/backend
+ Нативная интеграция с JetBrains IDE
+ IDE inspections как верификация (не просто текст -- реальные проверки)
+ Относительно дешёвый ($100-300/год)
+ Junie CLI -- выход за пределы IDE
- Только JetBrains IDE (до Junie CLI)
- Кредитная система: расход непредсказуем
- Нет 1M контекста
- Junie CLI в beta
```


## GitHub Copilot

**Разработчик**: Microsoft / GitHub
**Тип**: IDE-расширение + CLI + Agent mode

### Возможности

- Agent mode: автономные multi-file edits в VS Code
- Coding Agent: автоматическое решение GitHub Issues (создаёт PR)
- Copilot Chat: диалог о коде
- CLI: `gh copilot` в терминале
- Поддержка: VS Code, JetBrains, Neovim, Azure DevOps

### Стоимость

```
План         | Цена      | Возможности
-------------|-----------|---------------------------
Individual   | $10/мес   | Copilot + Chat
Business     | $19/мес   | + Policies, audit
Enterprise   | $39/мес   | + Knowledge bases, fine-tuning
Free         | Бесплатно | 2000 completions/мес, 50 agent msgs
```

### Плюсы и минусы

```
+ 37% рынка -- самый массовый
+ $10/мес -- самый доступный платный агент
+ Coding Agent: PR из Issues автоматически
+ Широкая IDE поддержка
+ GitHub интеграция (PR, Issues, Actions)
- Agent mode слабее конкурентов
- Контекстное окно меньше, чем у Claude/Gemini
- Привязка к экосистеме Microsoft
- Качество зависит от модели (GPT-4o, не лучшая для кодинга)
```


## Amazon Q Developer

**Разработчик**: Amazon Web Services
**Тип**: CLI + IDE (VS Code, JetBrains)

### Возможности

- CLI agent: чтение/запись файлов, bash, AWS API -- всё из терминала
- @workspace: анализ всего проекта (auth flows, dependencies)
- MCP server support: расширяемость через Model Context Protocol
- AWS-нативный: IAM, CloudFormation, CDK, Lambda -- глубокая интеграция
- Модель: Claude 3.7 Sonnet (через Amazon Bedrock)

### Стоимость

```
План          | Цена      | Возможности
--------------|-----------|---------------------------
Free          | $0        | Ограниченные completions
Pro           | $19/мес   | Полный доступ
```

### Плюсы и минусы

```
+ AWS-нативный: IAM, CloudFormation, CDK из коробки
+ $19/мес -- доступно
+ Free tier для старта
+ MCP поддержка
+ Claude 3.7 Sonnet -- хорошая модель
- Заточен под AWS (вне AWS -- менее полезен)
- Менее универсален, чем Claude Code / Cursor
- Нет собственных моделей (зависимость от Anthropic)
```


## Gemini Code Assist / CLI

**Разработчик**: Google
**Тип**: CLI + IDE (VS Code, JetBrains) + Cloud

### Возможности

- Gemini CLI: терминальный агент
- 1M токенов контекста (Flash и Pro) -- наравне с Claude Opus
- Бесплатный tier: 1000 запросов/день (Flash модели)
- Google Cloud интеграция: Cloud Run, GKE, BigQuery
- Pro модели: за подписку

### Стоимость

```
План          | Цена      | Модели
--------------|-----------|---------------------------
Free          | $0        | Flash (1000 req/день)
Paid          | $19+/мес  | Pro + Flash
Enterprise    | Custom    | Полная интеграция
```

### Плюсы и минусы

```
+ 1000 запросов/день бесплатно (Flash)
+ 1M контекст -- весь проект в одном сеансе
+ Google Cloud интеграция
+ CLI + IDE
- Flash модели слабее Claude Opus / GPT-4o
- Pro модели только за подписку
- Экосистема менее зрелая, чем у Copilot / Claude Code
- Частые изменения API и pricing
```


## Связанные статьи

- <-- [AI-агенты: обзор](README.md)
- --> [Открытые агенты](open-source.md)
- [Сравнение](comparison.md)
