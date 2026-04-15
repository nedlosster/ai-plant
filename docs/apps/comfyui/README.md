# ComfyUI

Node-based workflow engine для diffusion-моделей (картинки, видео, аудио, multi-modal). Автор -- comfyanonymous (2023), с 2025 под организацией Comfy-Org. Стандарт индустрии для сложных diffusion-пайплайнов с точным контролем каждого шага.

**Тип**: Python-приложение + Web UI (client-server)
**Лицензия**: GPL-3.0
**Статус на платформе**: работает через ggml Vulkan backend (ComfyUI-GGUF) и через PyTorch ROCm
**Порт по умолчанию**: 8188

## Когда использовать

- Генерация картинок с точным контролем каждого шага (FLUX, SD 3.5, HiDream)
- Генерация видео (Wan 2.7, LTX-2, HunyuanVideo, CogVideoX)
- Мульти-ступенчатые pipeline: txt2img → upscale → inpaint → face enhancer
- Автоматизация diffusion через API (headless ComfyUI)
- Кастомные workflow с ControlNet, LoRA stacking, IPAdapter

**Не для**: chat с LLM (для этого [Open WebUI](../open-webui/README.md) или [LobeChat](../lobe-chat/README.md)), coding (для этого [AI-агенты](../../ai-agents/README.md)), музыка-генерации (для этого [ACE-Step](../ace-step/README.md)).

## Файлы раздела

| Файл | О чём |
|------|-------|
| [introduction.md](introduction.md) | Что это, история (2023+), философия, позиционирование против A1111 и SwarmUI |
| [architecture.md](architecture.md) | Async graph execution engine, custom_nodes V3 schema, workflow JSON, client-server, model loaders, ComfyUI-GGUF path на Vulkan |
| [simple-use-cases.md](simple-use-cases.md) | txt2img через FLUX, txt2video через Wan, upscale, inpaint, первый запуск |
| [advanced-use-cases.md](advanced-use-cases.md) | Multi-model chains, ControlNet+LoRA stacking, API-mode, headless, batch, custom_nodes |

## Статус на Strix Halo

| Компонент | Состояние |
|-----------|-----------|
| ComfyUI core | установлен через [`scripts/comfyui/vulkan/install.sh`](../../../scripts/comfyui/vulkan/install.sh) |
| ComfyUI-Manager | установлен |
| ComfyUI-GGUF | установлен (загрузка GGUF-моделей через ggml Vulkan) |
| FLUX.1-schnell Q4_K_S | скачан (минимальный набор через `download-models.sh --minimal`) |
| T5-XXL Q8_0 | скачан |
| CLIP-L | скачан |
| Vulkan backend | основной, работает стабильно |
| ROCm backend | альтернативный, через [`scripts/comfyui/rocm/`](../../../scripts/comfyui/rocm/) |

## Быстрый старт

```bash
cd ~/projects/ai-plant
./scripts/comfyui/vulkan/install.sh
./scripts/comfyui/vulkan/download-models.sh --minimal
./scripts/comfyui/vulkan/check.sh
./scripts/comfyui/vulkan/start.sh --daemon
# Web UI: http://<SERVER_IP>:8188
```

Детали установки -- в [../../use-cases/images/comfyui-setup.md](../../use-cases/images/comfyui-setup.md). Этот раздел не дублирует гайд установки, а описывает саму платформу концептуально.

## Ссылки

- Официальный GitHub: [Comfy-Org/ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- Официальная документация: [docs.comfy.org](https://docs.comfy.org)
- ComfyUI-Manager: [Comfy-Org/ComfyUI-Manager](https://github.com/Comfy-Org/ComfyUI-Manager)
- ComfyUI-GGUF: [city96/ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF)
- Awesome ComfyUI: [ComfyUI-Workflow/awesome-comfyui](https://github.com/ComfyUI-Workflow/awesome-comfyui)

## Связанные статьи

- [introduction.md](introduction.md) -- начать отсюда, если первый раз видишь ComfyUI
- [../../use-cases/images/comfyui-setup.md](../../use-cases/images/comfyui-setup.md) -- установка на Strix Halo
- [../../use-cases/images/workflows.md](../../use-cases/images/workflows.md) -- готовые workflow для картинок
- [../../use-cases/video/quickstart.md](../../use-cases/video/quickstart.md) -- ComfyUI для видеогенерации
- [../../models/families/flux.md](../../models/families/flux.md), [../../models/families/ltx-2.md](../../models/families/ltx-2.md) -- модели для ComfyUI
- [../../../scripts/comfyui/README.md](../../../scripts/comfyui/README.md) -- bash-скрипты управления
