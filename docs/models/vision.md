# Vision LLM (multimodal)

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти), llama.cpp + Vulkan/HIP.

Vision LLM принимают на вход не только текст, но и изображения. Используются для: описания фото, OCR, понимания диаграмм/схем/UI, анализа графиков, визуального QA, решения задач по картинке.

## Архитектура: модель + mmproj

В llama.cpp vision реализован двухкомпонентно:

1. **Основная LLM** (текстовая часть) -- стандартный GGUF-файл с весами трансформера
2. **Vision-проектор (`mmproj`)** -- отдельный GGUF-файл с весами vision-encoder'а (обычно ViT/SigLIP) + проектор в эмбеддинг-пространство LLM

При запуске llama-server обоим файлам соответствуют разные флаги:

```bash
llama-server -m model.gguf --mmproj mmproj-BF16.gguf -ngl 99 ...
```

Без `--mmproj` модель работает только с текстом, vision-вход возвращает ошибку
`image input is not supported - hint: if this is unexpected, you may need to provide the mmproj`.

## Загруженные на платформе

### Gemma 4 26B-A4B (multimodal)

Уже стоит. Vision-проектор -- отдельный файл в том же репо unsloth.

**Архитектура**: 25.2B total / 3.8B active (MoE 8/128 + 1 shared expert), SigLIP-style vision encoder. Контекст 256K, native function calling.

```bash
# Загрузка mmproj (1.19 GB)
./scripts/inference/download-model.sh unsloth/gemma-4-26B-A4B-it-GGUF --include 'mmproj-BF16.gguf'

# Запуск с vision (пресет уже учитывает mmproj)
./scripts/inference/vulkan/preset/gemma4.sh -d
```

Варианты mmproj в репо:
- `mmproj-BF16.gguf` (1.19 GB) -- рекомендуется
- `mmproj-F16.gguf` (1.19 GB) -- идентично BF16 по размеру
- `mmproj-F32.gguf` (2.29 GB) -- максимальная точность, не нужна для практики

**Сильные кейсы:**
- Function calling по визуальному входу: получает скриншот UI -> вызывает tool с выделенными координатами
- Reasoning по диаграмме (thinking-режим через `<|think|>` token)
- Длинный контекст 256K -- можно загрузить много кадров видео или серию скриншотов
- Универсальный VLM "общего назначения" -- сильна на смешанных задачах
- Variable aspect ratio изображений -- понимает портрет/панораму, ландшафт без принудительного crop

**Слабые кейсы:**
- Sliding window attention -> sensitive к OOM при больших контекстах (см. пресет gemma4.sh с защитами)
- KV-cache shifting не работает -- multi-turn чат пересчитывает префикс
- OCR хуже Qwen3-VL и InternVL3
- Не специализирована под конкретный домен (math/science)

**Идеальные сценарии:**
- "Опиши скриншот ошибки и предложи фикс"
- Анализ UI-макета -> tool calls для генерации компонентов
- Reasoning-задачи по фото с длинным контекстом контекста

## Альтернативные vision-модели (2026)

Все имеют GGUF-версии и работают через llama.cpp.

### 1. Qwen3-VL 30B-A3B (рекомендую как замену Gemma 4)

**MoE с 3B активных параметров** -- быстрая как Qwen3-Coder-Next, но с vision.

