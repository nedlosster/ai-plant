# Анонсы и открытия в мире AI-агентов

Хроника последних релизов, событий и трендов в категории AI coding agents. Дополняет [trends.md](trends.md) (долгосрочные прогнозы) и per-agent страницы в [agents/](agents/).

## 2026-Q2 (актуально)

### Apr 2026 -- Claude Mythos Preview лидирует на SWE-bench Verified (93.9%)

**10 апреля 2026** -- обновление лидерборда [SWE-bench Verified](../llm-guide/benchmarks/swe-bench.md):
- **Claude Mythos Preview** -- 93.9% (Anthropic preview-модель)
- **GPT-5.3 Codex** -- 85.0%
- **Claude Opus 4.5** -- 80.9%

Прирост за квартал: с ~76% (Q1 2026) до 93.9% (+18 п.п.). Бенчмарк приближается к насыщению, обсуждается переход на SWE-bench Pro и SWE-rebench как более сложные.

### Apr 2026 -- Cursor 3 и Composer 2

Cursor выпустил [**Cursor 3**](agents/cursor.md) -- unified workspace для управления командой агентов: пользователь делегирует параллельные задачи нескольким AI-агентам, ревьюит результаты в одном окне.

**19 марта 2026** -- релиз **Cursor Composer 2**, проприетарной coding-модели третьего поколения. Построена поверх Moonshot AI Kimi K2.5 c обширным continued pretraining и large-scale RL.

### Apr 2026 -- OpenAI Codex 5.3

