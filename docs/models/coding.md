# Модели для кодинга

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), llama-server + Vulkan.

## Топ-набор для платформы (актуальный 2026)

| Модель | VRAM | tg tok/s | SWE-bench V | Назначение |
|--------|------|----------|-------------|------------|
| **Qwen2.5-Coder-1.5B** | ~2 GiB Q8 | 120 | -- | FIM-автодополнение в IDE |
| **Devstral 2 24B** | ~15 GiB Q4 | ~20 | 72.2% | Универсальный agent, FIM, 256K |
| **Qwen3-Coder-30B-A3B** | ~18 GiB Q4 | 86 | -- | Быстрый MoE chat, рефакторинг |
| **Qwen3-Coder-Next 80B-A3B** | ~45 GiB Q4 | 53 | 70.6% | Лидер MoE по efficiency, agents |
| **Codestral 25.08** | ~13 GiB Q4 | -- | -- | FIM 86.6% HumanEval, 256K |

## Доступны при 120 GiB

| Модель | VRAM | Назначение |
|--------|------|------------|
| **Qwen2.5-Coder-32B Q8_0** | ~40 GiB | Максимальное качество FIM + chat |
| **GLM-5 (744B)** | ~440 GiB | Не помещается. SWE-bench V 77.8%, лидер open-source |
| **MiniMax M2.5** | ~150 GiB | Не помещается. SWE-bench V 80.2% (~уровень Claude Opus 4.6) |

## Рейтинг по бенчмаркам (2026)

| Модель | Параметры | Active | SWE-bench V | HumanEval | Контекст | Лицензия | GGUF Q4 |
|--------|-----------|--------|-------------|-----------|----------|----------|---------|
| MiniMax M2.5 | 230B+ | -- | **80.2%** | -- | 128K | Open | ~150 GiB (не помещ.) |
| GLM-5 | 744B | -- | **77.8%** | 94.2% | 128K | MIT | ~440 GiB (не помещ.) |
| Devstral 2 | 24B dense | 24B | **72.2%** | -- | 256K | Apache 2.0 | ~15 GiB |
| **Qwen3-Coder-Next** | 80B MoE | 3B | **70.6%** | -- | 256K | Apache 2.0 | ~45 GiB |
| Devstral Small 2 | 24B dense | 24B | 68.0% | -- | 256K | Apache 2.0 | ~15 GiB |
| Qwen3-Coder-30B-A3B | 30B MoE | 3B | -- | -- | 256K | Apache 2.0 | ~18 GiB |
| Qwen2.5-Coder-32B | 32B dense | 32B | -- | 92.7% | 128K | Apache 2.0 | ~20 GiB |
| Codestral 25.08 | 22B dense | 22B | -- | 86.6% | 256K | MNPL | ~13 GiB |
| Qwen2.5-Coder-7B | 7B dense | 7B | -- | 88.4% | 128K | Apache 2.0 | ~5 GiB |
| Qwen2.5-Coder-1.5B | 1.5B dense | 1.5B | -- | ~75% | 128K | Apache 2.0 | ~1 GiB |

MoE-модели (Qwen3-Coder) активируют только 3B параметров на токен -- высокая скорость при большом объёме знаний.

## Бенчмарки на платформе (Vulkan, llama-bench pp512/tg128)

| Модель | Размер | pp tok/s | tg tok/s |
|--------|--------|----------|----------|
| Qwen2.5-Coder-1.5B Q8_0 | 1.5 GiB | 5245 | 120.6 |
| Qwen3-Coder-30B-A3B Q4_K_M | 17.3 GiB | 1036 | 86.1 |
| Qwen3-Coder-Next Q4_K_M | 45.1 GiB | 590 | 53.2 |

MoE даёт высокую скорость генерации: 30B-A3B -- 86 tok/s, Next 80B-A3B -- 53 tok/s. Dense 32B при том же VRAM дал бы ~12 tok/s.

## FIM-совместимость

Fill-in-Middle -- режим вставки кода между prefix и suffix. Критично для автодополнения в IDE.

