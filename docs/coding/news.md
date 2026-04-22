# AI-кодинг: хроника событий

Хроника релизов и событий в AI-assisted разработке: coding LLM, agents, инструменты, индустрия. Обновляется скиллом `/refresh-news coding`.

Профиль раздела -- [README.md](README.md). Каталог моделей -- [models/coding.md](../models/coding.md). Агенты -- [ai-agents/](../ai-agents/README.md).

---

## SWE-bench Verified лидерборд (апрель 2026)

| # | Модель | Verified | Pro | Вендор | Доступ |
|---|--------|----------|-----|--------|--------|
| 1 | Claude Mythos Preview | 93.9% | -- | Anthropic | preview |
| 2 | Claude Opus 4.7 | 87.6% | 64.3% | Anthropic | API |
| 3 | GPT-5.3 Codex | 85.0% | ~57% | OpenAI | API |
| 4 | Claude Opus 4.5 | 80.9% | 45.9% | Anthropic | устарел (заменён 4.7) |
| 5 | Gemini 3.1 Pro | 78.8% | 54.2% | Google | API |
| 6 | GLM-5 | 77.8% | -- | Zhipu AI | open MIT |
| 7 | GPT-5.4 | -- | 57.7% | OpenAI | API |
| 8 | GLM-5.1 | 58.4% | 58.4% | Zhipu AI | open MIT, SWE-Pro |
| 9 | Kimi K2.6 | -- | **58.6%** | Moonshot | open Apache 2.0 (Apr 20-22) |
| 10 | Kimi K2.5 | ~75% | -- | Moonshot | API |
| 11 | Qwen3-Coder Next | ~48% | -- | Alibaba | open, local |
| 12 | Devstral 2 | ~47% | -- | Mistral | open, local |

