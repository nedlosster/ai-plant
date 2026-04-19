# Claude Code (Anthropic, 2024-2026)

> Эталон CLI/IDE-агентов от Anthropic, 1M контекст, multi-agent, лучший frontend в индустрии. 41% профдевелоперов, $1B+ ARR.

**Тип**: CLI + IDE расширения (VS Code, JetBrains) + web (claude.ai/code)
**Лицензия**: Proprietary (Anthropic)
**Backend**: Anthropic API (Claude Opus 4.7 / Sonnet, Mythos Preview)
**Совместим с локальным llama-server**: **нет** (привязан к Anthropic API)
**Цена**: $20-200/мес или BYOK по токенам
**Доля рынка**: 41% профдевелоперов (Pragmatic Engineer survey, февраль 2026), 46% "most loved"
**ARR**: $1B+ (декабрь 2025)

## Файлы раздела

| Файл | О чём |
|------|-------|
| [news.md](news.md) | Хроника фич и анализ нововведений. Mental model "полного стека" из 6 механизмов: Skills, Subagents, Hooks, MCP, Plugins, Agent Teams |
| [agent-teams.md](agent-teams.md) | Стратегия использования Agent Teams: когда включать, три паттерна, Code Kit v5.0 YAML, playbook, антипаттерны |
| [skills-guide.md](skills-guide.md) | Как писать свои Skills: структура файла, паттерны, ecosystem, best practices, debugging |
| [hooks-guide.md](hooks-guide.md) | Hooks для safety и автоматизации: git guardrails, auto-format, secret scanning, audit log |
| [mcp-setup.md](mcp-setup.md) | Настройка MCP-серверов: filesystem, github, postgres, playwright, context7, разработка своего сервера |

## Обзор

Claude Code -- агент от Anthropic для работы с кодовыми базами через CLI, IDE или веб. Установил стандарт для современных coding-агентов: 1M контекст, sub-agents, MCP, hooks, agentic search. Был и остаётся бенчмарком, на который равняются open-source альтернативы (opencode, qwen-code, kilo-code).

Главная сила -- **глубокая интеграция с Anthropic-моделями**: специально натренированные Claude Opus/Sonnet версии для tool use, sub-agent дисциплины, расширенный prompt-форматирование. Это обеспечивает state-of-the-art качество на frontend-задачах (95% в Faros benchmark).

В 2026 столкнулся с обратной стороной популярности: третьи стороны (OpenClaw, Cline и др.) использовали Claude Pro/Max подписки как бесплатный backend. **4 апреля 2026 Anthropic заблокировал такое использование** -- спровоцировав миграцию пользователей на open-модели.

## Возможности

- **Agentic search** -- автоматически исследует кодбейз без ручного указания контекста
- **1M токенов контекста** (Opus 4.7) -- полный monorepo в одном сеансе
- **Sub-agents** -- специализированные параллельные агенты
- **Multi-agent (Claude Code agent team)** -- несколько агентов одновременно
- **Hooks** -- pre/post-action триггеры для enforce стандартов
- **MCP (Model Context Protocol)** -- расширяемость через внешние серверы (Anthropic стандарт)
- **CLAUDE.md** -- проектные инструкции, загружаемые автоматически
- **Skills** -- переиспользуемые навыки
- **Computer Use** -- через Anthropic API
- **Claude Code Channels** (апрель 2026) -- работа через Telegram/Discord

## Сильные стороны

- **Лучший frontend score (95%)** в индустрии (Faros benchmark)
- **1M контекст** -- видит весь крупный проект целиком
- **Multi-agent из коробки** -- параллельная работа специализированных агентов
- **CLI + IDE + web + Channels** -- максимальная гибкость интерфейса
- **CLAUDE.md** -- проектные инструкции из коробки
- **MCP экосистема** -- крупнейшая (Anthropic его создатели стандарта)
- **Самая зрелая экосистема** -- skills, hooks, settings, sub-agents
- **Sonnet 4.5 / Opus 4.7** доступны напрямую без интеграционной возни

