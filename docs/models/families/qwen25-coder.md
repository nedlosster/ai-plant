# Qwen2.5-Coder (Alibaba, 2024)

> Эталонная FIM-серия для автодополнения кода в IDE, линейка от 1.5B до 32B.

**Тип**: dense
**Лицензия**: Apache 2.0
**Статус на сервере**: скачана (1.5B Instruct Q8_0)
**Направления**: [coding](../coding.md)

## Обзор

Qwen2.5-Coder -- специализированная dense-серия для кодинга. В отличие от MoE-наследника [qwen3-coder](qwen3-coder.md), эти модели поддерживают **Fill-in-Middle (FIM)** -- режим вставки кода между prefix и suffix, критичный для inline-автодополнения в IDE.

HumanEval 92.7% (32B) -- лучший среди open-source dense на момент выхода. Линейка от 1.5B (FIM-сервер) до 32B (chat + FIM).

## Варианты

| Вариант | Параметры | Контекст | VRAM Q4 | VRAM Q8 | Статус | Hub |
|---------|-----------|----------|---------|---------|--------|-----|
| 1.5B Instruct | 1.5B dense | 128K | -- | ~2 GiB | скачана | [bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF](https://huggingface.co/bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF) |
| 7B Instruct | 7B dense | 128K | ~5 GiB | ~8 GiB | не скачана | [bartowski/Qwen2.5-Coder-7B-Instruct-GGUF](https://huggingface.co/bartowski/Qwen2.5-Coder-7B-Instruct-GGUF) |
| 32B Instruct | 32B dense | 128K | ~20 GiB | ~40 GiB | не скачана | [bartowski/Qwen2.5-Coder-32B-Instruct-GGUF](https://huggingface.co/bartowski/Qwen2.5-Coder-32B-Instruct-GGUF) |

### 1.5B Instruct {#1-5b}

Стандартная FIM-модель платформы для autocomplete.

- ~2 GiB Q8_0 (рекомендованная квантизация для FIM)
- **120 tok/s** генерация -- мгновенный отклик в IDE
- Помещается в любой запас VRAM, может работать параллельно с большими chat-моделями
- Базовая точность ~75% HumanEval -- достаточно для completion-сценариев

### 7B Instruct {#7b}

FIM повышенного качества. Хороший компромисс между точностью и скоростью.

- ~5 GiB Q4_K_M / ~8 GiB Q8_0
- HumanEval 88.4%
- Если 1.5B не хватает по точности, а 32B перебор по латентности

### 32B Instruct {#32b}

Максимум качества линейки -- chat + FIM в одной модели.

- ~20 GiB Q4_K_M / **~40 GiB Q8_0** -- на платформе можно держать Q8 благодаря 120 GiB
- HumanEval **92.7%** -- лучший open-source dense
- При 96 GiB Q8 был на пределе, при 120 GiB -- комфортно с запасом для параллельных моделей

## Архитектура и особенности

- **Dense-архитектура** -- проверенная стабильность, без сюрпризов MoE-роутинга
- **FIM из коробки** -- эталонная имплементация для [Continue.dev](../../ai-agents/agents/continue-dev.md), llama.vscode, [Aider](../../ai-agents/agents/aider.md)
- **Function calling**: native у 7B/14B/32B (Qwen `<tool_call>` формат), partial у 1.5B (FIM-фокус, не agentic)
- **Контекст 128K** -- достаточно для большинства репозиториев
- **Линейка размеров** -- 0.5B/1.5B/3B/7B/14B/32B (на платформе используются 1.5B/7B/32B как самые ходовые)
- **Apache 2.0** -- никаких ограничений

## Сильные кейсы

- **FIM эталон** -- инструменты типа [Continue.dev](../../ai-agents/agents/continue-dev.md) оптимизированы именно под Qwen Coder format
- **HumanEval 92.7% (32B)** -- лучший среди open-source dense моделей
- **Зрелая экосистема** -- интеграции в [Continue.dev](../../ai-agents/agents/continue-dev.md), llama.vscode, [Aider](../../ai-agents/agents/aider.md), SWE-agent
- **Линейка размеров** -- 1.5B для FIM-сервера, 32B для chat+FIM в одной модели максимального качества
- **Q8 32B на 120 GiB** -- можно держать максимум качества + параллельный 1.5B FIM

## Слабые стороны / ограничения

- **Dense -- медленнее MoE** при том же качестве (32B даст ~12 tok/s vs 86 у [Qwen3-Coder-30B-A3B](qwen3-coder.md#30b-a3b))
- **Старее новых релизов 2026** (но по качеству FIM ещё конкурентна)
- 32B нет SWE-bench-данных для прямого сравнения с [devstral](devstral.md)

## Идеальные сценарии применения

- **1.5B Q8 (~2 GiB)** -- FIM-сервер для IDE, 120 tok/s, низкая латентность
- **7B Q4 (~5 GiB)** -- FIM повышенного качества, баланс
- **32B Q4/Q8** -- chat + FIM в одной модели максимального качества
- IDE-плагины: **[Continue.dev](../../ai-agents/agents/continue-dev.md)**, **llama.vscode**, **Codecompanion**

## Загрузка

```bash
# 1.5B Q8 -- FIM-сервер (рекомендуется)
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF --include "*Q8_0*"

# 7B Q4 -- FIM повышенного качества
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-7B-Instruct-GGUF --include "*Q4_K_M*"

# 32B Q4 -- максимум качества (~20 GiB)
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-32B-Instruct-GGUF --include "*Q4_K_M*"

# 32B Q8 -- максимум качества (~40 GiB, на 120 GiB комфортно)
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-32B-Instruct-GGUF --include "*Q8_0*"
```

## Запуск

```bash
# 1.5B FIM на порту 8080 (через preset)
./scripts/inference/vulkan/preset/qwen2.5-coder-1.5b.sh -d

# 32B chat -- через общий start-server.sh
./scripts/inference/start-server.sh Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf --daemon
```

## Бенчмарки

| Бенч | 1.5B | 7B | 32B |
|------|------|-----|-----|
| HumanEval | ~75% | 88.4% | **92.7%** |
| pp512 (Vulkan, платформа) | 5245 | -- | -- |
| tg128 (Vulkan, платформа) | **120.6** | -- | -- |

## Связано

- Направления: [coding](../coding.md)
- Родственные семейства: [qwen3-coder](qwen3-coder.md) (новое поколение MoE для агентов, БЕЗ FIM), [codestral](codestral.md) (альтернативный FIM от Mistral)
- Пресет: [`scripts/inference/vulkan/preset/qwen2.5-coder-1.5b.sh`](../../../scripts/inference/vulkan/preset/qwen2.5-coder-1.5b.sh)
