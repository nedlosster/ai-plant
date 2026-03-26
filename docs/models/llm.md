# LLM общего назначения

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), llama-server + Vulkan. Только модели, помещающиеся на платформе.

## Рекомендуемый набор моделей

Минимальный набор для покрытия основных задач:

| Модель | VRAM (Q4) | tg tok/s | Назначение |
|--------|-----------|----------|-----------|
| **Qwen3.5-27B** | ~17 GiB | ~12.6 | Основная рабочая: русский, chat, vision |
| **Qwen3.5-35B-A3B** (MoE) | ~22 GiB | -- | Быстрая MoE, мультимодальная |
| **QwQ-32B** | ~19 GiB | -- | Reasoning, математика, аналитика |
| **Qwen2.5-Coder-1.5B-Instruct** | ~2 GiB (Q8) | ~120.6 | FIM-автодополнение в IDE |
| **Llama-3.1-8B-Instruct** | ~5 GiB | -- | Тесты, RAG, английский |

Расширенный набор (доступен благодаря 120 GiB):

| Модель | VRAM | tg tok/s | Назначение |
|--------|------|----------|-----------|
| **Qwen3.5-122B-A10B** (MoE) | ~71 GiB Q4 | ~22.2 | Максимальное качество, мультимодальная |
| **Qwen3-Coder-Next** (MoE) | ~45 GiB Q4 | ~53.2 | Кодинг нового поколения |
| **Llama-3.3-70B** | ~74 GiB Q8 | -- | Максимальный английский, лучшее качество в Q8 |
| **Mixtral 8x22B** (MoE) | ~82 GiB Q4 | -- | Быстрая MoE 141B, длинный контекст 64k |
| **Command A 111B** | ~65 GiB Q4 | -- | RAG, tool use, enterprise |
| **Llama 4 Scout** (MoE) | ~67 GiB Q4 | -- | Контекст 10M, vision |
| **DeepSeek-R1-Distill-32B** | ~19 GiB Q4 | -- | Reasoning (MATH-500 94.3%) |
| **Phi-4** | ~9 GiB Q4 | -- | Reasoning при малом VRAM |

## Что открывает 120 GiB (было недоступно при 96 GiB)

| Категория | При 96 GiB | При 120 GiB |
|-----------|-----------|-------------|
| 70B dense в Q8_0 + ctx 32k | на пределе (~90 GiB), нестабильно | комфортно (~94 GiB), запас 26 GiB |
| Mixtral 8x22B Q4_K_M | ~82 GiB, без контекста | + ctx 32k, запас ~20 GiB |
| Command A 111B Q5_K_M | не помещается (~78 GiB) | помещается |
| 122B MoE + параллельный FIM | ~73 GiB, мало запаса | ~73 GiB, запас 47 GiB |

## Загрузка всех моделей

Запуск на AI-сервере (`cd ~/projects/ai-plant`):

### Минимальный набор (~65 GiB)

```bash
# Основная рабочая (русский, chat, vision) -- ~17 GiB
./scripts/inference/download-model.sh unsloth/Qwen3.5-27B-GGUF --include "*Q4_K_M*"

# Быстрая MoE (мультимодальная) -- ~22 GiB
./scripts/inference/download-model.sh unsloth/Qwen3.5-35B-A3B-GGUF --include "*Q4_K_M*"

# Reasoning -- ~19 GiB
./scripts/inference/download-model.sh bartowski/QwQ-32B-GGUF --include "*Q4_K_M*"

# FIM для IDE (автодополнение) -- ~2 GiB
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF --include "*Q8_0*"

# Тесты, RAG -- ~5 GiB
./scripts/inference/download-model.sh bartowski/Llama-3.1-8B-Instruct-GGUF --include "*Q4_K_M*"
```

### Расширенный набор (дополнительно ~400 GiB диска)

```bash
# Максимальное качество (MoE, мультимодальная) -- ~71 GiB
./scripts/inference/download-model.sh unsloth/Qwen3.5-122B-A10B-GGUF --include "*Q4_K_M*"

# Кодинг нового поколения -- ~45 GiB
./scripts/inference/download-model.sh Qwen/Qwen3-Coder-Next-GGUF --include "*Q4_K_M*"

# Llama 70B в Q8 (максимальное качество dense) -- ~74 GiB
./scripts/inference/download-model.sh bartowski/Llama-3.3-70B-Instruct-GGUF --include "*Q8_0*"

# Mixtral 8x22B (MoE, 141B) -- ~82 GiB
./scripts/inference/download-model.sh bartowski/Mixtral-8x22B-Instruct-v0.1-GGUF --include "*Q4_K_M*"

# Command A 111B (RAG, tool use) -- ~65 GiB
./scripts/inference/download-model.sh bartowski/command-a-111b-GGUF --include "*Q4_K_M*"

# Длинный контекст 10M (MoE) -- ~67 GiB
./scripts/inference/download-model.sh bartowski/Llama-4-Scout-17B-16E-Instruct-GGUF --include "*Q4_K_M*"

# Reasoning (DeepSeek) -- ~19 GiB
./scripts/inference/download-model.sh bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF --include "*Q4_K_M*"

# Reasoning при малом VRAM -- ~9 GiB
./scripts/inference/download-model.sh bartowski/phi-4-GGUF --include "*Q4_K_M*"
```

