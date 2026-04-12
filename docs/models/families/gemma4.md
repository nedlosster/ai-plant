# Gemma 4 (Google, 2 апреля 2026)

> Multimodal MoE с native function calling, 256K контекстом, thinking-режимом, bounding box prediction, adaptive image tokens (70-1120). Четыре размера: E2B, E4B, 26B-A4B (MoE), 31B (dense).

**Тип**: MoE (3.8B active / 25.2B total) -- основной вариант; также 31B dense и edge E2B/E4B
**Лицензия**: Apache 2.0 (E2B, E4B), Gemma Terms of Use (26B, 31B)
**Статус на сервере**: скачана (26B-A4B Q6_K_XL + mmproj-BF16)
**Направления**: [llm](../llm.md), [vision](../vision.md)
**Function calling**: native (лучшее сочетание FC + vision на платформе)
**Vision**: да (SigLIP-style encoder, mmproj-BF16, 1.19 GB, adaptive 70-1120 tokens/image)
**Audio**: только E2B и E4B (USM-style conformer encoder)

## Обзор

Gemma 4 26B-A4B -- multimodal MoE-модель от Google нового поколения 2026. Total 25.2B параметров, активных 3.8B, что даёт скорость как у dense 4B-модели. Поддерживает text и images, native function calling, контекст 256K, thinking-режим через `<|think|>` token.

На платформе используется как основная multimodal через `vulkan/preset/gemma4.sh`. Vision реализован двухкомпонентно: основной GGUF + отдельный `mmproj-BF16.gguf` (1.19 GB) с весами vision-encoder'а.

## Варианты

Семейство включает **четыре размера**, от edge до flagship:

| Вариант | Параметры | Active | Контекст | Vision | Audio | VRAM Q4 | Статус | Лицензия |
|---------|-----------|--------|----------|--------|-------|---------|--------|----------|
| **E2B** | 2B dense | 2B | 32K | да | **да** | ~2 GiB | не скачана | Apache 2.0 |
| **E4B** | 4B dense | 4B | 32K | да | **да** | ~3 GiB | не скачана | Apache 2.0 |
| **26B-A4B** | 25.2B MoE | 3.8B | **256K** | да | нет | ~17 GiB | **скачана** (Q6_K_XL) | Gemma TOU |
| **31B** | 31B dense | 31B | **256K** | да | нет | ~19 GiB | не скачана | Gemma TOU |

**E2B и E4B** -- edge-варианты с **аудио-входом** (USM-style conformer encoder) помимо vision и text. Designed для мобильных устройств и embedded. На Strix Halo избыточны -- 26B-A4B качественнее при том же VRAM.

**31B dense** -- flagship, все параметры активны. Даёт лучшее качество в бенчмарках чем 26B-A4B MoE, но медленнее (dense 31B vs 3.8B active). На Strix Halo: ~19 GiB Q4 помещается, но tg ~5 tok/s (memory-bound на 31B), что непрактично для интерактивного чата.

**26B-A4B MoE** -- основной рабочий вариант на платформе. Баланс: 3.8B active = скорость dense 4B, качество большой 26B.

### Квантизации скачанного варианта (26B-A4B)

