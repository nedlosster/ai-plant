# Сравнение AI-агентов

Сводные таблицы, бенчмарки и ссылки на per-agent страницы. Данные: апрель 2026.

Полные описания каждого агента -- в [agents/](agents/). Общие новости -- в [news.md](news.md).

## Сводная таблица

| Агент | Тип | Интерфейс | Контекст | Backend | Local llama-server | Цена/мес |
|-------|-----|-----------|----------|---------|--------------------|----------|
| [Claude Code](agents/claude-code/README.md) | CLI+IDE+Web | Terminal, VS Code, JB, Channels | 1M | Anthropic API | нет | $20-200 |
| [Cursor 3](agents/cursor.md) | IDE | VS Code fork | 128K | Composer 2 (Kimi K2.5 base), Multi BYOK | частично | $20-40 |
| Codex 5.3 | Cloud | Web (ChatGPT) | 128K | OpenAI proprietary | нет | $200, unlimited промо |
| Windsurf | IDE | 40+ IDE | 128K | SWE-1, SWE-1.5 | нет | $20 |
| Devin 2.0 | Cloud | Web + Slack | N/A | Proprietary | нет | $20 + $2.25/ACU |
| Junie | IDE+CLI | JetBrains, CLI | 128K | Multi | нет | $100-300/год |
| Copilot | IDE+CLI | VS Code, JB, vim | 64K | GPT-4o | нет | $10-19 |
| Amazon Q | CLI+IDE | Terminal, VS Code, JB | 128K | Claude 3.7 | CLI: да | $0-19 |
| Gemini CLI | CLI | Terminal | 1M | Flash, Pro | да | $0-19 |
| [Aider](agents/aider.md) | CLI | Terminal | 128K* | Любая | **да** | Free |
| [opencode](agents/opencode.md) | CLI/TUI | Terminal | 128K* | Любая | **да** ⭐ | Free |
| Hermes | CLI+msg | Terminal, Telegram, Discord | 128K* | Любая | да | Free |
| [Cline](agents/cline.md) | IDE | VS Code | 128K* | Любая | **да** | Free |
| [Roo Code](agents/roo-code.md) | IDE | VS Code | 128K* | Любая | **да** | Free |
| [Kilo Code](agents/kilo-code.md) | IDE+CLI | VS Code, JB, CLI | 128K* | 500+ | **да** | Free + $19/мес pay |
| [Continue.dev](agents/continue-dev.md) | IDE | VS Code, JB | 128K* | Любая | **да** ⭐ | Free |
| OpenHands | Web | Browser | 128K* | Любая | да | Free |
| [Qwen Code](agents/qwen-code.md) | CLI | Terminal | 128K-1M | Multi-protocol | **да** | Free + Qwen OAuth |
| [OpenClaw](agents/openclaw.md) | Desktop/Cloud | Multi | 128K* | Model agnostic | да | Free |

(*) Контекст зависит от выбранной модели. С Claude Opus / Qwen3.6 -- до 1M.
(⭐) Использовано на нашей платформе.

## Бенчмарки Faros.ai (март 2026)

Данные: 10 реальных задач (frontend + backend). Метрики не учитывают UX, скорость итерации, стоимость.

| # | Агент | Overall | Frontend | Backend | Runtime | Tokens |
|---|-------|---------|----------|---------|---------|--------|
| 1 | Codex | 67.7% | 80.0% | **58.5%** | 426 сек | 258K |
| 2 | Junie | 63.5% | 85.0% | 54.3% | 312 сек | 180K |
| 3 | [Claude Code](agents/claude-code/README.md) | 55.5% | **95.0%** | 38.6% | 280 сек | 350K |
| 4 | Copilot | 48.2% | 65.0% | 35.0% | 180 сек | 120K |
| 5 | [Cursor](agents/cursor.md) | 46.0% | 70.0% | 30.0% | 150 сек | 100K |

### Наблюдения

- **Codex** лидирует overall за счёт backend (58.5%)
- **[Claude Code](agents/claude-code/README.md)** -- лучший frontend (95%), но backend тянет вниз
- **Junie** -- баланс frontend/backend, #2 overall
- **[Cursor](agents/cursor.md)** быстрее всех (150 сек), но score ниже

Open-source агенты ([Cline](agents/cline.md), [opencode](agents/opencode.md), [Aider](agents/aider.md), [Kilo Code](agents/kilo-code.md)) в Faros не тестировались -- их результат зависит от используемой модели. С Qwen3-Coder Next 70.6% SWE-V, с Claude Sonnet 4.5 -- сравнимо с Claude Code.

## Стоимость за задачу

Ориентировочная стоимость одной типовой задачи (feature/bugfix):

| Агент | Модель | Токены | Стоимость |
|-------|--------|--------|-----------|
| [Claude Code](agents/claude-code/README.md) | Opus 4.6 (Max) | 300-500K | $3-8 |
| Codex | codex-1 (Pro) | 258K | ~$6 |
| [Cursor](agents/cursor.md) | Claude 3.5 (Pro) | 100K | Включено в $20/мес |
| Devin | Proprietary | N/A | $2.25-9 (1-4 ACU) |
| [Aider](agents/aider.md) | Claude API | 200K | $2-5 |
| **[Aider](agents/aider.md) + llama-server** | **Qwen3-Coder Next** | 200K | **$0** (электричество) |
| **[opencode](agents/opencode.md) + llama-server** | **Qwen3-Coder Next** | 200K | **$0** |
| Gemini CLI | Flash (free) | 300K | $0 |
| [Qwen Code](agents/qwen-code.md) + Qwen OAuth | Qwen3-Coder Next | 100-200K | $0 (1000 req/день free) |

