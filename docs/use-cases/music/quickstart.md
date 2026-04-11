# ACE-Step 1.5: быстрый старт

**См. также**: [профиль платформы ACE-Step](../../apps/ace-step/README.md) -- что это как софтверный стек, архитектура DiT + LM.

## Системные требования

| Компонент | Минимум | Рекомендуемое |
|-----------|---------|---------------|
| Python | 3.11 | 3.12 |
| VRAM | 4 GiB (DiT-only) | 16+ GiB (с LM) |
| Диск | ~10 GiB (модели) | ~15 GiB |
| ОС | Linux, Windows, macOS | Ubuntu 24.04 |

## Установка (скрипты проекта)

На AI-сервере (<SERVER_IP>) -- через скрипты проекта:

```bash
cd ~/projects/ai-plant

# Установка: uv, клонирование, зависимости, PyTorch ROCm, модели (~20 GiB)
./scripts/music/ace-step/install.sh

# Запуск (фоновый режим, Gradio UI на 0.0.0.0:7860)
./scripts/music/ace-step/start.sh --daemon

# Статус
./scripts/music/ace-step/status.sh

# Остановка
./scripts/music/ace-step/stop.sh
```

Gradio UI: `http://<SERVER_IP>:7860` (доступен с рабочих станций).

### Текущая конфигурация платформы

| Параметр | Значение |
|----------|---------|
| Backend | CPU (PyTorch) |
| DiT | acestep-v15-turbo (8 шагов) |
| LM | tier1 -- DiT-only (LM не инициализируется на CPU автоматически) |
| Tier | 1 (batch 1, до 4 мин с LM, 6 мин без) |

