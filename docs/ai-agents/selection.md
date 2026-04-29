# Выбор AI-агента: decision tree

Краткий гид по выбору агента под задачу. Полные описания -- в [agents/](agents/), сравнительная таблица -- в [comparison.md](comparison.md).

## Decision tree (текстовый)

```
START
 │
 ├── Нужен полностью локальный inference (privacy/offline)?
 │    ├── ДА → CLI-стиль?
 │    │        ├── ДА → [opencode](agents/opencode/README.md) ⭐ или [Aider](agents/aider.md)
 │    │        └── НЕТ (IDE) → [Continue.dev](agents/continue-dev.md) ⭐ или [Cline](agents/cline.md) / [Kilo Code](agents/kilo-code.md)
 │    └── НЕТ → дальше
 │
 ├── Бюджет $0 (cloud free tier)?
 │    ├── ДА → [Qwen Code](agents/qwen-code.md) (1000 req/день) или Gemini CLI
 │    └── НЕТ → дальше
 │
 ├── Нужен максимум качества и не жалко $200/мес?
 │    ├── Frontend-heavy → [Claude Code](agents/claude-code/README.md) (95% Faros frontend)
 │    ├── Backend-heavy → Codex Pro (58.5% Faros backend)
 │    └── Баланс → Junie или [Claude Code](agents/claude-code/README.md)
 │
 ├── Нужен IDE с минимальной кривой обучения?
 │    ├── VS Code-привычка → [Cursor](agents/cursor.md) ($20)
 │    ├── JetBrains → Junie или [Continue.dev](agents/continue-dev.md)
 │    └── Power user → [Roo Code](agents/roo-code.md) или [Kilo Code](agents/kilo-code.md)
 │
 └── Нужен multi-agent orchestration?
      ├── Из коробки → [Claude Code](agents/claude-code/README.md) (sub-agents) или [Kilo Code](agents/kilo-code.md) (Orchestrator)
      └── Через custom modes → [Roo Code](agents/roo-code.md) или [opencode](agents/opencode/README.md)
```

## По задаче

| Задача | Рекомендация | Почему |
|--------|--------------|--------|
| Frontend (React/Vue/UI) | [Claude Code](agents/claude-code/README.md) | 95% Faros frontend, лучший в индустрии |
| Backend (API, БД, бизнес-логика) | Codex Pro или Junie | 58.5% и 54.3% Faros backend |
| Refactor крупного monorepo | [Claude Code](agents/claude-code/README.md) (1M контекст) или [Aider](agents/aider.md) (repo map) |
| Bugfix через git workflow | [Aider](agents/aider.md) | Auto-commit каждой правки |
| Code review PR | [Claude Code](agents/claude-code/README.md) `claude review` | Agentic search |
| Generate tests | Любой -- разница невелика | Простая задача |
| Multi-repo migration | [Claude Code](agents/claude-code/README.md) | 1M context + sub-agents |
| FIM autocomplete | [Continue.dev](agents/continue-dev.md) | Лучшая поддержка local llama-server |
| Inline-промпты в комментариях | [Aider](agents/aider.md) watch mode | `# ai!` синтаксис |
| Long-running background задачи | [Cursor](agents/cursor.md) Background Agents или [Claude Code](agents/claude-code/README.md) | Параллельные агенты |

## По бюджету

| Бюджет/мес | Выбор | Альтернативы |
|------------|-------|--------------|
| **$0** -- электричество | [opencode](agents/opencode/README.md) + Qwen3-Coder Next локально | [Continue.dev](agents/continue-dev.md), [Cline](agents/cline.md), [Aider](agents/aider.md) + local |
| **$0** -- free cloud | [Qwen Code](agents/qwen-code.md) + Qwen OAuth | Gemini CLI |
| **$10** | Copilot | -- |
| **$20** | [Cursor](agents/cursor.md) Pro | Windsurf, Devin starter |
| **$100** | [Claude Code](agents/claude-code/README.md) Pro или Junie ($100/год) | -- |
| **$200** | [Claude Code](agents/claude-code/README.md) Max (Opus 4.6, 1M) | Codex Pro |
| **$300+** | [Claude Code](agents/claude-code/README.md) Max + Codex (комбо) | -- |

## По интерфейсу

| Я работаю в... | Выбор |
|----------------|-------|
| Terminal only | [opencode](agents/opencode/README.md), [Aider](agents/aider.md), [Qwen Code](agents/qwen-code.md), Gemini CLI |
| VS Code | [Cline](agents/cline.md), [Continue.dev](agents/continue-dev.md), [Kilo Code](agents/kilo-code.md), [Roo Code](agents/roo-code.md), [Cursor](agents/cursor.md) |
| JetBrains IDE | [Continue.dev](agents/continue-dev.md), [Kilo Code](agents/kilo-code.md), Junie |
| Vim/Emacs | Copilot, [Aider](agents/aider.md) (CLI external) |
| Web/cloud | Codex (ChatGPT), Devin, OpenHands |
| Telegram/Discord | [Claude Code](agents/claude-code/README.md) Channels, Hermes |

## Сценарии нашей платформы

На AI-сервере 192.168.1.77 крутится llama-server с локальными моделями (Qwen3-Coder Next 80B-A3B, Gemma 4 26B-A4B). Рекомендуемые клиенты:

| Use case | Клиент | Конфиг |
|----------|--------|--------|
| Daily coding в CLI | [opencode](agents/opencode/README.md) ⭐ | `~/.config/opencode/opencode.json` → llama-server |
| FIM autocomplete в VS Code | [Continue.dev](agents/continue-dev.md) ⭐ | `~/.continue/config.json` → llama-server |
| Architect-режим (план на Opus, код локально) | [Aider](agents/aider.md) | `--architect --model claude-opus --editor-model qwen3-coder-next` |
| Параллельные эксперименты | [Cline](agents/cline.md) | VS Code + llama-server endpoint |

## Связано

- [comparison.md](comparison.md) -- полная сравнительная таблица
- [agents/](agents/) -- per-agent страницы
- [news.md](news.md) -- актуальные релизы
- [trends.md](trends.md) -- долгосрочные прогнозы
