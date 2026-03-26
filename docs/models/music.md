# Модели для генерации музыки и вокала

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), ROCm экспериментальный, PyTorch + ROCm нестабилен.

## Статус на платформе

Генерация музыки требует PyTorch с GPU-ускорением. На данной платформе:
- ROCm для gfx1151 -- экспериментальный (HSA_OVERRIDE_GFX_VERSION)
- PyTorch + ROCm -- возможны memory access faults
- **ACE-Step 1.5** -- явная поддержка AMD ROCm, лучший выбор для данной платформы
- Остальные модели -- экспериментально, может потребоваться отладка

## Рейтинг моделей

| Модель | Размер | VRAM | Возможности | Лицензия |
|--------|--------|------|-------------|----------|
| **ACE-Step 1.5** | <4 GiB | <4 GiB | Текст -> песня с вокалом, 2 мин за 66 сек | Apache 2.0 |
| SongGeneration v2 | 4B | 10-16 GiB | Полные песни с вокалом | Research |
| YuE | 7B+1B | 8-24 GiB | Lyrics -> song, мультиязычный | Apache 2.0 |
| MusicGen | 300M-3.3B | 8-16 GiB | Инструментальная музыка по описанию | MIT |
| Stable Audio Open | 1.2B | ~24 GiB | Text-to-audio, звуковые эффекты | Stability AI |

## ACE-Step 1.5 (рекомендуемый)

Лучший выбор для данной платформы: явная поддержка AMD ROCm, минимальные требования к VRAM.

### Возможности
- Генерация песен с вокалом по текстовому описанию
- Поддержка lyrics (текст песни)
- Длительность до 2+ минут
- Скорость: ~66 секунд на 2-минутный трек (на GPU)

### Установка

```bash
git clone https://github.com/ace-step/ACE-Step.git
cd ACE-Step

# Создание виртуального окружения
python3 -m venv venv
source venv/bin/activate

# Установка зависимостей для AMD ROCm
pip install -r requirements-rocm.txt

# Загрузка весов (автоматически при первом запуске)
```

### Запуск

```bash
# Установить переменную для gfx1151
export HSA_OVERRIDE_GFX_VERSION=11.5.0

# Gradio-интерфейс
python app.py

# CLI
python generate.py \
    --prompt "upbeat electronic dance music with female vocals" \
    --lyrics "Dancing in the moonlight..." \
    --duration 120 \
    --output output.wav
```

### Web-интерфейс

ACE-Step включает Gradio UI. После запуска `python app.py` -- открыть `http://localhost:7860`.

## MusicGen (Meta)

Инструментальная музыка по текстовому описанию. Без вокала.

### Варианты

| Модель | Параметры | VRAM | Качество |
|--------|-----------|------|----------|
| musicgen-small | 300M | ~2 GiB | базовое |
| musicgen-medium | 1.5B | ~8 GiB | хорошее |
| musicgen-large | 3.3B | ~16 GiB | высокое |
| musicgen-melody | 1.5B | ~8 GiB | хорошее + мелодия-промпт |

### Установка

```bash
pip install audiocraft

# Или через transformers
pip install transformers torch torchaudio
```

### Запуск

```python
from audiocraft.models import MusicGen

model = MusicGen.get_pretrained('facebook/musicgen-large')
model.set_generation_params(duration=30)

# Генерация по описанию
wav = model.generate(['epic orchestral soundtrack, cinematic, dramatic'])

# Сохранение
import torchaudio
torchaudio.save('output.wav', wav[0].cpu(), sample_rate=32000)
```

### Ограничения на AMD

Требует PyTorch + ROCm. На gfx1151 -- экспериментально:

```bash
export HSA_OVERRIDE_GFX_VERSION=11.5.0
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2
```

## YuE (lyrics-to-song)

Генерация полных песен с вокалом из текста и описания стиля.

| Параметр | Значение |
|----------|---------|
| Модель | 7B (генерация) + 1B (вокал) |
| VRAM | 8-24 GiB |
| Вход | Lyrics + style description |
| Выход | Полная песня с вокалом |
| Лицензия | Apache 2.0 |

```bash
git clone https://github.com/multimodal-art-projection/YuE.git
cd YuE
pip install -r requirements.txt

# Запуск
python infer.py \
    --genre "pop, upbeat" \
    --lyrics_file lyrics.txt \
    --output song.wav
```

## SongGeneration v2 (Tencent)

| Параметр | Значение |
|----------|---------|
| Модель | 4B параметров |
| VRAM | 10-16 GiB |
| Возможности | Полные песни с вокалом, высокое качество |
| Лицензия | Research only |

Закрытая лицензия для исследований. Для коммерческого использования -- ACE-Step или YuE.

## Stable Audio Open

Генерация звуковых эффектов и коротких музыкальных фрагментов.

| Параметр | Значение |
|----------|---------|
| Модель | 1.2B |
| VRAM | ~24 GiB |
| Длительность | до 47 секунд |
| Лицензия | Stability AI |

```bash
pip install stable-audio-tools

# Через diffusers
from diffusers import StableAudioPipeline
pipe = StableAudioPipeline.from_pretrained("stabilityai/stable-audio-open-1.0")
audio = pipe("ambient electronic music, calm and atmospheric", num_inference_steps=100)
```

## Источники моделей

| Модель | Источник |
|--------|---------|
| ACE-Step | [GitHub](https://github.com/ace-step/ACE-Step) |
| MusicGen | [HuggingFace](https://huggingface.co/facebook/musicgen-large) |
| YuE | [GitHub](https://github.com/multimodal-art-projection/YuE) |
| SongGeneration | [HuggingFace](https://huggingface.co/Tencent-Hunyuan) |
| Stable Audio | [HuggingFace](https://huggingface.co/stabilityai/stable-audio-open-1.0) |

## Рекомендация для данной платформы

1. **ACE-Step 1.5** -- начать с него: поддержка AMD, малый VRAM, полные песни
2. **MusicGen** -- для инструментальной музыки, если PyTorch+ROCm работает стабильно
3. **YuE** -- альтернатива ACE-Step для lyrics-to-song

## Связанные статьи

- [Русский вокал](russian-vocals.md)
- [ACE-Step: быстрый старт](../use-cases/music/quickstart.md)
