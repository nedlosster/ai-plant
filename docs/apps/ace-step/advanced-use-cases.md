# ACE-Step: сложные сценарии

Продвинутые use-cases: LoRA fine-tuning, cover/remix режимы, русский вокал с характером, batch generation, интеграция с Python API, production workflows.

## 1. LoRA fine-tuning под свой стиль

**Задача**: обучить LoRA поверх базовой ACE-Step модели на своём датасете для адаптации под конкретный стиль или вокалиста.

### Что такое LoRA для audio

LoRA (Low-Rank Adaptation) -- техника fine-tuning'а, которая обучает **малое количество дополнительных параметров** поверх заморожённой базовой модели. Для ACE-Step это означает:
- Базовая модель (3.5B + 4B LM) остаётся неизменной
- Тренируется LoRA-адаптер (~50-200 MB) поверх attention layers DiT
- LoRA может быть применён / отключён runtime'овски
- Одновременно может работать несколько LoRA

### Требования к датасету

Для качественного LoRA-fine-tune'а нужен датасет:
- **Минимум**: 50-100 песен в целевом стиле (или от целевого вокалиста)
- **Формат**: WAV 44.1 kHz, длительностью 30-180 секунд каждая
- **Annotations**: для каждого аудио -- `tags.txt` и `lyrics.txt` (чтобы LoRA научился маппить описание в стиль)
- **Разнообразие**: разные темы, разные tempo, разная длина -- чтобы LoRA не оверфитнулся

### Структура dataset

```
~/projects/my-lora-dataset/
├── song_001/
│   ├── audio.wav          # 44.1 kHz, 120 sec
│   ├── tags.txt           # "retro synthwave, female vocals, 110bpm, dreamy"
│   └── lyrics.txt         # lyrics песни
├── song_002/
│   ├── audio.wav
│   ├── tags.txt
│   └── lyrics.txt
...
└── song_100/
    ├── audio.wav
    ├── tags.txt
    └── lyrics.txt
```

### Запуск LoRA training

```bash
# Активация venv ACE-Step
source ~/projects/ACE-Step-1.5/.venv/bin/activate
cd ~/projects/ACE-Step-1.5

# Запуск trainer
python -m acestep.trainer.lora \
  --dataset_path ~/projects/my-lora-dataset \
  --output_path ~/projects/my-lora-output \
  --base_model checkpoints/acestep-v15-turbo \
  --lora_rank 16 \
  --lora_alpha 32 \
  --learning_rate 1e-4 \
  --batch_size 1 \
  --num_epochs 10 \
  --save_every 500
```

### Параметры

| Параметр | Значение | Описание |
|----------|----------|----------|
| `--lora_rank` | 8, 16, 32 | Размер LoRA матриц. Больше -- выразительнее, медленнее |
| `--lora_alpha` | обычно 2× rank | Scaling factor |
| `--learning_rate` | 1e-4 -- 5e-5 | LR для LoRA (обычно выше чем для full FT) |
| `--batch_size` | 1-4 | На Strix Halo в DiT-only режиме помещается 1 |
| `--num_epochs` | 5-20 | Больше = лучше fit, но overfitting |
| `--save_every` | 500 | Сохранять checkpoint каждые N steps |

### Ограничения на Strix Halo

Training ACE-Step LoRA на нашей платформе -- **медленно** из-за CPU-only / DiT-only ROCm. Оценки:
- **CPU training**: 8-16 часов на 100 песен × 10 эпох (непрактично)
- **DiT-only ROCm (без LM)**: 2-4 часа (возможно, но без LM conditioning качество хуже)
- **Full tier4 (RTX 4090)**: 30-60 минут (оптимально, но не наша платформа)

Для serious LoRA training -- лучше использовать cloud GPU или ждать fix KFD VRAM.

### Использование тренированного LoRA

```bash
./scripts/music/ace-step/start.sh \
  --lora ~/projects/my-lora-output/lora-final.safetensors \
  --lora_strength 0.8 \
  --daemon
```

Теперь Gradio UI использует базовую модель + твой LoRA. Генерации будут в стиле твоего датасета.

Strength (0.0 -- 1.5):
- 0.0 -- LoRA не применён (базовая модель)
- 0.7-1.0 -- типичный рабочий диапазон
- 1.3+ -- LoRA перевешивает базовую модель, могут быть артефакты

## 2. Cover mode: перепеть существующую песню

**Задача**: взять готовую песню (в mp3/wav), перепеть её другим голосом/стилем.

### Как работает

Cover mode использует **audio-to-audio** pipeline:
1. Input audio декодируется через Audio VAE в латент
2. Латент получает добавление шума (partial re-noising, не с нуля)
3. DiT выполняет sampling с новыми tags (но той же мелодической структурой)
4. VAE decode → новый audio с сохранённой мелодией но новым вокалом/стилем

Это аналог image-to-image в Stable Diffusion -- оригинал сохраняет forma, новые параметры дают variations.

### Запуск

