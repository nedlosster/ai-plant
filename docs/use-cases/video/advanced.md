# Продвинутое использование видеогенерации

## Wan2.1 14B: максимальное качество

Wan2.1 14B -- полная версия модели. Значительно выше качество motion, детализация, физика объектов по сравнению с 1.3B.

### Требования

| Параметр | Значение |
|----------|---------|
| VRAM | 45-70 GiB (fp16, зависит от разрешения) |
| Диск | ~28 GiB (веса модели) |
| Точность | fp16 / bf16 |

На 96 GiB VRAM модель помещается целиком в fp16 без квантизации и offloading.

### Загрузка

```bash
# Wan2.1 14B text-to-video (~28 GiB)
huggingface-cli download Wan-AI/Wan2.1-T2V-14B \
    --local-dir ComfyUI/models/diffusion_models/Wan2.1-T2V-14B/

# Wan2.1 14B image-to-video (~28 GiB)
huggingface-cli download Wan-AI/Wan2.1-I2V-14B \
    --local-dir ComfyUI/models/diffusion_models/Wan2.1-I2V-14B/
```

### Запуск через ComfyUI

```bash
cd ComfyUI
HSA_OVERRIDE_GFX_VERSION=11.5.0 python main.py --listen 0.0.0.0 --port 8188
```

В workflow ComfyUI-WanVideoWrapper выбрать модель `Wan2.1-T2V-14B`. Рекомендуемые параметры:

| Параметр | Значение |
|----------|---------|
| Width | 1280 |
| Height | 720 |
| Num frames | 81-129 |
| Steps | 25-50 |
| CFG | 5.0-7.0 |

### VRAM по разрешениям (14B, fp16)

| Разрешение | Кадры | VRAM (оценка) |
|-----------|-------|---------------|
| 832x480 | 81 | ~45 GiB |
| 1280x720 | 81 | ~55 GiB |
| 1280x720 | 129 | ~65 GiB |
| 1280x720 | 161 | ~75 GiB |

На 96 GiB все конфигурации помещаются без проблем.

## Image-to-Video (I2V)

Генерация видео из входного изображения. Модель анимирует статичную картинку, сохраняя её стиль и содержание.

### Wan2.1 I2V

```bash
# Загрузка I2V модели
huggingface-cli download Wan-AI/Wan2.1-I2V-14B \
    --local-dir ComfyUI/models/diffusion_models/Wan2.1-I2V-14B/
```

В ComfyUI использовать workflow с узлом загрузки изображения (LoadImage) + WanVideoWrapper I2V.

Промпт описывает желаемое движение:
```
The woman in the photo slowly turns her head to the right,
wind blowing her hair, soft smile appearing, cinematic
```

Входное изображение определяет внешний вид, промпт -- движение.

### SVD (Stable Video Diffusion)

Специализированная I2V модель от Stability AI. Генерирует 14-25 кадров из одного изображения.

```bash
# Загрузка SVD XT
huggingface-cli download stabilityai/stable-video-diffusion-img2vid-xt \
    --local-dir ComfyUI/models/diffusion_models/svd-xt/
```

В ComfyUI: узел SVDLoader + LoadImage. Параметры:
- **motion_bucket_id**: 127 (стандарт), увеличить для большего движения
- **fps**: 6-30
- **augmentation_level**: 0.0 (точное соответствие), 0.1+ (вариативность)

## Motion Control

Управление движением камеры и объектов.

### Через промпт

Базовый способ -- описание камеры в промпте (см. [промпт-инжиниринг](prompting.md)).

### Camera Control LoRA

Для Wan2.1 существуют LoRA-адаптеры для точного управления камерой:

```bash
# Пример загрузки camera control LoRA (если доступен)
huggingface-cli download Wan-AI/Wan2.1-CameraCtrl-14B \
    --local-dir ComfyUI/models/loras/
```

Типы движения камеры с LoRA:
- Pan left/right
- Tilt up/down
- Zoom in/out
- Orbit
- Static

### DragAnything / MotionCtrl

Экспериментальные расширения для точного управления траекторией объектов. Указание начальной и конечной точки объекта на экране.

## Интерполяция кадров

Увеличение числа кадров для плавности. Из 16 fps делает 48-60 fps.

### RIFE через ComfyUI

```bash
cd ComfyUI/custom_nodes
git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git
cd ComfyUI-Frame-Interpolation
pip install -r requirements.txt
```

В workflow ComfyUI добавить узел RIFE VFI (Video Frame Interpolation) после генерации:
- **multiplier**: 2 (удвоение кадров), 4 (учетверение)
- **model**: RIFE 4.22 (рекомендуемый)

Пример: 81 кадр (16 fps) -> multiplier 3 -> 243 кадра (48 fps) при той же длительности.

### FILM

Альтернатива RIFE. Доступна через тот же плагин ComfyUI-Frame-Interpolation. FILM лучше справляется с большими разрывами между кадрами.

## Upscaling видео

Покадровое увеличение разрешения через Real-ESRGAN или аналоги.

### Real-ESRGAN через ComfyUI

В ComfyUI встроена поддержка upscale-моделей. В workflow:

1. Узел генерации видео (WanVideoWrapper)
2. Узел разделения на кадры
3. Узел Upscale (Real-ESRGAN x2/x4)
4. Узел сборки обратно в видео

