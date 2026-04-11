# ComfyUI: простые сценарии

Базовые workflow'ы для первого знакомства с ComfyUI на Strix Halo. Предполагается, что установка уже выполнена (см. [../../use-cases/images/comfyui-setup.md](../../use-cases/images/comfyui-setup.md)).

## 1. Первый запуск и базовый txt2img (FLUX Q4)

**Задача**: сгенерировать картинку по текстовому промпту. Минимальный workflow для знакомства с интерфейсом.

### Шаги

```bash
cd ~/projects/ai-plant
./scripts/comfyui/vulkan/start.sh --daemon
```

Открыть в браузере `http://<SERVER_IP>:8188`.

В UI автоматически загружается **default workflow** -- стандартный txt2img pipeline. Если он не подходит или ты начинаешь с чистого листа:

1. Кликнуть `Clear` в правом меню (чтобы сбросить граф)
2. Кликнуть `Load Default` -- загрузится минимальный пример

### Минимальный workflow для FLUX GGUF

Набор нод:

```
+---------------------+    +-------------------+    +-------------------+
| UnetLoaderGGUF      |    | DualCLIPLoaderGGUF|    | VAELoader         |
| flux1-schnell-Q4.gguf|   | t5xxl_Q8_0        |    | ae.safetensors    |
|                     |    | clip_l            |    |                   |
|     [MODEL] ──┐     |    |   [CLIP] ──┐      |    |    [VAE] ─┐       |
+---------------------+    +-------------------+    +-------------------+
                │                     │                          │
                │                     ▼                          │
                │       +----------------------+                 │
                │       | CLIPTextEncode       |                 │
                │       | "a photo of a cat"   |                 │
                │       |  [CONDITIONING] ──┐  |                 │
                │       +----------------------+                 │
                │                           │                    │
                ▼                           ▼                    │
         +----------------------------------------------------+  │
         | KSampler                                           |  │
         | seed: 42                                           |  │
         | steps: 4           (FLUX schnell = 4 steps)        |  │
         | cfg: 1.0           (FLUX schnell = 1.0, no guide)  |  │
         | sampler: euler                                     |  │
         | schedule: simple                                   |  │
         |                                                    |  │
         |    [LATENT] ─────────────────────────────┐         |  │
         +----------------------------------------------------+  │
                                                    │            │
                                                    ▼            ▼
                                          +--------------------------+
                                          | VAEDecode                |
                                          |    [IMAGE] ──┐           |
                                          +--------------------------+
                                                         │
                                                         ▼
                                                +------------------+
                                                | SaveImage        |
                                                | filename: test   |
                                                +------------------+
```

Плюс одна нода `EmptyLatentImage` (входит в KSampler как `latent_image`): width=1024, height=1024, batch_size=1.

### Запуск

1. В правой панели кликнуть `Queue Prompt`
2. Смотреть подсветку нод в процессе выполнения
3. Progress-bar в KSampler покажет прогресс sampling'а (4 шага)
4. После VAEDecode -- картинка появляется в ноде SaveImage и сохраняется в `ComfyUI/output/`

Типичная скорость на Strix Halo: ~15-30 секунд на FLUX schnell Q4 1024x1024.

### Что происходит под капотом

1. `UnetLoaderGGUF` -- mmap'ит GGUF-файл U-Net модели в ggml Vulkan
2. `DualCLIPLoaderGGUF` -- загружает два text encoder'а (T5-XXL Q8 + CLIP-L)
3. `CLIPTextEncode` -- токенизирует промпт и прогоняет через CLIP + T5, получает embedding (conditioning)
4. `EmptyLatentImage` -- создаёт пустой тензор в latent space (128×128 латент для 1024×1024 картинки, потому что FLUX использует 8× spatial compression)
5. `KSampler` -- выполняет 4 шага denoising'а начиная с шумного латента, используя conditioning из текста
6. `VAEDecode` -- прогоняет финальный латент через VAE decoder, получает RGB-картинку 1024×1024
7. `SaveImage` -- пишет PNG в `output/`

## 2. txt2img с SD 3.5 Medium

**Задача**: использовать Stable Diffusion 3.5 Medium вместо FLUX. SD 3.5 может быть быстрее на некоторых задачах и лучше для фотореализма.

### Отличия от FLUX workflow

1. Заменить `UnetLoaderGGUF` на `CheckpointLoaderSimple` (если используем полную модель) или оставить GGUF если есть квантизация
2. В `KSampler`: `cfg: 4.5` (SD 3.5 требует CFG > 1.0 для guidance), `steps: 25-30`, `sampler: dpmpp_2m`
3. Для SD 3.5 нужны **три** text encoder'а (CLIP-L, CLIP-G, T5-XXL) -- используется нода `TripleCLIPLoader`

Детальный workflow -- в [`docs/use-cases/images/workflows.md`](../../use-cases/images/workflows.md).

### Загрузка моделей

```bash
# Если SD 3.5 ещё не скачана
./scripts/comfyui/vulkan/download-models.sh --sd3.5
```

## 3. Inpainting (редактирование части картинки)

**Задача**: взять существующую картинку, замаскировать часть и сгенерировать новое содержимое только в маске.