## Сводная таблица

| Модель | Параметры | Архитектура | Русский | Лицензия | Q4_K_M | Q8_0 |
|--------|-----------|------------|---------|----------|--------|------|
| **Qwen3.5-122B-A10B** | 122B MoE (10B active) | MoE | отличный | Apache 2.0 | ~71 GiB | -- |
| **Mixtral 8x22B** | 141B MoE (39B active) | MoE | средний | Apache 2.0 | ~82 GiB | -- |
| **Command A** | 111B dense | dense | средний | CC-BY-NC | ~65 GiB | -- |
| **Qwen3-Coder-Next** | 80B MoE (3B active) | MoE | хороший | Apache 2.0 | ~45 GiB | -- |
| **Llama 4 Scout** | 109B MoE (17B active) | MoE | средний | Llama CL | ~67 GiB | -- |
| **Llama-3.3-70B** | 70B dense | dense | базовый | Llama CL | ~42 GiB | ~74 GiB |
| **Qwen2.5-72B** | 72B dense | dense | отличный | Apache 2.0 | ~44 GiB | ~78 GiB |
| **Qwen3.5-35B-A3B** | 35B MoE (3B active) | MoE | отличный | Apache 2.0 | ~22 GiB | -- |
| **Qwen3.5-27B** | 27B dense | dense | отличный | Apache 2.0 | ~17 GiB | -- |
| **DeepSeek-R1-Distill-32B** | 32B dense | dense | средний | MIT | ~19 GiB | -- |
| **QwQ-32B** | 32B dense | dense | хороший | Apache 2.0 | ~19 GiB | -- |
| **Phi-4** | 14B dense | dense | слабый | MIT | ~9 GiB | -- |
| **Qwen3.5-9B** | 9B dense | dense | отличный | Apache 2.0 | ~6 GiB | -- |
| **Llama-3.1-8B** | 8B dense | dense | базовый | Llama CL | ~5 GiB | -- |
| **Qwen2.5-Coder-1.5B** | 1.5B dense | dense | -- | Apache 2.0 | ~1 GiB | ~2 GiB |

Все модели Qwen3.5 -- мультимодальные (текст + изображения).

---

## Qwen3.5 (Alibaba, февраль-март 2026)

Новейшее поколение. Все модели -- мультимодальные (image-text-to-text).

**Назначение**: универсальные мультимодальные модели. Лучший русский среди open-source.

**Сильные стороны**:
- Мультимодальность из коробки (текст + изображения)
- Линейка от 0.8B до 397B (dense + MoE)
- Лучший русский язык среди open-source
- Apache 2.0 -- без ограничений
- MoE-варианты: высокое качество при быстром отклике (3B/10B/17B active)
- GGUF от unsloth -- широкий выбор квантизаций

**Слабые стороны**:
- Свежий релиз -- community-экосистема растет
- 397B MoE не помещается на платформе (~230 GiB Q4)

**Применение**:
- Русскоязычный chat, суммаризация, перевод
- Анализ изображений, OCR, visual QA
- Замена отдельных text + vision моделей одной

| Модель | Тип | Active | VRAM (Q4) | tg tok/s (замер) |
|--------|-----|--------|-----------|------------------|
| Qwen3.5-122B-A10B | MoE | 10B | ~71 GiB | 22.2 |
| Qwen3.5-35B-A3B | MoE | 3B | ~22 GiB | -- |
| Qwen3.5-27B | dense | 27B | ~17 GiB | 12.6 |
| Qwen3.5-9B | dense | 9B | ~6 GiB | -- |
| Qwen3.5-4B | dense | 4B | ~3 GiB | -- |

---

## Mixtral 8x22B (Mistral, апрель 2024)

**Назначение**: быстрая MoE-модель 141B с 39B активных параметров.

**Сильные стороны**:
- 39B активных -- больше, чем у Qwen MoE (3-10B), потенциально выше качество на сложных задачах
- Контекст 64K
- Apache 2.0
- Проверенная экосистема

**При 120 GiB**: Q4_K_M (~82 GiB) + ctx 32k (~15 GiB) = ~97 GiB -- помещается. При 96 GiB это было невозможно.

---

## Command A (Cohere, март 2025)

**Назначение**: RAG, tool use, enterprise. 111B dense.

**Сильные стороны**:
- Оптимизирована для RAG и function calling
- Контекст 256K
- 111B параметров -- мощная dense-модель

**При 120 GiB**: Q4_K_M (~65 GiB) с запасом, Q5_K_M (~78 GiB) тоже помещается.

---

## Qwen3 -- специализированные

### Qwen3-Coder-Next (кодинг)

80B MoE (3B active). GGUF доступны (официальные от Qwen). SWE-bench Pro 44.3%.

