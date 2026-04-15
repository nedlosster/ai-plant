# ACE-Step: простые сценарии

Базовые use-cases для первого знакомства с ACE-Step как платформой. Предусловие: ACE-Step установлен через [`scripts/music/ace-step/install.sh`](../../../scripts/music/ace-step/install.sh), Gradio UI доступен на `http://<SERVER_IP>:7860`.

Подробная установка и первый запуск -- в [../../use-cases/music/quickstart.md](../../use-cases/music/quickstart.md). Здесь фокус на **что делать** в уже запущенном UI.

## 1. Генерация первой песни через Gradio UI

**Задача**: за 2 минуты получить готовую песню по простому описанию.

### Шаги

1. Открыть `http://<SERVER_IP>:7860` в браузере
2. В поле **Tags** написать:
   ```
   upbeat electronic dance, female vocals, 128bpm, synth, energetic
   ```
3. В поле **Lyrics** написать:
   ```
   [Verse 1]
   Dancing in the moonlight
   Stars are shining bright
   We're going to the sky
   Feeling so alive

   [Chorus]
   We are the dreamers
   We are the believers
   Never going to stop
   Reaching for the top
   ```
4. Настройки (обычно по умолчанию):
   - **Duration**: 120 seconds (2 минуты)
   - **Steps**: 8 (turbo)
   - **CFG scale**: 7.5
   - **Seed**: -1 (random)
5. Нажать **Generate**

### Что происходит

На Strix Halo в CPU-режиме:
- Tokenization (мгновенно)
- Sampling loop -- ~5-10 минут на 2-минутную песню (CPU медленный)
- VAE decode + vocoder -- ~30 сек
- WAV появляется в audio player Gradio UI

На машине с full ROCm/CUDA (для сравнения):
- Total: ~66 секунд для того же

### Скачать результат

