# Анонсы и открытия в мире AI-агентов

Хроника последних релизов, событий и трендов в категории AI coding agents. Дополняет [trends.md](trends.md) (долгосрочные прогнозы), [models/news.md](../models/news.md) (релизы моделей) и per-agent страницы в [agents/](agents/).

**Детальная хроника фич Claude Code** (со всеми Skills, Hooks, MCP, Agent Teams, Channels, Remote Control): [agents/claude-code/news.md](agents/claude-code/news.md).

## 2026-Q2 (актуально)

### Apr 15 -- OpenClaw v2026.4.15 "Dreaming" release: 347K GitHub stars, native Opus 4.7

**15 апреля 2026** -- [OpenClaw](agents/openclaw/README.md) выпустил релиз "Dreaming" (`v2026.4.15`):

- **347K GitHub stars** -- most starred repository in GitHub history (обогнал предыдущих лидеров)
- **Native Claude Opus 4.7 integration** -- first-class support через тот же `claudeclaw` proxy
- **Google Gemini TTS support** -- text-to-speech через Gemini API
- **Advanced memory management** -- multi-session memory persistence для long-running agent loops
- **Security hardening после ClawHavoc**: 341 malicious skill распространялись через ClawHub marketplace в январе 2026 (incident с supply chain). v2026.4.9 ужесточил SSRF defenses и node execution injection protections, продолжено в "Dreaming"

