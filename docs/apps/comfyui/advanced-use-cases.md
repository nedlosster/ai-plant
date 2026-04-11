# ComfyUI: сложные сценарии

Продвинутые workflow'ы и паттерны использования ComfyUI на Strix Halo. Предусловия: ты прошёл [simple-use-cases.md](simple-use-cases.md), понимаешь [architecture.md](architecture.md), готов работать с custom_nodes и writes Python.

## 1. Multi-model chains: txt2img → upscale → face enhance

**Задача**: сгенерировать портрет FLUX, апскейлить в 2x, улучшить лицо через специализированный face-restorer -- в одном workflow.

### Архитектура

```
FLUX KSampler (1024x1024)
        ↓
    VAEDecode
        ↓
ImageUpscaleWithModel (RealESRGAN_x4plus → 4096x4096)
        ↓
FaceDetailer (GFPGAN или CodeFormer)
        ↓ (только лицо обработано, остальное не тронуто)
    SaveImage
```

### Custom_nodes

- **[ComfyUI-Impact-Pack](https://github.com/ltdrdata/ComfyUI-Impact-Pack)** -- FaceDetailer, ImpactPack, segmentation
- **[ComfyUI_UltimateSDUpscale](https://github.com/ssitu/ComfyUI_UltimateSDUpscale)** -- tiled upscale с overlap
- Face restorers: CodeFormer, GFPGAN, RealESR-GeneralV3 (скачать в `models/upscale_models/` и `models/facerestore_models/`)

### Тонкости

- **VRAM**: 4096×4096 tensor в fp16 = 4096*4096*3*2 = ~100 MB только за картинку, плюс модели. На Strix Halo 120 GiB проходит, на 12 GB GPU нужно `UltimateSDUpscale` с tiling
- **FaceDetailer** внутри себя: детектирует лицо (YOLO-face) → кроп → VAEEncode → KSampler (denoise=0.3, sigma schedule) → VAEDecode → paste back. Это mini-inpainting специально для лица
- **Seed**: в цепочках важно зафиксировать seed каждого sampler'а отдельно, чтобы результаты были reproducible

## 2. ControlNet + LoRA stacking

**Задача**: сгенерировать картинку используя **структуру** одного референса (ControlNet) и **стиль** двух LoRA одновременно.

### ControlNet basics

ControlNet -- отдельная нейросеть, которая принимает "control image" (canny edges, depth map, openpose keypoints, и т.д.) и инжектит это в U-Net на определённых слоях. Результат: генерация следует композиции и геометрии референса.

Типичные ControlNet-модели:
- **Canny**: контурные линии
- **Depth**: карта глубины
- **OpenPose**: скелет человека
- **LineArt**: стилизованные линии
- **Tile**: для upscale/refinement
- **Scribble**: грубые наброски

### Workflow с ControlNet

```
LoadImage (reference) → CannyEdgePreprocessor → [IMAGE] ──┐
                                                           ▼
                                        ControlNetApply (strength=1.0)
                                                           │
LoadControlNetModel (controlnet-canny.safetensors)        │
                    │                                      │
                    ▼                                      │
              [CONTROL_NET] ───────────────────────────────┤
                                                           │
                                                           ▼
CLIPTextEncode (prompt) → [CONDITIONING] → ControlNetApply ← [CONTROL_NET + IMAGE]
                                                           │
                                                           ▼
                                             KSampler (с модифицированным conditioning)
```

Нода `ControlNetApply` **модифицирует conditioning**, инжектя control signal. Результат идёт в KSampler как обычный positive conditioning.

### LoRA stacking

LoRA -- маленький адаптер (обычно 10-500 MB), который модифицирует веса U-Net для определённого стиля/персонажа/концепта. Несколько LoRA можно применить одновременно:

```
CheckpointLoader → [MODEL] ──→ LoraLoader (anime_style, strength=0.8)
                                            ↓
                                       [MODEL] ──→ LoraLoader (detailed_eyes, strength=0.5)
                                                            ↓
                                                       [MODEL] → KSampler
```

Каждый `LoraLoader` принимает на вход `MODEL` и `CLIP`, применяет LoRA-деформацию, возвращает новый `MODEL` и `CLIP`. Chain из 2-3 LoRA -- типичная практика. Больше 5-7 -- обычно ломает качество.

### Важные детали

- **Порядок LoRA**: сильные стилистические LoRA ставить раньше, детальные эффекты позже
- **Strength**: 0.0 = не применяется, 1.0 = полная сила. Типично 0.5-0.8
- **Trigger words**: некоторые LoRA активируются только при наличии специальных слов в промпте
- **LoraLoaderModelOnly**: если LoRA меняет только U-Net без CLIP, используется эта вариация

## 3. API-mode: headless batch-генерация через HTTP

**Задача**: сгенерировать 1000 картинок по списку промптов из CSV, без UI, параллельно с работой других задач.

### Архитектура

ComfyUI -- это HTTP-сервер. Можно не открывать UI вообще, а отправлять workflow JSON через REST API.

### Подготовка workflow

1. В UI собрать нужный workflow
2. Enable "Dev mode" в настройках (правый верх → Settings → Enable Dev mode Options)
3. Save API-version workflow (отдельная кнопка в меню)

API-JSON отличается от UI-JSON: он содержит только нужное для исполнения, без UI-метаданных (позиции, цвета, comments).

Пример API JSON (упрощённый):

```json
{
  "1": {
    "class_type": "CheckpointLoaderSimple",
    "inputs": {
      "ckpt_name": "flux1-schnell-Q4_K_S.gguf"
    }
  },
  "2": {
    "class_type": "CLIPTextEncode",
    "inputs": {
      "clip": ["1", 1],
      "text": "{{PROMPT}}"
    }
  },
  "3": {
    "class_type": "KSampler",
    "inputs": {
      "model": ["1", 0],
      "positive": ["2", 0],
      "seed": 42,
      "steps": 4,
      "cfg": 1.0,
      "sampler_name": "euler",
      "scheduler": "simple"
    }
  }
}
```

### Python client для batch

```python
import requests, json, uuid

COMFY_URL = "http://192.168.1.77:8188"
client_id = str(uuid.uuid4())

with open("workflow_api.json") as f:
    workflow = json.load(f)

prompts = [
    "a cat in a hat",
    "a dog on a skateboard",
    # ... 1000 строк
]

for i, prompt in enumerate(prompts):
    workflow["2"]["inputs"]["text"] = prompt
    workflow["3"]["inputs"]["seed"] = i  # разный seed для каждой

    response = requests.post(
        f"{COMFY_URL}/prompt",
        json={"prompt": workflow, "client_id": client_id}
    )
    prompt_id = response.json()["prompt_id"]
    print(f"{i+1}/{len(prompts)}: queued {prompt_id}")
```

ComfyUI поставит все 1000 prompt'ов в очередь и будет обрабатывать их последовательно. На Strix Halo с FLUX Q4 это займёт ~5-8 часов.

### Endpoints

| Endpoint | Назначение |
|----------|------------|
| `POST /prompt` | Поставить workflow в очередь |
| `GET /queue` | Текущее состояние очереди |
| `GET /history/{prompt_id}` | Результат выполнения (outputs) |
| `GET /view?filename=...` | Скачать сгенерированную картинку |
| `POST /interrupt` | Прервать текущий prompt |
| `POST /queue` с `{"clear": true}` | Очистить очередь |
| `GET /object_info` | Список всех доступных нод и их input/output типов |

### WebSocket для streaming

Подключиться к `ws://host:8188/ws?clientId=...` -- получать real-time события:
- `progress` -- прогресс текущего sampling'а
- `executing` -- какая нода выполняется
- `executed` -- нода завершена, outputs доступны

Полезно для live UI-клиентов или мониторинга batch-пайплайна.

## 4. Video workflow: Wan 2.7 I2V через ComfyUI-WanVideoWrapper

**Задача**: взять статичную картинку и превратить её в 5-секундное видео с motion.

### Custom_node

**[ComfyUI-WanVideoWrapper](https://github.com/kijai/ComfyUI-WanVideoWrapper)** от kijai -- wrapper для семейства Wan моделей в ComfyUI. Добавляет ноды для загрузки Wan, sampling video, сохранения mp4.

### Нужные модели

```bash
# Wan 2.7 I2V в нужной квантизации (~20 GB)
hf download Wan-AI/Wan2.7-I2V-14B --local-dir ~/models/wan
```

### Workflow структура (упрощённо)

```
LoadImage (референс картинка)
    ↓
WanImageToVideo (загружает картинку в video latent)
    ↓
WanModelLoader (загружает Wan 2.7 I2V 14B)
    ↓ [MODEL]
CLIPTextEncode (промпт описывает motion: "camera slowly zooms in, leaves swaying")
    ↓ [CONDITIONING]
WanVideoSampler (denoise video latent)
    ↓ [VIDEO_LATENT]
WanVAEDecode (VAE decoder для video)
    ↓ [IMAGE_SEQUENCE]
VideoCombine (собирает кадры в mp4 с нужным fps)
    ↓
SaveVideo
```

### Параметры Wan 2.7

- `num_frames`: обычно 81 (для 5 секунд при 16 fps) или 101 (при 20 fps)
- `fps`: 16 или 20
- `resolution`: 832×480 или 1024×576
- `sampler_steps`: 30
- `cfg`: 5.0 (Wan требует CFG > 1)

### VRAM и производительность

- **fp16 14B**: ~30 GB VRAM для модели + ~20 GB для video latent
- **Strix Halo**: всё помещается в 120 GiB
- **Время**: ~30-60 минут на 5 секунд 832×480 (memory-bound)

См. [`docs/use-cases/video/advanced.md`](../../use-cases/video/advanced.md) для детальных рецептов видео.

## 5. Custom_node разработка

**Задача**: написать свой custom_node для специфичной задачи.

### Минимальный шаблон (V3 schema)

```python
# ComfyUI/custom_nodes/my_node_pack/__init__.py

class ImageBrightnessBoost:
    """Увеличивает яркость изображения."""

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "image": ("IMAGE",),
                "brightness": ("FLOAT", {
                    "default": 1.0,
                    "min": 0.0,
                    "max": 2.0,
                    "step": 0.01,
                    "display": "slider"
                }),
            }
        }

    RETURN_TYPES = ("IMAGE",)
    RETURN_NAMES = ("brightened_image",)
    FUNCTION = "boost"
    CATEGORY = "my_pack/effects"
    DESCRIPTION = "Multiplies image values by brightness factor"

    @classmethod
    def boost(cls, image, brightness):
        # image shape: [batch, height, width, 3] в ComfyUI
        result = image * brightness
        result = result.clamp(0.0, 1.0)
        return (result,)


NODE_CLASS_MAPPINGS = {
    "ImageBrightnessBoost": ImageBrightnessBoost,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "ImageBrightnessBoost": "Image Brightness Boost",
}
```

### Что важно

- `INPUT_TYPES` возвращает словарь с типами входов. Типы могут быть `"IMAGE"`, `"MODEL"`, `"CLIP"`, `"LATENT"`, `"FLOAT"`, `"INT"`, `"STRING"`, кастомные
- `RETURN_TYPES` -- tuple с типами выходов
- `FUNCTION` -- имя метода-исполнителя
- `CATEGORY` -- куда в menu добавить ноду
- `execute` (или другой метод с именем из `FUNCTION`) -- получает входы как kwargs, возвращает tuple outputs
- **Tensors shape**: images в ComfyUI -- `[batch, H, W, C]`, latents -- `[batch, C, H/8, W/8]`
- **Device**: inputs могут быть на GPU, работать нужно в том же device

### Установка

1. Создать папку в `ComfyUI/custom_nodes/my_node_pack/`
2. Положить `__init__.py` с определением нод
3. Перезапустить ComfyUI
4. Нода появится в menu → "my_pack/effects" → "Image Brightness Boost"

### Publish

Чтобы сделать доступным через ComfyUI-Manager -- запушить в GitHub, добавить `pyproject.toml` с metadata, отправить PR в реестр ComfyUI-Manager. После этого установка через Manager идёт автоматически.

## 6. Prompt scheduling: разные промпты на разных шагах

**Задача**: в течение одного sampling'а менять промпт. Например, первые 10 шагов -- "a cat in a forest", последние 20 шагов -- "the cat is smiling".

### Решение: ConditioningTimestepRange

Ноды из custom_node **[ComfyUI-Advanced-ControlNet](https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet)** и `ConditioningTimestepRange` (built-in):

```
CLIPTextEncode ("a cat in a forest")  →  ConditioningTimestepRange (start=0.0, end=0.3)
                                                      ↓
                                        ConditioningCombine
                                                      ↑
CLIPTextEncode ("the cat is smiling")  →  ConditioningTimestepRange (start=0.3, end=1.0)
                                                      ↓
                                                   [CONDITIONING] → KSampler
```

ComfyUI применит первый conditioning на steps 0-30% denoising (формирует общую композицию), второй -- на 30-100% (детали выражения).

### Практические применения

- **Multi-subject scenes**: начальный промпт -- композиция, поздний -- детали каждого субъекта
- **Style transition**: начало -- раскраска, конец -- стиль
- **Adjective emphasis**: общие атрибуты рано, специфичные поздно

## 7. Регионная генерация: разные промпты в разных частях картинки

**Задача**: в левой половине картинки сгенерировать кота, в правой -- собаку, чтобы они не смешивались.

### Решение: Regional Prompter

Через custom_node **[ComfyUI-Advanced-ControlNet](https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet)** или **[ComfyUI_Comfyroll_CustomNodes](https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes)**. Идея:

1. Создать маски: `mask_left` (левая половина белая), `mask_right` (правая половина белая)
2. CLIPTextEncode("a cat") + маска left → conditioning с attention только в левой
3. CLIPTextEncode("a dog") + маска right → conditioning с attention только в правой
4. ConditioningCombine → KSampler

Результат: два субъекта в нужных регионах без смешивания.

Это сложная техника, но очень мощная для character-in-scene композиций и multi-entity генерации.

## 8. Production: ComfyUI как микросервис

**Задача**: встроить ComfyUI в production-пайплайн, где он обрабатывает запросы от web-приложения.

### Архитектура

```
User request (web UI или mobile app)
    ↓
Your API server (FastAPI / Node / etc)
    ↓
ComfyUI REST API (POST /prompt)
    ↓
ComfyUI queue → graph execution
    ↓
Ваш API забирает результат (GET /history)
    ↓
Возвращает user'у
```

### Вопросы production

- **Queue management**: ComfyUI имеет single-threaded queue. Для параллельной обработки нескольких пользователей нужны несколько инстансов
- **Monitoring**: health check через `GET /system_stats`, endpoint `/queue` для метрик
- **Scaling**: запуск нескольких ComfyUI на одном сервере с разными портами + load balancer
- **Persistence**: сгенерированные картинки по умолчанию сохраняются локально, нужно организовать сброс в S3/Minio
- **Authentication**: ComfyUI не имеет встроенной auth, нужен reverse proxy (nginx + basic auth или JWT)
- **Rate limiting**: через proxy
- **Model management**: custom_nodes и модели синхронизируются между инстансами через shared filesystem или image baking

### Альтернатива: Serverless ComfyUI

Проекты типа **[Comfy Deploy](https://comfydeploy.com)** или **[RunComfy](https://www.runcomfy.com)** дают managed ComfyUI как API. Пользователь загружает workflow, получает endpoint для вызовов. Это обёртка, но снимает operational overhead.

## Связанные статьи

- [README.md](README.md) -- обзор профиля
- [architecture.md](architecture.md) -- для понимания async graph execution
- [simple-use-cases.md](simple-use-cases.md) -- предусловия, базовые паттерны
- [../../use-cases/images/workflows.md](../../use-cases/images/workflows.md) -- готовые image workflow
- [../../use-cases/video/advanced.md](../../use-cases/video/advanced.md) -- video workflow, API-режим
- [../../use-cases/video/resources.md](../../use-cases/video/resources.md) -- список custom_nodes для видео
- [../../models/families/flux.md](../../models/families/flux.md), [../../models/families/wan.md](../../models/families/wan.md), [../../models/families/ltx-2.md](../../models/families/ltx-2.md) -- модели для ComfyUI