```bash
./scripts/inference/download-model.sh Qwen/Qwen3-Coder-Next-GGUF --include "*Q4_K_M*"
```

### QwQ-32B (reasoning)

32B dense. AIME24 79.5, MATH-500 95.2. Chain-of-thought. Apache 2.0.

```bash
./scripts/inference/download-model.sh bartowski/QwQ-32B-GGUF --include "*Q4_K_M*"
```

### Qwen2.5-Coder (FIM)

Для автодополнения в IDE. 1.5B (FIM, Q8) -- рекомендуемая FIM-модель.

```bash
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF --include "*Q8_0*"
```

---

## DeepSeek R1-Distill

**Назначение**: reasoning в компактных моделях. Дистилляция из DeepSeek-R1 (671B).

**Сильные стороны**: R1-Distill-32B: MATH-500 94.3% при ~19 GiB. MIT-лицензия.

**Слабые стороны**: длинные chain-of-thought, русский нестабильный.

| Модель | MATH-500 | VRAM (Q4) |
|--------|----------|-----------|
| R1-Distill-32B (Qwen) | 94.3 | ~19 GiB |
| R1-Distill-14B (Qwen) | 93.9 | ~8.5 GiB |

---

## Llama (Meta)

**Назначение**: эталон open-source. Максимальная экосистема.

| Модель | Q4_K_M | Q8_0 | Особенность |
|--------|--------|------|------------|
| Llama-3.3-70B | ~42 GiB | ~74 GiB | Лучший английский. Q8 при 120 GiB -- максимум качества |
| Llama 4 Scout | ~67 GiB | -- | Контекст 10M, MoE 109B, vision |
| Llama-3.1-8B | ~5 GiB | -- | Стандарт для тестирования |

При 120 GiB: Llama-3.3-70B в **Q8_0** (~74 GiB) + ctx 32k (~20 GiB) = ~94 GiB -- помещается с запасом. При 96 GiB это было на пределе.

---

## Phi-4 (Microsoft)

14B dense. MMLU 84.8 (уровень 70B). MIT. Контекст 16K (короткий). Русский слабый.

---

## Что помещается в 120 GiB

| VRAM | Модели (Q4_K_M) |
|------|-----------------|
| <10 GiB | Qwen3.5-9B/4B/2B, Llama-3.1-8B, Phi-4, R1-Distill-14B, Coder-1.5B |
| 10-25 GiB | Qwen3.5-27B, Qwen3.5-35B-A3B, QwQ-32B, R1-Distill-32B |
| 25-50 GiB | Qwen3-Coder-Next (~45), Llama-3.3-70B Q4 (~42), Qwen2.5-72B Q4 (~44) |
| 50-85 GiB | Qwen3.5-122B-A10B (~71), Llama 4 Scout (~67), Command A (~65), Mixtral 8x22B (~82) |
| 85-120 GiB | Llama-3.3-70B Q8 (~74) + ctx 32k, Qwen2.5-72B Q8 (~78) + ctx 16k |

Два сервера: Coder 1.5B Q8 (~2 GiB) + Qwen3.5-27B Q4 (~17 GiB) = ~19 GiB. Остается ~101 GiB.

## Что не помещается

| Модель | Q4_K_M | Причина |
|--------|--------|---------|
| DeepSeek-V3 / R1 (671B MoE) | ~390 GiB | Серверная модель, multi-GPU |
| DeepSeek-Coder-V2 (236B MoE) | ~135 GiB | Превышает 120 GiB |
| Llama 4 Maverick (400B MoE) | ~240 GiB | Серверная модель |
| Qwen3.5-397B MoE | ~230 GiB | Серверная модель |

## Русский язык (рейтинг)

1. **Qwen3.5-122B-A10B** -- лучший (MoE, мультимодальная)
2. **Qwen2.5-72B Q8** -- отличный dense, максимум качества при 120 GiB
3. **Qwen3.5-27B / 35B-A3B** -- отличный
4. **QwQ-32B** -- хороший + reasoning
5. **Qwen3.5-9B / 4B** -- хороший, быстрые
6. **Mixtral 8x22B** -- средний, но быстрый MoE
7. **DeepSeek-R1-Distill-32B** -- средний, отличный reasoning
8. **Llama-3.3-70B / Llama 4** -- базовый
9. **Phi-4** -- слабый

## Лицензии

| Лицензия | Модели |
|----------|--------|
| Apache 2.0 (без ограничений) | Qwen3.5, QwQ, Qwen3-Coder, Qwen2.5-Coder, Mixtral 8x22B |
| MIT (без ограничений) | DeepSeek-R1-Distill, Phi-4 |
| Llama CL (ограничение 700M MAU) | Llama 3.1/3.3/4 |
| CC-BY-NC | Command A |

## Связанные статьи

- [Анатомия LLM](../llm-guide/model-anatomy.md)
- [Квантизация](../llm-guide/quantization.md)
- [HuggingFace](../llm-guide/huggingface.md)
- [Модели для кодинга](coding.md)
- [Российские LLM](russian-llm.md)
- [Бенчмарки](../inference/benchmarking.md)
