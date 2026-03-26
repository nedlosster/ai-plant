# ComfyUI Workflows

Описание основных workflows для генерации и обработки изображений. Все примеры -- для Radeon 8060S (96 GiB VRAM, ROCm).

## Структура ComfyUI

ComfyUI строится из нод (узлов), соединенных связями. Каждая нода выполняет одну операцию.

### Основные типы нод

| Категория | Ноды | Назначение |
|-----------|------|-----------|
| Загрузчики | Unet Loader, CLIP Loader, VAE Loader | Загрузка моделей в память |
| Энкодеры | CLIP Text Encode | Преобразование текста в эмбеддинги |
| Латенты | Empty Latent Image, VAE Encode | Создание/преобразование латентного пространства |
| Сэмплеры | KSampler, KSampler Advanced | Итеративная денойзинг-процедура |
| Декодеры | VAE Decode | Преобразование латентов в пиксели |
| Вывод | Save Image, Preview Image | Сохранение и предпросмотр |

## txt2img: текст в изображение

Базовый workflow -- генерация изображения из текстового промпта.

### Для FLUX (GGUF)

Структура нод:

```
Unet Loader (GGUF)
    |
    v
DualCLIPLoader (GGUF) --> CLIP Text Encode (промпт)
    |                          |
    v                          v
Empty Latent Image -------> KSampler
                               |
VAE Loader ----------------> VAE Decode
                               |
                            Save Image
```

Параметры KSampler для FLUX:
- **steps**: 20 (Dev), 4 (Schnell)
- **cfg**: 1.0
- **sampler**: euler
- **scheduler**: simple
- **denoise**: 1.0

Особенность FLUX: используется DualCLIPLoader для загрузки двух text encoders (clip_l + t5xxl). Обычный CLIPLoader не подходит.

### Для Stable Diffusion 3.5

Структура аналогична, но:
- Используется тройной text encoder (clip_g + clip_l + t5xxl)
- cfg: 7.0-10.0
- Нужен negative prompt (отдельная нода CLIP Text Encode)
- steps: 20-30
- sampler: dpmpp_2m, scheduler: karras

## img2img: изображение в изображение

Модификация существующего изображения на основе промпта.

### Отличия от txt2img

1. Вместо **Empty Latent Image** используется **Load Image** + **VAE Encode**
2. Параметр **denoise** в KSampler < 1.0:
   - 0.3-0.5 -- легкие изменения (сохранение структуры)
   - 0.5-0.7 -- умеренные изменения
   - 0.7-0.9 -- значительные изменения (от исходника остается мало)

```
Load Image --> VAE Encode --> KSampler (denoise: 0.5) --> VAE Decode --> Save Image
                                  ^
                                  |
                    CLIP Text Encode (новый промпт)
```

Применение: изменение стиля фотографии, добавление деталей, смена освещения.

## Inpainting: замена части изображения

Замаскировать область на изображении и сгенерировать в ней новый контент.

### Порядок действий

1. Загрузить изображение через **Load Image**
2. В свойствах ноды нажать правой кнопкой -- Open in MaskEditor
3. Закрасить область для замены (белым)
4. Использовать **VAE Encode (for Inpainting)** вместо обычного VAE Encode
5. В промпте описать, что должно появиться в замаскированной области
6. denoise: 0.8-1.0 для полной замены, 0.5-0.7 для мягкой интеграции

```
Load Image (с маской) --> VAE Encode (for Inpainting) --> KSampler --> VAE Decode
                                                             ^
                                                             |
                                               CLIP Text Encode (описание замены)
```

Пример: замаскировать небо на фотографии, промпт: `dramatic sunset sky with orange and purple clouds`.

## Upscale: увеличение разрешения

### Метод 1: AI-апскейл (Real-ESRGAN)

Для установки нужен **ComfyUI-Manager** или ручная установка ноды.

```
Load Image --> Upscale Image (Real-ESRGAN) --> Save Image
```

Модели апскейла:
- **RealESRGAN_x4plus** -- универсальный, x4
- **RealESRGAN_x4plus_anime_6B** -- оптимизирован для аниме

