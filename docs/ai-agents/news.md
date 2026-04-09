# Анонсы и открытия в мире AI-агентов

Хроника последних релизов, событий и трендов в категории AI coding agents. Дополняет [trends.md](trends.md) (долгосрочные прогнозы) и per-agent страницы в [agents/](agents/).

## 2026-Q2 (актуально)

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