## Слабые стороны / ограничения

- **Слабый backend score (38.6%)** -- тенденция к verbose решениям
- **Стоимость** при активном использовании ($120-220/мес)
- **Только Anthropic-модели** -- нельзя использовать с локальным llama-server
- **Иногда избыточные правки** (over-engineering)
- **Закрытый исходник** -- не модифицируется
- **Vendor lock-in** -- сложно переключиться без потери данных и настроек

## Базовые сценарии

- "Найди и исправь баг в этом проекте" -- автономный fix
- "Объясни архитектуру кодбейза" -- agentic search + summary
- "Сгенерируй тесты для модуля X"
- "Рефактор файла Y с сохранением API"
- Quick code review через `claude review <PR>`

## Сложные сценарии

- **Multi-repo refactoring** -- 1M контекст помогает держать все связанные репо
- **Sub-agent orchestration**: planner → coder → reviewer → tester параллельно
- **Migration major version framework** (например React 18 → 20) с координацией across files
- **Architecture review** всего проекта с анализом dependency graph
- **MCP-driven workflows** -- интеграция с Linear, GitHub, Jira через MCP-серверы
- **Custom hooks для CI/CD** -- pre-commit правила, post-deploy validation
- **Computer Use scenarios** -- автоматизация UI testing, browser-driven workflows

## Установка / запуск

```bash
# CLI
npm install -g @anthropic-ai/claude-code

# Установка credentials
claude login

# Запуск
cd /your/project
claude

# Один shot режим
claude "fix the bug in src/auth.ts"
```

## Конфигурация

`.claude.json` (project-level) и `~/.claude/settings.json` (global):

```json
{
  "model": "claude-opus-4-7",
  "context": "1m",
  "agents": {
    "build": {"tools": ["bash", "edit", "write"]},
    "review": {"tools": ["read", "grep"]}
  },
  "hooks": {
    "pre-commit": "npm run lint",
    "post-edit": "npm run typecheck"
  },
  "mcp": {
    "linear": {"url": "..."},
    "github": {"url": "..."}
  }
}
```

`CLAUDE.md` -- проектные правила, читаются автоматически.

## Бенчмарки

| Категория | Score |
|-----------|-------|
| Frontend | **95.0%** (лидер) |
| Backend | 38.6% |
| Overall | 55.5% |
| SWE-bench Verified | 87.6% (с Opus 4.7) |

## Анонсы и открытия

- **2026-04-16** -- **Claude Opus 4.7** (87.6% SWE-bench, xhigh effort, task budgets, /ultrareview, rebuilt tokenizer, vision 2576px)
- **2026-04-17** -- **Claude Design** (Anthropic Labs sub-brand)
- **2026-04** -- **Claude Code Channels** релиз (Telegram/Discord интеграция, ответ на OpenClaw)
- **2026-04-04** -- блокировка использования Claude Pro/Max в third-party tools (OpenClaw, Cline через прокси)
- **2026-Q1** -- релиз Claude Sonnet 4.5 как default
- **2026-Q1** -- Opus 4.6 с 1M контекстом для Max ($200/мес)
- **2025-Q4** -- multi-agent team (параллельные sub-agents)
- **2025** -- релиз MCP как открытого стандарта

## Ссылки

- [Официальный сайт](https://claude.com/code)
- [Документация](https://docs.claude.com/claude-code)
- [MCP протокол](https://modelcontextprotocol.io/)
- [Pricing](https://www.anthropic.com/pricing)

## Связано

- **Альтернативы (open)**: [opencode](../opencode.md), [qwen-code](../qwen-code.md), [openclaw](../openclaw/README.md)
- **Альтернативы (commercial)**: [cursor](../cursor.md)
- **Конкурент по протоколу**: Cline (также Anthropic API)
- **Тренды**: [../../trends.md](../../trends.md), [../../news.md](../../news.md)
- **Концепты**: [../../README.md](../../README.md)
