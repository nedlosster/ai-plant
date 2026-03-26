# Генерация изображений

Практические руководства по генерации изображений на Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти).

## Основной инструмент

**ComfyUI** -- node-based интерфейс для работы с diffusion-моделями. На Strix Halo работает через **ComfyUI-GGUF** (city96) -- плагин для GGUF-квантизаций, compute через ggml Vulkan backend.

Скрипты управления: `scripts/comfyui/` (install, start, stop, status, check, download-models).

## Ключевые модели

| Модель | Параметры | Особенности |
|--------|-----------|-------------|
| FLUX.1 Dev | 12B | Лучшее качество, промпты естественным языком |
| FLUX.1 Schnell | 12B | Быстрая генерация (4 шага), Apache 2.0 |
| SD 3.5 Large | 8B | Стабильное качество, широкая экосистема LoRA |
| HiDream-I1 Full | 17B | Apache 2.0, конкурент FLUX по качеству |

Полный справочник моделей: [docs/models/images.md](../../models/images.md).

## Преимущества 120 GiB GPU-памяти

- Любая модель в FP16/Q8 без квантизации
- Batch-генерация нескольких изображений одновременно
- Высокое разрешение (2048x2048+) без tiling
- Загрузка нескольких моделей в память параллельно
- ControlNet + базовая модель + LoRA без ограничений по памяти

## Документы раздела

| Документ | Описание |
|----------|----------|
| [comfyui-setup.md](comfyui-setup.md) | Установка ComfyUI + GGUF на Strix Halo, скрипты, backend'ы |
| [quickstart.md](quickstart.md) | Установка ComfyUI, загрузка модели, первое изображение |
| [prompting.md](prompting.md) | Промпт-инжиниринг: структура, стили, примеры |
| [workflows.md](workflows.md) | ComfyUI workflows: txt2img, img2img, inpainting, upscale, ControlNet |
| [lora-guide.md](lora-guide.md) | LoRA: поиск, использование, стекинг, тренировка |
| [resources.md](resources.md) | Ссылки на модели, сообщества, обучающие материалы |

## Рекомендуемый порядок чтения

1. **quickstart.md** -- установка и запуск, первый результат
2. **prompting.md** -- научиться формулировать запросы
3. **workflows.md** -- освоить пайплайны ComfyUI
4. **lora-guide.md** -- расширить возможности моделей
5. **resources.md** -- где искать модели, LoRA, workflows
