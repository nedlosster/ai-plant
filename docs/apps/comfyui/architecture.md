# ComfyUI: архитектура

Внутреннее устройство ComfyUI: клиент-серверная структура, async graph execution engine, workflow JSON, custom_nodes, model loaders, V3 schema, ComfyUI-GGUF path на Strix Halo. Самая глубокая часть документации по ComfyUI.

## Общая схема

ComfyUI -- **client-server приложение** на Python:

```
+---------------------------+
|  Web UI (JavaScript SPA)  |      <- пользователь взаимодействует отсюда
|  - LiteGraph.js           |
|  - WebSocket client       |
+------------+--------------+
             |
             |  HTTP REST + WebSocket
             |  :8188
             v
+---------------------------+
|  ComfyUI Server (Python)  |      <- ядро движка
|  - HTTP routes            |
|  - WebSocket handler      |
|  - PromptQueue            |
|  - Graph executor         |
|  - Node registry          |
+------------+--------------+
             |
             |  import / instantiate
             v
+---------------------------+
|  Built-in nodes           |
|  + Custom nodes (Python)  |
+------------+--------------+
             |
             |  tensor operations
             v
+---------------------------+
|  PyTorch (CUDA / ROCm /   |
|          MPS / CPU)       |
|  -- ИЛИ --                |
|  ComfyUI-GGUF → ggml      |
|          Vulkan backend   |
+---------------------------+
```

Ключевые компоненты:

| Компонент | Что делает |
|-----------|------------|
| **Web UI (JS)** | LiteGraph.js -- визуальный редактор графа. Пользователь рисует ноды, соединяет. Отправляет workflow как JSON через HTTP POST |
| **ComfyUI Server (Py)** | FastAPI-подобный HTTP-сервер. Принимает workflow, ставит в очередь (PromptQueue), исполняет |
| **PromptQueue** | In-memory FIFO очередь. Может держать несколько prompt'ов в ожидании |
| **Graph executor** | Разбирает граф, определяет порядок выполнения (topological sort), вызывает ноды по одной |
| **Node registry** | Каталог всех известных нод. Заполняется при старте: built-in + сканирование `custom_nodes/` |
| **Custom nodes** | Python-модули, зарегистрированные в registry. Каждый модуль описывает 1+ нод |
| **PyTorch** | Выполнение тензорных операций. Или через nVidia CUDA, AMD ROCm, Apple MPS, или ggml Vulkan backend |

## Workflow JSON: структура данных

Workflow в ComfyUI -- **JSON-документ**. Это и есть основной формат данных платформы. Сохранив workflow, ты получаешь полный рецепт, который можно открыть на любом ComfyUI-инстансе.

Структура (упрощённая, реальный файл -- сотни строк):

```json
{
  "last_node_id": 42,
  "last_link_id": 57,
  "nodes": [
    {
      "id": 1,
      "type": "CheckpointLoaderSimple",
      "pos": [100, 100],
      "size": [315, 98],
      "widgets_values": ["flux1-schnell-Q4_K_S.gguf"],
      "outputs": [
        { "name": "MODEL", "type": "MODEL", "links": [1] },
        { "name": "CLIP",  "type": "CLIP",  "links": [2] },
        { "name": "VAE",   "type": "VAE",   "links": [3] }
      ]
    },
    {
      "id": 2,
      "type": "CLIPTextEncode",
      "inputs": [
        { "name": "clip", "type": "CLIP", "link": 2 }
      ],
      "widgets_values": ["a photo of a cat"],
      "outputs": [
        { "name": "CONDITIONING", "type": "CONDITIONING", "links": [4] }
      ]
    },
    {
      "id": 3,
      "type": "KSampler",
      "inputs": [
        { "name": "model",     "link": 1  },
        { "name": "positive",  "link": 4  },
        { "name": "negative",  "link": 5  },
        { "name": "latent_image", "link": 6 }
      ],
      "widgets_values": [42, "fixed", 4, 1.0, "euler", "simple", 1.0],
      "outputs": [
        { "name": "LATENT", "type": "LATENT", "links": [7] }
      ]
    }
    // ... VAEDecode, SaveImage, etc.
  ],
  "links": [
    [1, 1, 0, 3, 0, "MODEL"],
    [2, 1, 1, 2, 0, "CLIP"],
    // ...
  ]
}
```