| Квант | VRAM | mmproj | Статус | Hub |
|-------|------|--------|--------|-----|
| **Q6_K_XL** | ~22 GiB | 1.19 GB | **скачана** | [unsloth/gemma-4-26B-A4B-it-GGUF](https://huggingface.co/unsloth/gemma-4-26B-A4B-it-GGUF) |
| Q4_K_M | ~17 GiB | 1.19 GB | не скачана | то же |
| Q8_0 | ~27 GiB | 1.19 GB | не скачана | то же |

### Варианты mmproj в репо

- **`mmproj-BF16.gguf`** (1.19 GB) -- рекомендуется
- `mmproj-F16.gguf` (1.19 GB) -- идентично BF16 по размеру
- `mmproj-F32.gguf` (2.29 GB) -- максимальная точность, не нужна для практики

## Архитектура и особенности

- **MoE 8/128 + 1 shared expert** -- активны 3.8B параметров на токен, скорость как у 4B-модели
- **SigLIP-style vision encoder** в отдельном `mmproj-BF16.gguf` файле
- **Контекст 256K** -- можно загрузить много кадров видео или серию скриншотов
- **Native function calling** -- из коробки, без отдельного fine-tune
- **Thinking-режим** через `<|think|>` token в начале system prompt
- **Variable aspect ratio** изображений -- понимает портрет/панораму без принудительного crop
- **Sliding window attention** -- чередование local (512-1024 токенов) и global слоёв
- **Bounding box prediction** -- нативный JSON output для координат объектов в кадре

## Интересные технические детали

### Адаптивные image tokens: 70 → 1120 на кадр

SigLIP vision encoder в Gemma 4 **не фиксирует количество токенов на изображение**. Вместо этого используется **configurable token budget**: 70, 140, 280, 560 или 1120 vision-токенов на кадр.

Это означает:
- **70 токенов** (минимум) -- грубое понимание сцены, достаточно для "что на фото" и классификации. Минимальный VRAM, максимальная скорость
- **280 токенов** (среднее) -- баланс для большинства задач (описание, OCR крупного текста)
- **1120 токенов** (максимум) -- pixel-level детализация для OCR мелкого текста, bounding box prediction, chart analysis

При загрузке 30 скриншотов в 256K контекст: `30 × 280 = 8400` vision-токенов -- менее 4% контекста. Если важна детализация: `30 × 1120 = 33600` -- ~13% контекста, всё ещё управляемо.

На практике llama-server автоматически выбирает budget на основе разрешения входного изображения. Малые картинки (<384px) → 70 токенов, средние → 280, большие (>1024px) → 560-1120.

### Чередование local и global attention

Gemma 4 **не использует чисто global attention** на всех слоях (как в Llama/Qwen). Вместо этого чередуются:

- **Local sliding-window слои** (window = 512 или 1024 токенов) -- видят только ближайший контекст. Быстрые, экономные по KV-cache
- **Global full-context слои** -- видят все 256K токенов. Медленнее, дороже

Чередование (упрощённо): local → local → global → local → local → global → ...

Это **снижает KV-cache** (local слои не кэшируют дальние токены) и ускоряет inference, но создаёт **побочный эффект**: sliding window cache не переиспользуется между turn'ами (ctx-shift не работает), поэтому в multi-turn каждый запрос фактически пересчитывает весь prefix.

### Per-Layer Embeddings (PLE) в E2B/E4B

Маленькие варианты (E2B, E4B) используют **PLE** -- дополнительный параллельный канал рядом с основным residual stream:

```
Основной поток:    x → attention → FFN → x'
PLE-поток:         e_token + e_context → маленький вектор на каждый layer
```

PLE даёт каждому слою **дополнительный conditioning signal**, который зависит:
1. От **token identity** (какой токен) -- через lookup table
2. От **контекста** (что вокруг) -- через mini-attention

Результат: E2B с PLE даёт качество, которое без PLE потребовало бы ~3-4B параметров. Это key innovation для edge-deployment.

### Аудио-encoder в E2B/E4B

Малые варианты имеют **USM-style conformer audio encoder** (как в Gemma 3n):
- Принимает аудио-вход (до 90 секунд)
- Конвертирует в sequence of audio tokens
- Токены объединяются с text и vision в общий input

Это делает E2B и E4B **tri-modal**: text + images + audio. У 26B-A4B и 31B аудио-входа нет.

Практический use case на edge: smart doorbell с Gemma 4 E4B -- видит камеру, слышит звук, отвечает текстом.

### Bounding box prediction: native JSON

Gemma 4 умеет возвращать координаты объектов прямо в JSON, без post-processing:

Промпт: "Найди все кнопки на скриншоте, верни координаты"

Ответ:
```json
[
  {"label": "Submit", "bbox": [120, 340, 280, 380]},
  {"label": "Cancel", "bbox": [300, 340, 420, 380]},
  {"label": "Settings icon", "bbox": [780, 10, 820, 50]}
]
```

Координаты `[x1, y1, x2, y2]` в пикселях исходного изображения. Это **нативная способность** модели, не требующая grammar constraints -- модель обучена возвращать bbox как часть ответа.

Полезно для: UI testing automation, accessibility audit (где clickable area < 44px), visual regression detection (сравнение bbox между screenshots).

### Бенчмарки

| Бенч | Значение |
|------|----------|
| LiveCodeBench v6 | 77.1% |
| Codeforces ELO | 1718 |
| AIME 2026 | 88.3% |

## Сильные кейсы

- **Function calling по визуальному входу** -- получает скриншот UI, вызывает tool с выделенными координатами
- **Reasoning по диаграмме** через thinking-режим
- **Длинный контекст 256K** -- много кадров видео, серия скриншотов, длинная инструкция
- **Универсальный VLM "общего назначения"** -- сильна на смешанных задачах
- **Variable aspect ratio** -- понимает портрет/панораму без потери информации
- **Скорость MoE** -- как у 4B при качестве 26B

## Слабые стороны / ограничения

- **Sliding window attention** -- чувствительна к OOM при больших контекстах (см. пресет gemma4.sh с защитами `--parallel 1 --no-mmap -c 65536`)
- **KV-cache shifting не работает** -- multi-turn чат пересчитывает префикс. `--cache-reuse 256` в пресете установлен, но llama.cpp выдаёт `cache reuse is not supported - ignoring n_cache_reuse = 256`
- **OCR хуже** [qwen3-vl](qwen3-vl.md) и [internvl](internvl.md)
- **Не специализирована под конкретный домен** (math/science -- лучше специализированные модели)

## Оптимальная стратегия применения на платформе

### Какой квант брать

| Квант | Размер | Качество | Когда |
|-------|--------|----------|-------|
| **Q6_K_XL** ⭐ | 22 GiB | ~99% F16 | **Рекомендуемый дефолт**. Скачан, используется в пресете |
| Q4_K_M | 17 GiB | ~96% F16 | Если нужно держать параллельно с большим Coder Next (Q4 + Coder Next + FIM = 64 GiB) |
| Q8_0 | 27 GiB | ~99.5% F16 | Не нужен -- разница с Q6_K_XL в пределах шума, +5 GiB не оправданы |

Q6_K_XL -- золотая середина для платформы 120 GiB. Q4_K_M только если хочется освободить место под второй большой сервер.

### Когда брать Gemma 4, а когда альтернативы

| Задача | Gemma 4 | Лучшая альтернатива | Почему |
|--------|---------|----------------------|--------|
| Скриншот UI → код | **Gemma 4** ⭐ | -- | Специально натренирована на screenshot-to-code, native function calling даёт чистый JSX |
| Function calling по картинке | **Gemma 4** ⭐ | -- | Vision + tool use в одной модели без лишних оберток |
| Длинный контекст 256K + vision | **Gemma 4** ⭐ | -- | 256K больше всех VLM на платформе |
| Чистый OCR (не-латинские шрифты, мелкий текст) | -- | [Qwen3-VL 30B-A3B](qwen3-vl.md#30b-a3b) | OCR -- профильная сила Qwen3-VL, у Gemma слабее |
| Math reasoning по диаграмме | -- | [InternVL3.5-38B](internvl.md#3-5-38b) | InternViT-6B даёт лучше chart understanding и math |
| Vision + audio (omni) | -- | [Qwen2.5-Omni 7B](qwen25-omni.md) | Gemma 4 не работает с аудио |
| Простые "опиши фото", quick chat | Gemma 4 | [Qwen3-VL 30B-A3B](qwen3-vl.md#30b-a3b) | Обе работают, выбор по тому что уже запущено |
| Multi-image сравнение | -- | [Qwen3-VL 30B-A3B](qwen3-vl.md#30b-a3b) или [Pixtral 12B](pixtral.md) | У Gemma нет специальной оптимизации под multi-image |

**Главное правило**: брать Gemma 4 когда нужно **vision + (function calling или длинный контекст или screenshot-to-code)**. Если задача чисто OCR или reasoning над диаграммой -- альтернативы лучше.

### Параллельные конфигурации

Gemma 4 Q6_K_XL занимает 22 GiB + mmproj 1.2 GiB = ~23 GiB, оставляя 97 GiB запаса. Можно держать параллельно:

- **Стандарт**: Gemma 4 (23 GiB) + FIM 1.5B (2 GiB) = 25 GiB → 95 GiB запас
- **С Coder Next**: Gemma 4 (23 GiB) + Coder Next (45 GiB) + FIM (2 GiB) = 70 GiB → 50 GiB запас
- **С Devstral 2**: Gemma 4 (23 GiB) + Devstral 2 24B (14 GiB) + FIM (2 GiB) = 39 GiB → 81 GiB запас
- **Vision-zoo**: Gemma 4 (23 GiB) + Qwen3-VL 30B-A3B (20 GiB) + InternVL3.5-38B (27 GiB) = 70 GiB → 50 GiB запас (`--parallel 1` везде)

В последней конфигурации можно переключаться между всеми тремя vision-моделями через `/model` в opencode без перезагрузки серверов -- идеально для сравнительных задач.

## Базовые сценарии (простые)

- **"Опиши что на скриншоте"** -- быстрый описательный ответ
- **OCR простого документа** (счёт, чек, скан паспорта) → структурированный JSON
- **"Что не так на этом фото?"** -- описание видимых проблем (битый интерфейс, неправильная вёрстка)
- **Скриншот ошибки IDE → объяснение и фикс** в [opencode](../../ai-agents/agents/opencode.md)
- **Распознавание объектов на фото** для inventory / каталогизации
- **Перевод текста с фото вывески / меню**
- **"Сгенерируй HTML по этому скетчу"** -- простая wireframe → стартовый каркас

Все эти задачи 30B-A3B Instruct тоже выполнит, но Gemma 4 быстрее на function-call'ах и стабильнее на длинных prompt'ах.

## Сложные сценарии

### 1. Screenshot-to-code production-ready компонент

Скриншот реального UI компонента (например карточка товара из e-commerce). Gemma 4:
- Распознаёт компоненты Material UI / Ant Design / Tailwind
- Генерирует **полный JSX/TSX** с правильными props
- Учитывает adaptive layout (mobile/desktop варианты, если поданы оба)
- Через function calling может **сразу** вызвать `write_file` с готовым компонентом

Минус по сравнению с [Qwen3-VL](qwen3-vl.md) -- хуже определяет конкретную UI-библиотеку, склонна делать "плоский" Tailwind вариант. Плюс -- более чистый код на выходе.

### 2. Анализ wireframe и итеративная разработка

Загрузить wireframe в Figma-стиле → Gemma 4 с function calling:
- Извлекает структуру компонентов в JSON
- Для каждого компонента вызывает `create_file` с TSX-кодом
- Подключает routing, state management через дополнительные tool calls
- Возвращает план файловой структуры

Один промпт → готовый стартовый шаблон проекта. Это работает потому что Gemma 4 -- одна из немногих VLM с **native function calling** без оберток.

### 3. Reasoning по длинной видеоинструкции

Загрузить серию кадров (20-50 скриншотов) из обучающего видео + текстовый prompt с задачей. Gemma 4:
- Использует 256K контекст для удержания всех кадров одновременно (в отличие от 128K у Qwen3-VL)
- Через `<|think|>` reasoning-режим связывает кадры в последовательность действий
- Восстанавливает алгоритм или процедуру из видео в виде пошаговой инструкции
- Может сразу написать код для воспроизведения (например туториал по библиотеке → рабочий пример)

256K контекст -- ключевой плюс Gemma 4 для multi-frame задач.

### 4. Multi-document reasoning с переключением функций

Загрузить несколько разнородных документов: PDF договора, скриншот таблицы, фото подписи. Gemma 4:
- Через function calling вызывает разные tools для каждого типа: `extract_pdf_text`, `parse_table_image`, `verify_signature`
- Координирует results между tool calls
- Выдаёт сводное заключение

Это близко к agentic-режиму, но в одной модели без оркестратора.

### 5. UI accessibility audit

Скриншот веб-страницы → Gemma 4 проверяет:
- Контрастность текста (визуально оценивает)
- Размер кликабельных областей (>= 44×44 для mobile)
- Наличие визуальных подсказок для interactive элементов
- Иерархия заголовков
- Альтернативный текст для иконок (если виден alt в DOM-скриншоте)

Через function calling выдаёт structured report с severity для каждой проблемы.

### 6. Live debugging UI с серией скриншотов

3-5 скриншотов одного экрана в разных состояниях (idle / loading / error / success). Gemma 4:
- Восстанавливает state machine
- Находит **противоречия** между состояниями (например loader не убирается на success)
- Предлагает фикс на уровне кода (если виден React DevTools-скриншот)
- Через function calling сразу вызывает `apply_patch`

### 7. Reasoning по техническому скриншоту с длинной инструкцией

Сложный случай: скриншот системы (например Kubernetes Dashboard, Grafana) + 20K токенов документации + промпт "помоги разобраться". Gemma 4:
- Использует 256K контекст для удержания всей документации
- Анализирует скриншот в контексте документации
- Через thinking-режим строит цепочку рассуждений
- Возвращает structured ответ с references на конкретные места в документации

### 8. Form filling из скана документа + business logic

Сканированная анкета или счёт → Gemma 4:
- OCR извлекает поля
- Function calling вызывает `validate_field` для каждого
- Применяет business rules (дата не в будущем, сумма с НДС = сумма без НДС × 1.20)
- Заполняет форму в системе через tool calls

Альтернатива -- [Qwen3-VL](qwen3-vl.md#30b-a3b) даст лучше OCR, но без function calling придётся делать orchestration снаружи.

### 9. Bounding box для UI-тестирования

Скриншот веб-приложения → промпт: "Найди все интерактивные элементы и верни bounding boxes в JSON"

Gemma 4 возвращает нативный JSON с координатами:
```json
[
  {"label": "Login button", "bbox": [520, 400, 720, 450], "type": "button"},
  {"label": "Email input", "bbox": [520, 280, 720, 320], "type": "input"},
  {"label": "Hamburger menu", "bbox": [20, 10, 60, 50], "type": "icon"}
]
```

Координаты -- в пикселях исходного скриншота, `[x1, y1, x2, y2]`. Это **нативная способность** (не grammar constraint), модель обучена возвращать bbox как часть structured output.

Применения:
- **Cypress/Playwright test generation**: bbox → координаты для `page.click(x, y)`
- **Visual regression**: сравнить bbox между двумя скриншотами (до и после деплоя)
- **Accessibility audit**: проверить что все clickable areas >= 44x44 px
- **Auto-annotation**: разметить UI-элементы для ML-датасета

### 10. Настройка image token budget для batch-обработки

При batch-обработке большого количества изображений (1000+ скриншотов из e2e тестов) -- важна скорость. Gemma 4 позволяет **снизить token budget** до 70 токенов на кадр:

- **70 tokens**: ~50 мс на кадр на Strix Halo. Достаточно для classification ("Pass/Fail"), detection грубых ошибок, тривиального OCR
- **280 tokens** (default): ~150 мс на кадр. OCR среднего текста, описание сцены
- **1120 tokens**: ~500 мс на кадр. Pixel-level детализация, мелкий текст

Для batch в 1000 скриншотов разница: 50 сек (70 tokens) vs 8 мин (1120 tokens). Выбор token budget через prompt engineering: "Describe this screenshot very briefly" (модель выбирает меньше tokens) vs "Provide detailed OCR of all text visible" (модель выбирает больше).

### 11. Multimodal RAG: изображения + документы в одном контексте

256K контекст позволяет загрузить **одновременно** документ (20K токенов текста) + серию скриншотов (10 × 280 = 2800 vision tokens) + промпт. Всё в одном запросе, без RAG-пайплайна:

Пример: "Вот техническое задание (PDF извлечённый в текст) и 10 скриншотов текущего UI. Какие требования из ТЗ не реализованы?"

Gemma 4:
1. Парсит текст ТЗ, извлекает требования
2. Анализирует скриншоты, находит реализованное
3. Cross-reference: требования vs визуальное состояние
4. Выдаёт structured список несоответствий

Это **multimodal RAG в одном запросе** -- без embedding модели, без vector store, без чанкинга. Работает пока всё влезает в 256K.

### 12. Code review по скриншотам (before/after)

Два скриншота: `before.png` (старый UI) и `after.png` (после PR). Промпт: "Сравни оба скриншота, опиши что изменилось визуально"

Gemma 4:
- Извлекает layout differences
- Находит новые/удалённые элементы
- Замечает color changes, font changes, spacing differences
- Через function calling может сразу вызвать `create_issue` если найдена регрессия

Use case: visual code review в CI pipeline -- автоматическая проверка что PR не сломал UI.

### Антипаттерны

- **Не использовать Gemma 4 для чистого OCR мелкого текста** -- [Qwen3-VL](qwen3-vl.md) точнее на 10-15%
- **Не использовать Gemma 4 для math по диаграммам** -- [InternVL3.5](internvl.md) даёт более глубокое reasoning над схемами
- **Не запускать без `--parallel 1 --no-mmap`** -- sliding window cache схлопывается, OOM
- **Не пытаться использовать `--cache-reuse` agressively** -- llama.cpp игнорирует для Gemma 4, prefix пересчитывается каждый turn (см. слабые стороны выше)
- **Не использовать F32 mmproj** -- BF16 даёт идентичное качество при половинном размере
- **Не загружать 31B dense для интерактивного чата** -- ~5 tok/s на Strix Halo, тяжёлый memory-bound. Лучше 26B-A4B (MoE, ~70 tok/s)

## Загрузка

```bash
# Основная модель Q6_K_XL (~22 GB) + vision (~1.2 GB)
./scripts/inference/download-model.sh unsloth/gemma-4-26B-A4B-it-GGUF \
    --include '*Q6_K_XL*' --include 'mmproj-BF16.gguf'

# Альтернатива: Q4_K_M (меньше) или Q8_0 (выше качество)
./scripts/inference/download-model.sh unsloth/gemma-4-26B-A4B-it-GGUF \
    --include '*Q4_K_M*' --include 'mmproj-BF16.gguf'
```

## Запуск

```bash
# Через Vulkan-пресет (защиты от OOM, mmproj подключен)
./scripts/inference/vulkan/preset/gemma4.sh -d
```

Пресет автоматически:
- Подключает `--mmproj $MODELS_DIR/mmproj-BF16.gguf`
- Устанавливает `--parallel 1` (защита от OOM из-за sliding window checkpoints)
- Устанавливает `--no-mmap` (модель сразу в RAM)
- `--jinja` для function calling
- `-c 65536` (64K -- меньше памяти на context checkpoints)

Подробности про OOM-защиту -- в комментариях `scripts/inference/vulkan/preset/gemma4.sh`.

## Связано

- Направления: [llm](../llm.md), [vision](../vision.md)
- Родственные семейства: альтернативы по vision -- [qwen3-vl](qwen3-vl.md) (лучше OCR), [qwen25-omni](qwen25-omni.md) (vision + audio)
- Пресет: `scripts/inference/vulkan/preset/gemma4.sh`
