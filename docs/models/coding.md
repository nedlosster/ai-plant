# Модели для кодинга

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), llama-server + Vulkan.

Полные описания моделей -- в `families/`. Эта страница: сравнительные таблицы и выбор под задачу.

## Скачано на платформе

| Модель | Семейство | Параметры | Пресет |
|--------|-----------|-----------|--------|
| Qwen3-Coder-Next | [qwen3-coder](families/qwen3-coder.md#next-80b-a3b) | 80B MoE / 3B active | `vulkan/preset/qwen-coder-next.sh` |
| Qwen3-Coder-30B-A3B | [qwen3-coder](families/qwen3-coder.md#30b-a3b) | 30B MoE / 3B active | `vulkan/preset/qwen3-coder-30b.sh` |
| Qwen2.5-Coder-1.5B | [qwen25-coder](families/qwen25-coder.md#1-5b) | 1.5B dense Q8 | `vulkan/preset/qwen2.5-coder-1.5b.sh` |

## Топ open-моделей для платформы (апрель 2026)

Ранжирование по совокупности SWE-bench Verified, скорости на платформе, качества tool use и зрелости экосистемы. Все варианты помещаются в 120 GiB unified memory.

| # | Модель | SWE-V | tg tok/s | Сильное место |
|---|--------|-------|----------|----------------|
| 1 | [Qwen3-Coder Next 80B-A3B](families/qwen3-coder.md#next-80b-a3b) | 70.6% | 53 | Лучший agent-style на платформе, 256K контекст |
| 2 | [Devstral 2 24B](families/devstral.md) | **72.2%** | ~25 | Лидер dense-сегмента, FIM+agent в одной модели |
| 3 | [Qwen3-Coder 30B-A3B](families/qwen3-coder.md#30b-a3b) | ~62% | **86** | Самый быстрый chat по коду, идеален для коротких запросов |
| 4 | [Qwen2.5-Coder 32B](families/qwen25-coder.md#32b) | -- | ~12 | HumanEval 92.7%, эталон FIM, 32B dense |
| 5 | [Codestral 25.08](families/codestral.md) | -- | ~28 | Лидер LMSYS Copilot Arena по FIM, 80+ языков |

**#1 Qwen3-Coder Next** -- основной выбор для daily agentic-кодинга. 80B MoE с 3B активных параметров: качество как у 24B dense, скорость почти как у 3B. 256K контекст уверенно держит средний monorepo. Проигрывает Devstral 2 на dense-задачах с одним сложным файлом, выигрывает на multi-file orchestration и speed/quality.

**#2 Devstral 2 24B** -- лидер dense-семейства с 72.2% SWE-V (рекорд для размера). Tool use дисциплина строже MoE-вариантов, итерации более последовательные. Минус -- 25 tok/s ощутимо медленнее MoE на той же платформе, на длинных сессиях opencode выматывает.

**#3 Qwen3-Coder 30B-A3B** -- младшая MoE того же семейства. 86 tok/s даёт ощущение мгновенного ответа, идеален для "объясни функцию", "перепиши этот блок", быстрых code review. Слабее Coder Next на multi-file задачах из-за меньшего числа экспертов.

**#4 Qwen2.5-Coder 32B** -- классика dense-сегмента. HumanEval 92.7% всё ещё впечатляет, FIM-токены работают эталонно. Минус -- 12 tok/s и контекст 128K делают его непрактичным для agent loop, но как FIM-сервер премиум-уровня жив.

**#5 Codestral 25.08** -- лидер FIM в LMSYS Copilot Arena. 80+ языков покрытия, 256K контекст. Лицензия MNPL (не Apache), что для коммерческих сценариев требует внимания.

## Сравнительная таблица

| Модель | Семейство | Параметры | Active | SWE-bench V | HumanEval | FIM | FC | Контекст | Лицензия |
|--------|-----------|-----------|--------|-------------|-----------|-----|-----|----------|----------|
| Qwen3-Coder-Next | [qwen3-coder](families/qwen3-coder.md#next-80b-a3b) | 80B MoE | 3B | **70.6%** | -- | нет | **native** ⭐ | 256K | Apache 2.0 |
| Qwen3-Coder-30B-A3B | [qwen3-coder](families/qwen3-coder.md#30b-a3b) | 30B MoE | 3B | -- | -- | нет | native | 256K | Apache 2.0 |
| Devstral 2 | [devstral](families/devstral.md) | 24B dense | 24B | **72.2%** | -- | да | native | 256K | Apache 2.0 |
| Qwen2.5-Coder-32B | [qwen25-coder](families/qwen25-coder.md#32b) | 32B dense | 32B | -- | **92.7%** | да | native | 128K | Apache 2.0 |
| Codestral 25.08 | [codestral](families/codestral.md) | 22B dense | 22B | -- | 86.6% | **да (лидер FIM)** | native | 256K | MNPL |
| Qwen2.5-Coder-7B | [qwen25-coder](families/qwen25-coder.md#7b) | 7B dense | 7B | -- | 88.4% | да | partial | 128K | Apache 2.0 |
| Qwen2.5-Coder-1.5B | [qwen25-coder](families/qwen25-coder.md#1-5b) | 1.5B dense | 1.5B | -- | ~75% | да | нет | 128K | Apache 2.0 |

⭐ Лучший FC на платформе для agent-style кодинга. Запуск с `--jinja` обязателен -- см. [llm-guide/function-calling.md](../llm-guide/function-calling.md#function-calling-на-платформе-2026).

## Бенчмарки на платформе (Vulkan, llama-bench pp512/tg128)

| Модель | Размер | pp tok/s | tg tok/s |
|--------|--------|----------|----------|
| Qwen2.5-Coder-1.5B Q8_0 | 1.5 GiB | 5245 | **120.6** |
| Qwen3-Coder-30B-A3B Q4_K_M | 17.3 GiB | 1036 | **86.1** |
| Qwen3-Coder-Next Q4_K_M | 45.1 GiB | 590 | **53.2** |

MoE-модели (Qwen3-Coder) дают высокую скорость генерации за счёт малой активации. Dense 32B при том же VRAM дал бы ~12 tok/s.

### ROCm/HIP (тест 2026-04-09)

| Модель | Размер | pp tok/s | tg tok/s | vs Vulkan |
|--------|--------|----------|----------|-----------|
| Qwen3-Coder-30B-A3B Q4_K_M | 17.3 GiB | 441 | **63.5** | pp -57%, tg -26% |
| Qwen3-Coder-Next Q4_K_M | 45.1 GiB | **OOM** | -- | `hipMalloc` не может выделить 45 GiB |

Vulkan быстрее HIP во всех тестах. **Vulkan -- рекомендованный backend для inference на Strix Halo**. ROCm использовать для PyTorch-задач (ACE-Step, training). Подробнее: [docs/inference/rocm-setup.md](../inference/rocm-setup.md#hip-inference-ограничение-по-vram-аллокации-2026-04-09).

## Выбор под задачу

### IDE FIM (autocomplete)

[Codestral 25.08](families/codestral.md) -- лидер LMsys copilot arena по FIM, 80+ языков, 256K контекст.
[Qwen2.5-Coder 1.5B](families/qwen25-coder.md#1-5b) -- если нужна минимальная латентность (120 tok/s).

### Agent-style ([opencode](../ai-agents/agents/opencode.md), [Aider](../ai-agents/agents/aider.md), [Cline](../ai-agents/agents/cline.md), SWE-agent)

[Qwen3-Coder Next](families/qwen3-coder.md#next-80b-a3b) -- лидер MoE efficiency (70.6% SWE-V при 3B active), 256K контекст. Используется на платформе через `vulkan/preset/qwen-coder-next.sh`.
[Devstral 2 24B](families/devstral.md) -- лидер dense (72.2% SWE-V), FIM+agent в одной модели.

### Универсальный chat по коду

[Qwen3-Coder 30B-A3B](families/qwen3-coder.md#30b-a3b) -- 86 tok/s на платформе, 256K контекст, идеальное соотношение качество/скорость.

### Максимум качества HumanEval

[Qwen2.5-Coder 32B](families/qwen25-coder.md#32b) -- 92.7% HumanEval, на 120 GiB можно держать в Q8 (~40 GiB) + параллельный 1.5B FIM.

### Многоязычное программирование

[Codestral 25.08](families/codestral.md) -- 80+ языков от стандартных до экзотики.

## FIM-совместимость

| Модель | FIM |
|--------|-----|
| [qwen25-coder](families/qwen25-coder.md) (все размеры) | да |
| [codestral](families/codestral.md) | да (лидер) |
| [devstral](families/devstral.md) | да |
| [qwen3-coder](families/qwen3-coder.md) | **нет** |

## Два сервера одновременно

FIM (1.5B Q8, ~2 GB) + Chat (Qwen3-Coder-Next, ~45 GB) = ~47 GB. Остаётся ~73 GB на параллельные модели.

```bash
# Терминал 1: FIM (порт 8080)
./scripts/inference/start-fim.sh Qwen2.5-Coder-1.5B-Instruct-Q8_0.gguf --daemon

# Терминал 2: Chat agent (порт 8081, через пресет)
./scripts/inference/vulkan/preset/qwen-coder-next.sh -d
```

## Инструменты

| Инструмент | Рекомендуемая модель | Порт |
|-----------|----------------------|------|
| [Continue.dev](../ai-agents/agents/continue-dev.md) autocomplete | [Codestral](families/codestral.md) / [Qwen2.5-Coder 1.5B](families/qwen25-coder.md#1-5b) | 8080 (/infill) |
| [Continue.dev](../ai-agents/agents/continue-dev.md) chat | [Qwen3-Coder 30B-A3B](families/qwen3-coder.md#30b-a3b) / [Devstral 2](families/devstral.md) | 8081 |
| [Aider](../ai-agents/agents/aider.md) | [Qwen3-Coder Next](families/qwen3-coder.md#next-80b-a3b) | 8081 |
| [Cline](../ai-agents/agents/cline.md) / [Roo Code](../ai-agents/agents/roo-code.md) | [Qwen3-Coder Next](families/qwen3-coder.md#next-80b-a3b) | 8081 |
| SWE-agent | [Qwen3-Coder Next](families/qwen3-coder.md#next-80b-a3b) | 8081 |
| [opencode](../ai-agents/agents/opencode.md) | [Qwen3-Coder Next](families/qwen3-coder.md#next-80b-a3b) (256K) | 8081 |

## Стратегия использования моделей в opencode

[opencode](../ai-agents/agents/opencode.md) позволяет переключать модели на лету (`/model`) и держать несколько провайдеров в одном конфиге. На нашей платформе разные модели крутятся параллельно через пресеты в `scripts/inference/vulkan/preset/` на разных портах.

### Маппинг задача → модель

| Задача | Модель | Порт | Почему |
|--------|--------|------|--------|
| Daily agent loop (multi-file edits, refactor) | [Qwen3-Coder Next](families/qwen3-coder.md#next-80b-a3b) | 8081 | 256K, 70.6% SWE-V, 53 tok/s достаточно для loop |
| Быстрые однофайловые правки, "объясни код" | [Qwen3-Coder 30B-A3B](families/qwen3-coder.md#30b-a3b) | 8082 | 86 tok/s -- мгновенный отклик |
| Architecture review, multi-step reasoning | [Devstral 2 24B](families/devstral.md) | 8083 | dense 72.2% SWE-V, более последовательные планы |
| Скриншот ошибки → код | [Gemma 4 26B-A4B](families/gemma4.md) + mmproj | 8081 | screenshot-to-code, vision из коробки |
| FIM в IDE параллельно с opencode chat | [Qwen2.5-Coder 1.5B Q8](families/qwen25-coder.md#1-5b) | 8080 | 120 tok/s, 2 GiB |
| Frontier-задачи (когда local не вытягивает) | [Kimi K2.5](families/kimi-k25.md) через API | -- | $0.45/1M, 76.8% SWE-V |

### Параллельные конфигурации (что во что помещается)

120 GiB позволяет держать несколько серверов одновременно:

- **Стандарт**: FIM 1.5B (~2 GiB) + Coder Next (~45 GiB) = 47 GiB → 73 GiB запас
- **Расширенный**: FIM + Coder Next + Coder 30B-A3B (~17 GiB) = 64 GiB → 56 GiB запас
- **Максимум**: FIM + Coder Next + Devstral 2 (~14 GiB) + Gemma 4 26B (~16 GiB) = 77 GiB → 43 GiB запас (`--parallel 1` обязательно везде)

### Конфиг opencode (фрагмент)

```json
{
  "provider": {
    "local-coder-next": {
      "type": "openai",
      "baseURL": "http://192.168.1.77:8081/v1",
      "models": { "qwen3-coder-next": { "name": "Qwen3-Coder Next" } }
    },
    "local-coder-30b": {
      "type": "openai",
      "baseURL": "http://192.168.1.77:8082/v1",
      "models": { "qwen3-coder-30b": { "name": "Qwen3-Coder 30B-A3B" } }
    },
    "local-devstral": {
      "type": "openai",
      "baseURL": "http://192.168.1.77:8083/v1",
      "models": { "devstral-2": { "name": "Devstral 2 24B" } }
    },
    "kimi-cloud": {
      "type": "openai",
      "baseURL": "https://api.moonshot.ai/v1",
      "models": { "kimi-k2.5": { "name": "Kimi K2.5" } }
    }
  }
}
```

Переключение в TUI: `/model local-coder-next/qwen3-coder-next` для daily, `/model kimi-cloud/kimi-k2.5` для frontier-режима.

### Антипаттерны

- **Не использовать [Qwen3.5 122B-A10B](families/qwen35.md) как coder backend** -- universal-серия, 22 tok/s убивает agentic loop. Подробнее в [families/qwen35.md](families/qwen35.md#имеет-ли-смысл-в-агентах-кодинга).
- **Не запускать два больших сервера с -ngl 99** без `--parallel 1` -- конфликт по memory pressure, sliding-window cache схлопывается.
- **Не использовать Qwen3-Coder для FIM** -- серия не поддерживает FIM-токены, только chat-интерфейс. Для FIM брать [Qwen2.5-Coder](families/qwen25-coder.md) или [Codestral](families/codestral.md).
- **Не выбирать модель с контекстом <32K** для opencode -- repo map + grep + tool history съедают 16-24K только на старт.

## Open vs облачные лидеры (апрель 2026)

Сравнение нашего локального стека с frontier-моделями. Цифры -- последние известные на апрель 2026 (см. источники в "Где смотреть рейтинги" ниже).

| Модель | SWE-V | Открыта | На 120 GiB | $/1M input | Примечание |
|--------|-------|---------|------------|-----------|------------|
| Claude Mythos Preview | **93.9%** | нет | нет | -- | preview, лидер leaderboard |
| GPT-5.3 Codex | 85.0% | нет | нет | $10 | OpenAI, актуальный flagship |
| Claude Opus 4.5 | 80.9% | нет | нет | $15 | Anthropic flagship |
| MiniMax M2.5 | 80.2% | да (671B) | нет | $0.30 | open, но не помещается |
| Gemini 3.1 Pro Preview | 78.8% | нет | нет | $1.25 | Google flagship |
| GLM-5 (744B) | 77.8% | да | нет (~440 GiB) | -- | open, не помещается |
| Kimi K2.5 (1T MoE) | 76.8% | да | нет (240+ GiB) | $0.45 | open, frontier через API |
| **Devstral 2 24B** | **72.2%** | да | **да** ⭐ | $0 | топ open на платформе |
| **Qwen3-Coder Next 80B-A3B** | **70.6%** | да | **да** ⭐ | $0 | топ MoE на платформе |

**Вывод**: локальный open-стек на платформе отстаёт от Claude Opus 4.5 / GPT-5.3 Codex на 8-15 пунктов SWE-V. При нулевой инференс-стоимости, privacy и отсутствии rate limits эта разница приемлема для большинства задач разработки. Frontier-tier (Mythos, GPT-5.3 Codex) ощутимо лучше на сложных multi-step задачах и редких языках, локальный стек -- на повторяющихся, шаблонных и типичных рефакторингах. Гибридная стратегия: daily-loop локально, frontier через API ([Kimi K2.5](families/kimi-k25.md) за $0.45/1M -- лучший value).

**Caveat**: в марте 2026 OpenAI опубликовала аудит, согласно которому frontier-модели (GPT-5.2, Claude Opus 4.5, Gemini 3 Flash) воспроизводили verbatim gold patches на части задач SWE-bench Verified -- то есть бенчмарк частично загрязнён. OpenAI прекратила публиковать Verified-цифры, рекомендуя [SWE-Bench Pro](https://www.morphllm.com/swe-bench-pro). Цифры выше следует читать с этой поправкой.

## Где смотреть актуальные рейтинги

- [SWE-bench Leaderboards](https://www.swebench.com/) -- основной agentic-бенчмарк (Verified, Pro, Multimodal)
- [SWE-Bench Pro](https://www.morphllm.com/swe-bench-pro) -- contamination-resistant вариант, рекомендован OpenAI вместо Verified
- [Aider Polyglot Leaderboard](https://aider.chat/docs/leaderboards/) -- multi-language code editing через Aider
- [LiveCodeBench](https://livecodebench.github.io/leaderboard.html) -- contamination-free, обновляется ежемесячно
- [BigCodeBench](https://bigcode-bench.github.io/) -- реальные библиотеки и API, не учебные задачи
- [EvalPlus (HumanEval+ / MBPP+)](https://evalplus.github.io/leaderboard.html) -- расширенный HumanEval с дополнительными тестами
- [LMSYS WebDev Arena](https://web.lmarena.ai/leaderboard) -- frontend, human preference voting
- [LMSYS Copilot Arena](https://lmarena.ai/) -- FIM, IDE-style завершение
- [llm-stats: SWE-bench Verified](https://llm-stats.com/benchmarks/swe-bench-verified) -- агрегатор leaderboard
- [Artificial Analysis: Coding](https://artificialanalysis.ai/) -- скорость + цена + качество в одной таблице
- [Hugging Face Open LLM Leaderboard](https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard) -- общий, для open-моделей
- [Vals AI: SWE-bench](https://www.vals.ai/benchmarks/swebench) -- независимая верификация
- [Epoch AI: SWE-bench Verified](https://epoch.ai/benchmarks/swe-bench-verified/) -- исторические данные

## Слухи, новости, ожидания (Q2-Q3 2026)

### Уже анонсировано / API доступно

- **[Qwen3.6-Plus](families/qwen36.md)** (Alibaba, 2 апреля 2026) -- agentic coding уровня Claude 4.5 Opus, 1M контекст, native function calling, multimodal. API-only через Alibaba Cloud Model Studio. Open-варианты обещаны "в developer-friendly размерах" -- ждём 30-122B диапазон в Q2-Q3, по аналогии с Qwen3.5.
- **[Kimi K2.5](families/kimi-k25.md)** (Moonshot AI, январь 2026) -- 1T MoE открыт, 76.8% SWE-V, лидер open-source. Локально не помещается (240+ GiB), на платформе только через API за $0.45/1M.
- **Claude Mythos Preview** -- лидер SWE-bench Verified (93.9%) от Anthropic, preview-режим, в production раскатки нет.

### Ожидания (слухи и пайплайны вендоров)

- **Devstral 3** (Mistral) -- слухи о релизе Q2 2026, ожидается 30-40B dense с прицелом на 75%+ SWE-V и нативный agent loop. Логичное продолжение [Devstral 2](families/devstral.md).
- **Qwen3.6-Coder** -- coder-вариант на базе Qwen3.6, по аналогии с Qwen3-Coder Next/30B-A3B. Если останется MoE с 3B active -- поместится на платформу и потенциально станет новым топ-1.
- **GLM-5 distill** (Zhipu AI) -- обсуждается дистилляция 744B флагмана в 30-70B размер. Если выйдет и сохранит хотя бы половину качества (≈60-65% SWE-V) -- сильный кандидат для платформы.
- **DeepSeek V3.2 Coder distill** -- слухов мало, V3.2 уже есть, distill-вариант под кодинг ожидаем.
- **Anthropic open-source модель** -- заявлено в дорожной карте на 2026, конкретики нет, после блокировки Claude Pro/Max в third-party tools (4 апреля 2026) у Anthropic появилась мотивация выпустить open-вариант.
- **OpenAI open-weights** -- gpt-oss серия (август 2025) пока не получила coder-варианта, ждём anonsa.

### События в экосистеме агентов

См. [docs/ai-agents/news.md](../ai-agents/news.md) -- хроника релизов и событий:
- **Apr 2026** -- блокировка Claude Pro/Max в third-party tools, миграция на Kimi K2.5 / Qwen3.6-Plus
- **Apr 2026** -- Claude Code Channels (Telegram/Discord интеграция как ответ на OpenClaw)
- **Mar 2026** -- $8M seed для [Kilo Code](../ai-agents/agents/kilo-code.md), 1.5M+ пользователей
- **Feb 2026** -- Claude Sonnet 4.5 / Opus 4.6 default в Claude Code

### Источники для отслеживания

- [Hugging Face: новые модели по тегу code](https://huggingface.co/models?other=code) -- свежие релизы
- [r/LocalLLaMA](https://www.reddit.com/r/LocalLLaMA/) -- основной community-хаб
- [Simon Willison's blog](https://simonwillison.net/) -- разборы релизов
- [Latent Space podcast](https://www.latent.space/) -- индустриальные тренды
- [Hacker News: Show HN / front page](https://news.ycombinator.com/) -- ранние анонсы

## Не помещаются на платформе

- GLM-5 (744B) -- 77.8% SWE-bench Verified, не помещается даже в Q4 (~440 GB)
- MiniMax M2.5 -- 80.2% SWE-bench Verified, не помещается (~150 GB)
- DeepSeek V3.2 -- 671B MoE, не помещается
- [Kimi K2.5](families/kimi-k25.md) -- 1T MoE, 76.8% SWE-V, минимум 240 GB

Эти модели в каталог моделей не включены (кроме Kimi K2.5 с пометкой), см. описание в README.md.

## Связанные направления

- [llm.md](llm.md) -- общие LLM
- [vision.md](vision.md) -- multimodal (в т.ч. для скриншотов в [opencode](../ai-agents/agents/opencode.md))
- [tts.md](tts.md) -- voice cloning