### Нужные ноды дополнительно

- `LoadImage` -- загрузить оригинальную картинку
- `LoadImage (as Mask)` -- загрузить маску (чёрно-белое изображение, белое = где генерировать)
- `VAEEncode (for Inpainting)` -- кодирует оригинал + маску в latent space
- Вместо `EmptyLatentImage` → выход `VAEEncode (for Inpainting)` идёт в `KSampler.latent_image`
- В `KSampler`: `denoise: 0.7` -- только 70% шума добавляется, 30% оригинала сохраняется

### Пошагово

1. Загружаем картинку (drag-and-drop в UI -- автоматически создаёт LoadImage ноду)
2. Правой кнопкой мыши по картинке → "Open in MaskEditor" -- рисуем маску кистью
3. Маска автоматически передаётся в `VAEEncode (for Inpainting)`
4. Промпт описывает что должно быть в маске ("a dog instead of a cat")
5. `KSampler` с denoise=0.7 -- генерирует новое содержимое только в маске, сохраняя фон

## 4. Image-to-image (стилизация существующей картинки)

**Задача**: взять фотографию и сделать её в стиле "oil painting" или "anime".

### Workflow

```
LoadImage → VAEEncode → [LATENT] ──┐
                                   ▼
                               KSampler (denoise: 0.5-0.8)
                                   │
                                   ▼
                               VAEDecode → SaveImage
```

- `denoise: 0.5` -- лёгкая стилизация, сохраняется композиция и формы
- `denoise: 0.8` -- сильная стилизация, остаётся только общий концепт
- `denoise: 1.0` -- полная регенерация, ничего от оригинала не остаётся (эквивалентно txt2img)

Промпт: `"oil painting, vibrant colors, impressionist style, thick brush strokes"` или любой описательный стиль.

## 5. Upscale (увеличение разрешения)

**Задача**: увеличить картинку 1024×1024 до 2048×2048 с сохранением качества.

### Простой способ: latent upscale

```
KSampler → VAEDecode → UpscaleImageBy (latent 2x) → SaveImage
```

Нода `UpscaleImageBy` использует простую билинейную интерполяцию. Быстро, но теряет детали.

### Лучший способ: ESRGAN upscale

Нода `ImageUpscaleWithModel` -- загружает ESRGAN модель (RealESRGAN, 4x-UltraSharp, др.) и применяет её:

```
VAEDecode → ImageUpscaleWithModel (RealESRGAN_x4plus) → SaveImage
```

Требует скачать модель в `models/upscale_models/`. После этого в списке ноды появится опция.

### Ещё лучше: "high-res fix" -- iterative refinement

```
KSampler (1024x1024) → VAEDecode → Upscale (2x) → VAEEncode →
  KSampler (denoise=0.5, 2048x2048) → VAEDecode → SaveImage
```

Сначала генерируем в 1024, потом upscale до 2048, потом ещё проход KSampler с низким denoise. Это добавляет детали, которых не было в маленькой версии.

## 6. Загрузка community workflow из civitai

**Задача**: взять готовый workflow с [civitai.com](https://civitai.com) и запустить локально.

### Шаги

1. На civitai выбрать workflow (обычно картинка-результат с ссылкой "Workflow")
2. Скачать `.json` файл или `.png` (ComfyUI embed'ит workflow в PNG metadata -- можно просто drag-and-drop картинку в UI)
3. В ComfyUI: drag-and-drop JSON / PNG в окно браузера
4. Граф загружается со всеми нодами

Если workflow использует custom_nodes, которых нет локально -- появится сообщение "Missing nodes". Установить через **ComfyUI-Manager**:
- Menu → "Manager" → "Install Missing Custom Nodes"
- Выбрать нужные → Install → перезапустить ComfyUI

## 7. Batch-генерация: несколько картинок за запуск

**Задача**: сгенерировать 10 картинок с разными seed'ами за один Queue Prompt.

### Варианты

**Простой**: в `EmptyLatentImage` поставить `batch_size: 10`. ComfyUI сгенерирует 10 картинок параллельно (в пределах VRAM). Все с одним промптом, но разными начальными шумами.

**Через `RepeatLatentBatch`**: аналогично, но позволяет группировать.

**Через queue + variation**: нажать `Queue Prompt` несколько раз подряд, меняя seed. Каждый запрос идёт в очередь, обрабатывается последовательно. Текущий прогресс виден в UI.

**Программно через API** -- см. [advanced-use-cases.md](advanced-use-cases.md).

## Связанные статьи

- [README.md](README.md) -- обзор профиля
- [architecture.md](architecture.md) -- внутреннее устройство (чтобы понимать что происходит)
- [advanced-use-cases.md](advanced-use-cases.md) -- сложные сценарии: ControlNet, LoRA, API
- [../../use-cases/images/comfyui-setup.md](../../use-cases/images/comfyui-setup.md) -- установка (предусловие)
- [../../use-cases/images/workflows.md](../../use-cases/images/workflows.md) -- детальные workflow-рецепты
- [../../use-cases/images/prompting.md](../../use-cases/images/prompting.md) -- как писать промпты
- [../../models/families/flux.md](../../models/families/flux.md) -- модели FLUX