- **Параметры**: 30B (A3B)
- **Hub**: [Qwen/Qwen3-VL-30B-A3B-Instruct-GGUF](https://huggingface.co/Qwen/Qwen3-VL-30B-A3B-Instruct-GGUF)
- **Размер**: 18.6 GB Q4_K_M + 1.08 GB mmproj F16
- **Также**: [Thinking-вариант](https://huggingface.co/Qwen/Qwen3-VL-30B-A3B-Thinking-GGUF) с reasoning

**Архитектура**: MoE Qwen3 с vision encoder Qwen-VL. Поддержка native dynamic resolution -- разные размеры картинок без potions/тайлинга.

```bash
./scripts/inference/download-model.sh Qwen/Qwen3-VL-30B-A3B-Instruct-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*F16*'
```

**Сильные кейсы:**
- **OCR на 30+ языках** -- лучшая в open-source. Распознаёт даже рукописный текст, слабые сканы, фото с искажениями
- **Document understanding** -- структурированный JSON-вывод из PDF/счетов/договоров: таблицы, иерархия секций, метаданные
- **Video understanding** -- ввод нескольких кадров, понимание событий, action recognition, таймкоды
- **Structured output** -- выдаёт строго валидный JSON по schema (полезно для интеграции в pipeline)
- **Agentic GUI** -- кликабельные координаты на скриншотах, screen agents (browser automation, mobile testing)
- **Чтение комиксов/манги** -- понимает порядок панелей, текст в баблах
- **Скриншот -> код**: HTML/React по фото макета (UI-to-code)

**Слабые кейсы:**
- Reasoning-задачи лучше делать через Thinking-вариант (выше latency)
- Эмоциональный анализ лиц слабее специализированных моделей
- 3D-понимание (глубина, перспектива) уступает GLM-4.5V

**Идеальные сценарии:**
- Парсинг чеков/счетов -> JSON для бухгалтерии
- Извлечение данных из научных публикаций (таблицы + графики)
- Browser automation: скриншот страницы -> следующий клик
- Многоязычный OCR (русский, китайский, японский, арабский в одном потоке)
- Замена платных Document AI сервисов

### 2. Qwen3-VL 235B-A22B (флагман, на пределе платформы)

Конкурирует с Gemini-2.5-Pro и GPT-5 на multimodal-бенчмарках.

- **Параметры**: 235B (A22B)
- **Hub**: [Qwen/Qwen3-VL-235B-A22B-Instruct-GGUF](https://huggingface.co/Qwen/Qwen3-VL-235B-A22B-Instruct-GGUF)
- **Размер**: ~135 GB Q4_K_M + ~3 GB mmproj
- **VRAM**: на пределе 120 GiB Vulkan (без запаса на контекст)

**Архитектура**: Та же что Qwen3-VL 30B, но multiplied. 22B активных параметров на токен -- значительно мощнее в reasoning.

```bash
./scripts/inference/download-model.sh Qwen/Qwen3-VL-235B-A22B-Instruct-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*'
```

**Сильные кейсы:**
- **Сложные научные диаграммы** -- понимание формул, графиков с множественными осями, химических структур
- **Юридические документы** -- глубокий анализ договоров с длинными зависимостями и cross-references
- **Visual reasoning** -- задачи где нужно несколько шагов рассуждения: "сколько столов на 5 фото и какой самый дорогой"
- **Multi-image reasoning** -- сравнение нескольких изображений (до/после, варианты дизайна, разные ракурсы)
- **Конкурентоспособна с GPT-5/Gemini-2.5** -- на сложных задачах разница минимальна

**Слабые кейсы:**
- На пределе VRAM -- мало места под контекст (max ~16K-32K)
- Скорость низкая (~22 tok/s)
- Загрузка модели долгая (~2-3 минуты)
- Простые задачи (OCR счетов) разумнее делать на 30B-A3B быстрее и не хуже

**Идеальные сценарии:**
- Когда 30B-A3B не справляется -- сложный научный/математический visual reasoning
- "Один большой запрос" вместо потока мелких
- Замена облачных flagship-моделей для конфиденциальных данных

### 3. Qwen2.5-Omni 7B (vision + audio + text)

**Multimodal в три стороны** -- понимает картинки И аудио. От ggml-org (официальный конвертер llama.cpp).

- **Параметры**: 7B
- **Hub**: [ggml-org/Qwen2.5-Omni-7B-GGUF](https://huggingface.co/ggml-org/Qwen2.5-Omni-7B-GGUF)
- **Размер**: ~5 GB Q4_K_M + ~1 GB mmproj

**Архитектура**: Qwen2.5 с двумя encoder-ами -- vision (Qwen-VL ViT) + audio (Whisper-style). Talker-Thinker архитектура: один поток для генерации текста, другой для синтеза речи.

```bash
./scripts/inference/download-model.sh ggml-org/Qwen2.5-Omni-7B-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*'
```

**Сильные кейсы:**
- **Real-time speech conversation** -- голос на входе и на выходе, streaming
- **Анализ видео-звонков** -- одновременно обрабатывает картинку (что показывают) и звук (что говорят)
- **Audio captioning** -- транскрипция + описание (музыка, шумы, эмоции)
- **Voice-controlled vision agent** -- "посмотри что на экране и опиши голосом"
- **Аудиокниги по картинкам** -- описание изображения голосом для слабовидящих
- **Multimodal обучение** -- понимает картинки в видеолекциях вместе с речью лектора

**Слабые кейсы:**
- 7B -- слабее 30B+ моделей на сложных vision-задачах
- OCR хуже Qwen3-VL
- Качество speech уступает специализированным TTS (см. [tts.md](tts.md))

**Идеальные сценарии:**
- Голосовой ассистент в умном доме (Home Assistant + Wyoming protocol)
- Real-time captioning для слабослышащих
- Анализ записей встреч (Zoom/Teams) -- кто что показал и сказал
- Доступность для слабовидящих -- "что на этом фото"
- Multimodal CLI: `screenshot && voice-prompt | qwen-omni`

### 4. Pixtral 12B (Mistral)

**Apache 2.0** -- полная коммерческая свобода. Превосходит Qwen2-VL 7B, LLaVa-OneVision 7B, Phi-3.5 Vision.

- **Параметры**: 12B
- **Hub**: [ggml-org/pixtral-12b-GGUF](https://huggingface.co/ggml-org/pixtral-12b-GGUF)
- **Размер**: 7.48 GB Q4_K_M + 463 MB mmproj Q8_0

**Архитектура**: Mistral 12B + custom Pixtral vision encoder с поддержкой arbitrary resolution и aspect ratio. Поддержка нескольких изображений в одном запросе с interleaving с текстом.

```bash
./scripts/inference/download-model.sh ggml-org/pixtral-12b-GGUF \
    --include '*Q4_K_M*' --include 'mmproj*Q8_0*'
```

**Сильные кейсы:**
- **Instruction following** на vision-задачах -- лучше следует точным инструкциям ("найди ровно три объекта", "опиши только цвета")
- **Multi-image input** -- несколько фото за раз с textual interleaving ("сравни эти три варианта")
- **Arbitrary resolution** -- картинки любого размера без resize, сохранение деталей
- **Apache 2.0** -- встраивание в коммерческие продукты без оговорок
- **Хорошая память на длинные инструкции** -- сложные многошаговые vision-таски

**Слабые кейсы:**
- OCR-русский слабее Qwen-серии
- Reasoning средний (12B dense, не MoE)
- Контекст ограничен (~128K, меньше Qwen3-VL)
- Не так силён на математике как InternVL3

**Идеальные сценарии:**
- E-commerce: "сравни 3 фото товаров и выбери лучший по описанию"
- Quality control в производстве: фото детали + чек-лист дефектов
- Архивирование фото с тегами по строгому tag schema
- Замена платного OpenAI Vision API в SaaS-продуктах (Apache 2.0)

### 5. Mistral Small 3.1 24B (multimodal)

Сбалансированный размер, Apache 2.0.

- **Параметры**: 24B
- **Hub**: [ggml-org/Mistral-Small-3.1-24B-Instruct-2503-GGUF](https://huggingface.co/ggml-org/Mistral-Small-3.1-24B-Instruct-2503-GGUF)
- **Размер**: ~14 GB Q4_K_M + ~1 GB mmproj

**Архитектура**: Mistral Small 3.1 (24B dense) с vision encoder Pixtral-style. Контекст 128K. Function calling из коробки.

```bash
./scripts/inference/download-model.sh ggml-org/Mistral-Small-3.1-24B-Instruct-2503-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*'
```

**Сильные кейсы:**
- **Универсальная workhorse** -- неплохо во всех задачах, ничего сильно проваленного
- **Function calling по vision** -- скриншот + tool call в одном request
- **Production stability** -- зрелая Mistral-серия, проверенная экосистема
- **Apache 2.0** + контекст 128K -- хороший компромисс для бизнеса
- **Хороший русский и европейские языки** -- лучше Pixtral на не-английском

**Слабые кейсы:**
- Dense 24B -- медленнее MoE моделей того же качества (~20 tok/s vs 80 у Qwen3-VL 30B-A3B)
- На каждой отдельной задаче (OCR, math, agentic) есть более сильный специалист
- "Серединка по всему" -- если нужно лучшее в чём-то конкретном, бери специализированную

**Идеальные сценарии:**
- Single-model setup для небольшой команды -- одна модель на все задачи
- Production API когда нужны predictable timings и стабильность
- Mistral-экосистема (если уже используешь их LLM)

### 6. InternVL3 (OpenGVLab)

Серия с фокусом на reasoning и сложные задачи.

- **Параметры**: 2B / 14B / 78B
- **Hub**: [bartowski/InternVL3-14B-GGUF](https://huggingface.co/bartowski/InternVL3-14B-GGUF), [официальные](https://huggingface.co/OpenGVLab)
- **Размер 14B**: ~8 GB Q4_K_M + ~3 GB mmproj
- **InternVL3-78B**: 72.2 на MMMU benchmark

**Архитектура**: InternViT-6B-448px-V2_5 (большой vision encoder, 6B параметров) + Qwen-based LLM. **Vision-encoder в 6 раз больше типового** -- отсюда сила на сложных визуальных задачах.

```bash
./scripts/inference/download-model.sh bartowski/InternVL3-14B-GGUF \
    --include '*Q4_K_M*' --include 'mmproj*'
```

**Сильные кейсы:**
- **Математика по картинке** -- решение задач из учебников, уравнения с переменными, геометрия
- **Научные диаграммы** -- графики из статей, диаграммы рассеяния, контурные карты, фазовые диаграммы
- **Chart QA** -- "какое значение в столбце X на этом гистограмме" -- одна из лучших на ChartQA benchmark
- **Reasoning по схемам** -- блок-схемы алгоритмов, UML, ER-диаграммы
- **Tables** -- извлечение и понимание таблиц из научных статей и финансовых отчётов
- **Лидер на MMMU** -- комплексный multimodal reasoning benchmark (78B = 72.2)

**Слабые кейсы:**
- mmproj большой (3 GB) -- занимает заметно VRAM
- OCR на текстах не лучше Qwen3-VL
- Function calling слабее
- Не поддерживает видео нативно

**Идеальные сценарии:**
- Исследовательская работа -- обработка научных PDF с диаграммами
- Образовательные приложения -- решение задач по фото из учебника
- Финансовая аналитика -- понимание квартальных отчётов с графиками
- STEM-education tools

### 7. MiniCPM-o 2.6 (OpenBMB)

End-side multimodal с поддержкой **изображений + видео + аудио + текста**.

- **Параметры**: ~8B
- **Hub**: [openbmb/MiniCPM-o-2_6-gguf](https://huggingface.co/openbmb/MiniCPM-o-2_6-gguf)
- **Размер**: ~5 GB Q4_K_M + ~1 GB mmproj

**Архитектура**: Llama 3-based + SigLIP vision + Whisper-style audio. End-to-end omni-модель -- все модальности в одном forward pass. Compact: 8B параметров общего назначения для всех модальностей.

```bash
./scripts/inference/download-model.sh openbmb/MiniCPM-o-2_6-gguf \
    --include '*Q4_K_M*' --include 'mmproj*'
```

**Сильные кейсы:**
- **End-side эффективность** -- задумана для запуска на смартфонах, edge-устройствах. Работает молниеносно
- **Real-time multimodal streaming** -- видео + аудио + текст одновременно с минимальной латентностью
- **OCR компактного класса** -- лучшая среди 7-8B моделей
- **Видео-вопросы-ответы** -- "что происходит в этом 30-секундном клипе"
- **Continuous video analysis** -- streaming video с обновлением понимания каждые N кадров
- **Function calling** из коробки

**Слабые кейсы:**
- Меньше Qwen2.5-Omni по абсолютному качеству на сложных задачах
- Reasoning средний (8B размер)
- Аудио не такое качественное как у специализированных speech-моделей

**Идеальные сценарии:**
- IoT/edge: умные камеры с локальным анализом
- Видеонаблюдение -- "был ли человек в кадре последний час"
- Live captioning + action recognition
- Locally-running mobile assistant
- Embedded devices с ограниченной памятью

### 8. SmolVLM2 2.2B (компактная)

Самая лёгкая, для edge или экспериментов. Поддержка видео.

- **Параметры**: 2.2B (есть варианты 256M, 500M, 2.2B)
- **Hub**: [HuggingFaceTB/SmolVLM2-2.2B-Instruct](https://huggingface.co/HuggingFaceTB/SmolVLM2-2.2B-Instruct), GGUF: [ggml-org/SmolVLM2-2.2B-Instruct-GGUF](https://huggingface.co/ggml-org/SmolVLM2-2.2B-Instruct-GGUF)
- **Размер**: ~1.4 GB Q4_K_M + ~0.5 GB mmproj

**Архитектура**: SmolLM2 base + tiny SigLIP. Train набор сосредоточен на простых задачах. Самая маленькая VLM (256M вариант -- меньше 1 GB).

```bash
./scripts/inference/download-model.sh ggml-org/SmolVLM2-2.2B-Instruct-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*'
```

**Сильные кейсы:**
- **Скорость** -- ~150 tok/s, мгновенный отклик
- **Минимальный footprint** -- 256M вариант запустится даже на ноутбуке без GPU
- **Видео из коробки** -- понимание коротких клипов
- **Batch-обработка** -- можно обработать тысячи фото за минуты
- **Edge-deployment** -- Raspberry Pi 5, мобильные устройства, embedded
- **Низкое энергопотребление** -- идеально для постоянно работающих сервисов

**Слабые кейсы:**
- Простая модель -- ошибается на сложных reasoning задачах
- OCR ограничен (короткие тексты)
- Не понимает мелкие детали на больших изображениях
- Function calling отсутствует

**Идеальные сценарии:**
- Tagging огромного фотоархива (миллионы снимков)
- Filter / first-pass: SmolVLM делает быструю классификацию, сложные случаи отдаёт в Qwen3-VL
- Locally на телефоне или Raspberry Pi
- Realtime camera feed analysis с минимальной задержкой
- Batch quality control в производстве

## Сравнение для платформы (gfx1151, 120 GiB)

| Модель | Размер Q4 | mmproj | tg (ожид.) | Особенность |
|--------|-----------|--------|------------|-------------|
| **Qwen3-VL 30B-A3B** ⭐ | 18.6 GB | 1.1 GB | ~80 tok/s | universal vision, OCR, video |
| Qwen3-VL 235B-A22B | 135 GB | ~3 GB | ~22 tok/s | флагман уровня Gemini-2.5/GPT-5 |
| Qwen2.5-Omni 7B | ~5 GB | ~1 GB | ~50 tok/s | vision + audio + text |
| Pixtral 12B | 7.5 GB | 463 MB | ~40 tok/s | instruction following, Apache 2.0 |
| Mistral Small 3.1 24B | ~14 GB | ~1 GB | ~20 tok/s | сбалансированная |
| InternVL3-14B | 8 GB | ~3 GB | ~25 tok/s | reasoning, диаграммы |
| MiniCPM-o 2.6 | ~5 GB | ~1 GB | ~40 tok/s | мультимодальность (audio/video) |
| SmolVLM2 2.2B | ~1.4 GB | ~0.5 GB | ~150 tok/s | edge, видео, минимум задержки |
| Gemma 4 26B-A4B | 17 GB | 1.2 GB | ~80 tok/s | function calling, reasoning |

## Запуск vision-модели через llama-server

Для своей кастомной модели (не из готовых пресетов):

```bash
~/projects/llama.cpp/build/bin/llama-server \
    -m /path/to/model.gguf \
    --mmproj /path/to/mmproj.gguf \
    --port 8081 -ngl 99 -fa on -c 32768 \
    --host 0.0.0.0 --jinja --parallel 1
```

## Использование из Open WebUI

Open WebUI автоматически определяет vision-возможности модели через `/v1/models` и показывает кнопку attach image, если модель multimodal. Достаточно настроить `inference.env` на хост llama-server (см. [scripts/webui/README.md](../../scripts/webui/README.md)).

## Связанные статьи

- [LLM общего назначения](llm.md)
- [Кодинг](coding.md)
- [Картинки (генерация)](images.md) -- diffusion, не vision-LLM
