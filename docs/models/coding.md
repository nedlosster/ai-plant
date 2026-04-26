# Модели для кодинга

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), llama-server + Vulkan.

Полные описания моделей -- в [`families/`](families/README.md). Эта страница: сравнительные таблицы и выбор под задачу.

## Скачано на платформе

| Модель | Семейство | Параметры | Пресет |
|--------|-----------|-----------|--------|
| Qwen3-Coder-Next | [qwen3-coder](families/qwen3-coder.md#next-80b-a3b) | 80B MoE / 3B active | `vulkan/preset/qwen-coder-next.sh` |
| Qwen3-Coder-30B-A3B | [qwen3-coder](families/qwen3-coder.md#30b-a3b) | 30B MoE / 3B active | `vulkan/preset/qwen3-coder-30b.sh` |
| Qwen3.6-35B-A3B | [qwen36](families/qwen36.md#35b-a3b) | 35B MoE / 3B active (vision) | пресет TODO |
| Qwen2.5-Coder-1.5B | [qwen25-coder](families/qwen25-coder.md#1-5b) | 1.5B dense Q8 | `vulkan/preset/qwen2.5-coder-1.5b.sh` |

## Топ open-моделей для платформы (апрель 2026)

Ранжирование по совокупности SWE-bench Verified, скорости на платформе, качества tool use и зрелости экосистемы. Все варианты помещаются в 120 GiB unified memory.

| # | Модель | SWE-V | tg tok/s | Сильное место |
|---|--------|-------|----------|----------------|
| 1 | [Qwen 3.6-27B](families/qwen36.md#27b) | **77.2%** | ~15 (оценка) | Лидер локального SWE-V, multimodal (vision) |
| 2 | [Qwen 3.6-35B-A3B](families/qwen36.md#35b-a3b) | **73.4%** | ~80 (оценка) | Лидер MoE на платформе с vision, новый default daily agent |
| 3 | [Qwen3-Coder Next 80B-A3B](families/qwen3-coder.md#next-80b-a3b) | 70.6% | 53 | Лучший agent-style на скорости, 256K контекст |
| 4 | [Devstral 2 24B](families/devstral.md) | 72.2% | ~25 | Лидер dense-сегмента 24B, FIM+agent в одной модели |
| 5 | [Qwen3-Coder 30B-A3B](families/qwen3-coder.md#30b-a3b) | ~62% | **86** | Самый быстрый chat по коду, идеален для коротких запросов |
| 6 | [Qwen2.5-Coder 32B](families/qwen25-coder.md#32b) | -- | ~12 | HumanEval 92.7%, эталон FIM, 32B dense |
| 7 | [Codestral 25.08](families/codestral.md) | -- | ~28 | Лидер LMSYS Copilot Arena по FIM, 80+ языков |

### Не помещаются на платформе (для справки)

- **Qwen3-Coder-480B-A35B-Instruct** (256K-1M контекст) -- флагман семейства, 480B total / 35B active. ~270 GB Q4.
- **Kimi-Dev-72B** (Moonshot AI, 2026) -- 72B dense, конкурент Devstral 2 в dense-сегменте, ~42 GB Q4 -- помещается, но не интегрирован в пресеты.
- **DeepSeek V3.2** (671B MoE, MIT license) -- consistently strong scores на всех бенчмарках, ~390 GB Q4.
- **MiniMax M2.7** (апрель 2026) -- open-source, SWE-Pro **56.2%** (был рекорд open-source до GLM-5.1), Terminal-Bench 2 57.0%. Размер не раскрыт, предположительно >120 GiB. [HuggingFace](https://huggingface.co/MiniMaxAI). См. [news.md](news.md).
- **[GLM-5.1](families/glm.md)** (Z.ai, 7 апреля 2026) -- 744B MoE / 44B active, MIT, **SWE-Pro 58.4%** (первый open-weight в топе лидерборда, обогнал GPT-5.4 и Claude Opus 4.6). ~440 GB Q4, используется через API. Полный профиль: [families/glm.md](families/glm.md).
- **[Kimi K2.6](families/kimi-k25.md)** (Moonshot, 20-22 апреля 2026) -- 1T MoE, Modified MIT, **SWE-V 80.2%** (близко к Claude Opus 4.6 80.8%), **SWE-Bench Pro 58.6%**, HLE 54.0%, SWE-bench Multilingual 76.7%. Четыре варианта: Instant / Thinking / Agent / Agent Swarm (до 300 агентов). Quality Index 54 (#1 open-source). ~240+ GB Q4, через API. См. [news.md](news.md).
- **Xiaomi MiMo V2.5-Pro** (22 апреля 2026) -- 1T MoE / 42B active, multimodal (text+vision+audio), **SWE-Pro 57.2%** (выше Opus 4.6 53.4%), **Terminal-Bench 2.0 86.7%** (лидер). 1M контекст. Open-source "soon", предшественник MiMo-V2-Flash 309B под MIT. См. [news.md](news.md).
- **DeepSeek V4-Pro** (24 апреля 2026) -- 1.6T MoE / 49B active, MIT, 1M контекст. **SWE-V 80.6%**, **Terminal-Bench 2.0 67.9%**, **LiveCodeBench 93.5%**, SWE-Pro 55.4%. Гибридное внимание CSA+HCA, 10% KV-кеша от V3.2. Pricing $1.74 / $3.48 за 1M. Веса на [HuggingFace](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro). См. [news.md](news.md).
- **DeepSeek V4-Flash** (24 апреля 2026) -- 284B MoE / 13B active, MIT, 1M контекст. Pricing $0.14 / $0.28 за 1M. ~165 GB Q4. [HuggingFace](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash).

### Frontier (closed-source, для контекста)

| Модель | SWE-bench Verified | SWE-Bench Pro | Дата |
|--------|-------------------|---------------|------|
| Claude Mythos Preview (Anthropic) | **93.9%** | -- | 10 апр 2026 |
| GPT-6 (OpenAI) | -- | -- | 14 апр 2026 |
| GPT-5.3 Codex | 85.0% | -- | апр 2026 |
| Claude Opus 4.6 | 80.8% | 57.3% | апр 2026 |
| Gemini 3.1 Pro | 80.6% | -- | 8 апр 2026 |
| **DeepSeek V4-Pro (open MIT)** | **80.6%** ⭐ | 55.4% | 24 апр 2026 |
| **Kimi K2.6 (open Modified MIT)** | **80.2%** ⭐ | **58.6%** ⭐ | 20-22 апр 2026 |
| Claude Opus 4.5 | 80.9% | -- | апр 2026 |
| Qwen3.6-Plus (Alibaba) | 78.8% | -- | 2 апр 2026 |
| **Qwen 3.6-27B (open Apache 2.0)** | **77.2%** ⭐ | -- | 23 апр 2026 |
| GPT-5.4 | -- | 57.7% | апр 2026 |
| **Xiaomi MiMo V2.5-Pro (open soon)** | -- | **57.2%** ⭐ | 22 апр 2026 |
| **GLM-5.1 (open-weight, MIT)** | -- | **58.4%** ⭐ | 7 апр 2026 |
| Qwen3.6-Max-Preview (Alibaba) | -- | -- | апр 2026 |

Источник: [llm-stats.com](https://llm-stats.com/benchmarks/swe-bench-verified). Лучшая open-source модель в SWE-bench Verified, помещающаяся на платформу -- **Qwen 3.6-27B (77.2%)** с 23 апреля 2026 (предыдущий лидер -- Devstral 2 24B, 72.2%).

Подробный обзор closed-source coding моделей (профили, API pricing, decision matrix "когда API vs локально", agent→model mapping): **[closed-source-coding.md](closed-source-coding.md)**.

**#1 Qwen 3.6-27B** -- лидер локального SWE-V. Dense 27B на hybrid Gated DeltaNet, **77.2% SWE-bench Verified** -- лучший результат среди open-source моделей, помещающихся в платформу. Multimodal (vision encoder) -- работа со скриншотами интерфейсов и диаграмм. ~17 GiB Q4_K_M. Минус: dense-архитектура memory-bound, ~15 tok/s (оценка) -- медленнее MoE-моделей семейства Qwen3-Coder. Apache 2.0, GGUF одновременно с релизом.

**#2 Qwen 3.6-35B-A3B** -- новый рекомендуемый default для daily agentic-loop. Sparse MoE 35B total / 3B active с встроенным vision encoder, **73.4% SWE-bench Verified**, **Terminal-Bench 2.0 51.5%**, **QwenWebBench 1397**. ~20 GiB Q4_K_M, оценка скорости ~80 tok/s (3B active против ~17 GiB у Qwen3-Coder Next 53 tok/s -- лучший баланс качества и скорости). Vision из коробки -- скриншоты UI прямо в agent loop. Apache 2.0. Trade-off vs 27B dense: -3.8 п.п. SWE-V в обмен на 5× скорость генерации, что критично для agentic итераций.

**#3 Qwen3-Coder Next** -- альтернатива для daily-loop когда нужен 256K контекст. 80B MoE с 3B активных параметров: качество как у 24B dense, скорость почти как у 3B. 256K контекст уверенно держит средний monorepo. Проигрывает Qwen 3.6-27B и Qwen 3.6-35B-A3B на SWE-V, но даёт максимальный контекст среди MoE на платформе.

**#4 Devstral 2 24B** -- лидер dense-семейства 24B с 72.2% SWE-V. Tool use дисциплина строже MoE-вариантов, итерации более последовательные. Минус -- 25 tok/s ощутимо медленнее MoE на той же платформе.

**#5 Qwen3-Coder 30B-A3B** -- младшая MoE того же семейства. 86 tok/s даёт ощущение мгновенного ответа, идеален для "объясни функцию", "перепиши этот блок", быстрых code review. Слабее Coder Next на multi-file задачах из-за меньшего числа экспертов.

**#6 Qwen2.5-Coder 32B** -- классика dense-сегмента. HumanEval 92.7% всё ещё впечатляет, FIM-токены работают эталонно. Минус -- 12 tok/s и контекст 128K делают его непрактичным для agent loop, но как FIM-сервер премиум-уровня жив.

**#7 Codestral 25.08** -- лидер FIM в LMSYS Copilot Arena. 80+ языков покрытия, 256K контекст. Лицензия MNPL (не Apache), что для коммерческих сценариев требует внимания.

## Сравнительная таблица

| Модель | Семейство | Параметры | Active | SWE-bench V | HumanEval | FIM | FC | Контекст | Лицензия |
|--------|-----------|-----------|--------|-------------|-----------|-----|-----|----------|----------|
| Qwen 3.6-27B | [qwen36](families/qwen36.md#27b) | 27B dense | 27B | **77.2%** ⭐ | -- | -- | native | 1M (?) | Apache 2.0 |
| Qwen 3.6-35B-A3B | [qwen36](families/qwen36.md#35b-a3b) | 35B MoE | 3B | **73.4%** | -- | -- | native | ~128K (?) | Apache 2.0 |
| Qwen3-Coder-Next | [qwen3-coder](families/qwen3-coder.md#next-80b-a3b) | 80B MoE | 3B | 70.6% | -- | нет | **native** ⭐ | 256K | Apache 2.0 |
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

[Qwen 3.6-35B-A3B](families/qwen36.md#35b-a3b) -- **новый рекомендуемый default daily agent**. MoE 35B/3B-active с vision encoder, **73.4% SWE-V**, оценка ~80 tok/s (между 27B dense ~15 и Coder 30B-A3B 86). Vision из коробки -- скриншоты в agent loop без отдельного mmproj-сервера. Apache 2.0, ~20 GiB Q4_K_M. Когда контекст ~128K хватает и важна скорость loop.
[Qwen 3.6-27B](families/qwen36.md#27b) -- максимум качества SWE-V локально (**77.2%**, лидер open-source local). Выбор когда +3.8 п.п. SWE-V критичны для задачи и скорость не главное. Multimodal. ~17 GiB, ~15 tok/s (оценка).
[Qwen3-Coder Next](families/qwen3-coder.md#next-80b-a3b) -- альтернатива когда нужен 256K контекст. 70.6% [SWE-bench Verified](../llm-guide/benchmarks/swe-bench.md) при 3B active, 53 tok/s. Выбор для long-context daily-loop. Практические workflow'ы -- [coding/workflows.md](../coding/workflows.md#workflow-1-fim--cli-agent-основной).
[Devstral 2 24B](families/devstral.md) -- лидер dense 24B (72.2% SWE-V), FIM+agent в одной модели.

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

[opencode](../ai-agents/agents/opencode.md) позволяет переключать модели на лету (`/model`) и держать несколько провайдеров в одном конфиге. На нашей платформе разные модели крутятся параллельно через пресеты в [`scripts/inference/vulkan/preset/`](../../scripts/inference/vulkan/preset/) на разных портах.

### Маппинг задача → модель

| Задача | Модель | Порт | Почему |
|--------|--------|------|--------|
| **Daily agent loop (новый default)** | **[Qwen 3.6-35B-A3B](families/qwen36.md#35b-a3b)** | 8085 | 73.4% SWE-V, ~80 tok/s (оценка), MoE 3B-active, native vision |
| Long-context loop (256K, multi-file refactor) | [Qwen3-Coder Next](families/qwen3-coder.md#next-80b-a3b) | 8081 | 256K, 70.6% SWE-V, 53 tok/s |
| Сложные SWE-задачи, максимум качества локально | [Qwen 3.6-27B](families/qwen36.md#27b) | 8084 | 77.2% SWE-V (лидер local), multimodal, ~15 tok/s (оценка) |
| Быстрые однофайловые правки, "объясни код" | [Qwen3-Coder 30B-A3B](families/qwen3-coder.md#30b-a3b) | 8082 | 86 tok/s -- мгновенный отклик |
| Architecture review, multi-step reasoning | [Devstral 2 24B](families/devstral.md) | 8083 | dense 72.2% SWE-V, более последовательные планы |
| Скриншот ошибки → код | [Qwen 3.6-35B-A3B](families/qwen36.md#35b-a3b) или [Qwen 3.6-27B](families/qwen36.md#27b) | 8085 / 8084 | vision из коробки, 35B-A3B быстрее |
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
| Claude Opus 4.6 | 80.8% | нет | нет | $15 | Anthropic flagship |
| Gemini 3.1 Pro | 80.6% | нет | нет | $1.25 | Google flagship |
| **DeepSeek V4-Pro** | **80.6%** | да (1.6T) | нет (~960 GiB) | $1.74 | open MIT, frontier через API |
| **Kimi K2.6 (1T MoE)** | **80.2%** | да | нет (240+ GiB) | $0.45 | open, лидер open-source |
| Qwen3.6-Plus | 78.8% | нет (API) | нет | -- | Alibaba, Terminal-Bench 61.6% |
| GLM-5.1 (744B) | -- | да | нет (~440 GiB) | -- | open MIT, SWE-Pro 58.4% |
| **Qwen 3.6-27B** | **77.2%** | да | **да** ⭐ | $0 | лидер локального SWE-V, multimodal |
| **Devstral 2 24B** | 72.2% | да | **да** | $0 | топ dense 24B на платформе |
| **Qwen3-Coder Next 80B-A3B** | 70.6% | да | **да** | $0 | топ MoE на платформе по скорости |

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

- **[Qwen 3.6-27B](families/qwen36.md#27b)** (Alibaba, 23 апреля 2026) -- **первый open-weight вариант Qwen3.6**. Dense 27B, hybrid Gated DeltaNet, multimodal (vision). **SWE-V 77.2%** -- лидер open-source local, опередил Devstral 2 (72.2%) и Coder Next (70.6%). Apache 2.0, GGUF одновременно с релизом, помещается на платформу (~17 GiB Q4, оценка ~15 tok/s).
- **[Qwen 3.6-35B-A3B](families/qwen36.md#35b-a3b)** (Alibaba, 16 апреля 2026) -- **MoE multimodal вариант Qwen3.6**. 35B total / 3B active, sparse MoE + vision encoder. **SWE-V 73.4%**, **Terminal-Bench 2.0 51.5%**, **QwenWebBench 1397**. Apache 2.0, ~20 GiB Q4, оценка ~80 tok/s (3B active). Новый рекомендуемый default daily agent на платформе -- между 27B dense (77.2%, ~15 tok/s) и Coder 30B-A3B (86 tok/s) по балансу качества и скорости. [HuggingFace](https://huggingface.co/Qwen/Qwen3.6-35B-A3B).
- **[Qwen3.6-Plus](families/qwen36.md)** (Alibaba, 2 апреля 2026) -- agentic coding уровня Claude 4.5 Opus, 1M контекст, native function calling, multimodal. **SWE-V 78.8%**, **Terminal-Bench 2.0 61.6%** (vs Claude Opus 4.6 59.3%). API-only через Alibaba Cloud Model Studio.
- **[Kimi K2.5](families/kimi-k25.md)** (Moonshot AI, январь 2026) -- 1T MoE открыт, 76.8% SWE-V, лидер open-source. Локально не помещается (240+ GiB), на платформе только через API за $0.45/1M.
- **[Kimi K2.6](families/kimi-k25.md)** (Moonshot AI, 20-22 апреля 2026) -- 1T MoE, Modified MIT. SWE-V **80.2%**, SWE-Bench Pro **58.6%** (SOTA среди open-weight), HLE 54.0%, SWE-bench Multilingual 76.7%, Quality Index 54 (#1 open-source). Четыре варианта (Instant / Thinking / Agent / **Agent Swarm** -- native multi-agent до 300). Не помещается, через API.
- **Xiaomi MiMo V2.5-Pro** (22 апреля 2026) -- 1T MoE / 42B active, multimodal (text+vision+audio), 1M контекст. SWE-Pro **57.2%** (выше Opus 4.6), Terminal-Bench 2.0 **86.7%** (лидер). Open-source "soon" (предшественник MiMo-V2-Flash 309B под MIT, декабрь 2025).
- **DeepSeek V4** (24 апреля 2026) -- preview, MIT-лицензия, 1M контекст, гибридное внимание CSA+HCA (10% KV-кеша от V3.2). V4-Pro 1.6T/49B active: SWE-V **80.6%**, Terminal-Bench 2.0 67.9%, LiveCodeBench 93.5%. V4-Flash 284B/13B active: $0.14/$0.28 за 1M. Pre-train в FP4+FP8 mixed precision (32T токенов).
- **Qwen3.6-Max-Preview** (Alibaba, апрель 2026) -- early preview следующего flagship. Улучшенный agentic coding. API-only через Alibaba Cloud Model Studio.
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

- DeepSeek V4-Pro (1.6T MoE / 49B active) -- 80.6% SWE-V, MIT, ~960 GB Q4
- DeepSeek V4-Flash (284B MoE / 13B active) -- MIT, ~165 GB Q4
- Xiaomi MiMo V2.5-Pro (1T MoE / 42B active) -- multimodal, SWE-Pro 57.2%, Terminal-Bench 86.7%
- [Kimi K2.6](families/kimi-k25.md) -- 1T MoE, 80.2% SWE-V, 58.6% SWE-Pro, 240+ GB Q4
- GLM-5.1 (744B) -- SWE-Pro 58.4%, ~440 GB Q4
- MiniMax M2.5 -- 80.2% SWE-bench Verified, ~150 GB Q4
- DeepSeek V3.2 -- 671B MoE, не помещается
- [Kimi K2.5](families/kimi-k25.md) -- 1T MoE, 76.8% SWE-V, минимум 240 GB

Эти модели в каталог моделей не включены (кроме Kimi K2.5/K2.6 с пометкой), см. описание в README.md.

## Связанные направления

- [llm.md](llm.md) -- общие LLM
- [vision.md](vision.md) -- multimodal (в т.ч. для скриншотов в [opencode](../ai-agents/agents/opencode.md))
- [tts.md](tts.md) -- voice cloning
