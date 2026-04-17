# Открытые AI-агенты

Индекс open-source агентов: BYO API key или локальная модель, self-hosted, без vendor lock-in. Полные описания -- в [agents/](agents/), сравнение -- в [comparison.md](comparison.md), выбор -- в [selection.md](selection.md).

## Список

| Агент | Лицензия | Интерфейс | Local llama-server | Per-agent |
|-------|----------|-----------|--------------------|-----------|
| opencode | MIT | TUI/CLI | **да** ⭐ | [agents/opencode.md](agents/opencode.md) |
| Aider | Apache 2.0 | CLI | **да** | [agents/aider.md](agents/aider.md) |
| Cline | Apache 2.0 | VS Code | **да** | [agents/cline.md](agents/cline.md) |
| Roo Code | Apache 2.0 | VS Code | **да** | [agents/roo-code.md](agents/roo-code.md) |
| Kilo Code | Apache 2.0 | VS Code+JB+CLI | **да** | [agents/kilo-code.md](agents/kilo-code.md) |
| Continue.dev | Apache 2.0 | VS Code+JB | **да** ⭐ | [agents/continue-dev.md](agents/continue-dev.md) |
| Qwen Code | Apache 2.0 | CLI | **да** | [agents/qwen-code.md](agents/qwen-code.md) |
| OpenClaw | Open source | Desktop/Multi | да | [agents/openclaw/README.md](agents/openclaw/README.md) |
| Hermes | Open source | CLI + Telegram/Discord/Slack | да | -- |
| OpenHands | MIT | Web UI | да | -- |
| SWE-agent | MIT | CLI (research) | да | -- |
| Goose | Open source | CLI | да | -- |

⭐ Используется на нашей платформе.

## Общие характеристики open-source агентов

**Плюсы**:
- BYO API key -- выбор модели и провайдера
- Self-hosted -- код не покидает инфраструктуру
- Privacy -- нет телеметрии
- Нет vendor lock-in -- модели меняются на лету
- Полная совместимость с local llama-server (Qwen3-Coder Next, Devstral 2)
- Бесплатно (кроме API/электричества)

**Минусы**:
- Настройка: API keys, конфиги, совместимость моделей
- Нет managed infrastructure
- Качество зависит от модели
- Документация часто отстаёт от кода

## Связь с локальными моделями

На нашей платформе (AMD Strix Halo, 96 GiB unified VRAM, llama-server) рекомендуются:

| Use case | Агент + модель |
|----------|----------------|
| Daily coding в CLI | [opencode](agents/opencode.md) + Qwen3-Coder Next |
| FIM autocomplete в IDE | [Continue.dev](agents/continue-dev.md) + Qwen2.5-Coder 1.5B FIM |
| Architect режим (план + код) | [Aider](agents/aider.md) + Claude Opus / Qwen3-Coder Next |
| VS Code agentic | [Cline](agents/cline.md) + Qwen3-Coder Next |

Подробнее -- в [use-cases/coding/agents.md](../use-cases/coding/agents.md).

## Связано

- [commercial.md](commercial.md) -- платные альтернативы
- [comparison.md](comparison.md) -- сравнительная таблица
- [selection.md](selection.md) -- выбор по сценарию/бюджету
- [news.md](news.md) -- актуальные релизы
- [agents/](agents/) -- per-agent страницы