OpenClaw закрепил позицию как production-grade open-source alternative для Fortune 500 (self-hosted security-sensitive workloads). Источники: [clawbot.blog](https://www.clawbot.blog/blog/openclaw-the-rise-of-an-open-source-ai-agent-framework-april-2026-update/), [Releasebot OpenClaw notes](https://releasebot.io/updates/openclaw).

### Apr 14 -- Claude Code: full desktop app redesign + Routines (cloud automation)

**14 апреля 2026** -- Anthropic shipped **полный редизайн** Claude Code desktop app:

- **Новый sidebar** -- проект-tree с быстрой навигацией
- **Parallel sessions** -- несколько Claude Code сессий в одном окне
- **Project tabs** -- переключение между проектами без перезапуска CLI
- **Routines** -- cloud automation layer для scheduled agent runs (replacement для Agent Teams workflow)

Anthropic также shipped 30+ releases в Claude Code за 5 недель апреля 2026 -- focus на rendering cycles, enterprise cloud setups, Linux process isolation. Подробная хроника: [agents/claude-code/news.md](agents/claude-code/news.md). Источник: [BuildToLaunch обзор](https://buildtolaunch.substack.com/p/claude-code-redesign-routines-vs-cursor-openclaw).

### Apr 2026 -- Anthropic запустил managed agent cloud service

**Апрель 2026** -- Anthropic запустил [managed agent cloud service](https://www.anthropic.com/) -- enterprise offering для развёртывания Claude-агентов на инфраструктуре Anthropic. Снимает требование к customer'ам управлять собственным compute / scaling. Конкурирует с **Cursor cloud agents on isolated VMs** (релиз в Cursor 3) и **OpenClaw self-hosted** -- "agent infrastructure race" между тремя крупными игроками.

Параллельные индустриальные сдвиги:
- **Visa открыл payment rails для autonomous agents** -- агенты могут совершать payments без human-in-the-loop verification
- **Microsoft релизнул OWASP-aligned governance toolkit** для всех 10 OWASP agentic risks -- enterprise security framework

### Apr 22 -- SpaceX берёт $60B option на покупку Cursor

**22 апреля 2026** -- [SpaceX подписал $60B option на покупку Cursor](https://9to5mac.com/) (Anysphere). Сделка предусматривает совместную разработку AI-coding на суперкомпьютере **Colossus**. Cursor пока сохраняет операционную независимость, переход в собственность SpaceX -- по решению опциона. Один из крупнейших M&A-анонсов 2026 года в AI-coding-сегменте. Источники: [9to5Mac](https://9to5mac.com/), [The New Stack](https://thenewstack.io/).

### Apr 2026 -- Cursor 3 release: cloud agents, /worktree, parallel Agent Tabs

[Cursor 3](agents/cursor.md) выпущен в апреле 2026 -- следующий шаг после Composer 2:
- **Cloud agents** на изолированных VM -- запуск задач в managed-окружении без локальных ресурсов
- **/worktree** команда для isolated branch changes -- агент работает в отдельном worktree, не трогая основное дерево
- **Self-hosted agents** -- возможность поднимать агентов на собственной инфраструктуре
- **Parallel Agent Tabs** -- несколько агентских вкладок параллельно, каждая со своим контекстом
- Внутренняя метрика Cursor: **30% PR в самом Cursor** уже сделаны агентами

### Apr 20-22 -- Kimi K2.6 (Moonshot AI) с Agent Swarm

Moonshot AI выпустила [Kimi K2.6](../models/families/kimi-k25.md) -- open-source 1T MoE нового поколения. Четыре варианта под разные сценарии: **Instant** (быстрый), **Thinking** (extended reasoning), **Agent** (single-agent workflow), **Agent Swarm** (multi-agent orchestration).

Рекорды: **HLE 54.0%**, **SWE-bench Verified 80.2%** (близко к Opus 4.6 80.8%), **SWE-Bench Pro 58.6%**, **SWE-bench Multilingual 76.7%**, **Quality Index 53.9** (live open-source лидер) -- SOTA среди open-weight. Agent Swarm вариант -- native multi-agent orchestration из коробки, без внешнего оркестратора. Веса под Apache 2.0.

### Apr 20 -- Shipper: AI-агент для web/mobile и Chrome extensions

Запущен [**Shipper**](https://shipper.ai/) -- AI-агент, который проектирует, кодит и монетизирует web/mobile-приложения и Chrome-расширения в одном workflow. Позиционируется как end-to-end решение "от идеи до платящих пользователей".

### Apr 2026 -- Cursor: $2B раунд при оценке $50B+

[Cursor](agents/cursor.md) поднял **$2B** при оценке **$50B+** (Nvidia, Thrive Capital, a16z). Для контекста: 6 месяцев назад оценка была $29.3B -- рост на ~70% за полгода. Раунд отражает доминирование Cursor в IDE-сегменте AI-агентов после релиза Composer 2.

### Apr 2026 -- Amazon +$5B в Anthropic, 5 GW compute

Amazon увеличил инвестиции в Anthropic на **дополнительные $5B** (с опцией до **$20B**). В рамках сделки -- **5 GW compute** на AWS (Trainium-кластеры), **1 GW к концу 2026**. Крупнейшее compute-партнёрство в индустрии на данный момент.

### Apr 16 -- Claude Opus 4.7 (Anthropic)

Релиз Claude Opus 4.7 (`claude-opus-4-7`):
- **SWE-bench Verified 87.6%** (Opus 4.6 было 80.8%), **SWE-bench Pro 64.3%** (было 53.4%)
- Контекст 1M tokens, max output 128K, vision 2,576px (3.75 MP)
- Новый xhigh effort level, task budgets (public beta), `/ultrareview` в Claude Code
- Rebuilt tokenizer, цена без изменений ($5/$25 per M tokens)
- Claude Design -- Anthropic Labs sub-brand, анонсирован 17 апреля
- Доступен: Claude Platform, Bedrock, Vertex AI, Microsoft Foundry

### Apr 2026 -- Claude Mythos Preview лидирует на SWE-bench Verified (93.9%)

**10 апреля 2026** -- обновление лидерборда [SWE-bench Verified](../llm-guide/benchmarks/swe-bench.md):
- **Claude Mythos Preview** -- 93.9% (Anthropic preview-модель)
- **Claude Opus 4.7** -- 87.6%
- **GPT-5.3 Codex** -- 85.0%

Прирост за квартал: с ~76% (Q1 2026) до 93.9% (+18 п.п.). Бенчмарк приближается к насыщению, обсуждается переход на SWE-bench Pro и SWE-rebench как более сложные.

### Apr 2026 -- Cursor 3 и Composer 2

Cursor выпустил [**Cursor 3**](agents/cursor.md) -- unified workspace для управления командой агентов: пользователь делегирует параллельные задачи нескольким AI-агентам, ревьюит результаты в одном окне.

**19 марта 2026** -- релиз **Cursor Composer 2**, проприетарной coding-модели третьего поколения. Построена поверх Moonshot AI Kimi K2.5 c обширным continued pretraining и large-scale RL. Бенчмарки: 61.3 CursorBench, 73.7% SWE-bench Multilingual.

### Apr 2026 -- OpenAI Codex 5.3

Релиз [Codex 5.3](https://openai.com/) -- новые рекорды на SWE-bench Verified (85%). Промо: unlimited access на ChatGPT Pro для притока пользователей в ответ на доминирование Claude Code.

### Apr 2026 -- Devin 2.0: Interactive Planning + цена $20

Cognition выпустила **Devin 2.0**:
- **Interactive Planning** -- разработчик участвует в планировании, не только в ревью результата
- **Devin Wiki** -- авто-документирование codebase
- **Цена**: с $500/мес снижена до **$20/мес + $2.25 за ACU** (Agent Compute Unit) -- 25x дешевле для on-demand сценариев

### Apr 2026 -- MCP: 97 млн установок, де-факто стандарт

Model Context Protocol (MCP) от Anthropic пересёк **97 млн установок** (данные за март 2026). Каждый крупный AI-провайдер поставляет MCP-совместимые инструменты. MCP стал default-механизмом для подключения агентов к внешним data sources и инструментам. Поддерживается: Claude Code, [Open WebUI](../apps/open-webui/README.md), [Ollama](../inference/ollama.md), Cursor, Cline, Roo Code, Kilo Code и др.

### Apr 2026 -- "Война подписок": Anthropic vs OpenClaw

**4 апреля 2026** -- [Anthropic заблокировал использование Claude Pro/Max подписок в third-party tools](https://www.axios.com/2026/04/06/anthropic-openclaw-subscription-openai). До этого пользователи [OpenClaw](agents/openclaw/README.md), [Cline](agents/cline.md) и других прокси-инструментов использовали $20/$100 подписку как "бесплатный" backend через web auth.

После блокировки -- массовая миграция на:
- **Open-source модели**: Kimi 2.5, Qwen3.6-Plus
- **Локальные модели**: Qwen3-Coder Next через [opencode](agents/opencode/README.md), [continue-dev](agents/continue-dev.md)

**Реакция Anthropic**: запуск [Claude Code Channels](https://venturebeat.com/orchestration/anthropic-just-shipped-an-openclaw-killer-called-claude-code-channels) -- интеграция Claude Code с Telegram и Discord как "родной" канал для тех use cases которые покрывал OpenClaw.

### Apr 2026 -- Qwen3.6-Plus от Alibaba

**2 апреля 2026** -- релиз [Qwen 3.6-Plus](../models/families/qwen36.md):
- Контекст 1M токенов
- Always-on chain-of-thought
- Native function calling
- Multimodal
- Поддержка Anthropic API protocol
- Совместим с Claude Code, [opencode](agents/opencode/README.md), [Qwen Code](agents/qwen-code.md), Kilo Code, Cline, OpenClaw

API-only пока, open-варианты обещаны Alibaba.

### Mar 2026 -- LTX-Video 2.3, Wan 2.7

Прорыв в **видеогенерации**: LTX-Video 2.3 даёт 4K 50fps в реалтайме, Wan 2.7 -- 1080p с native audio sync. Отдельно от агентов, но влияет на coding в смысле "AI-driven content production". См. [video.md](../models/video.md).

### Mar 2026 -- $8M seed для Kilo Code

[Kilo Code](agents/kilo-code.md) поднял $8M seed funding. 1.5M+ пользователей, 302B токенов/день -- самый быстрорастущий VS Code AI extension.

## 2026-Q1

### Feb 2026 -- Claude Code 41% профдевелоперов, $1B+ ARR

[Claude Code](agents/claude-code/README.md) запущен в мае 2025 -- к февралю 2026 захватил **41% профессиональных разработчиков** (Pragmatic Engineer survey, n=15,000), потеснив инкумбента с 15M пользователей и enterprise-дистрибуцией Microsoft. **46% "most loved"** против 19% Cursor и 9% GitHub Copilot.

В декабре 2025 GitHub Copilot, Claude Code и Anysphere (Cursor) одновременно перешагнули **$1B ARR**. Cursor зафиксировал $500M ARR в начале 2026.

### Feb 2026 -- Claude Sonnet 4.5 / Opus 4.6 default в Claude Code

Anthropic переключил [Claude Code](agents/claude-code/README.md) на новые модели. Sonnet 4.5 как default (быстрее, дешевле), Opus 4.6 для $200 Max plan с 1M контекстом. В апреле 2026 заменён на Opus 4.7.

### Jan 2026 -- OpenClaw rebranded дважды

**29 января 2026** -- агент [OpenClaw](agents/openclaw/README.md) был переименован: Clawdbot → Moltbot → OpenClaw. Причина: trademark complaints от Anthropic.

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
- **[Claude Code](agents/claude-code/README.md) agent team** -- параллельные sub-agents
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