Релиз [Codex 5.3](https://openai.com/) -- новые рекорды на SWE-bench Verified (85%). Промо: unlimited access на ChatGPT Pro для притока пользователей в ответ на доминирование Claude Code.

### Apr 2026 -- Devin 2.0: Interactive Planning + цена $20

Cognition выпустила **Devin 2.0**:
- **Interactive Planning** -- разработчик участвует в планировании, не только в ревью результата
- **Devin Wiki** -- авто-документирование codebase
- **Цена**: с $500/мес снижена до **$20/мес + $2.25 за ACU** (Agent Compute Unit) -- 25x дешевле для on-demand сценариев

### Apr 2026 -- "Война подписок": Anthropic vs OpenClaw

**4 апреля 2026** -- [Anthropic заблокировал использование Claude Pro/Max подписок в third-party tools](https://www.axios.com/2026/04/06/anthropic-openclaw-subscription-openai). До этого пользователи [OpenClaw](agents/openclaw.md), [Cline](agents/cline.md) и других прокси-инструментов использовали $20/$100 подписку как "бесплатный" backend через web auth.

После блокировки -- массовая миграция на:
- **Open-source модели**: Kimi 2.5, Qwen3.6-Plus
- **Локальные модели**: Qwen3-Coder Next через [opencode](agents/opencode.md), [continue-dev](agents/continue-dev.md)

**Реакция Anthropic**: запуск [Claude Code Channels](https://venturebeat.com/orchestration/anthropic-just-shipped-an-openclaw-killer-called-claude-code-channels) -- интеграция Claude Code с Telegram и Discord как "родной" канал для тех use cases которые покрывал OpenClaw.

### Apr 2026 -- Qwen3.6-Plus от Alibaba

**2 апреля 2026** -- релиз [Qwen 3.6-Plus](../models/families/qwen36.md):
- Контекст 1M токенов
- Always-on chain-of-thought
- Native function calling
- Multimodal
- Поддержка Anthropic API protocol
- Совместим с Claude Code, [opencode](agents/opencode.md), [Qwen Code](agents/qwen-code.md), Kilo Code, Cline, OpenClaw

API-only пока, open-варианты обещаны Alibaba.

### Mar 2026 -- LTX-Video 2.3, Wan 2.7

Прорыв в **видеогенерации**: LTX-Video 2.3 даёт 4K 50fps в реалтайме, Wan 2.7 -- 1080p с native audio sync. Отдельно от агентов, но влияет на coding в смысле "AI-driven content production". См. [video.md](../models/video.md).

### Mar 2026 -- $8M seed для Kilo Code

[Kilo Code](agents/kilo-code.md) поднял $8M seed funding. 1.5M+ пользователей, 302B токенов/день -- самый быстрорастущий VS Code AI extension.

## 2026-Q1

### Feb 2026 -- Claude Code 41% профдевелоперов, $1B+ ARR

[Claude Code](agents/claude-code.md) запущен в мае 2025 -- к февралю 2026 захватил **41% профессиональных разработчиков** (Pragmatic Engineer survey, n=15,000), потеснив инкумбента с 15M пользователей и enterprise-дистрибуцией Microsoft. **46% "most loved"** против 19% Cursor и 9% GitHub Copilot.

В декабре 2025 GitHub Copilot, Claude Code и Anysphere (Cursor) одновременно перешагнули **$1B ARR**. Cursor зафиксировал $500M ARR в начале 2026.

### Feb 2026 -- Claude Sonnet 4.5 / Opus 4.6 default в Claude Code

Anthropic переключил [Claude Code](agents/claude-code.md) на новые модели. Sonnet 4.5 как default (быстрее, дешевле), Opus 4.6 для $200 Max plan с 1M контекстом.

### Jan 2026 -- OpenClaw rebranded дважды

**29 января 2026** -- агент [OpenClaw](agents/openclaw.md) был переименован: Clawdbot → Moltbot → OpenClaw. Причина: trademark complaints от Anthropic.

### Jan 2026 -- Qwen3-VL 30B-A3B и 235B-A22B

Релиз [Qwen3-VL](../models/families/qwen3-vl.md) -- лучший open-source VL-агент для OCR, document understanding, video. 235B-A22B на multimodal-бенчмарках сравним с Gemini-2.5-Pro и GPT-5.

## 2025-Q4

### Dec 2025 -- HunyuanVideo 1.5 (Tencent)

Эффективная foundation video-модель -- 8.3B параметров вместо 13B в 1.0. См. [hunyuanvideo.md](../models/families/hunyuanvideo.md).

### Dec 2025 -- Devstral 2 24B (Mistral)

[Devstral 2](../models/families/devstral.md) -- лидер dense-сегмента по SWE-bench Verified (72.2% при 24B параметров). Помещается на одном RTX 4090 или Mac 32GB.

### Nov 2025 -- HunyuanVideo 1.5

Релиз 8.3B варианта (foundation для дальнейших fine-tune), уменьшение размера с 13B без потери качества.

### Q4 2025 -- Multi-agent зрелость

Появляются коммерческие агенты с встроенной multi-agent оркестрацией:
- **[Kilo Code](agents/kilo-code.md) Orchestrator** -- planner/coder/debugger sub-agents в одном продукте
- **[Claude Code](agents/claude-code.md) agent team** -- параллельные sub-agents
- **[Roo Code](agents/roo-code.md) Custom Modes** -- per-mode настройки

## 2025-Q3

### Sep 2025 -- $12.8B рынок AI coding agents

Аналитика индустрии: рынок вырос с $5.1B (2024) до $12.8B (2025). См. [README.md](README.md) для market data.

### Sep 2025 -- Qwen3-Coder Next 80B-A3B

Релиз [Qwen3-Coder Next](../models/families/qwen3-coder.md#next-80b-a3b) -- MoE с 3B активных параметров, SWE-bench Verified 70.6%. Эталон efficiency-сегмента.

## Тренды

См. [trends.md](trends.md) для долгосрочных прогнозов:
- Multi-agent -- norm к 2026
- Bounded autonomy
- Context race (1M+ норма)
- Background execution
- Computer Use mainstream

## Связано

- [README.md](README.md) -- концепты и эволюция
- [trends.md](trends.md) -- долгосрочные прогнозы
- [comparison.md](comparison.md) -- сравнительная таблица
- [agents/](agents/) -- per-agent страницы с собственными разделами "Анонсы и открытия"