| Модель | FIM | Применение |
|--------|-----|------------|
| Qwen2.5-Coder (все размеры) | да | Continue.dev, llama.vscode |
| Codestral 25.08 | да | Лучший FIM по бенчмаркам |
| Devstral 2 | да | Универсальная: FIM + chat + agent |
| StarCoder2-15B | да | Бывшая классика |
| Qwen3-Coder-Next, 30B-A3B | **нет** | Только chat/agents |
| GLM-5, MiniMax M2.5 | нет | Chat/agents |

---

## Qwen3-Coder-Next 80B-A3B (efficiency лидер)

**Назначение**: agent-task кодинг, MoE с минимальной активацией. Эталон efficiency 2026.

- **Параметры**: 80B total / 3B active
- **Hub**: [Qwen/Qwen3-Coder-Next-GGUF](https://huggingface.co/Qwen/Qwen3-Coder-Next-GGUF)
- **Размер**: ~45 GiB Q4_K_M (split на 4 файла)
- **Контекст**: 256K
- **SWE-bench Verified**: 70.6% (лидер MoE-сегмента, обходит DeepSeek V3 при 10-20x меньшей активации)
- **Архитектура**: hybrid attention + MoE, обучалась с large-scale RL на agentic task

**Сильные кейсы:**
- **AI-агенты** -- best efficiency: 70.6% SWE-bench Verified при 3B активных параметров
- **Длинный контекст 256K** -- весь репозиторий + история обсуждений в одном запросе
- **Скорость генерации** -- 53 tok/s на платформе (для сравнения dense 70B даст ~5 tok/s)
- **Apache 2.0** -- никаких ограничений
- **Рефакторинг больших проектов** -- "перепиши все компоненты с класс-компонент на хуки"
- **Code review** длинных PR

**Слабые кейсы:**
- **Нет FIM** -- не подходит для inline-автодополнения
- 45 GB на диске -- долгая загрузка
- В отдельных задачах (математика) уступает специализированным reasoning-моделям

**Идеальные сценарии:**
- Aider, SWE-agent, Cline, Roo Code -- agent-style работа
- "Изучи проект и предложи план рефакторинга"
- Анализ legacy-кодбейзов с длинной историей
- Бекенд для opencode -- основной use case на платформе

```bash
./scripts/inference/download-model.sh Qwen/Qwen3-Coder-Next-GGUF --include "*Q4_K_M*"
./scripts/inference/vulkan/preset/qwen-coder-next.sh -d
```

---

## Devstral 2 24B (Mistral, лидер по SWE-bench среди dense)

**Назначение**: универсальный кодинг -- agents + FIM + chat. Декабрь 2025, актуальная.

- **Параметры**: 24B dense
- **Hub**: [bartowski/Devstral-2-24B-Instruct-GGUF](https://huggingface.co/bartowski/Devstral-2-24B-Instruct-GGUF) (или unsloth)
- **Размер**: ~15 GiB Q4_K_M
- **Контекст**: 256K
- **SWE-bench Verified**: **72.2%** -- лучший среди моделей до 30B!
- **Лицензия**: Apache 2.0
- **FIM**: да

**Сильные кейсы:**
- **Лучший SWE-bench среди компактных моделей** -- 72.2% при всего 24B параметров
- **Помещается на одном RTX 4090 или Mac 32GB** -- стандартное оборудование
- **256K контекст** -- весь проект целиком
- **FIM из коробки** -- одна модель для inline и chat-режимов
- **Apache 2.0** для коммерции
- **Стабильность Mistral** -- проверенная экосистема

**Слабые кейсы:**
- Dense 24B -- медленнее MoE моделей того же качества (~20 vs 86 tok/s у Qwen3-Coder-30B-A3B)
- Русский комментарии в коде слабее Qwen
- Не лидер по чистому HumanEval (там Qwen2.5-Coder-32B сильнее)

**Идеальные сценарии:**
- Универсальная коробка "одна модель на всё" -- FIM + chat + agent
- Когда нужен FIM **и** strong agent в одной модели
- Production-окружения с predictable timings
- Замена нескольких отдельных моделей одной

```bash
./scripts/inference/download-model.sh unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF --include "*Q4_K_M*"
```

---

## Qwen3-Coder-30B-A3B (быстрый рабочий MoE)

**Назначение**: повседневный chat-кодинг с высокой скоростью.

- **Параметры**: 30B / 3B active (MoE)
- **Hub**: [unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF](https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF)
- **Размер**: ~18 GiB Q4_K_M
- **Контекст**: 256K
- **Скорость на платформе**: 86 tok/s

**Сильные кейсы:**
- **Самая быстрая MoE на платформе** -- 86 tok/s на 17 GB модели
- **Идеальное соотношение качество/скорость** -- между 1.5B FIM и Coder-Next
- **256K контекст** -- работа с большими проектами
- **Apache 2.0**
- **Эффективное использование платформы** -- помещается с большим запасом (110 GiB свободно)

**Слабые кейсы:**
- Нет FIM -- не для автодополнения
- SWE-bench не лидер -- для агентов лучше Coder-Next или Devstral 2
- На очень сложных задачах MoE A3B уступает 80B+

**Идеальные сценарии:**
- Повседневный chat по коду в IDE/CLI
- Быстрый рефакторинг небольших файлов
- Code review для PR
- Параллельный режим: 30B-A3B как chat + 1.5B как FIM на втором порту

```bash
./scripts/inference/download-model.sh unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF --include "*Q4_K_M*"
./scripts/inference/vulkan/preset/qwen3-coder-30b.sh -d
```

---

## Qwen2.5-Coder Series (FIM-классика)

**Назначение**: лучшая FIM-серия для inline-автодополнения. Линейка от 1.5B до 32B.

- **Hub**: [bartowski/Qwen2.5-Coder-32B-Instruct-GGUF](https://huggingface.co/bartowski/Qwen2.5-Coder-32B-Instruct-GGUF) (и другие размеры)
- **Контекст**: 128K
- **Лицензия**: Apache 2.0
- **HumanEval**: 32B = 92.7%, 7B = 88.4%, 1.5B = ~75%

**Сильные кейсы:**
- **FIM из коробки** -- эталон для inline-автодополнения
- **Линейка размеров** -- 1.5B (FIM-сервер), 7B (балансный FIM), 32B (chat + FIM)
- **HumanEval 92.7% (32B)** -- лучший среди open-source dense
- **Зрелая экосистема** -- интеграции в Continue.dev, llama.vscode, Aider, SWE-agent
- **Q8_0 32B на 120 GiB** -- максимум качества (~40 GiB), параллельный 1.5B FIM

**Слабые кейсы:**
- Dense -- медленнее MoE при том же качестве
- Старее новых релизов (но по качеству ещё конкурентна)
- 32B нет SWE-bench-данных в сравнении с Devstral 2

**Идеальные сценарии:**
- **1.5B Q8 (~2 GiB)** -- FIM-сервер для IDE, 120 tok/s
- **7B Q4 (~5 GiB)** -- FIM повышенного качества
- **32B Q4/Q8** -- chat + FIM в одной модели максимального качества
- IDE-плагины (Continue.dev, llama.vscode)

```bash
# FIM 1.5B
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF --include "*Q8_0*"
# FIM 7B
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-7B-Instruct-GGUF --include "*Q4_K_M*"
# Chat/FIM 32B
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-32B-Instruct-GGUF --include "*Q4_K_M*"
```

---

## Codestral 25.08 (Mistral, FIM-чемпион)

**Назначение**: специализированный code completion. Лидер LMsys copilot arena по FIM.

- **Параметры**: 22B dense
- **Hub**: [bartowski/Codestral-25.08-GGUF](https://huggingface.co/bartowski/Codestral-25.08-GGUF) (или официальные)
- **Размер**: ~13 GiB Q4_K_M
- **Контекст**: 256K
- **HumanEval**: 86.6%
- **MBPP**: 91.2%
- **Лицензия**: MNPL (для коммерции -- проверить)

**Сильные кейсы:**
- **Лидер на LMsys copilot arena** по FIM -- лучший выбор для autocompletion
- **80+ языков программирования** -- от стандартных до экзотики
- **256K контекст** -- repo-level FIM
- **HumanEval 86.6%, MBPP 91.2%** -- сильные синтетические бенчи
- **Mistral-стабильность**

**Слабые кейсы:**
- **MNPL-лицензия** -- ограничения на коммерческое использование (нужно проверить)
- 22B dense -- ~15 tok/s на платформе (для FIM это ОК, для chat медленно)
- Reasoning слабее Qwen3-Coder

**Идеальные сценарии:**
- **IDE FIM на максимальном качестве** -- Continue.dev/llama.vscode
- **Многоязычные проекты** -- 80+ языков, лучший выбор для polyglot-разработки
- **Repository-level completion** -- понимание контекста всего проекта

```bash
./scripts/inference/download-model.sh bartowski/Codestral-25.08-GGUF --include "*Q4_K_M*"
```

---

## Не помещаются на платформе (для справки)

### GLM-5 (744B, Zhipu AI, MIT)

- **SWE-bench Verified**: 77.8%
- **HumanEval**: 94.2%
- Лидер open-source по полному стеку метрик
- Не помещается даже в Q4 (~440 GB)
- **Hub**: [zai-org/GLM-5](https://huggingface.co/zai-org/GLM-5)

### MiniMax M2.5

- **SWE-bench Verified**: 80.2% -- **в 0.6 пунктах от Claude Opus 4.6 (80.8%)**
- Лучший open-source по SWE-bench Verified
- Не помещается (~150 GB Q4)

### DeepSeek V3.2

- **Aider polyglot**: 74.2%
- 671B MoE, не помещается (~390 GB Q4)
- Дешевле большинства закрытых моделей при сопоставимом качестве

---

## Загрузка рекомендуемого набора

```bash
cd ~/projects/ai-plant

# 1. FIM в IDE (Qwen2.5-Coder 1.5B Q8) -- 2 GB
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF --include "*Q8_0*"

# 2. Универсальный agent + FIM (Devstral 2 24B) -- 15 GB
./scripts/inference/download-model.sh unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF --include "*Q4_K_M*"

# 3. Быстрый chat (Qwen3-Coder-30B-A3B) -- 18 GB
./scripts/inference/download-model.sh unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF --include "*Q4_K_M*"

# 4. Максимум для агентов (Qwen3-Coder-Next 80B-A3B) -- 45 GB
./scripts/inference/download-model.sh Qwen/Qwen3-Coder-Next-GGUF --include "*Q4_K_M*"

# 5. Лучший FIM (Codestral 25.08) -- 13 GB
./scripts/inference/download-model.sh bartowski/Codestral-25.08-GGUF --include "*Q4_K_M*"

# 6. Опционально: Qwen2.5-Coder-32B Q8 максимум качества -- 40 GB
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-32B-Instruct-GGUF --include "*Q8_0*"
```

## Два сервера одновременно

FIM (1.5B Q8, ~2 GB) + Chat (Qwen3-Coder-Next, ~45 GB) = ~47 GB. Остаётся ~73 GB.

```bash
# Терминал 1: FIM (порт 8080)
./scripts/inference/start-fim.sh Qwen2.5-Coder-1.5B-Instruct-Q8_0.gguf --daemon

# Терминал 2: Chat (порт 8081, через пресет)
./scripts/inference/vulkan/preset/qwen-coder-next.sh -d
```

## Инструменты

Подробнее: [use-cases/coding/](../use-cases/coding/README.md)

| Инструмент | Модель | Порт |
|-----------|--------|------|
| Continue.dev (autocomplete) | Codestral 25.08 / Coder 1.5B FIM | 8080 (/infill) |
| Continue.dev (chat) | Qwen3-Coder-30B-A3B / Devstral 2 | 8081 (/v1/chat) |
| Aider | Coder-Next или Devstral 2 | 8081 |
| Cline / Roo Code | Coder-Next | 8081 |
| SWE-agent | Coder-Next | 8081 |
| opencode | Coder-Next (256K) | 8081 |

## Связанные статьи

- [Справочник LLM](llm.md) -- общие LLM, новинки 2026
- [Vision LLM](vision.md) -- multimodal модели
- [TTS](tts.md) -- voice cloning
- [IDE-интеграция](../use-cases/coding/ide-integration.md)
- [AI-агенты](../use-cases/coding/agents.md)
- [Настройка сервера](../use-cases/coding/server-setup.md)
- [Бенчмарки](../inference/benchmarking.md)