Скачать модели в `ComfyUI/models/upscale_models/`.

### Метод 2: Tile ControlNet + img2img

Апскейл с добавлением деталей через diffusion-модель:

1. Увеличить изображение (Upscale Image, метод lanczos)
2. Через ControlNet Tile подать увеличенное изображение как guide
3. Запустить img2img с denoise 0.3-0.5

Результат: увеличение разрешения с генерацией новых деталей (текстуры, мелкие элементы).

### Метод 3: Hires Fix

Двухпроходная генерация:
1. Генерация на базовом разрешении (512x512 или 1024x1024)
2. Upscale латента (Latent Upscale, nearest-exact)
3. Повторный KSampler с denoise 0.4-0.6

При 96 GiB VRAM можно генерировать до 2048x2048 напрямую для большинства моделей (см. [справочник](../../models/images.md)).

## ControlNet: управление композицией

ControlNet добавляет структурные условия к генерации.

### Canny (контуры)

Входные данные: изображение с выделенными контурами (Canny edge detection).
Результат: генерация с сохранением формы объектов.

```
Load Image --> Canny Preprocessor --> Apply ControlNet --> KSampler
```

Применение: перерисовка изображения в другом стиле с сохранением композиции.

### Depth (глубина)

Входные данные: карта глубины (Depth Estimator, MiDaS/Zoe).
Результат: генерация с сохранением пространственной глубины.

Применение: замена объектов с сохранением перспективы.

### OpenPose (поза человека)

Входные данные: скелетная карта позы человека.
Результат: генерация с сохранением позы.

Применение: создание персонажа в заданной позе.

### Установка ControlNet моделей

```bash
# Пример: FLUX ControlNet (canny)
huggingface-cli download InstantX/FLUX.1-dev-Controlnet-Canny \
    --local-dir ComfyUI/models/controlnet/
```

Также нужны ноды-препроцессоры. Установка через ComfyUI-Manager: поиск "ControlNet Preprocessors".

## Batch-генерация

Генерация нескольких изображений за один запуск.

### Через batch_size

В ноде **Empty Latent Image** параметр batch_size > 1:
- batch_size: 4 -- генерация 4 изображений с одним промптом и разными seed
- VRAM-потребление увеличивается пропорционально batch_size

При 96 GiB и FLUX Q4_K (~7 GiB модель) реально batch_size до 8-10 на 1024x1024.

### Через несколько KSampler

Для генерации с разными промптами -- дублировать ветку KSampler + CLIP Text Encode.

## Workflow для FLUX (особенности)

FLUX-workflow отличается от SD:

| Элемент | FLUX | SD 3.5 |
|---------|------|--------|
| Model Loader | Unet Loader (GGUF) | Checkpoint Loader / Unet Loader |
| CLIP Loader | DualCLIPLoader (clip_l + t5xxl) | TripleCLIPLoader (clip_g + clip_l + t5xxl) |
| CFG | 1.0 | 7.0-10.0 |
| Negative prompt | Не используется | Обязательно |
| Steps (Dev) | 20-30 | 20-30 |
| Steps (Schnell) | 4 | -- |
| Sampler | euler | dpmpp_2m |
| Scheduler | simple | karras |

## Где скачать готовые workflows

| Источник | Описание |
|----------|----------|
| [comfyanonymous/ComfyUI_examples](https://github.com/comfyanonymous/ComfyUI_examples) | Официальные примеры от авторов ComfyUI |
| [CivitAI](https://civitai.com) | Workflows от сообщества, привязаны к конкретным моделям |
| [OpenArt](https://openart.ai/workflows) | Каталог workflows с превью результатов |

Workflow в ComfyUI сохраняется/загружается как JSON-файл. Drag-and-drop файла в web-интерфейс для загрузки.

## Связанные документы

- [quickstart.md](quickstart.md) -- установка ComfyUI и первый запуск
- [prompting.md](prompting.md) -- составление промптов
- [lora-guide.md](lora-guide.md) -- подключение LoRA в workflows
- [Справочник моделей](../../models/images.md) -- модели, квантизации, VRAM
