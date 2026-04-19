# Платные AI-агенты

Индекс коммерческих агентов с managed-инфраструктурой и проприетарными моделями. Полные описания -- в [agents/](agents/), сравнение -- в [comparison.md](comparison.md), выбор -- в [selection.md](selection.md).

## Список

| Агент | Вендор | Тип | Цена/мес | Per-agent |
|-------|--------|-----|----------|-----------|
| Claude Code | Anthropic | CLI+IDE+Web+Channels | $20-200 | [agents/claude-code/README.md](agents/claude-code/README.md) |
| Cursor 3 (Composer 2) | Anysphere | IDE (VS Code fork) | $20-60 | [agents/cursor.md](agents/cursor.md) |
| OpenAI Codex 5.3 | OpenAI | Cloud (ChatGPT) | $200, unlimited промо | -- |
| Windsurf | Codeium | IDE (40+ IDE) | $15-200 | -- |
| Devin 2.0 | Cognition | Cloud + Slack | $20 + $2.25/ACU | -- |
| Junie | JetBrains | JetBrains IDE + CLI | $100-300/год | -- |
| GitHub Copilot | Microsoft | IDE + CLI | $10-39 | -- |
| Amazon Q Developer | AWS | CLI + IDE | $0-19 | -- |
| Gemini Code Assist / CLI | Google | CLI + IDE | $0-19 | -- |

⭐ Выделенные жирным имеют per-agent страницу с подробным разбором.

## Общие характеристики коммерческих агентов

**Плюсы**:
- Managed infrastructure -- ничего настраивать не нужно
- Проприетарные модели последнего поколения (Opus 4.7, GPT-5, codex-1)
- Enterprise support, SLA, compliance
- Зрелые продукты с большим community

**Минусы**:
- Vendor lock-in -- настройки и история привязаны к продукту
- Стоимость при активном использовании ($120-220/мес)
- Код уходит на серверы вендора (privacy concerns)
- Нет совместимости с локальным llama-server (исключение -- Cursor BYOK, Q Developer CLI, Gemini CLI)

## Бенчмарки Faros.ai (март 2026)

| # | Агент | Overall | Frontend | Backend |
|---|-------|---------|----------|---------|
| 1 | Codex | 67.7% | 80.0% | **58.5%** |
| 2 | Junie | 63.5% | 85.0% | 54.3% |
| 3 | Claude Code | 55.5% | **95.0%** | 38.6% |
| 4 | Copilot | 48.2% | 65.0% | 35.0% |
| 5 | Cursor | 46.0% | 70.0% | 30.0% |

Полные данные -- в [comparison.md](comparison.md#бенчмарки-farosai-март-2026).

## SWE-bench Verified (апрель 2026)

| # | Модель | SWE-bench Verified | SWE-bench Pro |
|---|--------|--------------------|----|
| 1 | Claude Mythos Preview (Anthropic) | 93.9% | -- |
| 2 | Claude Opus 4.7 | 87.6% | 64.3% |
| 3 | GPT-5.3 Codex | 85.0% | ~57% |
| 4 | GPT-5.4 | -- | 57.7% |

Источник: [llm-stats.com/benchmarks/swe-bench-verified](https://llm-stats.com/benchmarks/swe-bench-verified), 16 апреля 2026.

## Доля рынка (Q1 2026)

- **Claude Code**: 41% профессиональных разработчиков (Pragmatic Engineer survey, n=15000, февраль 2026), 46% "most loved"
- **GitHub Copilot**: 42% (data from JetBrains research, апрель 2026)
- **Cursor**: 18% работающих разработчиков, $500M ARR
- **$1B+ ARR threshold (декабрь 2025)**: GitHub Copilot, Claude Code, Anysphere -- одновременно перешагнули

## Связано

- [open-source.md](open-source.md) -- открытые альтернативы
- [comparison.md](comparison.md) -- сравнительная таблица
- [selection.md](selection.md) -- выбор по сценарию/бюджету
- [news.md](news.md) -- актуальные релизы
- [agents/](agents/) -- per-agent страницы
