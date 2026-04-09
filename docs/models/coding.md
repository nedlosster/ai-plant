# Модели для кодинга

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), llama-server + Vulkan.

Полные описания моделей -- в `families/`. Эта страница: сравнительные таблицы и выбор под задачу.

## Скачано на платформе

| Модель | Семейство | Параметры | Пресет |
|--------|-----------|-----------|--------|
| Qwen3-Coder-Next | [qwen3-coder](families/qwen3-coder.md#next-80b-a3b) | 80B MoE / 3B active | `vulkan/preset/qwen-coder-next.sh` |
| Qwen3-Coder-30B-A3B | [qwen3-coder](families/qwen3-coder.md#30b-a3b) | 30B MoE / 3B active | `vulkan/preset/qwen3-coder-30b.sh` |
| Qwen2.5-Coder-1.5B | [qwen25-coder](families/qwen25-coder.md#1-5b) | 1.5B dense Q8 | `vulkan/preset/qwen2.5-coder-1.5b.sh` |

## Сравнительная таблица

| Модель | Семейство | Параметры | Active | SWE-bench V | HumanEval | FIM | Контекст | Лицензия |
|--------|-----------|-----------|--------|-------------|-----------|-----|----------|----------|
| Qwen3-Coder-Next | [qwen3-coder](families/qwen3-coder.md#next-80b-a3b) | 80B MoE | 3B | **70.6%** | -- | нет | 256K | Apache 2.0 |
| Qwen3-Coder-30B-A3B | [qwen3-coder](families/qwen3-coder.md#30b-a3b) | 30B MoE | 3B | -- | -- | нет | 256K | Apache 2.0 |
| Devstral 2 | [devstral](families/devstral.md) | 24B dense | 24B | **72.2%** | -- | да | 256K | Apache 2.0 |
| Qwen2.5-Coder-32B | [qwen25-coder](families/qwen25-coder.md#32b) | 32B dense | 32B | -- | **92.7%** | да | 128K | Apache 2.0 |
| Codestral 25.08 | [codestral](families/codestral.md) | 22B dense | 22B | -- | 86.6% | **да (лидер FIM)** | 256K | MNPL |
| Qwen2.5-Coder-7B | [qwen25-coder](families/qwen25-coder.md#7b) | 7B dense | 7B | -- | 88.4% | да | 128K | Apache 2.0 |
| Qwen2.5-Coder-1.5B | [qwen25-coder](families/qwen25-coder.md#1-5b) | 1.5B dense | 1.5B | -- | ~75% | да | 128K | Apache 2.0 |

## Бенчмарки на платформе (Vulkan, llama-bench pp512/tg128)

| Модель | Размер | pp tok/s | tg tok/s |
|--------|--------|----------|----------|
| Qwen2.5-Coder-1.5B Q8_0 | 1.5 GiB | 5245 | **120.6** |
| Qwen3-Coder-30B-A3B Q4_K_M | 17.3 GiB | 1036 | **86.1** |
| Qwen3-Coder-Next Q4_K_M | 45.1 GiB | 590 | **53.2** |

MoE-модели (Qwen3-Coder) даюt высокую скорость генерации за счёт малой активации. Dense 32B при том же VRAM дал бы ~12 tok/s.

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

## Связанные направления

- [llm.md](llm.md) -- общие LLM
- [vision.md](vision.md) -- multimodal (в т.ч. для скриншотов в [opencode](../ai-agents/agents/opencode.md))
- [tts.md](tts.md) -- voice cloning

## Ожидается open weights

[Qwen3.6-Plus](families/qwen36.md) -- свежий флагман от Alibaba (2 апреля 2026), agentic coding "в одном классе с Claude 4.5 Opus". Контекст 1M токенов, native function calling, multimodal. Сейчас API-only через Alibaba Cloud, open-варианты обещаны "в developer-friendly размерах".

[Kimi K2.5](families/kimi-k25.md) -- open-weight 1T MoE от Moonshot AI (январь 2026). **SWE-Bench Verified 76.8%** -- лидер open-source agentic-сегмента, превосходит Qwen3-Coder Next (70.6%). Agent Swarm координирует до 100 под-агентов параллельно. Веса открыты, но локально требует 240+ GiB -- для нашей платформы доступ только через API ($0.45/1M input).

## Не помещаются на платформе

- GLM-5 (744B) -- лидер open-source по SWE-bench Verified (77.8%), не помещается даже в Q4 (~440 GB)
- MiniMax M2.5 -- 80.2% SWE-bench Verified (уровень Claude Opus 4.6), не помещается (~150 GB)
- DeepSeek V3.2 -- 671B MoE, не помещается

Эти модели в каталог не включены, см. описание в README.md.