Ключевые концепты в структуре:

- **`nodes`** -- массив узлов. Каждый узел имеет `id`, `type` (имя класса ноды из registry), `inputs`/`outputs`, `widgets_values` (значения UI-виджетов)
- **`links`** -- соединения между узлами в формате `[link_id, from_node, from_slot, to_node, to_slot, type]`
- **`type`** -- имя класса ноды (`CheckpointLoaderSimple`, `CLIPTextEncode`, `KSampler`, ...). Должно существовать в registry на момент загрузки
- **`widgets_values`** -- позиционные значения UI-виджетов ноды (seed, step count, CFG, промпт-текст и т.д.)

Когда пользователь нажимает "Queue Prompt", Web UI преобразует визуальный граф в этот JSON и отправляет `POST /prompt`. Сервер разбирает JSON, проверяет что все типы и связи валидны, ставит в PromptQueue.

## Async graph execution engine

Главная инженерная идея ComfyUI. Исполнитель графа работает так:

### 1. Topological sort

Граф `nodes + links` -- это направленный ациклический граф (DAG). Исполнитель делает топологическую сортировку: порядок, в котором каждая нода появляется **после** всех своих зависимостей. Классический Kahn's algorithm или DFS-based.

Пример: `Loader → CLIPTextEncode → KSampler → VAEDecode → SaveImage`. Топологический порядок -- слева направо, потому что каждая нода зависит от выхода предыдущей.

### 2. Caching с hash-based invalidation

Ключевая фишка: **только те ноды, которые изменились или зависят от изменённых, будут выполнены заново**.

Как работает: для каждой ноды считается hash от её `widgets_values` + hash'ей всех входных выходов (тензоров). Если на втором запуске hash ноды совпадает с hash'ем прошлого -- используется cached result. Если hash изменился -- нода выполняется заново, и все downstream-ноды тоже (они получили новый input).

Это означает:
- Поменял промпт -- заново выполняются только CLIPTextEncode → KSampler → VAEDecode → SaveImage. Loader не выполняется (модель уже в памяти)
- Поменял seed -- только KSampler → VAEDecode → SaveImage. CLIPTextEncode не выполняется (conditioning не менялся)
- Поменял VAE decoder -- только VAEDecode → SaveImage. Sampler не выполняется

На практике это даёт **на порядок быстрее итерации**. Classic diffusion UI перезагружает модель при каждом запуске, ComfyUI -- только при изменении. При iterative prompt tweaking это экономит минуты.

### 3. Execution

Для каждой ноды в порядке топологической сортировки:
1. Проверить cache (hash check)
2. Если cache miss -- вызвать Python метод ноды (обычно `execute(self, **kwargs)`), передав ей inputs
3. Сохранить outputs как промежуточные tensor'ы
4. Передать outputs downstream-нодам через links

Вычисления идут через PyTorch (или через ggml Vulkan в ComfyUI-GGUF). Тензоры остаются на GPU между нодами (нет копирований в RAM если не нужно).

### 4. Streaming результата в UI

Через WebSocket ComfyUI стримит обновления в Web UI:
- `executing` -- какая нода сейчас выполняется
- `progress` -- % прогресса sampling'а внутри KSampler (для visual feedback)
- `executed` -- нода завершена
- `executing` с `node=null` -- весь workflow завершён

Пользователь видит визуально, как подсвечивается активная нода и растёт прогресс-бар.

## Node registry и custom_nodes

### Built-in nodes

