# Qwen3-Coder (Alibaba, 2025-2026)

> MoE-серия от Qwen для кодинга, флагман efficiency-сегмента 2026.

**Тип**: MoE (3B active / 30B-80B total)
**Лицензия**: Apache 2.0
**Статус на сервере**: скачана (Next и 30B-A3B)
**Направления**: [coding](../coding.md), [llm](../llm.md)

## Обзор

Qwen3-Coder -- специализированная MoE-серия от Alibaba для задач программирования. Главная фишка -- **3B активных параметров** при общем размере до 80B, что даёт очень высокую скорость генерации при качестве больших моделей.

Серия обучалась с large-scale reinforcement learning на agentic-задачах. По SWE-bench Verified обходит DeepSeek V3 при 10-20x меньшем числе активных параметров.

Используется на платформе как основной бекенд для [opencode](../../ai-agents/agents/opencode.md), [Aider](../../ai-agents/agents/aider.md), [Cline](../../ai-agents/agents/cline.md) и других agent-style инструментов через 256K контекст.

**Function calling**: native (лучший на платформе для agent-style кодинга, формат `<tool_call>...</tool_call>`). Запуск с `--jinja` обязателен -- см. [llm-guide/function-calling.md](../../llm-guide/function-calling.md#function-calling-на-платформе-2026).

## Варианты

| Вариант | Параметры | Active | Контекст | VRAM Q4 | Статус | Hub |
|---------|-----------|--------|----------|---------|--------|-----|
| Next 80B-A3B | 80B MoE | 3B | 256K | ~45 GiB | скачана | [Qwen/Qwen3-Coder-Next-GGUF](https://huggingface.co/Qwen/Qwen3-Coder-Next-GGUF) |
| 30B-A3B Instruct | 30B MoE | 3B | 256K | ~18 GiB | скачана | [unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF](https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF) |

### Next 80B-A3B {#next-80b-a3b}

Флагман серии. **SWE-bench Verified 70.6%** -- лидер MoE-сегмента, обходит DeepSeek V3 (70.2%) при 10-20x меньшей активации.

- Hybrid attention + MoE архитектура
- Контекст 256K -- весь репозиторий + история обсуждений в одном запросе
- ~45 GiB Q4_K_M в split-формате (4 файла)
- Скорость генерации **53 tok/s** на платформе через Vulkan

### 30B-A3B Instruct {#30b-a3b}

Быстрый рабочий MoE для повседневного chat-кодинга.

- ~18 GiB Q4_K_M -- помещается с большим запасом
- Скорость генерации **86 tok/s** -- идеальное соотношение качество/скорость
- Контекст 256K
- Подходит для быстрого рефакторинга, code review, обсуждения архитектуры

## Архитектура и особенности

- **Hybrid attention** -- сочетание разных attention-механизмов для эффективности на длинных контекстах
- **MoE A3B** -- только 3B параметров активны на токен, генерация быстрая как у dense 3B-модели
- **Трейн с RL на agentic-задачах** -- хорошо следует инструкциям, понимает tool use
- **Контекст 256K** в обоих вариантах -- работает с большими проектами без compaction
- **НЕТ FIM** (Fill-in-Middle) -- только chat/agentic, не для inline-автодополнения в IDE

## Сильные кейсы

- **AI-агенты на полную катушку** -- 70.6% SWE-bench Verified при 3B активных параметров (efficiency-чемпион)
- **Длинный контекст 256K** -- весь репозиторий целиком + история обсуждений
- **Скорость генерации MoE** -- 53-86 tok/s на платформе (для сравнения dense 70B даст ~5 tok/s)
- **Apache 2.0** -- никаких ограничений для коммерции
- **Рефакторинг больших проектов** -- "перепиши все компоненты с класс-компонент на хуки"
- **Code review** длинных PR с пониманием контекста

## Слабые стороны / ограничения

- **Нет FIM** -- не подходит для inline-автодополнения в IDE (для FIM см. [qwen25-coder](qwen25-coder.md) или [codestral](codestral.md))
- Next: ~45 GB на диске -- долгая загрузка модели
- В отдельных задачах (математика, физика) уступает специализированным reasoning-моделям

## Идеальные сценарии применения

- **[opencode](../../ai-agents/agents/opencode.md)** -- основной use case на платформе, через `vulkan/preset/qwen-coder-next.sh` на порту 8081
- **[Aider](../../ai-agents/agents/aider.md), SWE-agent, [Cline](../../ai-agents/agents/cline.md), [Roo Code](../../ai-agents/agents/roo-code.md)** -- agent-style работа с кодом
- **"Изучи проект и предложи план рефакторинга"** -- сложные многошаговые задачи
- **Анализ legacy-кодбейзов** с длинной историей коммитов
- **Параллельный setup**: 30B-A3B как chat (быстрый отклик) + 1.5B FIM на втором порту для IDE

## Загрузка

```bash
# Next 80B-A3B (~45 GiB Q4_K_M, split на 4 файла)
./scripts/inference/download-model.sh Qwen/Qwen3-Coder-Next-GGUF --include "*Q4_K_M*"

# 30B-A3B Instruct (~18 GiB)
./scripts/inference/download-model.sh unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF --include "*Q4_K_M*"
```

## Запуск

```bash
# Next 80B-A3B (256K контекст, через Vulkan)
./scripts/inference/vulkan/preset/qwen-coder-next.sh -d

# 30B-A3B (128K контекст по умолчанию в пресете)
./scripts/inference/vulkan/preset/qwen3-coder-30b.sh -d
```

## Бенчмарки

### Vulkan (основной backend)

| Бенч | Next 80B-A3B | 30B-A3B |
|------|--------------|---------|
| SWE-bench Verified | **70.6%** | -- |
| pp512 (платформа) | 590 tok/s | 1036 tok/s |
| tg128 (платформа) | **53 tok/s** | **86 tok/s** |

### ROCm/HIP (тест 2026-04-09)

| Модель | pp tok/s | tg tok/s | vs Vulkan |
|--------|----------|----------|-----------|
| 30B-A3B Q4_K_M | 441 | **63.5** | pp -57%, tg -26% |
| Next 80B-A3B Q4_K_M | **OOM** | -- | `cudaMalloc failed` (45 GiB > лимит HIP-аллокатора) |

ROCm/HIP видит 96 GiB carved-out VRAM, но `hipMalloc` не может выделить буфер >30-35 GiB единым блоком при текущей BIOS-конфигурации (96 GiB carved-out). Next (45 GiB) не загружается через HIP. 30B-A3B работает стабильно.

Vulkan быстрее на 26-57%. **Рекомендация: Vulkan для inference**, ROCm для PyTorch/training. Подробнее: [rocm-setup.md](../../inference/rocm-setup.md#статус-gfx1151-strix-halo).

## Замеры на платформе (Aider Polyglot)

| Прогон | Tasks | pass_rate_1 | pass_rate_2 | sec/case | Дата |
|--------|-------|-------------|-------------|----------|------|
| **30B-A3B full** (no rust, --tries 2) | 194/195 | 10.8% | **26.3%** | 47.7 | 2026-04-26 |
| **Next 80B-A3B full** (no rust, --tries 2) | в процессе | ~37% | **~67-70%** на 87+ задач | ~95-100 | 2026-04-27 |

Coder Next выигрывает у 30B-A3B по качеству (+40pp pass_rate_2), но 30B-A3B в 2× быстрее (47.7 vs 95 sec/case). Trade-off скорость vs качество.

Подробные отчёты: [docs/llm-guide/benchmarks/runs/](../../llm-guide/benchmarks/runs/README.md).

## Roadmap и planned updates

### Текущие приоритеты Qwen team (по [техническому отчёту 2026-03-03](https://arxiv.org/pdf/2603.00729))

> "We plan to improve the model's reasoning and decision-making, support more tasks, and update quickly based on how people use it."

**Ожидаемые updates** (Q2-Q3 2026):

1. **Qwen3-Coder-Next checkpoint refreshes** -- incremental improvements на той же hybrid Gated DeltaNet архитектуре. Веса обновятся, размер 80B-A3B и формат GGUF останутся, можно будет просто перекачать.
2. **Qwen3.6-Coder** -- coder-specific вариант новой Qwen3.6 серии. По паттерну (Qwen3 → Qwen3-Coder через ~1-2 мес) ожидается **июнь-июль 2026**. Скорее всего на той же 80B-A3B hybrid base, но с улучшенным coding fine-tune. Прогноз SWE-V: **~75-80%** (vs 70.6% у Coder Next текущего).
3. **Возможен [Qwen3.6-27B](qwen36.md#27b) как coder-strong general** -- релиз 23 апр 2026, dense 27B с **SWE-V 77.2%** (лучший open-weight на момент апреля 2026). Не coder-specific, но coding качество выше Coder Next. **Сильный кандидат к скачиванию и тестированию** на платформе.

### Архитектурный outlook

Все 2026 Qwen coding модели используют **hybrid Gated DeltaNet** -- это значит:

- **Cache-reuse в llama.cpp архитектурно blocked** -- ждём merge upstream PR'ов (см. [optimization-backlog U-001](../../inference/optimization-backlog.md#u-001))
- **3B active parameters стандарт** для Coder MoE -- даёт ~50-90 tok/s на платформе через Vulkan
- **Размер 80B-A3B -- идеальный sweet spot** для нашего 120 GiB unified memory (45 GiB Q4 + KV cache + parallel slots)

### Следить за обновлениями

- [QwenLM/Qwen3-Coder GitHub](https://github.com/QwenLM/Qwen3-Coder) -- основной канал релизов, watch repo
- [qwen.ai/blog](https://qwen.ai/blog) -- технические анонсы
- [HuggingFace Qwen org](https://huggingface.co/Qwen) -- свежие веса
- llama.cpp [PR #20376](https://github.com/ggml-org/llama.cpp/pull/20376) (Vulkan f16 GATED_DELTA_NET) -- merge ускорит **все** hybrid модели на 10-20%

## Связано

- Направления: [coding](../coding.md), [llm](../llm.md)
- Родственные семейства: [qwen25-coder](qwen25-coder.md) (FIM-линейка для inline-автодополнения), [qwen35](qwen35.md) (general-purpose Qwen той же эпохи), [qwen36](qwen36.md) (новое поколение, источник ожидаемого Qwen3.6-Coder)
- Пресеты: [`scripts/inference/vulkan/preset/qwen-coder-next.sh`](../../../scripts/inference/vulkan/preset/qwen-coder-next.sh), [`scripts/inference/vulkan/preset/qwen3-coder-30b.sh`](../../../scripts/inference/vulkan/preset/qwen3-coder-30b.sh)
- Бенчмарки на платформе: [benchmarks/runs/](../../llm-guide/benchmarks/runs/README.md)