## Категории и характеристики

### По типу backend

| Тип | Агенты |
|-----|--------|
| Anthropic-привязанные | [Claude Code](agents/claude-code/README.md) |
| OpenAI-compatible (любые модели) | [opencode](agents/opencode.md), [Aider](agents/aider.md), [Cline](agents/cline.md), [Kilo Code](agents/kilo-code.md), [Roo Code](agents/roo-code.md), [Continue.dev](agents/continue-dev.md), [Qwen Code](agents/qwen-code.md) |
| Multi-protocol | [Qwen Code](agents/qwen-code.md), [OpenClaw](agents/openclaw.md), [Kilo Code](agents/kilo-code.md) |
| Proprietary только | Codex, Devin, Cursor (только IDE), Windsurf |

### По интерфейсу

| Интерфейс | Агенты |
|-----------|--------|
| **CLI only** | [Aider](agents/aider.md), [opencode](agents/opencode.md), [Qwen Code](agents/qwen-code.md), Gemini CLI |
| **VS Code only** | [Cline](agents/cline.md), [Roo Code](agents/roo-code.md), Cursor (fork) |
| **VS Code + JetBrains** | [Continue.dev](agents/continue-dev.md), [Kilo Code](agents/kilo-code.md), Junie |
| **CLI + IDE + Web** | [Claude Code](agents/claude-code/README.md), Amazon Q |
| **Desktop / Multi-app** | [OpenClaw](agents/openclaw.md) |

### По multi-agent поддержке

| Поддержка | Агенты |
|-----------|--------|
| **Built-in multi-agent** | [Claude Code](agents/claude-code/README.md) (sub-agents), [Kilo Code](agents/kilo-code.md) (Orchestrator) |
| **Custom modes для имитации** | [Roo Code](agents/roo-code.md), [opencode](agents/opencode.md) (custom agents) |
| **Architect mode (2 модели)** | [Aider](agents/aider.md) |
| **Без multi-agent** | [Cline](agents/cline.md), [Continue.dev](agents/continue-dev.md), [Cursor](agents/cursor.md), [Qwen Code](agents/qwen-code.md) |

### По MCP support

| MCP | Агенты |
|-----|--------|
| **Зрелая экосистема** | [Claude Code](agents/claude-code/README.md) (создатели стандарта) |
| **Поддержка** | [opencode](agents/opencode.md), [Cline](agents/cline.md), [Kilo Code](agents/kilo-code.md), [Roo Code](agents/roo-code.md), [Continue.dev](agents/continue-dev.md), [Qwen Code](agents/qwen-code.md), [OpenClaw](agents/openclaw.md) |
| **Нет** | [Aider](agents/aider.md) (на момент 2026), Cursor (частично) |

## Матрица выбора

### По сценарию

| Сценарий | Рекомендация |
|----------|--------------|
| Локальные модели + privacy + opencode-стиль | [opencode](agents/opencode.md) |
| Локальные модели + IDE | [Continue.dev](agents/continue-dev.md), [Cline](agents/cline.md), [Kilo Code](agents/kilo-code.md) |
| FIM autocomplete с local llama-server | [Continue.dev](agents/continue-dev.md) |
| Multi-agent орчестрация без танцев | [Kilo Code](agents/kilo-code.md) Orchestrator или [Claude Code](agents/claude-code/README.md) |
| Git-first workflow | [Aider](agents/aider.md) |
| Lifestyle agent (не только код) | [OpenClaw](agents/openclaw.md) |
| Native интеграция с Qwen-моделями | [Qwen Code](agents/qwen-code.md) |
| Best frontend score | [Claude Code](agents/claude-code/README.md) (95%) |
| Best backend score | Codex (58.5%) |
| JetBrains | [Continue.dev](agents/continue-dev.md), [Kilo Code](agents/kilo-code.md), Junie |
| Power user customization | [Roo Code](agents/roo-code.md) или [Kilo Code](agents/kilo-code.md) |

### По бюджету

| Бюджет | Оптимальный выбор |
|--------|-------------------|
| **$0 (open-source + local)** | [opencode](agents/opencode.md) / [Cline](agents/cline.md) / [Continue.dev](agents/continue-dev.md) + Qwen3-Coder Next |
| **$0 (free cloud)** | Gemini CLI или [Qwen Code](agents/qwen-code.md) + Qwen OAuth (1000 req/day) |
| **$10-20/мес** | Copilot ($10) или [Cursor](agents/cursor.md) ($20) |
| **$100-200/мес** | [Claude Code](agents/claude-code/README.md) Max ($200) |
| **$300+/мес** | [Claude Code](agents/claude-code/README.md) + Codex |

## Связанные статьи

- [README.md](README.md) -- концепты и эволюция
- [news.md](news.md) -- актуальные релизы и события
- [trends.md](trends.md) -- долгосрочные прогнозы
- [agents/](agents/) -- per-agent страницы
- [open-source.md](open-source.md) / [commercial.md](commercial.md) -- индексы по типу
- [use-cases/coding/agents.md](../use-cases/coding/agents.md) -- операционные setup команды
