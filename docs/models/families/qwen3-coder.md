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

| Бенч | Next 80B-A3B | 30B-A3B |
|------|--------------|---------|
| SWE-bench Verified | **70.6%** | -- |
| pp512 (Vulkan, платформа) | 590 tok/s | 1036 tok/s |
| tg128 (Vulkan, платформа) | **53 tok/s** | **86 tok/s** |

## Связано

- Направления: [coding](../coding.md), [llm](../llm.md)
- Родственные семейства: [qwen25-coder](qwen25-coder.md) (FIM-линейка для inline-автодополнения), [qwen35](qwen35.md) (general-purpose Qwen той же эпохи)
- Пресеты: `scripts/inference/vulkan/preset/qwen-coder-next.sh`, `scripts/inference/vulkan/preset/qwen3-coder-30b.sh`
