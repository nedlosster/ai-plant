# Ресурсы для AI-видеогенерации

## GitHub: модели и инструменты

| Репозиторий | Описание |
|-------------|----------|
| [GitHub](https://github.com/Wan-Video/Wan2.1) | Wan2.1 T2V/I2V -- основная модель для данной платформы |
| [GitHub](https://github.com/THUDM/CogVideo) | CogVideoX 2B/5B -- text-to-video |
| [GitHub](https://github.com/Tencent/HunyuanVideo) | HunyuanVideo 13B |
| [GitHub](https://github.com/genmoai/mochi) | Mochi 1 -- 10B T2V |
| [GitHub](https://github.com/Lightricks/LTX-Video) | LTX Video -- легковесная T2V |
| [GitHub](https://github.com/hpcaitech/Open-Sora) | Open-Sora -- open-source Sora-подобная архитектура |
| [GitHub](https://github.com/guoyww/AnimateDiff) | AnimateDiff -- motion module для SD 1.5 |
| [GitHub](https://github.com/Stability-AI/generative-models) | SVD (Stable Video Diffusion) |

## GitHub: ComfyUI и плагины

| Репозиторий | Описание |
|-------------|----------|
| [GitHub](https://github.com/comfyanonymous/ComfyUI) | Основной инструмент, node-based интерфейс |
| [GitHub](https://github.com/kijai/ComfyUI-WanVideoWrapper) | Плагин для Wan2.1 в ComfyUI |
| [GitHub](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite) | Утилиты для видео: превью, экспорт, конвертация |
| [GitHub](https://github.com/Fannovel16/ComfyUI-Frame-Interpolation) | RIFE/FILM интерполяция кадров |
| [GitHub](https://github.com/ssitu/ComfyUI_UltimateSDUpscale) | Покадровый upscale через Real-ESRGAN |
| [GitHub](https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved) | AnimateDiff для ComfyUI |
| [GitHub](https://github.com/kijai/ComfyUI-CogVideoXWrapper) | CogVideoX для ComfyUI |
| [GitHub](https://github.com/kijai/ComfyUI-HunyuanVideoWrapper) | HunyuanVideo для ComfyUI |

## HuggingFace: модели

| Репозиторий | Описание |
|-------------|----------|
| [HuggingFace](https://huggingface.co/Wan-AI/Wan2.1-T2V-14B) | Wan2.1 14B text-to-video |
| [HuggingFace](https://huggingface.co/Wan-AI/Wan2.1-T2V-1.3B) | Wan2.1 1.3B text-to-video |
| [HuggingFace](https://huggingface.co/Wan-AI/Wan2.1-I2V-14B) | Wan2.1 14B image-to-video |
| [HuggingFace](https://huggingface.co/THUDM/CogVideoX-5b) | CogVideoX 5B |
| [HuggingFace](https://huggingface.co/THUDM/CogVideoX-2b) | CogVideoX 2B |
| [HuggingFace](https://huggingface.co/tencent/HunyuanVideo) | HunyuanVideo |
| [HuggingFace](https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt) | SVD XT |
| [HuggingFace](https://huggingface.co/Lightricks/LTX-Video) | LTX Video |
| [HuggingFace](https://huggingface.co/genmo/mochi-1-preview) | Mochi 1 |

## Reddit

| Сообщество | Описание |
|-----------|----------|
| r/StableDiffusion | Генерация изображений и видео, workflows, модели |
| r/aivideo | AI-видеогенерация, сравнения моделей, примеры |
| r/comfyui | ComfyUI workflows, плагины, помощь |
| r/LocalLLaMA | Локальный AI, обсуждения hardware, AMD ROCm |
| r/AIVideoGeneration | Новости и примеры AI-видео |

## YouTube: туториалы

| Канал / тема | Описание |
|-------------|----------|
| Olivio Sarikas | ComfyUI workflows, видеогенерация, промпт-инжиниринг |
| Sebastian Kamph | Wan2.1 в ComfyUI, пошаговые руководства |
| Pixverse / AI tutorials | Сравнения видеомоделей, tips & tricks |
| Matt Wolfe | Обзоры AI-инструментов, видеогенерация |
| Aitrepreneur | Локальный запуск AI-моделей, AMD GPU |

Поиск по ключевым словам: "Wan2.1 ComfyUI tutorial", "CogVideoX local setup", "AI video generation AMD".

## ComfyUI: расширения для видео

| Расширение | Назначение |
|-----------|-----------|
| ComfyUI-WanVideoWrapper | Wan2.1 T2V/I2V генерация |
| ComfyUI-VideoHelperSuite | Работа с видеофайлами (загрузка, экспорт, превью) |
| ComfyUI-Frame-Interpolation | Интерполяция кадров (RIFE, FILM) |
| ComfyUI-AnimateDiff-Evolved | AnimateDiff motion module |
| ComfyUI-CogVideoXWrapper | CogVideoX генерация |
| ComfyUI-HunyuanVideoWrapper | HunyuanVideo генерация |
| ComfyUI_UltimateSDUpscale | Покадровый upscale |

### Установка расширений

Все расширения устанавливаются одинаково:

```bash
cd ComfyUI/custom_nodes
git clone <URL_репозитория>
cd <имя_расширения>
pip install -r requirements.txt   # если есть
```

После установки -- перезапустить ComfyUI.

## Workflows

Готовые workflows для ComfyUI (JSON-файлы) доступны:

- В репозиториях расширений (каталог `workflows/` или `examples/`)
- На [civitai.com](https://civitai.com) -- раздел Workflows
- На [openart.ai/workflows](https://openart.ai/workflows) -- коллекция workflows
- В Reddit-сообществах (r/comfyui, r/StableDiffusion)

## Утилиты

| Инструмент | Назначение |
|-----------|-----------|
| ffmpeg | Конвертация, обрезка, объединение, масштабирование видео |
| mpv | Воспроизведение видео из терминала |
| ffprobe | Информация о видеофайле (кодек, fps, разрешение) |
| Real-ESRGAN (CLI) | Покадровый upscale вне ComfyUI |

## Документация проекта

| Документ | Описание |
|----------|----------|
| [Справочник моделей](../../models/video.md) | Таблица видеомоделей, VRAM, загрузка |
| [Быстрый старт](quickstart.md) | Wan2.1 1.3B через ComfyUI |
| [Промпт-инжиниринг](prompting.md) | Составление промптов для видео |
| [Продвинутое использование](advanced.md) | 14B, I2V, upscaling, интерполяция |

## Связанные статьи

- [Быстрый старт](quickstart.md)
- [Промпт-инжиниринг](prompting.md)
- [Продвинутое использование](advanced.md)