Ограничения текущей версии:
- **CPU-режим** -- генерация медленнее (минуты вместо секунд)
- **ROCm GPU** -- KFD видит 15.5 GiB из 96 GiB, автоконфиг блокирует LM 4B
- **LM** -- не инициализируется автоматически на tier1 (CPU)
- Модели LM 1.7B и 4B скачаны, ожидают исправления ROCm или ACE-Step
- Подробности: [rocm-setup.md](../../inference/rocm-setup.md#статус-gfx1151-strix-halo)

### Ручная установка (без скриптов)

Вариант 1: uv (чистая установка, CPU)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
git clone https://github.com/ACE-Step/ACE-Step-1.5.git
cd ACE-Step-1.5
uv sync
uv run acestep-download
uv run acestep --port 7860
```

Вариант 2: uv + PyTorch ROCm (GPU)

```bash
git clone https://github.com/ACE-Step/ACE-Step-1.5.git
cd ACE-Step-1.5
uv sync

# Замена CPU torch на ROCm (после uv sync, не через uv run!)
uv pip install --no-deps torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/rocm6.2.4 --reinstall

# Переменные окружения
export HSA_OVERRIDE_GFX_VERSION=11.5.0
export MIOPEN_FIND_MODE=FAST

# Загрузка моделей (через .venv/bin/python, не uv run!)
.venv/bin/python -m acestep.model_downloader
.venv/bin/python -m acestep.model_downloader --model acestep-5Hz-lm-4B

# Запуск (через .venv/bin/python, не uv run!)
.venv/bin/python -m acestep.acestep_v15_pipeline --port 7860 --server-name 0.0.0.0
```

Важно: `uv run` пересинхронизирует зависимости и заменяет ROCm torch на CPU-версию.
После установки ROCm torch все команды -- через `.venv/bin/python`.

### Docker

```bash
# NVIDIA
docker run --gpus all -p 7860:7860 \
    ghcr.io/dotnetautor/ace-step-1.5-docker:latest

# AMD ROCm
docker run --device=/dev/kfd --device=/dev/dri \
    --group-add video --group-add render \
    -e HSA_OVERRIDE_GFX_VERSION=11.5.0 \
    -p 7860:7860 \
    ghcr.io/dotnetautor/ace-step-1.5-docker:latest
```

## Конфигурация (.env)

```bash
# Выбор DiT-модели
ACESTEP_CONFIG_PATH=acestep-v15-turbo    # быстрая (8 шагов)
# ACESTEP_CONFIG_PATH=acestep-v15-sft    # качественная (50 шагов)

# Выбор LM-модели (влияет на качество планирования)
ACESTEP_LM_MODEL_PATH=acestep-5Hz-lm-1.7B   # баланс
# ACESTEP_LM_MODEL_PATH=acestep-5Hz-lm-4B   # максимальное качество
# ACESTEP_LM_MODEL_PATH=acestep-5Hz-lm-0.6B # минимальный VRAM

# Backend LM
ACESTEP_LM_BACKEND=pt       # PyTorch (для ROCm)
# ACESTEP_LM_BACKEND=mlx    # для macOS

# Инициализация LLM
ACESTEP_INIT_LLM=true       # false для DiT-only режима

PORT=7860
LANGUAGE=en
```

## Загрузка моделей

```bash
# Модели по умолчанию (turbo DiT + 1.7B LM)
uv run acestep-download

# Все модели
uv run acestep-download --all

# Конкретная LM
uv run acestep-download --model acestep-5Hz-lm-4B

# Список доступных
uv run acestep-download --list
```

Модели загружаются в `~/.cache/huggingface/` (~10 GiB).

## Первая песня

### Через Gradio UI

1. Открыть `http://localhost:7860`
2. Вкладка **Simple Mode**
3. Заполнить:
   - **Caption**: `pop, female vocals, emotional, piano, 110 bpm`
   - **Lyrics**:
     ```
     [Verse]
     Walking through the morning light
     Every shadow fades away

     [Chorus]
     We are the ones who shine tonight
     Breaking through the dark
     ```
4. Нажать **Generate**

### Через CLI

```bash
uv run acestep-api &   # Запуск API-сервера на порту 8001

# Генерация
curl -X POST http://localhost:8001/generate \
    -H "Content-Type: application/json" \
    -d '{
        "caption": "pop, female vocals, emotional, piano, 110 bpm",
        "lyrics": "[Verse]\nWalking through the morning light\nEvery shadow fades away\n\n[Chorus]\nWe are the ones who shine tonight\nBreaking through the dark",
        "duration": 120
    }' --output song.mp3
```

### Через Python API

```python
from acestep import ACEStepPipeline

pipe = ACEStepPipeline.from_pretrained("ACE-Step/Ace-Step1.5")

result = pipe.generate(
    caption="pop, female vocals, emotional, piano, 110 bpm",
    lyrics="""[Verse]
Walking through the morning light
Every shadow fades away

[Chorus]
We are the ones who shine tonight
Breaking through the dark""",
    duration=120,
    seed=42,
)

result.save("my_first_song.mp3")
```

## Первая песня на русском

Caption:
```
russian pop, female vocals, emotional, piano, strings, 110 bpm, ballad
```

Lyrics:
```
[Verse 1]
Снова ночь, и город спит в тиши,
Только ветер шепчет мне слова.
Я иду по улицам пустым,
Вспоминая все, что было у нас.

[Chorus]
Не уходи, останься рядом,
Мне без тебя так холодно одной.
Не уходи, мне больше ничего не надо,
Только быть с тобой.
```

Рекомендации:
- Указать `russian` в caption
- Ритмичные строки одинаковой длины
- Рифмовать -- модель лучше обрабатывает рифмованный текст
- Генерировать 2-4 варианта (разные seed), выбрать лучший

## Варианты DiT-моделей

| Модель | Шаги | Скорость | Особенности |
|--------|------|----------|-------------|
| acestep-v15-turbo | 8 | быстрая | По умолчанию |
| acestep-v15-turbo-shift1 | 8 | быстрая | Богаче деталями |
| acestep-v15-turbo-shift3 | 8 | быстрая | Чище тембр |
| acestep-v15-sft | 50 | стандартная | Выше качество |
| acestep-v15-base | 50 | стандартная | Полный набор режимов |

Для начала -- `turbo` (по умолчанию). Для максимального качества -- `sft`.

## Проверка работоспособности

```bash
# GPU определяется
python3 -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"

# Модели загружены
ls ~/.cache/huggingface/hub/ | grep ace

# UI доступен
curl -s http://localhost:7860 | head -1
```

## Связанные статьи

- [Промпт-инжиниринг](prompting.md)
- [Продвинутое использование](advanced.md)
- [Ресурсы](resources.md)