В Gradio UI:
1. Переключиться в таб **"Cover Mode"** (если есть) или использовать параметр `--cover` в CLI
2. Upload original.wav
3. Настроить:
   - **Strength** (0.1-1.0) -- насколько сильно меняем оригинал
   - **New tags** -- новый стиль/вокалист
   - **New lyrics** (опционально) -- если хотим другой текст
4. Generate

### Параметры strength

- **0.3** -- лёгкое изменение, сохраняется оригинальный вокал с небольшими artistic tweaks
- **0.5** -- заметное изменение стиля, вокал частично меняется
- **0.7** -- сильное перепевание, новый вокалист поверх оригинальной мелодии
- **0.9+** -- почти полная регенерация, мелодия может "уплывать"

### Пример workflow

Original: английская поп-песня
New tags: `french chanson, male baritone vocals, acoustic guitar, intimate, slow`
New lyrics: (переведено на французский вручную)
Strength: 0.6

Результат: та же мелодия, но в стиле французского шансона с мужским вокалом и французским текстом.

## 3. Remix mode: изменить часть песни

**Задача**: взять существующую песню и изменить **только припев** (или другую секцию), оставив остальное.

### Как работает

Remix mode использует **inpainting** подход:
1. Original audio полностью декодируется в латент
2. Пользователь указывает **time range** для изменения (например 30-60 секунд)
3. В этом range латент re-noised, остальное оставляется как есть
4. DiT делает sampling только для masked region (с тем же или новым prompt'ом)
5. VAE decode → новая песня с изменённой только указанной секцией

### Запуск (CLI)

```bash
python -m acestep.remix \
  --input original.wav \
  --mask_start 30 \
  --mask_end 60 \
  --new_tags "aggressive rock, distorted guitar, shouted vocals" \
  --strength 0.8 \
  --output remixed.wav
```

### Use cases

- **Заменить припев**: оставить verses, переделать chorus в другом стиле
- **Добавить инструментальный brief**: сгенерировать instrumental breakdown вместо существующей секции
- **Crossover genre**: поп-песня с металлическим мостом
- **Исправить ошибку**: если оригинал имел странную секцию -- переделать только её

### Tricky parts

- **Transitions**: в начале и конце masked region -- crossfade (~1-2 секунды), иначе слышен резкий скачок
- **Tempo matching**: новая секция должна быть в том же темпе, иначе disjoint
- **Key matching**: лучше работает если новый стиль в той же тональности

## 4. Русский вокал с характером

**Задача**: сгенерировать песню на русском языке с конкретным стилем (русский рок, русский шансон, классическая песня).

ACE-Step поддерживает русский язык как first-class citizen. Детальное руководство -- в [`docs/use-cases/music/russian-classics.md`](../../use-cases/music/russian-classics.md). Здесь сжатые примеры.

### Русский рок

Tags:
```
russian rock, male vocals, electric guitar, drums, heavy, melancholic, 110bpm
```

Lyrics пример:
```
[Verse 1]
Я стою на краю обрыва
Смотрю в пустоту
Тени прошлого тянут руки
Манят в черноту

[Chorus]
Ветер гонит по степи
Одинокие огни
Мы с тобою в этом мире
Словно тени от луны
```

Tags "russian rock" триггерит pattern из тренировочных данных: heavy guitar, meaningful lyrics, male baritone vocals. Модель попадает в стиль Земфиры / ДДТ / Сплина.

### Русский шансон

Tags:
```
russian chanson, male baritone vocals, accordion, acoustic guitar, nostalgic, 90bpm
```

Lyrics -- в тематике "дорога", "тюрьма", "любовь к маме", "ностальгия". Для модели это узнаваемый паттерн благодаря обилию таких песен в open-source датасетах.

### Советская эстрада

Tags:
```
soviet pop, female vocals, orchestra, romantic, waltz, 70bpm
```

Симулирует стиль Пугачёвой / Ротару / Гурченко. Романтический текст, слушательный темп, оркестровое сопровождение.

### Проблемы и workarounds

1. **Modelling lyrics hard**: ACE-Step может путаться в падежах русского языка. Workaround -- использовать простые конструкции, избегать сложных склонений
2. **Ударения**: иногда ударение падает "не туда". Workaround -- в lyrics пометить явно: "покá" вместо "пока" (но модель не гарантированно это учитывает)
3. **Редкие слова**: специализированные термины могут произноситься странно. Workaround -- использовать общеупотребимый словарь

Детали в [russian-classics.md](../../use-cases/music/russian-classics.md).

## 5. Batch generation через Python API

**Задача**: сгенерировать 50 песен по списку prompts автоматически.

### Python script

```python
#!/usr/bin/env python
"""Batch song generator."""

import sys
sys.path.insert(0, '/home/user/projects/ACE-Step-1.5')

from acestep.pipeline import ACEStepPipeline
import pandas as pd

# Загрузить prompts из CSV
df = pd.read_csv('prompts.csv')
# columns: id, tags, lyrics, duration

# Initialize pipeline (один раз)
pipeline = ACEStepPipeline(
    checkpoint_path='checkpoints/acestep-v15-turbo',
    lm_enabled=False,  # DiT-only для Strix Halo
    device='cpu',      # или 'cuda' с override gfx1151
)

# Batch loop
for i, row in df.iterrows():
    print(f"[{i+1}/{len(df)}] Generating {row['id']}...")

    audio = pipeline.generate(
        tags=row['tags'],
        lyrics=row['lyrics'],
        duration_sec=row['duration'],
        num_steps=8,
        cfg_scale=7.5,
        seed=42 + i  # разный seed для каждой
    )

    # Save
    output_path = f"output/{row['id']}.wav"
    audio.save(output_path)
    print(f"  → {output_path}")

print("Done!")
```

### Запуск

```bash
source ~/projects/ACE-Step-1.5/.venv/bin/activate
python batch_generate.py
```

### Полезно для

- **Создание корпуса** для LoRA training (iterative synthesize → hand-curate → re-train)
- **Production pipeline**: список тем из продакт-бэклога → batch-генерация
- **A/B testing**: та же lyrics, разные tags -- посмотреть какие работают лучше
- **Content creation**: 50 backing tracks для стримов, youtube-видео, подкастов

### Оптимизация batch на CPU

На CPU batch -- sequential (no benefit от параллелизации в обычном смысле). Что можно:
- **Reuse pipeline instance** -- модели грузятся один раз
- **Short durations** -- 30-сек песни в 2x быстрее чем 60-сек
- **Lower step count** -- 4 шага вместо 8 (снижение качества, но 2x ускорение)
- **Parallel CPU threads**: `OMP_NUM_THREADS=16` использует все Zen 5 cores

## 6. Integration с DAW (Digital Audio Workstation)

**Задача**: использовать ACE-Step как генератор stems для DAW (Ableton, FL Studio, Logic, Reaper).

### Стратегия: ACE-Step как "idea generator"

1. Генерация в ACE-Step -- получение **scratch tracks** (быстрые идеи)
2. Export WAV в DAW
3. В DAW: резать, layer'ить, обрабатывать эффектами
4. ACE-Step output -- **starting point**, не финальный продукт

### Stem separation

ACE-Step выдаёт mixed output (вокал + инструменты в одном файле). Для DAW удобнее иметь отдельные stems (vocal, drums, bass, other).

Workaround: использовать **отдельный stem separator** поверх ACE-Step output:
- **[Demucs](https://github.com/facebookresearch/demucs)** (Facebook) -- открытый stem separator, качественный
- **[Spleeter](https://github.com/deezer/spleeter)** (Deezer) -- быстрый, проще
- **[UVR](https://github.com/Anjok07/ultimatevocalremovergui)** -- популярный в мастеринг-сообществе

Workflow:
1. ACE-Step генерирует song.wav
2. Demucs разделяет на vocal.wav, drums.wav, bass.wav, other.wav
3. Загрузка stems в DAW
4. В DAW можно замаксить drums, добавить effects на vocal, заменить bass

### Pipeline scripted

```bash
# 1. ACE-Step generate
./scripts/music/ace-step/... → song.wav

# 2. Demucs separate (отдельный tool, установить через pip)
python -m demucs.separate --two-stems=vocals song.wav

# 3. Import stems в DAW (вручную или через DAW scripting)
```

## 7. Production workflow для content creators

**Задача**: ежедневно генерировать backing tracks для YouTube-видео / подкастов.

### Архитектура

```
Content plan (Google Sheet / Notion)
    ↓
Script переводит план в prompts
    ↓
Batch generate через ACE-Step API
    ↓
Результаты в object storage (S3/Minio)
    ↓
CDN для отдачи на video editing software
    ↓
Video editor pulls backing tracks по URL
```

### Автоматизация

Cron job каждую ночь:
1. Читает новые items из production queue
2. Генерирует через Python API
3. Загружает в S3
4. Обновляет статус в БД ("ready for editing")
5. Notification в Slack команде

### Метрики

- **Песен в день**: 10-30 (при CPU режиме Strix Halo)
- **Стоимость**: $0 (self-hosted)
- **Latency per song**: 5-15 мин
- **Overhead**: минимальный (один process, один venv, 20GB дискового места)

Сравнение с Suno API: $0.05 за генерацию, что даёт $0.50-$1.50 в день -- экономия не велика, но **privacy** (никакие lyrics не уходят в cloud) и **flexibility** (кастомный LoRA) -- ключевые преимущества.

## Связанные статьи

- [README.md](README.md) -- обзор профиля
- [architecture.md](architecture.md) -- понимание sampling loop и VAE необходимо для advanced use cases
- [simple-use-cases.md](simple-use-cases.md) -- предусловия
- [../../models/families/ace-step.md](../../models/families/ace-step.md) -- карточка модели
- [../../use-cases/music/russian-classics.md](../../use-cases/music/russian-classics.md) -- детальные примеры русского вокала
- [../../use-cases/music/prompting.md](../../use-cases/music/prompting.md) -- промпт-инжиниринг
- [../../use-cases/music/advanced.md](../../use-cases/music/advanced.md) -- практические рецепты
- [../comfyui/advanced-use-cases.md](../comfyui/advanced-use-cases.md) -- для сравнения с другим генеративным workflow
