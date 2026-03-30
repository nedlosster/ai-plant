# Открытые AI-агенты

Open-source агенты: BYO API key (или локальная модель), self-hosted,
без vendor lock-in. Качество зависит от выбранной модели.
Основное преимущество -- privacy и контроль.


## Содержание

- [Aider](#aider)
- [OpenCode](#opencode)
- [Hermes Agent](#hermes-agent)
- [Cline](#cline)
- [Roo Code](#roo-code)
- [Continue](#continue)
- [OpenHands](#openhands)
- [SWE-agent](#swe-agent)
- [Goose](#goose)
- [Общие плюсы и минусы](#общие-плюсы-и-минусы)


## Aider

**Разработчик**: Paul Gauthier
**GitHub**: 39K stars, 4.1M installs
**Лицензия**: Apache 2.0
**Интерфейс**: CLI (терминал)

### Ключевые особенности

- **Git-first**: каждая AI-правка автоматически коммитится с описательным сообщением
- Architect mode: отдельная модель планирует, другая реализует
- Linting + testing loop: запускает линтер и тесты, итерирует по ошибкам
- 15B токенов/неделю обрабатывается через Aider глобально
- Поддержка любого OpenAI-совместимого API (локальные модели, llama-server)
- Карта репозитория (repo map): автоматическое индексирование кодовой базы

### Использование с локальными моделями

```bash
aider \
    --model openai/qwen2.5-coder-32b \
    --openai-api-base http://<SERVER_IP>:8080/v1 \
    --openai-api-key dummy
```

### Плюсы и минусы

```
+ Git auto-commit: каждая правка -- reviewable коммит
+ Architect mode: разделение планирования и реализации
+ Зрелый проект (2+ лет), стабильный
+ Отличная поддержка локальных моделей
+ Активное развитие, еженедельные релизы
- Только CLI (нет GUI/TUI)
- Нет параллельных агентов
- Repo map медленный на больших проектах
- Конфигурация через env/CLI флаги (нет config-файла из коробки)
```


## OpenCode

**Разработчик**: Community
**GitHub**: 120K+ stars, 5M+ разработчиков/мес
**Лицензия**: MIT
**Интерфейс**: TUI + Desktop + IDE extensions

### Ключевые особенности

- Polished TUI (Terminal User Interface): не просто CLI, а интерактивный интерфейс
- Параллельные агенты: несколько агентов на одном проекте одновременно
- Shareable session links: делиться сессией для пары-программирования
- Desktop app, IDE extension, CLI -- выбор интерфейса
- Поддержка десятков провайдеров и локальных моделей
- Privacy-first: никакие данные не отправляются на серверы OpenCode

### Использование с локальными моделями

```bash
opencode --provider openai-compat \
    --api-base http://<SERVER_IP>:8080/v1 \
    --model qwen2.5-coder-32b
```

### Плюсы и минусы

```
+ 120K stars -- самый популярный open-source агент
+ TUI + Desktop + IDE -- три интерфейса
+ Параллельные агенты
+ Shareable sessions
+ Privacy: ноль телеметрии
+ Быстрое развитие
- Молодой проект (стартовал конец 2024)
- TUI менее стабилен, чем CLI Aider
- Нет git auto-commit (как у Aider)
- Документация отстаёт от развития
```


## Hermes Agent

**Разработчик**: Nous Research
**GitHub**: Open source
**Лицензия**: Open source
**Интерфейс**: CLI (TUI) + Telegram + Discord + Slack + WhatsApp

### Ключевые особенности

- **Persistent memory**: запоминает проекты, решения, паттерны между сессиями
- **Auto-generated skills**: автоматически создаёт навыки из решённых задач
- 40+ встроенных инструментов: web search, file ops, terminal, image gen, TTS, vision
- 6 terminal backends: local, Docker, SSH, Daytona, Singularity, Modal
- Multi-platform: CLI, Telegram, Discord, Slack, WhatsApp -- единый контекст
- Self-hosted: установка за 60 секунд, без подписки

### Ключевая идея

Hermes -- не просто coding agent, а универсальный AI-агент с фокусом
на persistent memory. Решил задачу -- запомнил как. В следующий раз
использует накопленный опыт. Это ближе к "AI-ассистенту", чем к "кодинг-агенту".

### Плюсы и минусы

```
+ Persistent memory: не забывает решения
+ Multi-platform: CLI + мессенджеры
+ 40+ инструментов из коробки
+ 6 terminal backends (Docker, SSH, Modal...)
+ Полностью self-hosted, без лимитов
- Не специализирован на кодинге (универсальный агент)
- Менее зрелый, чем Aider/OpenCode
- Требует настройки memory и skills
- Документация в развитии
```


## Cline

**GitHub**: 36K+ stars, 5M installs
**Лицензия**: Apache 2.0
**Интерфейс**: VS Code extension

### Ключевые особенности

- VS Code расширение: agentic режим прямо в редакторе
- Zero markup: оплата только за токены модели, без наценки
- Любые модели: OpenAI, Anthropic, локальные через OpenAI API
- Plan mode: отдельное планирование перед реализацией
- Поддержка MCP серверов
- Human-in-the-loop: подтверждение каждого действия (настраиваемо)

### Плюсы и минусы

```
+ 5M installs -- массовый
+ Zero markup: только стоимость модели
+ Plan mode: контролируемый подход
+ MCP support
+ Настраиваемый human-in-the-loop
- Только VS Code
- Нет CLI-режима
- Менее автономен, чем Cursor/Claude Code
- UI может быть перегружен
```


## Roo Code

**GitHub**: Open source
**Лицензия**: Apache 2.0
**Интерфейс**: VS Code extension

### Ключевые особенности

- Режимы: Code (пишет), Architect (планирует), Debug (дебажит), Ask (отвечает)
- Community modes: пользователи создают свои режимы
- Любые модели через OpenRouter, API keys, локальные
- Задачи: multi-file edits, запуск тестов, terminal access

### Плюсы и минусы

```
+ Режимы: специализация под задачу
+ Community modes: расширяемость
+ Любые модели
- Только VS Code
- Менее известен, чем Cline
- Нет CLI
```


## Continue

**GitHub**: 20K+ stars
**Лицензия**: Apache 2.0 (open core)
**Интерфейс**: VS Code + JetBrains

### Ключевые особенности

- IDE extension: VS Code и JetBrains
- Privacy-first: self-hosted вариант, данные не покидают инфраструктуру
- Tab autocomplete + chat + agentic
- Любые модели: Ollama, llama.cpp, cloud API
- Open core: базовый функционал open-source, enterprise features -- платные

### Плюсы и минусы

```
+ VS Code + JetBrains (оба)
+ Privacy-first
+ Self-hosted вариант
+ Локальные модели из коробки
- Open core: часть features платная
- Менее мощный agent mode, чем Cline/Cursor
- Нет CLI
```


## OpenHands

**GitHub**: 50K+ stars
**Лицензия**: MIT
**Интерфейс**: Web UI

### Ключевые особенности

- Web-интерфейс для управления агентом
- Docker sandbox: код выполняется в контейнере
- Поддержка нескольких агентов (browsing agent, code agent)
- Любые модели через API
- Подходит для автономных задач: issue -> PR

### Плюсы и минусы

```
+ Web UI -- визуальный интерфейс
+ Docker sandbox -- безопасность
+ Multi-agent architecture
+ 50K stars -- активное community
- Не для real-time пары-программирования
- Требует Docker
- Setup сложнее, чем CLI-агенты
```


## SWE-agent

**Разработчик**: Princeton NLP
**Лицензия**: MIT
**Интерфейс**: CLI

### Ключевые особенности

- Research-grade: фокус на SWE-bench (стандартный бенчмарк AI-кодинга)
- Специализированный интерфейс для модели: упрощённые команды для навигации
- Docker sandbox
- Подходит для исследований и автоматического решения issues

### Плюсы и минусы

```
+ Research-grade: воспроизводимые бенчмарки
+ SWE-bench лидер среди open-source
- Не для ежедневной разработки
- Сложная настройка
- Нет интерактивного режима
```


## Goose

**Разработчик**: Block (ex-Square)
**Лицензия**: Open source
**Интерфейс**: CLI

### Ключевые особенности

- Автономный агент: минимум вмешательства разработчика
- Multi-session: параллельная работа
- Расширяемые toolkits
- Создан командой Block для internal use, затем open-sourced

### Плюсы и минусы

```
+ Автономность: минимум hand-holding
+ Создан для реальной разработки (Block)
+ Расширяемый
- Менее известен
- Документация ограничена
- Узкое community
```


## Общие плюсы и минусы open-source

### Плюсы

```
+ BYO API key: выбор модели и провайдера
+ Self-hosted: код не покидает инфраструктуру
+ Privacy: нет телеметрии, нет data collection
+ Нет vendor lock-in: можно менять модели на лету
+ Локальные модели: llama-server, Ollama -- полностью offline
+ Community: быстрые фиксы, community modes, расширения
+ Бесплатно (кроме стоимости API/моделей)
```

### Минусы

```
- Настройка: API keys, конфиги, совместимость моделей
- Нет managed infrastructure: sandbox, параллельность -- своими силами
- Качество сильно зависит от модели (локальная 7B << Claude Opus)
- Нет enterprise support: SLA, compliance, SSO
- Документация часто отстаёт от кода
- Breakages: быстрое развитие = частые breaking changes
```


## Связь с локальными моделями

Open-source агенты -- естественный выбор для работы с llama-server
и локальными моделями на AMD Strix Halo (96 GiB unified VRAM):

- Aider + Qwen2.5-Coder-32B: парное программирование
- OpenCode + Qwen3-Coder: interactive TUI
- Hermes + любая модель: универсальный ассистент с памятью

Подробнее: [Локальные агенты с llama-server](../use-cases/coding/agents.md)


## Связанные статьи

- <-- [Платные агенты](commercial.md)
- --> [Сравнение](comparison.md)
