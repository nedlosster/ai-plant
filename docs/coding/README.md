# AI-кодинг: модели, агенты, инструменты

Центральный раздел для всего, что связано с AI-assisted разработкой: open-source coding LLM, coding agents, workflow'ы, ресурсы community. Объединяет информацию из [models/coding.md](../models/coding.md), [ai-agents/](../ai-agents/README.md) и дополняет хроникой, workflow'ами и курированными ресурсами.

Актуализация: `/refresh-news coding`.

## Файлы раздела

| Файл | О чём |
|------|-------|
| [news.md](news.md) | Хроника AI-кодинга: релизы моделей, обновления агентов, SWE-bench лидерборд, значимые блог-посты |
| [workflows.md](workflows.md) | Практические workflow'ы на платформе: IDE FIM + CLI agent, multi-agent, code review, refactoring |
| [resources.md](resources.md) | Курированные ресурсы: блоги, рассылки, YouTube, community, leaderboard-сайты |
| [ide-setup.md](ide-setup.md) | Continue.dev, Cline, Roo Code: настройка IDE для автодополнения и inline edit |
| [server-setup.md](server-setup.md) | llama-server: dual-instance config (FIM порт 8080 + Chat порт 8081) |
| [prompts.md](prompts.md) | System prompts и prompt engineering для coding-задач |

## Текущий стек (апрель 2026)

### Модели на платформе (Strix Halo, 120 GiB VRAM)

| Модель | Параметры | SWE-bench | VRAM Q4 | Роль |
|--------|-----------|-----------|---------|------|
| [Qwen 3.6-35B-A3B](../models/families/qwen36.md#35b-a3b) | 35B MoE (3B active), vision | **73.4%** | ~20 GiB | **Default daily agent** (баланс качества и скорости, vision) |
| [Qwen 3.6-27B](../models/families/qwen36.md#27b) | 27B dense, hybrid Gated DeltaNet, vision | **77.2%** | ~17 GiB | Heavy SWE (максимум качества, multimodal) |
| [Qwen3-Coder Next](../models/families/qwen3-coder.md) | 80B MoE (3B active) | 70.6% | ~5 GiB | Long-context loop (256K) |
| [Devstral 2](../models/families/devstral.md) | 24B dense | 72.2% | ~14 GiB | Agent alternative (dense 24B) |
| [Qwen3.5-122B-A10B](../models/families/qwen35.md) | 122B MoE (10B active) | -- | ~71 GiB | Heavy reasoning |
| [Qwen3-Coder 30B-A3B](../models/families/qwen3-coder.md) | 30B MoE (3B active) | ~42% | ~18 GiB | FIM autocomplete / quick chat |

### Coding agents

| Агент | Тип | Модель default | Лицензия |
|-------|-----|----------------|----------|
| [Claude Code](../ai-agents/agents/claude-code/README.md) | CLI | Claude Opus 4.7 | Proprietary ($20/мес) |
| [opencode](../ai-agents/agents/opencode.md) | CLI | любая (OpenAI-compat) | MIT |
| [Cursor](../ai-agents/agents/cursor.md) | IDE | Claude/GPT/custom | Proprietary ($20/мес) |
| [Cline](../ai-agents/agents/cline.md) | VS Code ext | любая | Apache 2.0 |
| [Aider](../ai-agents/agents/aider.md) | CLI | любая | Apache 2.0 |

### Frontier closed-source (для контекста)

| Модель | SWE-bench Verified | Провайдер |
|--------|--------------------|-----------|
| Claude Mythos Preview | 93.9% | Anthropic |
| Claude Opus 4.7 | 87.6% | Anthropic |
| GPT-5.3 Codex | 85.0% | OpenAI |
| Gemini 3.1 Pro | 78.8% | Google |
| GLM-5 | 77.8% | Zhipu AI (open MIT) |
| GPT-5.4 | -- (Pro 57.7%) | OpenAI |

## Зачем отдельный раздел

Информация по AI-кодингу распылена по документации:
- [models/coding.md](../models/coding.md) -- каталог open coding LLM, таблицы, стратегия opencode
- [models/closed-source-coding.md](../models/closed-source-coding.md) -- GPT-5.3, Opus, Gemini, Kimi K2.5
- [ai-agents/](../ai-agents/README.md) -- агенты для разработки (не только кодинг)
- [models/news.md](../models/news.md) -- новости ВСЕХ моделей (не только coding)
- [ai-agents/news.md](../ai-agents/news.md) -- новости ВСЕХ агентов

Этот раздел -- **единая точка входа**: что нового в AI-кодинге, какие workflow'ы работают, какие ресурсы читать. Не дублирует, а связывает и дополняет.

## Ключевые вопросы

Раздел помогает ответить на:
- Какая open-source модель лучше для кодинга прямо сейчас?
- Как организовать workflow: FIM + agent + code review?
- Что нового за последний месяц? (модели, агенты, фичи)
- Какие блоги и каналы читать чтобы не отставать?
- Когда local модель достаточна, а когда нужен cloud API?

## Связанные статьи

- [Модели для кодинга](../models/coding.md) -- каталог open LLM, бенчмарки на платформе
- [Closed-source coding](../models/closed-source-coding.md) -- GPT-5.3, Opus 4.7, Gemini, Kimi
- [AI-агенты](../ai-agents/README.md) -- полный обзор индустрии агентов
- [Сравнение агентов](../ai-agents/comparison.md) -- сводные таблицы
- [SWE-bench](../llm-guide/benchmarks/swe-bench.md) -- методология бенчмарка
- [Inference стек](../inference/README.md) -- как запускать модели на платформе