ComfyUI имеет ~100 built-in нод в `comfy/nodes.py` и `comfy_extras/`. Это базовые блоки: loaders (Checkpoint, VAE, LoRA, ControlNet), encoders (CLIP, T5), samplers (KSampler, SDESampler, BrownianSampler), decoders (VAEDecode), latent ops (Upscale, Crop, Mask), output (Save, Preview).

### Custom nodes (расширения)

Директория `custom_nodes/` сканируется при старте. Каждая папка содержит Python-модуль, регистрирующий новые ноды:

```python
# ComfyUI/custom_nodes/my_node/__init__.py

class MyCustomNode:
    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "image": ("IMAGE",),
                "strength": ("FLOAT", {"default": 1.0, "min": 0.0, "max": 2.0}),
            }
        }

    RETURN_TYPES = ("IMAGE",)
    FUNCTION = "process"
    CATEGORY = "my_category"

    def process(self, image, strength):
        # обработка
        return (processed_image,)


NODE_CLASS_MAPPINGS = {
    "MyCustomNode": MyCustomNode,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "MyCustomNode": "My Custom Node",
}
```

При старте ComfyUI импортирует все модули в `custom_nodes/`, читает `NODE_CLASS_MAPPINGS`, добавляет классы в registry. После этого ноды доступны в UI.

### V3 schema (2026)

В начале 2026 ComfyUI начал миграцию на **V3 schema** для custom nodes. Ключевые изменения:

- **Stateless execution**: метод `execute` становится `@classmethod`, получает `cls` вместо `self`. Никакого `self.state = ...` -- каждое выполнение изолировано
- **Caching API**: для дорогих computation -- явный caching через `cls.cache_get()` / `cls.cache_set()`. Раньше делали через instance variables, что не надёжно
- **Process isolation (future)**: в дальнейшем каждый node pack будет жить в отдельном Python-процессе -- одна зависимость не сможет "отравить" другие (классическая проблема `transformers` vs `diffusers` vs `torch` из разных custom_nodes)
- **Type-safe inputs**: более строгая схема описания входов с поддержкой Python type hints

Старый V1 schema поддерживается, но новые ноды рекомендуется писать под V3.

### ComfyUI-Manager