Модели upscale:
```bash
# Real-ESRGAN x4 (~65 MiB)
huggingface-cli download ai-forever/Real-ESRGAN \
    --include "RealESRGAN_x4.pth" \
    --local-dir ComfyUI/models/upscale_models/

# Real-ESRGAN x2 (для умеренного upscale)
huggingface-cli download ai-forever/Real-ESRGAN \
    --include "RealESRGAN_x2.pth" \
    --local-dir ComfyUI/models/upscale_models/
```

### Через ffmpeg + Real-ESRGAN CLI

Покадровая обработка вне ComfyUI:

```bash
# Извлечение кадров
ffmpeg -i input.mp4 -qscale:v 2 frames/frame_%05d.png

# Upscale каждого кадра (Real-ESRGAN CLI)
realesrgan-ncnn-vulkan -i frames/ -o frames_upscaled/ -n realesrgan-x4plus

# Сборка обратно
ffmpeg -framerate 16 -i frames_upscaled/frame_%05d.png \
    -c:v libx264 -pix_fmt yuv420p output_upscaled.mp4
```

## Конвертация через ffmpeg

### Базовые операции

```bash
# Конвертация формата
ffmpeg -i input.mp4 -c:v libx264 -crf 18 output.mp4

# Изменение fps
ffmpeg -i input.mp4 -r 24 output_24fps.mp4

# Обрезка (с 2 по 7 секунду)
ffmpeg -i input.mp4 -ss 00:00:02 -to 00:00:07 -c copy trimmed.mp4

# Масштабирование
ffmpeg -i input.mp4 -vf scale=1920:1080 output_1080p.mp4

# GIF из видео
ffmpeg -i input.mp4 -vf "fps=10,scale=480:-1:flags=lanczos" output.gif

# Добавление аудио
ffmpeg -i video.mp4 -i audio.mp3 -c:v copy -c:a aac -shortest output.mp4
```

### Объединение клипов

```bash
# Создание списка файлов
echo "file 'clip1.mp4'" > list.txt
echo "file 'clip2.mp4'" >> list.txt
echo "file 'clip3.mp4'" >> list.txt

# Конкатенация
ffmpeg -f concat -safe 0 -i list.txt -c copy merged.mp4
```

### Оптимизация размера

```bash
# Сжатие для веба (CRF 23 -- хороший баланс)
ffmpeg -i input.mp4 -c:v libx264 -crf 23 -preset medium \
    -c:a aac -b:a 128k output_web.mp4

# Максимальное качество
ffmpeg -i input.mp4 -c:v libx264 -crf 15 -preset slow output_hq.mp4
```

## Looping: бесшовные петли

Создание видео, которое зацикливается без видимого перехода.

### Способ 1: промпт

Добавить в промпт:
```
seamless loop, cyclical motion, loop-friendly
```

Подходит для: абстрактных анимаций, вращение объекта, волны, пламя.

### Способ 2: blend через ffmpeg

Смешивание начала и конца видео:

```bash
# Создание плавного перехода (crossfade последних 30 кадров)
ffmpeg -i input.mp4 -filter_complex \
    "[0:v]split[main][end]; \
     [end]trim=start_frame=51:end_frame=81,setpts=PTS-STARTPTS[tail]; \
     [main]trim=start_frame=0:end_frame=51,setpts=PTS-STARTPTS[head]; \
     [head][tail]xfade=transition=fade:duration=1:offset=2[out]" \
    -map "[out]" loop.mp4
```

### Способ 3: ping-pong

Воспроизведение видео вперед, затем назад:

```bash
# Ping-pong (вперед + назад)
ffmpeg -i input.mp4 -filter_complex \
    "[0:v]reverse[rev];[0:v][rev]concat=n=2:v=1:a=0" \
    pingpong.mp4
```

Подходит для: простых движений (волна, качание, дыхание).

## Пакетная генерация

### Через ComfyUI API

ComfyUI предоставляет REST API для автоматизации:

```python
import json
import urllib.request

# Загрузка workflow
with open("workflow.json") as f:
    workflow = json.load(f)

# Список промптов
prompts = [
    "A cat walking on a fence at sunset, cinematic",
    "Ocean waves crashing on rocks, slow motion, dramatic",
    "Clouds moving fast over mountains, timelapse, wide shot",
]

for i, prompt_text in enumerate(prompts):
    # Изменить текст промпта в workflow
    workflow["6"]["inputs"]["text"] = prompt_text
    workflow["3"]["inputs"]["seed"] = i * 1000

    # Отправить на генерацию
    data = json.dumps({"prompt": workflow}).encode("utf-8")
    req = urllib.request.Request(
        "http://localhost:8188/prompt",
        data=data,
        headers={"Content-Type": "application/json"},
    )
    urllib.request.urlopen(req)
    print(f"Запущена генерация {i+1}/{len(prompts)}")
```

## Следующие шаги

- [Справочник моделей](../../models/video.md) -- сравнение всех видеомоделей
- [Ресурсы](resources.md) -- расширения, сообщества, туториалы

## Связанные статьи

- [Быстрый старт](quickstart.md)
- [Промпт-инжиниринг](prompting.md)
- [Ресурсы](resources.md)
- [Модели для видео](../../models/video.md)
