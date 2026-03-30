# Сравнение AI-агентов

Сводные таблицы, бенчмарки и матрица выбора.
Данные: март 2026.


## Сводная таблица

```
Агент           | Тип     | Интерфейс      | Контекст | Модель              | Цена/мес      | Open
----------------|---------|----------------|----------|---------------------|---------------|-----
Claude Code     | CLI+IDE | Terminal, VS Code, JB, Web | 1M  | Opus 4.6        | $100-200      | Нет
Codex           | Cloud   | Web (ChatGPT)  | 128K     | codex-1             | $200          | Нет
Cursor          | IDE     | VS Code (fork) | 128K     | Multi (GPT, Claude) | $20           | Нет
Windsurf        | IDE     | 40+ IDE        | 128K     | SWE-1, SWE-1.5     | $20           | Нет
Devin           | Cloud   | Web + Slack    | N/A      | Проприетарный       | $20 + ACU     | Нет
Junie           | IDE+CLI | JetBrains, CLI | 128K     | Multi               | $100-300/год  | Нет
Copilot         | IDE+CLI | VS Code, JB, vim| 64K     | GPT-4o              | $10-19        | Нет
Amazon Q        | CLI+IDE | Terminal, VS Code, JB | 128K| Claude 3.7 Sonnet| $0-19         | CLI: да
Gemini CLI      | CLI     | Terminal       | 1M       | Flash, Pro          | $0-19         | CLI: да
Aider           | CLI     | Terminal       | 128K*    | Любая               | Бесплатно**   | Да
OpenCode        | TUI+IDE | Terminal, Desktop, IDE | 128K*| Любая            | Бесплатно**   | Да
Hermes          | CLI+msg | Terminal, Telegram, Discord| 128K*| Любая        | Бесплатно**   | Да
Cline           | IDE     | VS Code        | 128K*    | Любая               | Бесплатно**   | Да
OpenHands       | Web     | Browser        | 128K*    | Любая               | Бесплатно**   | Да
```

(*) Контекст зависит от выбранной модели. С Claude Opus -- до 1M.
(**) Бесплатно = софт бесплатный. Стоимость API моделей оплачивается отдельно.
     С локальными моделями (llama-server) -- полностью бесплатно.


## Бенчмарки

Данные Faros.ai (март 2026): 10 реальных задач (frontend + backend).

### Overall Score

```
#  | Агент       | Overall | Frontend | Backend | Runtime | Tokens
---|-------------|---------|----------|---------|---------|-------
1  | Codex       | 67.7%   | 80.0%    | 58.5%   | 426 сек | 258K
2  | Junie       | 63.5%   | 85.0%    | 54.3%   | 312 сек | 180K
3  | Claude Code | 55.5%   | 95.0%    | 38.6%   | 280 сек | 350K
4  | Copilot     | 48.2%   | 65.0%    | 35.0%   | 180 сек | 120K
5  | Cursor      | 46.0%   | 70.0%    | 30.0%   | 150 сек | 100K
```

### Наблюдения

- **Codex** лидирует overall за счёт backend (58.5% -- на 4+ п.п. впереди)
- **Claude Code** -- лучший frontend (95%), но backend тянет вниз
- **Junie** -- баланс frontend/backend, #2 overall
- **Cursor** быстрее всех (150 сек), но score ниже
- Бенчмарки не учитывают UX, скорость итерации, стоимость за задачу


## Стоимость за задачу

Ориентировочная стоимость одной типовой задачи (feature/bugfix):

```
Агент       | Модель           | Токены   | Стоимость
------------|------------------|----------|----------
Claude Code | Opus 4.6 (Max)   | 300-500K | $3-8
Codex       | codex-1 (Pro)    | 258K     | ~$6*
Cursor      | Claude 3.5 (Pro) | 100K     | Включено в $20/мес
Devin       | Proprietary      | N/A      | $2.25-9 (1-4 ACU)
Aider       | Claude API       | 200K     | $2-5
Aider       | llama-server     | 200K     | $0 (электричество)
OpenCode    | llama-server     | 200K     | $0 (электричество)
Gemini CLI  | Flash (free)     | 300K     | $0
```

(*) Codex $200/мес / ~30-35 задач = ~$6/задача.


## Матрица выбора

### По сценарию использования

```
Сценарий                                 | Рекомендация
-----------------------------------------|----------------------------
Ежедневная разработка, основной инструмент| Claude Code или Cursor
Сложные multi-step задачи, backend       | Codex
Автономные задачи (issue -> PR)          | Devin или Codex
JetBrains IDE                            | Junie
Privacy / self-hosted / air-gapped       | OpenCode или Aider + llama-server
Бесплатно / минимальный бюджет           | Gemini CLI (free) или Aider + llama-server
AWS стек                                 | Amazon Q Developer
Множество IDE (VS Code + JetBrains + vim)| Windsurf (40+ IDE)
Максимальный frontend score              | Claude Code (95%)
Исследования / SWE-bench                 | SWE-agent или OpenHands
Универсальный AI-ассистент с памятью     | Hermes Agent
```

### По бюджету

```
Бюджет       | Оптимальный выбор
-------------|----------------------------
$0           | Gemini CLI (Flash) + Aider + llama-server
$10-20/мес   | Copilot ($10) или Cursor/Windsurf ($20)
$100-200/мес | Claude Code Max ($200) или Codex ($200)
$300+/мес    | Claude Code + Codex (комбинация)
```

### По типу проекта

```
Проект                     | Агент            | Почему
---------------------------|------------------|----------------------------
Стартап, быстрые итерации  | Cursor           | Быстрый, визуальный, $20
Enterprise, compliance     | Copilot Enterprise| SSO, audit, knowledge bases
Open-source проект         | Aider            | Git-first, reviewable commits
ML/AI pipeline             | Claude Code      | 1M контекст, сложная логика
DevOps / IaC               | Amazon Q         | AWS-нативный
Frontend SPA               | Claude Code      | 95% frontend accuracy
Backend microservices      | Codex            | 58.5% backend accuracy
Offline / air-gapped       | OpenCode + Qwen  | Полностью локальный
```


## Комбинации агентов

Многие разработчики используют 2-3 агента параллельно:

```
Основной      | Дополнительный | Сценарий
--------------|----------------|----------------------------------
Claude Code   | Codex          | Code = ежедневно, Codex = сложные баги
Cursor        | Claude Code    | Cursor = IDE, CC = терминал/CI
Copilot       | Gemini CLI     | Copilot = IDE, Gemini = free research
Aider         | OpenCode       | Aider = git-heavy, OC = exploration
```

Типичная связка 2026: Claude Code (основной, 80% задач) + Codex (сложные задачи, 15%) + Gemini CLI (быстрые вопросы, 5%).


## Связанные статьи

- <-- [Открытые агенты](open-source.md)
- --> [Тренды](trends.md)
- [Локальные агенты](../use-cases/coding/agents.md) -- Aider/OpenCode + llama-server
