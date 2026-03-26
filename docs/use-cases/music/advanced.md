# ACE-Step 1.5: продвинутое использование

## Режимы генерации

| Режим | Вход | Описание |
|-------|------|----------|
| **text2music** | caption + lyrics | Генерация с нуля |
| **cover** | source audio + caption | Сохранение структуры, изменение стиля |
| **repaint** | source audio + start/end | Перегенерация фрагмента |
| **lego** | source audio + track type | Добавление инструментального слоя (только base) |
| **extract** | source audio + track type | Изоляция трека (только base) |
| **complete** | source audio | Автоаранжировка (только base) |

Режимы lego, extract, complete доступны только с моделью `acestep-v15-base` (50 шагов).

### Cover (ремикс)

Загрузить source audio, написать caption целевого стиля. Настроить Remix Strength (0.0-1.0): выше = ближе к оригиналу.

```
Source: original_song.mp3
Caption: jazz, piano trio, upright bass, brushed drums, 130 bpm, warm
Remix Strength: 0.7
```

### Repaint (исправление фрагмента)

Перегенерация отрезка песни без изменения остального. Полезно для исправления неудачного куплета или припева.

```
Source: my_song.mp3
Start: 30.0   # секунды
End: 60.0
Caption: (тот же или измененный)
```

### Extract (разделение на stems)

Изоляция отдельного инструмента или вокала:

```
Source: full_mix.mp3
Track type: vocals / drums / bass / guitar / keyboard / strings / synth
```

Доступные треки: vocals, backing_vocals, drums, bass, guitar, keyboard, percussion, strings, synth, fx, brass, woodwinds.

### Lego (добавление слоя)

Добавление инструментального слоя к существующему треку:

```
Source: instrumental.mp3
Track type: guitar
Caption: electric guitar, clean tone, jazzy
```

## LoRA-тренировка

Тренировка собственного стиля на 8-100 песнях.

### Требования

| Параметр | Значение |
|----------|---------|
| Данные | 8-100 песен (.mp3/.wav/.flac) + lyrics (.txt) + metadata (JSON) |
| VRAM | 16+ GiB (рекомендуется 20+) |
| Время | ~1 час (LoRA) / ~5 мин (LoKR) на RTX 3090 |
| Эпохи | 500-800 |

### Подготовка данных

```
training_data/
  song1.mp3
  song1.txt          # Lyrics
  song1_meta.json    # {"caption": "...", "bpm": 120, "key": "Am"}
  song2.mp3
  song2.txt
  song2_meta.json
  ...
```

### Запуск тренировки

Через Gradio UI: вкладка "Train LoRA" или "Train LoKR".

**LoKR** -- в 10x быстрее стандартного LoRA, рекомендуется для экспериментов.

### Использование LoRA

После тренировки -- выбрать адаптер в Gradio UI или указать путь в API.

## REST API

```bash
# Запуск API-сервера
uv run acestep-api --port 8001
```

### Эндпоинты

```bash
# Генерация
POST /generate
{
    "caption": "pop, female vocals, 120 bpm",
    "lyrics": "[Verse]\nHello world\n\n[Chorus]\nLa la la",
    "duration": 120,
    "seed": 42,
    "batch_size": 2,
    "audio_format": "mp3"
}

# Cover
POST /cover
{
    "source_audio": "base64_encoded_audio",
    "caption": "jazz, piano trio",
    "remix_strength": 0.7
}

# Repaint
POST /repaint
{
    "source_audio": "base64_encoded_audio",
    "start": 30.0,
    "end": 60.0,
    "caption": "..."
}
```

### Python-клиент

```python
import requests
import base64

# Генерация
response = requests.post("http://localhost:8001/generate", json={
    "caption": "russian pop, female vocals, piano, 110 bpm",
    "lyrics": "[Verse]\nЗдесь текст куплета\n\n[Chorus]\nЗдесь текст припева",
    "duration": 120,
    "seed": 42,
})

with open("output.mp3", "wb") as f:
    f.write(response.content)
```

## Постобработка

### Demucs (разделение на stems)

```bash
pip install demucs

# Разделение на 4 stems
python -m demucs song.mp3 --out separated/
# separated/htdemucs/song/vocals.wav
# separated/htdemucs/song/drums.wav
# separated/htdemucs/song/bass.wav
# separated/htdemucs/song/other.wav

# Только вокал + фон
python -m demucs --two-stems=vocals song.mp3 --out separated/
```

### RVC (замена голоса)

Конвертация тембра вокала -- замена "синтетического" голоса на клон реального.

Пайплайн:
1. Генерация через ACE-Step
2. Разделение вокала (Demucs)
3. Конвертация тембра (RVC)
4. Микширование обратно

```bash
git clone https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI.git
cd Retrieval-based-Voice-Conversion-WebUI
pip install -r requirements.txt

# Web UI
python infer-web.py
```

Встроенная функция ACE-Step: extract режим нативно изолирует вокал.

### Нормализация громкости

```bash
ffmpeg -i input.wav -af loudnorm=I=-14:TP=-1.5:LRA=11 output.wav
```

### Конвертация форматов

```bash
# WAV -> MP3
ffmpeg -i song.wav -codec:a libmp3lame -qscale:a 2 song.mp3

# WAV -> FLAC
ffmpeg -i song.wav -codec:a flac song.flac
```

## ComfyUI-интеграция

```bash
cd ComfyUI/custom_nodes
git clone https://github.com/billwuhao/ComfyUI_ACE-Step.git
```

Документация: docs.comfy.org/tutorials/audio/ace-step/ace-step-v1-5

## VST3-плагин

Интеграция с DAW (Ableton, FL Studio, Reaper):

```
github.com/ace-step/acestep.vst3
```

C++/GGML реализация, работает без Python.

## Автоматическая генерация LRC

ACE-Step автоматически генерирует файлы с временными метками текста (LRC-формат). Включено по умолчанию, файл создается рядом с аудио.

## Пакетная генерация

```python
# Генерация нескольких песен из файла промптов
import json

with open("prompts.jsonl") as f:
    prompts = [json.loads(line) for line in f]

for i, p in enumerate(prompts):
    result = pipe.generate(
        caption=p["caption"],
        lyrics=p["lyrics"],
        duration=p.get("duration", 120),
        batch_size=2,
    )
    result.save(f"output/song_{i:03d}.mp3")
```

## Side-Step CLI

Продвинутый CLI-инструмент для research:

```bash
pip install side-step

# Генерация с расширенными параметрами
sidestep generate \
    --caption "pop, female vocals" \
    --lyrics-file lyrics.txt \
    --model acestep-v15-turbo \
    --lm-model acestep-5Hz-lm-4B \
    --output output.wav
```

Функционал: corrected timestep sampling, LoKR adapters, VRAM optimization, gradient sensitivity analysis.

Документация: docs/sidestep/Getting Started.md в репозитории.

## Связанные статьи

- [Быстрый старт](quickstart.md)
- [Промпт-инжиниринг](prompting.md)
- [Ресурсы](resources.md)
- [Модели для музыки](../../models/music.md)