В Gradio audio player кнопка "Download" (три точки в правом углу player'а). Сохраняет WAV файл локально.

### Формат результата

- **Частота дискретизации**: 44.1 kHz (CD quality)
- **Битность**: 16 bit
- **Каналы**: mono или stereo (зависит от модели)
- **Длительность**: соответствует параметру Duration

## 2. Выбор стиля: tags как определяющий фактор

**Задача**: попробовать разные жанры, чтобы понять влияние tags.

### Примеры tags по жанрам

**Поп-рок**:
```
rock, male vocals, electric guitar, drums, bass, 120bpm, energetic
```

**Джаз**:
```
smooth jazz, female vocals, saxophone, piano, upright bass, slow, intimate, 80bpm
```

**Фолк**:
```
acoustic folk, male vocals, acoustic guitar, fingerpicking, warm, storytelling, 100bpm
```

**Электронная танцевальная**:
```
EDM, female vocals, synth, heavy bass, 128bpm, buildup, drop, euphoric
```

**Хип-хоп**:
```
hip hop, male vocals, 808 bass, trap beats, rhythmic, 140bpm
```

**Классический**:
```
classical, operatic vocals, orchestra, violin, cello, piano, dramatic, 90bpm
```

Одни и те же lyrics в разных tags дают совершенно разные песни. Это полезно для A/B тестирования.

### Как работают tags

Tags -- это **свободный текст**, не enum. Модель видела в обучении множество комбинаций, и интерпретирует tags через embedding. Работающие паттерны:
- **Жанр**: rock, pop, jazz, electronic, hip hop, classical, folk, blues, country, R&B
- **Голос**: male vocals, female vocals, operatic, whispered, rapping
- **Инструменты**: guitar, piano, drums, bass, synth, violin, saxophone
- **Темп**: 60bpm (slow ballad), 120bpm (moderate), 140bpm (fast), 180bpm (very fast)
- **Настроение**: upbeat, melancholic, energetic, intimate, dramatic, playful, dark
- **Эпоха**: 80s synthwave, 90s rock, 70s funk, modern pop

Tags можно комбинировать -- модель обычно понимает сочетания.

### Что НЕ работает хорошо

- **Точные числовые требования**: "exactly 132 BPM" -- модель понимает общий темп, но не микро-точно
- **Сверхсложные стилистические сочетания**: "medieval gregorian chant meets dubstep" -- может дать странное
- **Имена исполнителей**: "sing like Taylor Swift" -- юридически не обучено, результат будет general
- **Специфичные альбомы**: "in the style of Dark Side of the Moon" -- может не сработать

## 3. Lyrics structure: [Verse] [Chorus] [Bridge]

**Задача**: использовать структурные маркеры для управления композицией.

### Поддерживаемые маркеры

ACE-Step понимает стандартные song structure markers:

```
[Intro]             -- инструментальное вступление, обычно 8-16 секунд
[Verse 1]           -- первый куплет
[Verse 2]           -- второй куплет
[Pre-Chorus]        -- pre-припев, нарастание энергии
[Chorus]            -- припев, обычно повторяется
[Bridge]            -- бридж, контрастная секция
[Outro]             -- инструментальное/fade завершение
[Instrumental]      -- инструментальный брейк
[Breakdown]         -- музыкальный breakdown (для EDM)
[Drop]              -- drop (для EDM)
```

### Пример структурированного lyrics

```
[Intro]

[Verse 1]
Walking down the empty street
The city sleeps beneath my feet
Neon signs flicker and fade
Another night, another trade

[Pre-Chorus]
And I wonder if you're thinking about me
Wondering if tonight we'll be free

[Chorus]
Dance with me in the rain
Take away all the pain
We are young, we are free
This is how it should be

[Verse 2]
Cars rush by with headlights bright
Stars are lost in city light
But when I look into your eyes
I see our reflection in the skies

[Pre-Chorus]
And I wonder if you're thinking about me
Wondering if tonight we'll be free

[Chorus]
Dance with me in the rain
Take away all the pain
We are young, we are free
This is how it should be

[Bridge]
Time is running, time is flying
All the while we're slowly dying
But tonight we're alive
Tonight we'll survive

[Chorus]
Dance with me in the rain
Take away all the pain
We are young, we are free
This is how it should be

[Outro]
```

Модель понимает что [Chorus] повторяется, использует ту же мелодию. [Bridge] получает контрастную гармонию. [Intro]/[Outro] -- инструментальные (вокал не генерируется в этих секциях).

### Практический совет

- Начни с короткой lyrics (1 verse + 1 chorus) -- проще отлаживать
- Добавляй структуру постепенно
- [Chorus] повтори 2-3 раза -- модель генерирует похожую мелодию
- [Bridge] -- опциональный, добавляет разнообразие

## 4. Seed и reproducibility

**Задача**: получить тот же результат повторно или вариацию с тем же "feel".

### Seed (зерно генерации)

В Gradio UI:
- **Seed: -1** -- случайный seed каждый раз (разные результаты)
- **Seed: 42** (любое число) -- фиксированный seed, одинаковый результат при тех же tags/lyrics/параметрах

### Зачем фиксировать seed

- **Reproducibility**: получить тот же результат на другой машине
- **Variation через seed+1**: с близкими seeds получаются похожие, но немного разные версии
- **Сравнение параметров**: "как меняется CFG scale с тем же seed"

### Практический workflow

1. Генерация с seed=-1 (random) -- запоминается фактический seed, отображается в UI после генерации
2. Понравился результат -- скопировать seed
3. Теперь можно:
   - Повторить с тем же seed для reproducibility
   - Меняя seed на соседние (43, 44, 45) -- получить вариации
   - Меняя другие параметры с тем же seed -- увидеть эффект

## 5. CFG scale: влияние на "следование lyrics"

**Задача**: понять как CFG scale влияет на результат.

### Что такое CFG scale

**CFG (Classifier-Free Guidance) scale** -- параметр diffusion-моделей, который определяет насколько сильно генерация должна следовать условным параметрам (в нашем случае -- tags и lyrics).

- **CFG = 1.0** -- генерация игнорирует conditioning, получается "хаотичное" что-то в пространстве модели
- **CFG = 7.5** (рекомендуемый default) -- баланс
- **CFG = 15+** -- очень строгое следование, но модель начинает "cращать" и может дать артефакты

### Эксперимент

Та же tags+lyrics, разные CFG:
- **CFG 3**: мелодия может "уплывать", вокал расплывчатый, общая атмосфера правильная
- **CFG 7.5**: хороший баланс, lyrics чёткие, мелодия в стиле
- **CFG 12**: очень строго по tags, может звучать "натужно"

### Когда повысить / понизить

- **Не следует lyrics** (слова неразборчивы) → **повысить** CFG до 10-12
- **Звучит как клон шаблона** (слишком generic) → **понизить** CFG до 5-7
- **Хочется творческой свободы** модели → низкий CFG (3-5)
- **Нужно точное попадание в жанр** → высокий CFG (10-15)

## 6. Duration: длинные vs короткие треки

**Задача**: понять trade-offs между длинными и короткими песнями.

### Короткие (15-60 секунд)

- **Быстрее генерируются** (меньше latent frames)
- **Высокая coherence** (модель легко удерживает структуру)
- **Подходят для**: intro/outro, jingles, ringtones, backing tracks для видео

### Средние (1-3 минуты)

- **Основной use case** -- полные песни
- **Баланс coherence и expressivity**
- **Structure**: verse + chorus минимум, можно bridge

### Длинные (4+ минуты)

- **Медленнее генерируются** (linear scale)
- **Риск coherence drift** -- к концу мелодия может "уплыть"
- **Нужна детальная lyrics с чёткой структурой**
- **Подходят для**: ambient, experimental, full-length songs

### Практический совет

Начинай с 60-90 секунд чтобы быстро итерировать на tags и lyrics. Когда нравится direction -- пересгенерируй 3-минутную версию.

## 7. Базовый troubleshooting

### Проблема: "OOM" (Out of Memory)

На Strix Halo с ROCm:
```
RuntimeError: HIP out of memory. Tried to allocate 8.00 GiB
```

**Причина**: LM 4B пытается загрузиться, но KFD VRAM limit 15.5 GiB не хватает. См. [architecture.md](architecture.md#проблема-на-strix-halo-gfx1151).

**Решение**:
```bash
# В config.sh установить:
export ACESTEP_INIT_LLM=false
```

Это отключит LM, оставит DiT-only. Работает стабильно но без lyrics conditioning.

### Проблема: "Very slow generation"

На CPU режиме 2-минутная песня может занимать 10+ минут.

**Причины**:
- DiT 3.5B на CPU -- ограничен AVX-512 (~50 tok/s equivalent)
- Vocoder на CPU медленный

**Решения**:
1. **Ждать ROCm fix** -- ожидаем в 2026
2. **Использовать GPU tier 2** (`--init_llm false` + ROCm) -- ~2 мин на песню
3. **Generate короче** -- 30 сек вместо 120

### Проблема: "Vocals sound gibberish"

Вокал произносит что-то похожее на слова, но неразборчиво.

**Причины**:
- LM не инициализирован (DiT-only без lyrics conditioning)
- Low CFG scale
- Сложная lyrics (много специальных терминов, названий)

**Решения**:
1. Повысить CFG scale до 10-12
2. Упростить lyrics (обычные слова)
3. Включить LM (`--init_llm true` если возможно)
4. Попробовать другой seed

## Связанные статьи

- [README.md](README.md) -- обзор профиля и статус на платформе
- [introduction.md](introduction.md) -- что это, история
- [architecture.md](architecture.md) -- внутреннее устройство (чтобы понимать причины problems)
- [advanced-use-cases.md](advanced-use-cases.md) -- LoRA training, cover/remix, batch
- [../../use-cases/music/quickstart.md](../../use-cases/music/quickstart.md) -- операционный quickstart (установка)
- [../../use-cases/music/prompting.md](../../use-cases/music/prompting.md) -- глубокое руководство по промптам
- [../../use-cases/music/russian-classics.md](../../use-cases/music/russian-classics.md) -- русский вокал
