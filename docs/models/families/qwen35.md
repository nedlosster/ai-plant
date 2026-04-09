# Qwen3.5 (Alibaba, 2026)

> Новейшее поколение Qwen для общего назначения, мультимодальные dense + MoE, лучший русский среди open-source.

**Тип**: dense + MoE
**Лицензия**: Apache 2.0
**Статус на сервере**: скачаны (27B dense, 122B-A10B MoE)
**Направления**: [llm](../llm.md), [vision](../vision.md), [russian-llm](../russian-llm.md)

## Обзор

Qwen3.5 -- новое (февраль-март 2026) поколение универсальных моделей от Alibaba. Все варианты **мультимодальные** (image-text-to-text), с лучшим русским среди open-source. Серия включает dense и MoE-варианты от 2B до 397B. Apache 2.0 -- без ограничений.

На платформе используется как основная универсальная модель: 27B для повседневных задач, 122B-A10B как флагман для самых сложных запросов.

## Варианты

| Вариант | Параметры | Active | VRAM Q4 | tg tok/s | Статус | Hub |
|---------|-----------|--------|---------|----------|--------|-----|
| 122B-A10B | 122B MoE | 10B | ~71 GiB | 22.2 | скачана | [unsloth/Qwen3.5-122B-A10B-GGUF](https://huggingface.co/unsloth/Qwen3.5-122B-A10B-GGUF) |
| 35B-A3B | 35B MoE | 3B | ~22 GiB | -- | не скачана | [unsloth/Qwen3.5-35B-A3B-GGUF](https://huggingface.co/unsloth/Qwen3.5-35B-A3B-GGUF) |
| 27B | 27B dense | 27B | ~17 GiB | 12.6 | скачана | [unsloth/Qwen3.5-27B-GGUF](https://huggingface.co/unsloth/Qwen3.5-27B-GGUF) |
| 9B | 9B dense | 9B | ~6 GiB | -- | не скачана | [unsloth/Qwen3.5-9B-GGUF](https://huggingface.co/unsloth/Qwen3.5-9B-GGUF) |
| 4B | 4B dense | 4B | ~3 GiB | -- | не скачана | -- |

### 122B-A10B {#122b-a10b}

Флагман на платформе. Лучшее качество из того что помещается.

- ~71 GiB Q4_K_M -- занимает большую часть памяти
- 10B активных параметров -- умнее MoE-моделей с 3B active, но медленнее
- **22.2 tok/s** -- приемлемо для интерактивного chat'а
- Контекст ~128K
- Multimodal (text + images)

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
- Контекст 8K (мало для opencode)
- Подходит для standalone reasoning-задач (математика, алгоритмы)

## Бенчмарки

| Модель | Параметры | tg tok/s (Vulkan) | Эффективность от bandwidth |
|--------|-----------|-------------------|----------------------------|
| 122B-A10B | 122B MoE | 22.2 | -- (MoE bonus) |
| 27B dense | 27B | 12.6 | 77% |

## Связано

- Направления: [llm](../llm.md), [vision](../vision.md), [russian-llm](../russian-llm.md)
- Родственные семейства: [qwen3-coder](qwen3-coder.md) (специализированный кодинг), [qwen3-vl](qwen3-vl.md) (специализированный vision)
- Пресеты: `scripts/inference/vulkan/preset/qwen3.5-27b.sh`, `scripts/inference/vulkan/preset/qwen3.5-122b.sh`
