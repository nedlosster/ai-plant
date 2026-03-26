# Ресурсы для генерации изображений

Ссылки на модели, инструменты, сообщества и обучающие материалы.

## Модели и LoRA

### CivitAI (civitai.com)

Крупнейшая платформа для diffusion-моделей:
- Checkpoint-модели (FLUX, SDXL, SD 1.5)
- LoRA-адаптеры (стили, персонажи, концепты)
- Готовые workflows для ComfyUI и Automatic1111
- Галереи примеров с промптами и параметрами

Фильтрация по базовой модели, типу, рейтингу, лицензии.

### HuggingFace

| Репозиторий | Содержимое |
|-------------|-----------|
| [city96](https://huggingface.co/city96) | GGUF-квантизации FLUX, SD 3.5, HiDream, T5-XXL |
| [black-forest-labs](https://huggingface.co/black-forest-labs) | Оригинальные FLUX.1 модели (Dev, Schnell) |
| [stabilityai](https://huggingface.co/stabilityai) | SD 3.5 (Large, Medium), SDXL |
| [comfyanonymous](https://huggingface.co/comfyanonymous) | Text encoders для ComfyUI (flux_text_encoders) |
| [InstantX](https://huggingface.co/InstantX) | ControlNet для FLUX |

## ComfyUI и расширения

### ComfyUI

- Репозиторий: [comfyanonymous/ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- Документация в README и wiki репозитория

### ComfyUI Manager

Менеджер расширений -- установка и обновление custom nodes из web-интерфейса ComfyUI.

```bash
cd ComfyUI/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
```

После установки: в web-интерфейсе появляется кнопка "Manager" для поиска и установки нод.

### Ключевые расширения

| Расширение | Назначение |
|------------|-----------|
| [ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF) | Загрузка GGUF-квантизаций (обязательно для AMD без ROCm) |
| [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager) | Менеджер расширений |
| [comfyui_controlnet_aux](https://github.com/Fannovel16/comfyui_controlnet_aux) | Препроцессоры ControlNet (Canny, Depth, OpenPose) |
| [ComfyUI-Impact-Pack](https://github.com/ltdrdata/ComfyUI-Impact-Pack) | Детектор лиц, сегментация, после-обработка |

## Примеры workflows

| Источник | Описание |
|----------|----------|
| [comfyanonymous/ComfyUI_examples](https://github.com/comfyanonymous/ComfyUI_examples) | Официальные примеры: txt2img, img2img, inpainting, ControlNet |
| [CivitAI](https://civitai.com) | Workflows от пользователей, привязаны к конкретным моделям |
| [OpenArt](https://openart.ai/workflows) | Каталог workflows с превью результатов |

## Сообщества

### Reddit

| Сабреддит | Тематика |
|-----------|----------|
| [r/StableDiffusion](https://reddit.com/r/StableDiffusion) | Общие обсуждения SD, FLUX, промпты, примеры |
| [r/comfyui](https://reddit.com/r/comfyui) | ComfyUI-специфичные вопросы, workflows, расширения |

### Discord

- **ComfyUI Discord** -- ссылка в README репозитория ComfyUI. Каналы по моделям, workflow-sharing, техподдержка.
- **CivitAI Discord** -- обсуждение моделей и LoRA.
- **Stability AI Discord** -- официальный канал Stable Diffusion.

## Обучающие материалы

### YouTube

Поиск по запросам:
- "ComfyUI beginner tutorial" -- вводные гайды
- "ComfyUI FLUX workflow" -- настройка FLUX в ComfyUI
- "ComfyUI ControlNet" -- использование ControlNet
- "LoRA training kohya" -- тренировка LoRA

Рекомендуемые каналы (актуальны на 2025):
- **Scott Detweiler (Pixaroma)** -- регулярные гайды по ComfyUI
- **Olivio Sarikas** -- SD и FLUX workflows
- **Sebastian Kamph** -- ComfyUI продвинутые workflows

### Документация

- [ComfyUI Wiki](https://github.com/comfyanonymous/ComfyUI/wiki) -- официальная документация
- [Stability AI docs](https://platform.stability.ai/docs) -- документация SD моделей

## Связанные документы проекта

- [Справочник моделей](../../models/images.md) -- полный список моделей, квантизации, VRAM
- [quickstart.md](quickstart.md) -- установка и первый запуск
- [lora-guide.md](lora-guide.md) -- поиск и использование LoRA
- [workflows.md](workflows.md) -- описание workflows
