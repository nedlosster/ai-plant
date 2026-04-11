# Быстрый старт: Wan2.1 1.3B через ComfyUI

Генерация первого видео из текстового описания. Wan2.1 1.3B -- легковесная модель, подходит для экспериментов и обучения.

**См. также**: [профиль ComfyUI](../../apps/comfyui/README.md) -- архитектура платформы, на которой это работает.

## Системные требования

| Компонент | Минимум | Рекомендуемое |
|-----------|---------|---------------|
| Python | 3.10 | 3.12 |
| VRAM | 8 GiB | 16+ GiB |
| Диск | ~10 GiB (модель + зависимости) | ~20 GiB |
| ОС | Linux | Ubuntu 24.04 |
| ROCm | 6.0+ | 6.2 |

## Шаг 1: Установка ComfyUI

Если ComfyUI не установлен:

```bash
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI

python3 -m venv venv
source venv/bin/activate

# PyTorch для AMD ROCm
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2

# Зависимости ComfyUI
pip install -r requirements.txt
```

Если ComfyUI уже установлен -- перейти к шагу 2.

## Шаг 2: Установка ComfyUI-WanVideoWrapper

Плагин для работы с Wan2.1 моделями в ComfyUI.

```bash
cd ComfyUI/custom_nodes

git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git
cd ComfyUI-WanVideoWrapper
pip install -r requirements.txt
```

### Дополнительно: ComfyUI-VideoHelperSuite

Утилиты для работы с видео в ComfyUI (превью, экспорт, объединение кадров).

```bash
cd ComfyUI/custom_nodes
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
cd ComfyUI-VideoHelperSuite
pip install -r requirements.txt
```

## Шаг 3: Загрузка модели Wan2.1 1.3B

```bash
# Основная модель T2V 1.3B (~2.6 GiB)
huggingface-cli download Wan-AI/Wan2.1-T2V-1.3B \
    --local-dir ComfyUI/models/diffusion_models/Wan2.1-T2V-1.3B/
```

### Text Encoder (CLIP)

Wan2.1 использует UMT5-XXL text encoder:

```bash
# UMT5-XXL encoder
huggingface-cli download Wan-AI/Wan2.1-T2V-1.3B \
    --include "models_t5_umt5-xxl-enc-bf16.safetensors" \
    --local-dir ComfyUI/models/text_encoders/
```

### VAE

```bash
# Wan2.1 VAE
huggingface-cli download Wan-AI/Wan2.1-T2V-1.3B \
    --include "Wan2.1_VAE.safetensors" \
    --local-dir ComfyUI/models/vae/
```

### Проверка структуры файлов

```
ComfyUI/models/
  diffusion_models/
    Wan2.1-T2V-1.3B/           # основная модель
  text_encoders/
    models_t5_umt5-xxl-enc-bf16.safetensors
  vae/
    Wan2.1_VAE.safetensors
```

## Шаг 4: Запуск ComfyUI

```bash
cd ComfyUI

# Обязательно: переопределение GFX-версии для Radeon 8060S
export HSA_OVERRIDE_GFX_VERSION=11.5.0

# Запуск
python main.py --listen 0.0.0.0 --port 8188
```

Web-интерфейс: `http://localhost:8188`

### Проверка GPU

```bash
# Перед запуском -- убедиться, что PyTorch видит GPU
HSA_OVERRIDE_GFX_VERSION=11.5.0 python3 -c "
import torch
print('CUDA available:', torch.cuda.is_available())
print('Device:', torch.cuda.get_device_name(0))
print('VRAM:', round(torch.cuda.get_device_properties(0).total_mem / 1024**3, 1), 'GiB')
"
```

## Шаг 5: Первое видео (5 сек, 480p)

### Через workflow в ComfyUI

1. Открыть `http://localhost:8188`
2. Загрузить workflow для Wan2.1 из ComfyUI-WanVideoWrapper (примеры в `custom_nodes/ComfyUI-WanVideoWrapper/workflows/`)
3. В узле загрузки модели выбрать `Wan2.1-T2V-1.3B`
4. Настроить параметры:
   - **Width**: 832
   - **Height**: 480
   - **Num frames**: 81 (~5 секунд при 16 fps)
   - **Steps**: 20-30
   - **CFG**: 6.0
   - **Seed**: любое число (или -1 для случайного)
5. В текстовом поле ввести промпт:
   ```
   A calm ocean wave rolling onto a sandy beach at sunset,
   golden light reflecting on the water, gentle camera pan right,
   cinematic, 4k quality
   ```
6. Нажать **Queue Prompt**

### Параметры генерации

| Параметр | Значение | Описание |
|----------|---------|----------|
| Width | 832 | Ширина в пикселях |
| Height | 480 | Высота в пикселях |
| Num frames | 81 | Число кадров (~5 сек при 16 fps) |
| Steps | 20-30 | Шаги денойзинга (больше = качественнее, медленнее) |
| CFG | 5.0-7.0 | Guidance scale (соответствие промпту) |
| Seed | -1 | Случайный seed; фиксировать для воспроизводимости |

### Время генерации (ориентировочно)

На Radeon 8060S с Wan2.1 1.3B:
- 480p, 81 кадр, 25 шагов: ~2-5 минут
- Точное время зависит от ROCm-оптимизации и текущей загрузки

## Шаг 6: Проверка результата

Результат сохраняется в `ComfyUI/output/`. ComfyUI-VideoHelperSuite позволяет просмотреть видео в интерфейсе.

```bash
# Проверка выходного файла
ls -la ComfyUI/output/

# Проигрывание (если есть mpv)
mpv ComfyUI/output/wan_video_00001.mp4

# Информация о видео
ffprobe ComfyUI/output/wan_video_00001.mp4
```

### Типичные проблемы

| Проблема | Решение |
|----------|---------|
| `RuntimeError: No HIP GPUs are available` | Проверить `HSA_OVERRIDE_GFX_VERSION=11.5.0` |
| OOM (Out of Memory) | Уменьшить разрешение или число кадров |
| Черное видео | Проверить подключение VAE в workflow |
| Статичное видео (нет движения) | Добавить описание движения в промпт ("camera pan", "walking") |
| Артефакты на лицах/руках | Типичная проблема diffusion-моделей, уменьшить CFG |

## Следующие шаги

- [Промпт-инжиниринг](prompting.md) -- составление промптов для видео
- [Продвинутое использование](advanced.md) -- переход на Wan2.1 14B, I2V, постобработка
- [Справочник моделей](../../models/video.md) -- сравнение всех видеомоделей

## Связанные статьи

- [Промпт-инжиниринг](prompting.md)
- [Продвинутое использование](advanced.md)
- [Модели для видео](../../models/video.md)