Extension [`ComfyUI-Manager`](https://github.com/Comfy-Org/ComfyUI-Manager) -- **пакетный менеджер для custom_nodes**. Устанавливает/обновляет/удаляет ноды через UI, показывает rating, managed-список проверенных плагинов, hub with workflow-шаблонами. Де-факто обязательное расширение для любого production-инстанса.

## Model loaders: разные пути

ComfyUI поддерживает несколько форматов моделей через специализированные loader-ноды:

| Формат | Loader-нода | Файлы | Путь |
|--------|-------------|-------|------|
| safetensors (полная) | `CheckpointLoaderSimple` | `.safetensors` | `models/checkpoints/` |
| safetensors (split components) | `UNETLoader`, `DualCLIPLoader`, `VAELoader` | отдельные файлы | `models/unet/`, `models/clip/`, `models/vae/` |
| **GGUF** | `UnetLoaderGGUF` (из ComfyUI-GGUF) | `.gguf` | `models/unet/` |
| LoRA | `LoraLoader` | `.safetensors` с LoRA-структурой | `models/loras/` |
| ControlNet | `ControlNetLoader` | `.safetensors` | `models/controlnet/` |

Каждый loader выдаёт на выход типизированные выходы (`MODEL`, `CLIP`, `VAE`), которые потом подключаются к остальным нодам. Это обеспечивает type-safety: ты не можешь случайно подключить `LoRA` туда где ожидается `MODEL`.

## ComfyUI-GGUF: путь через ggml Vulkan на Strix Halo

На нашей платформе (Radeon 8060S, gfx1151) основной путь -- **[ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF)** от city96. Это custom_node, который добавляет альтернативный inference path через ggml Vulkan backend:

```
Standard PyTorch path:
  .safetensors → torch.load() → torch tensors → CUDA/ROCm/Vulkan (PyTorch backend)

ComfyUI-GGUF path:
  .gguf → ggml loader → ggml tensors → ggml Vulkan shader (прямой SPIR-V)
```

### Зачем отдельный путь

- **Квантизация в GGUF** даёт Q4_K_S, Q4_K_M, Q8_0 для diffusion-моделей (FLUX -- с 23 GB до 6 GB)
- **ggml Vulkan backend** не требует ROCm -- работает через Mesa RADV, который на gfx1151 стабильнее чем PyTorch ROCm
- **Меньший VRAM footprint** -- для FLUX fp16 нужно 24+ GB, для FLUX GGUF Q4_K_S -- ~8 GB
- **Быстрее первый запуск** -- ggml mmap'ит файл сразу, PyTorch копирует в VRAM

### Какие ноды добавляются

- `UnetLoaderGGUF` -- загружает `.gguf` U-Net модели (FLUX, SD 3.5, HiDream)
- `DualCLIPLoaderGGUF` -- загружает text encoder (T5-XXL) в GGUF
- `UnetLoaderGGUFAdvanced` -- управление offload и split

Workflow для FLUX в ComfyUI-GGUF выглядит практически идентично стандартному, только loader-ноды заменены на GGUF-варианты. Всё остальное (CLIPTextEncode, KSampler, VAEDecode, SaveImage) -- стандартные.

Подробнее -- в [../../use-cases/images/comfyui-setup.md](../../use-cases/images/comfyui-setup.md) и [../../models/families/flux.md](../../models/families/flux.md).

## Memory management и оптимизации

### Automatic memory management

ComfyUI автоматически выгружает компоненты из VRAM когда они не нужны:

1. Пользователь запускает workflow с U-Net + CLIP + VAE
2. Сначала выполняется CLIPTextEncode (CLIP в VRAM, U-Net в RAM)
3. Перед KSampler -- выгружается CLIP, загружается U-Net в VRAM
4. После KSampler -- выгружается U-Net, загружается VAE в VRAM для декодирования
5. После VAEDecode -- VAE тоже выгружается

Это позволяет запускать 24 GB-модель на 12 GB VRAM GPU. На Strix Halo с 120 GiB такой оптимизации не требуется (всё помещается), но она всё равно активна.

### `--lowvram`, `--highvram`, `--gpu-only`

Флаги запуска, управляющие стратегией:
- `--lowvram` -- агрессивный offload, подходит для 8 GB VRAM
- `--normalvram` (default) -- баланс
- `--highvram` -- не выгружает ничего, всё в VRAM (быстрее, но требует много памяти)
- `--gpu-only` -- ничего не использует CPU, всё на GPU
- `--cpu` -- fallback на CPU (медленно, для отладки)

На Strix Halo обычно используется `--normalvram` или `--highvram`.

### Preview-режим для sampling

Во время sampling (50+ шагов denoising) ComfyUI может показывать preview каждые N шагов. Опции:
- `none` -- без preview (быстрее всего)
- `latent2rgb` -- быстрый low-quality preview через линейную проекцию latent в RGB
- `taesd` -- качественный preview через TAESD (маленький VAE decoder)

## Связанные статьи

- [README.md](README.md) -- обзор профиля
- [introduction.md](introduction.md) -- что это, история, философия
- [simple-use-cases.md](simple-use-cases.md) -- базовые сценарии
- [advanced-use-cases.md](advanced-use-cases.md) -- сложные сценарии, API, batch
- [../../use-cases/images/comfyui-setup.md](../../use-cases/images/comfyui-setup.md) -- установка на Strix Halo
- [../../use-cases/images/workflows.md](../../use-cases/images/workflows.md) -- готовые workflow
- [../../llm-guide/quantization.md](../../llm-guide/quantization.md) -- K-quants и IQ-quants (ComfyUI-GGUF использует их же)