Источники: [swebench.com](http://www.swebench.com/), [llm-stats.com](https://llm-stats.com/benchmarks/swe-bench-verified)

Примечание: SWE-bench Verified результаты выше 80% вызывают вопросы о data contamination. SWE-bench Pro ([labs.scale.com](https://labs.scale.com/leaderboard/swe_bench_pro_public)) -- более надёжный индикатор реального agentic coding.

---

## 2026-Q2

### Апрель 2026

**Apr 20-22 -- Kimi K2.6 (Moonshot AI)**
- 1T MoE, open-source (Apache 2.0), четыре варианта: Instant / Thinking / Agent / Agent Swarm
- **HLE 54.0%** (SOTA), **SWE-Bench Pro 58.6%** (лидер open-weight, опережает GLM-5.1), **SWE-bench Multilingual 76.7%**
- Agent Swarm -- native multi-agent orchestration
- Подробнее: [ai-agents/news.md](../ai-agents/news.md), [models/families/kimi-k25.md](../models/families/kimi-k25.md)

**Apr 2026 -- Qwen3.6-Max-Preview (Alibaba)**
- Early preview следующего flagship семейства Qwen
- Улучшенный agentic coding: tool use, multi-step планирование, long-horizon задачи
- API-only через Alibaba Cloud Model Studio
- [qwenlm.github.io](https://qwenlm.github.io/)

**Apr 16 -- Claude Opus 4.7 (Anthropic)**
- Model ID: `claude-opus-4-7`, контекст 1M tokens, max output 128K
- SWE-bench Verified 87.6% (Opus 4.6 было 80.8%), SWE-bench Pro 64.3% (было 53.4%)
- Vision: 2,576px (3.75 MP), было 1,568px (1.15 MP)
- Новый xhigh effort level (между high и max)
- Task budgets (public beta) -- контроль расхода токенов на задачу
- `/ultrareview` command в Claude Code
- Rebuilt tokenizer
- Цена без изменений: $5/$25 per M tokens
- Claude Design (Anthropic Labs sub-brand) -- анонсирован на следующий день
- Доступен: Claude Platform, Bedrock, Vertex AI, Microsoft Foundry
- [anthropic.com/blog](https://www.anthropic.com/blog)

**Apr 17 -- llama.cpp b8708**
- ROCm 7.2.1: native gfx1151 в целевых GPU
- Vulkan backend: улучшения производительности и стабильности
- [Release notes](https://github.com/ggml-org/llama.cpp/releases/tag/b8708)

**Apr 14 -- Claude Code Opus 4.6 (1M context)**
- Новая модель: Opus 4.6 с 1M context window
- SWE-bench Verified 80.8% (агентный режим)
- Market share Claude Code ~41% среди coding-агентов
- [Anthropic blog](https://www.anthropic.com/blog)

**Apr 10 -- Cursor Composer 2**
- CursorBench 61.3 (+37% относительно Composer 1.5)
- SWE-bench Multilingual 73.7%
- Введён новый бенчмарк CursorBench для оценки IDE-интеграции
- [cursor.com](https://www.cursor.com/)

**Apr 4 -- Anthropic блокирует third-party tools**
- Claude Pro/Max подписки заблокированы для OpenClaw, Cline и других сторонних клиентов
- Часть пользователей мигрирует на Kimi K2.5 и Qwen 3.6
- Подробнее: [ai-agents/news.md](../ai-agents/news.md)

**Apr 2026 -- GLM-5.1 лидирует SWE-Bench Pro**
- 58.4% на SWE-Bench Pro -- первое место среди open-weight моделей
- Design2Code 94.8% (GLM-5V-Turbo)
- MIT лицензия, обучена на Huawei Ascend NPU
- [chatglm.cn](https://chatglm.cn/)

### Значимые блог-посты Q2 2026

| Дата | Автор/Источник | Тема | Ссылка |
|------|---------------|------|--------|
| Apr 2026 | DataCamp | OpenClaw vs Claude Code: полное сравнение | [datacamp.com](https://www.datacamp.com/blog/openclaw-vs-claude-code) |
| Apr 2026 | MindStudio | OpenClaw vs Claude Code Channels vs Managed Agents | [mindstudio.ai](https://www.mindstudio.ai/blog/openclaw-vs-claude-code-channels-vs-managed-agents-2026) |
| Apr 2026 | Codegen | Best AI Coding Agents Ranked | [codegen.com](https://codegen.com/blog/best-ai-coding-agents/) |
| Apr 2026 | MorphLLM | SWE-Bench Pro: Why 46% Beats 81% | [morphllm.com](https://www.morphllm.com/swe-bench-pro) |
| Apr 2026 | Qodo | 15 Best AI Coding Assistant Tools | [qodo.ai](https://www.qodo.ai/blog/best-ai-coding-assistant-tools/) |

---

## 2026-Q1

### Март 2026

**Mar 2026 -- OpenClaw "Claude Code killer" хайп**
- VentureBeat, DataCamp, AnalyticsVidhya -- масштабное освещение
- Позиционирование как "Life OS" (coding + general automation) vs coding-only инструменты
- Open-source core, коммерческий cloud-план
- [openclaw.ai](https://openclaw.ai/)

**Mar 2026 -- Devstral 2 (Mistral)**
- 24B dense, SWE-bench Verified ~47%
- Apache 2.0, помещается на Strix Halo (~14 GiB при Q4_K_M)
- Ориентирован на локальный inference
- [Карточка модели](../models/families/devstral.md)

**Mar 2026 -- InternVL3-38B (Shanghai AI Lab)**
- Мультимодальная модель, сильные coding-бенчмарки
- Open-source, MIT лицензия
- [huggingface.co/OpenGVLab](https://huggingface.co/OpenGVLab)

### Февраль 2026

**Feb 2026 -- Claude Code Agent Teams (experimental)**
- Параллельные sub-агенты для крупных кодовых задач
- Архитектура: Opus 4.6 lead + Sonnet 4.5 executors
- [Guide](../ai-agents/agents/claude-code/agent-teams.md)

**Feb 2026 -- Peter Steinberger (OpenClaw) уходит в OpenAI**
- Создатель OpenClaw присоединился к OpenAI
- Проект продолжает развиваться community-driven

**Feb 2026 -- Qwen3.5-35B (Alibaba)**
- 35B dense, 128K context, strong reasoning
- Apache 2.0, хорошо подходит для local coding
- [qwenlm.github.io](https://qwenlm.github.io/)

### Январь 2026

**Jan 2026 -- Devin снижает цену до $20/мес**
- Ранее $500/мес единственный план
- Core план: $20/мес + $2.25/ACU (compute unit)
- Открыт индивидуальный доступ (ранее только team)
- [devin.ai](https://devin.ai/)

**Jan 2026 -- Kimi K2.5 интеграция с агентами**
- 1T MoE, сильный reasoning и coding
- De facto standard для open-source coding-агентов
- [kimi.moonshot.cn](https://kimi.moonshot.cn/)

**Jan 2026 -- Windsurf (Codeium) обновляет pricing**
- Pro $15/мес (ранее $10), Ultimate $60/мес
- Agentic mode с multi-file editing
- [windsurf.com](https://windsurf.com/)

---

## 2025-Q4

### Декабрь 2025

**Dec 2025 -- Qwen3-Coder Next (Alibaba)**
- 80B MoE (3B active), 128K context
- SWE-bench Verified ~48%, FIM (fill-in-the-middle) support
- Apache 2.0, оптимизирован для local deployment
- [Карточка модели](../models/families/qwen3-coder.md)

**Dec 2025 -- Claude Opus 4.5 (Anthropic)**
- 200K context, extended thinking
- SWE-bench Verified 80.9%
- [anthropic.com/claude](https://www.anthropic.com/claude)

### Ноябрь 2025

**Nov 2025 -- Claude Code Skills + Hooks**
- Skills: markdown-based slash commands для расширения агента
- Hooks: shell scripts на events (pre/post tool use, notification)
- Значительно расширяет возможности кастомизации workflow
- [Skills guide](../ai-agents/agents/claude-code/skills-guide.md), [Hooks guide](../ai-agents/agents/claude-code/hooks-guide.md)

**Nov 2025 -- GitHub Copilot Agent Mode GA**
- Agentic coding в VS Code (terminal commands, multi-file edits)
- Доступен всем подписчикам Copilot
- [github.blog](https://github.blog/)

### Октябрь 2025

**Oct 2025 -- MCP standard (Anthropic)**
- Model Context Protocol -- открытый стандарт интеграции LLM с инструментами
- К апрелю 2026: 97M установок, 12k+ серверов
- Поддержан VS Code, JetBrains, Cursor, Windsurf
- [MCP setup guide](../ai-agents/agents/claude-code/mcp-setup.md)

**Oct 2025 -- Cline 3.0 (open-source agent)**
- Autonomous coding agent для VS Code
- Поддержка любых LLM провайдеров через API
- [cline.bot](https://cline.bot/)

---

## 2025-Q3

### Сентябрь 2025

**Sep 2025 -- Claude Code GA**
- General Availability после beta-периода
- CLI-based coding agent с Plan mode, multi-file edits
- Max subscription: $200/мес (5x rate limits)
- [anthropic.com/claude-code](https://www.anthropic.com/claude-code)

**Sep 2025 -- OpenAI Codex (cloud agent)**
- Cloud-based coding agent
- Sandboxed execution environment
- Интеграция с GitHub (PR, issues)
- [openai.com/codex](https://openai.com/codex)

### Август 2025

**Aug 2025 -- DeepSeek-Coder-V3 анонс**
- Следующая итерация на базе DeepSeek-V3 architecture
- MIT лицензия (ожидалось)
- [deepseek.com](https://www.deepseek.com/)

### Июль 2025

**Jul 2025 -- SWE-bench Pro launch (Scale AI)**
- Cleaned dataset: исключены утечки из training data
- Более надёжная оценка реального agentic coding
- [labs.scale.com](https://labs.scale.com/leaderboard/swe_bench_pro_public)

**Jul 2025 -- Cursor 1.0**
- Первый стабильный релиз
- Composer mode: multi-file agentic editing
- [cursor.com](https://www.cursor.com/)

---

## 2025-Q2

**Jun 2025 -- Claude Sonnet 4 (Anthropic)**
- Coding-оптимизированная модель среднего класса
- Быстрая, хорошо подходит для sub-agent роли
- [anthropic.com](https://www.anthropic.com/)

**May 2025 -- Codestral 25.01 (Mistral)**
- 32K context, FIM-оптимизирован
- Хорошая производительность для autocomplete
- [mistral.ai](https://mistral.ai/)

**Apr 2025 -- Claude Code public beta**
- Terminal-based coding agent
- Plan mode, CLAUDE.md project memory
- [anthropic.com](https://www.anthropic.com/)

---

## Что следить (Q2-Q3 2026)

### Ожидаемые релизы

- **Qwen4-Coder (Alibaba)** -- следующее поколение, ожидается Q3 2026
- **Llama 4 Coder (Meta)** -- coding-специализация на базе Maverick architecture
- **DeepSeek-Coder-V3** -- потенциальный coding fine-tune DeepSeek-V3.2-Speciale
- **ROCm 7.2+** -- native gfx1151, возможный fix VRAM limit для APU
- **Claude Code Channels** -- многопоточные сессии (в разработке)

### Тренды

- **SWE-bench Verified загрязнён** -- результаты >80% вероятно содержат утечки из training data; SWE-bench Pro становится основным бенчмарком
- **Multi-agent coding** -- Agent Teams, parallel sub-agents, supervisor + executor архитектура
- **MCP как де-факто стандарт** -- интеграция LLM с инструментами через Model Context Protocol
- **Local models догоняют cloud** -- GLM-5 (MIT) = 77.8% SWE-bench, Qwen3-Coder Next = ~48% на consumer GPU
- **IDE-агенты vs CLI-агенты** -- Cursor/Windsurf (IDE) vs Claude Code/OpenClaw (CLI/terminal)
- **Pricing pressure** -- Devin $500 -> $20, Windsurf $10 -> $15, конкуренция снижает цены
- **Open-weight coding models** -- Devstral 2, GLM-5, Qwen3-Coder позволяют полностью локальную разработку

---

## Связанные статьи

- [README.md](README.md) -- обзор раздела
- [resources.md](resources.md) -- блоги, рассылки, community
- [workflows.md](workflows.md) -- практические workflow'ы
- [Модели для кодинга](../models/coding.md) -- каталог open LLM
- [AI-агенты: хроника](../ai-agents/news.md) -- новости агентов (шире чем coding)
- [SWE-bench](../llm-guide/benchmarks/swe-bench.md) -- методология бенчмарка
