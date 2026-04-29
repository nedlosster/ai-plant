# Qwen3.5 (Alibaba, 2026)

> Новейшее поколение Qwen для общего назначения, мультимодальные dense + MoE, лучший русский среди open-source.

**Тип**: dense + MoE
**Лицензия**: Apache 2.0
**Статус на сервере**: скачана (122B-A10B MoE + 35B-A3B Q4_K_M; 27B был удалён -- перекрывается флагманом)
**Направления**: [llm](../llm.md), [vision](../vision.md), [russian-llm](../russian-llm.md)

## Обзор

Qwen3.5 -- новое (февраль-март 2026) поколение универсальных моделей от Alibaba. Все варианты **мультимодальные** (image-text-to-text), с лучшим русским среди open-source. Серия включает dense и MoE-варианты от 2B до 397B. Apache 2.0 -- без ограничений.

На платформе используется как основная универсальная модель: 27B для повседневных задач, 122B-A10B как флагман для самых сложных запросов.

## Варианты

| Вариант | Параметры | Active | VRAM Q4 | tg tok/s | Статус | Hub |
|---------|-----------|--------|---------|----------|--------|-----|
| 122B-A10B | 122B MoE | 10B | ~71 GiB | 22.2 | скачана | [unsloth/Qwen3.5-122B-A10B-GGUF](https://huggingface.co/unsloth/Qwen3.5-122B-A10B-GGUF) |
| 35B-A3B | 35B MoE | 3B | ~21 GiB | -- | **скачана (Q4_K_M)** | [unsloth/Qwen3.5-35B-A3B-GGUF](https://huggingface.co/unsloth/Qwen3.5-35B-A3B-GGUF) |
| 27B | 27B dense | 27B | ~17 GiB | 12.6 | не скачана (был, удалён) | [unsloth/Qwen3.5-27B-GGUF](https://huggingface.co/unsloth/Qwen3.5-27B-GGUF) |
| 9B | 9B dense | 9B | ~6 GiB | -- | не скачана | [unsloth/Qwen3.5-9B-GGUF](https://huggingface.co/unsloth/Qwen3.5-9B-GGUF) |
| 4B | 4B dense | 4B | ~3 GiB | -- | не скачана | -- |

### 122B-A10B {#122b-a10b}

Флагман на платформе. Лучшее качество из того что помещается.

- ~71 GiB Q4_K_M -- занимает большую часть памяти
- 10B активных параметров -- умнее MoE-моделей с 3B active, но медленнее
- **22.2 tok/s** -- приемлемо для интерактивного chat'а
- **Контекст 262144 (256K) native**, расширяемо до 1M через YaRN
- Multimodal (text + images)
- **Архитектура hybrid Gated DeltaNet** (по llama-server log: `qwen35moe`, 12 attention layers из 49, остальные 37 -- recurrent SSM). Это значит:
  - **inter-task cache reuse архитектурно blocked** (как у Coder Next, 35B-text). Между разными запросами с разным prompt префиксом llama.cpp пересчитывает весь промпт с нуля
  - **intra-task cache работает** через встроенный slot context checkpoint механизм llama-server
  - Решение upstream: llama.cpp [PR #19670](https://github.com/ggml-org/llama.cpp/pull/19670) (partial seq_rm для hybrid memory) -- ETA 3-6 мес

### 27B Dense {#27b}

Основная рабочая модель. Универсал для русскоязычного chat и кода.

- ~17 GiB Q4_K_M -- помещается с большим запасом
- **12.6 tok/s** -- близко к bandwidth-ceiling (256 GB/s ÷ 15.6 GB ≈ 16.4 t/s, ~77% эффективность)
- Multimodal -- понимает картинки
- Лучший русский язык в этом размере

### 35B-A3B (MoE) {#35b-a3b}

Быстрая мультимодальная MoE с 3B active. Альтернатива 27B dense -- быстрее, чуть больше памяти.

- ~22 GiB Q4_K_M
- Скорость как у 3B-модели за счёт MoE
- Mультимодальная

## Архитектура и особенности

- **Мультимодальность из коробки** -- все размеры понимают text + images без отдельного mmproj-файла
- **Hybrid dense + MoE линейка** -- от 4B dense для слабого железа до 122B MoE для максимума
- **Лучший русский среди open-source** в среднем сегменте (27B и 35B-A3B)
- **Apache 2.0** -- никаких ограничений
- **GGUF от unsloth** -- широкий выбор квантизаций (Q2 - Q8, IQ-варианты)

## Сильные кейсы

- **Русскоязычный chat, суммаризация, перевод** -- лучший в open-source среднем сегменте
- **Универсальность** -- одна модель закрывает text + vision + chat
- **122B на платформе** -- ранее (96 GiB) был на пределе, при 120 GiB запас 47 GiB на параллельный FIM или большой контекст
- **Замена отдельных text + vision моделей** -- не нужно держать две

## Слабые стороны / ограничения

- **397B MoE не помещается** на платформе (~230 GiB Q4) -- только 122B и меньше
- **Свежий релиз 2026** -- community-экосистема ещё растёт
- На специфичных задачах (агентный кодинг, OCR документов) уступает специализированным [qwen3-coder](qwen3-coder.md), [qwen3-vl](qwen3-vl.md)

## Идеальные сценарии применения

- **Повседневный русскоязычный chat** -- 27B как основная рабочая
- **Большой контекст + reasoning** -- 122B-A10B для сложных задач, требующих "интеллектуального" ответа
- **Vision-вопросы общего характера** -- описание фото, анализ скриншотов (но для специализированного OCR/документов лучше [qwen3-vl](qwen3-vl.md))
- **Замена нескольких отдельных моделей** одной универсальной

## Загрузка

```bash
# 27B (рекомендуется как основная) -- ~17 GiB
./scripts/inference/download-model.sh unsloth/Qwen3.5-27B-GGUF --include "*Q4_K_M*"

# 35B-A3B (быстрая мультимодальная MoE) -- ~22 GiB
./scripts/inference/download-model.sh unsloth/Qwen3.5-35B-A3B-GGUF --include "*Q4_K_M*"

# 122B-A10B (флагман) -- ~71 GiB
./scripts/inference/download-model.sh unsloth/Qwen3.5-122B-A10B-GGUF --include "*Q4_K_M*"
```

## Запуск

```bash
# 27B (порт 8081, ctx 64K)
./scripts/inference/vulkan/preset/qwen3.5-27b.sh -d

# 122B (порт 8081, ctx 64K, --parallel 2 для запаса)
./scripts/inference/vulkan/preset/qwen3.5-122b.sh -d
```

## Community-варианты

### Qwen3.5-35B-A3B-APEX (mudler)

Та же базовая 35B-A3B, но с **APEX-квантизацией** -- умное распределение точности между слоями экспертов.

- **Hub**: [mudler/Qwen3.5-35B-A3B-APEX-GGUF](https://huggingface.co/mudler/Qwen3.5-35B-A3B-APEX-GGUF)
- APEX Quality (21.3 GB) -- PPL 6.527 (лучше F16!)
- APEX Balanced (23.6 GB) -- общего назначения
- APEX Compact (16.1 GB) -- для consumer 24GB
- Архитектура: edges Q6_K, middle Q5/IQ4, shared experts Q8_0

### Qwen3.5-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled (Jackrong)

LoRA-дообучение на трассах рассуждений Claude 4.6 Opus. Структурированное планирование в `<think>` блоках.

- **Hub**: [Jackrong/Qwen3.5-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled](https://huggingface.co/Jackrong/Qwen3.5-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled)
- **GGUF**: [mradermacher GGUF](https://huggingface.co/mradermacher/Qwen3.5-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled-GGUF)
- Контекст 8K (мало для [opencode](../../ai-agents/agents/opencode/README.md))
- Подходит для standalone reasoning-задач (математика, алгоритмы)

### Qwen3-14B-Claude-4.5-Opus-High-Reasoning-Distill (TeichAI)

Fine-tune Qwen3-14B на 250 reasoning-трассах Claude Opus 4.5 (high reasoning effort). Компактная dense-модель для standalone reasoning.

- **Hub**: [TeichAI/Qwen3-14B-Claude-4.5-Opus-High-Reasoning-Distill](https://huggingface.co/TeichAI/Qwen3-14B-Claude-4.5-Opus-High-Reasoning-Distill)
- **GGUF**: [TeichAI/Qwen3-14B-Claude-4.5-Opus-High-Reasoning-Distill-GGUF](https://huggingface.co/TeichAI/Qwen3-14B-Claude-4.5-Opus-High-Reasoning-Distill-GGUF)
- 14B dense, Apache 2.0
- VRAM: Q4_K_M ~9 GiB, Q8_0 ~15.7 GiB -- помещается с большим запасом
- Обучающий датасет: [TeichAI/claude-4.5-opus-high-reasoning-250x](https://huggingface.co/datasets/TeichAI/claude-4.5-opus-high-reasoning-250x) -- 250 samples, 2.13M tokens, $52 training cost
- **Caveat**: микро-датасет (250 samples) -- качество reasoning не подтверждено стандартными бенчмарками. Использовать как эксперимент, не как production-модель
- Подходит для: standalone reasoning (математика, логика, алгоритмы), быстрые ответы (~25-30 tok/s dense 14B на платформе)
- **Не подходит для**: agent-style кодинга (нет SWE-bench данных, нет tool use training), длинные контексты (контекст не расширен)

## Бенчмарки

| Модель | Параметры | tg tok/s (Vulkan) | Эффективность от bandwidth |
|--------|-----------|-------------------|----------------------------|
| 122B-A10B | 122B MoE | 22.2 | -- (MoE bonus) |
| 27B dense | 27B | 12.6 | 77% |

## Имеет ли смысл в агентах кодинга

**Краткий ответ**: нет, как основной бэкенд для [opencode](../../ai-agents/agents/opencode/README.md) / [Aider](../../ai-agents/agents/aider.md) / [Cline](../../ai-agents/agents/cline.md) -- не стоит. Для редких вспомогательных задач -- можно, но почти всегда есть лучший вариант.

### Почему не рекомендуется

1. **Не coding-tuned**. Qwen3.5 -- universal-серия, оптимизированная под chat / reasoning / multimodal / русский. Кодинг покрывает специализированная линейка [qwen3-coder](qwen3-coder.md), которая на той же базе обучена на ~7T токенов agentic-данных и trace'ах tool use. Сравнение на SWE-bench Verified:

   | Модель | SWE-V | Active | tg tok/s | Назначение |
   |--------|-------|--------|----------|------------|
   | [Qwen3-Coder Next 80B-A3B](qwen3-coder.md#next-80b-a3b) | **70.6%** | 3B | ~80 | agent-style coding |
   | [Qwen3-Coder 30B-A3B](qwen3-coder.md#30b-a3b) | ~62% | 3B | ~86 | chat по коду |
   | [Devstral 2 24B](devstral.md) | **72.2%** | 24B (dense) | ~25 | dense alternative |
   | Qwen3.5 122B-A10B | не публикуется | 10B | 22.2 | universal/chat |
   | Qwen3.5 27B dense | не публикуется | 27B | 12.6 | universal/chat |

   Qwen3.5 не публикует SWE-bench именно потому, что это не её домен -- сравнение проиграет coder-вариантам той же базы.

2. **Слабее на tool use дисциплине**. Agent-инструменты требуют чёткого формата вызовов, стабильного JSON, не "уезжающего" reasoning-цикла. Coder-варианты тренированы именно на trace'ах tool calling, у Qwen3.5 это побочный навык.

3. **Скорость убивает интерактивность**. opencode/Cline на одну задачу делают 5-20 итераций tool-loop. На 122B-A10B (22 tok/s) средний agentic запрос съест 2-5 минут wall clock против 30-60 сек на Qwen3-Coder Next (~80 tok/s). На 27B dense (12.6 tok/s) -- ещё хуже.

4. **Контекст 128K vs 256K у coder-серии**. Для крупных monorepo разница ощутима: agentic-loop с repo map + grep + diff быстро забивает 128K, у Qwen3-Coder Next вдвое больший запас.

5. **Multimodal не нужна** в большинстве coding-задач. Сильная сторона Qwen3.5 (vision, русский) в agent-кодинге не используется.

### Когда всё-таки имеет смысл

- **Скриншот ошибки + код в одном промпте** через [opencode](../../ai-agents/agents/opencode/README.md) -- но для этого лучше [Gemma 4 26B-A4B](gemma4.md) (специально натренирована на screenshot-to-code) или [Qwen3-VL](qwen3-vl.md).
- **Code review с русскоязычными комментариями** -- 27B dense даёт лучший русский, объясняет диффы понятным языком. Узкая ниша.
- **Standalone reasoning-задачи**: алгоритмика, математика, "объясни сложный участок", без многошаговой агентности. 122B-A10B здесь сильнее coder-вариантов на reasoning, но это уже не agent use case -- это chat по коду.
- **35B-A3B-Claude-4.6-Opus-Reasoning-Distilled** (community-вариант) -- интересен для reasoning, но контекст 8K делает его непригодным для agent-loop.

### Вердикт

Для daily agent-кодинга на нашей платформе оставлять [Qwen3-Coder Next 80B-A3B](qwen3-coder.md#next-80b-a3b) (через `vulkan/preset/qwen-coder-next.sh`). Qwen3.5 122B-A10B держать как **универсальный chat / vision / русскоязычный assistant** (Open WebUI), не как agent backend. Параллельный запуск возможен -- 71 GiB (122B) + 45 GiB (Coder Next) ≈ 116 GiB, впритык под 120 GiB.

## Как выбрать вариант (27B vs 35B-A3B vs 122B-A10B)

Подробный разбор с decision tree, расшифровкой обозначений (`A3B`, `A10B`) и практическими сценариями -- в статье **[«Имена моделей и выбор варианта»](../../llm-guide/naming-and-variants.md)**. Использует Qwen3.5 как сквозной пример.

Кратко:
- **27B dense** -- universal, экономия VRAM, ~12 tok/s
- **35B-A3B (MoE)** -- быстрый отклик 80+ tok/s, баланс качество/скорость
- **122B-A10B (MoE)** -- максимум знаний, 22 tok/s, флагман

## Связано

- Направления: [llm](../llm.md), [vision](../vision.md), [russian-llm](../russian-llm.md)
- Родственные семейства: [qwen3-coder](qwen3-coder.md) (специализированный кодинг), [qwen3-vl](qwen3-vl.md) (специализированный vision)
- Теория: [architectures.md](../../llm-guide/architectures.md) (Dense vs MoE), [naming-and-variants.md](../../llm-guide/naming-and-variants.md) (выбор варианта)
- Пресеты: [`scripts/inference/vulkan/preset/qwen3.5-122b.sh`](../../../scripts/inference/vulkan/preset/qwen3.5-122b.sh)
