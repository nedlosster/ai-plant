# ComfyUI: скрипты управления

Генерация изображений через ComfyUI + ComfyUI-GGUF (Vulkan) или PyTorch ROCm.

## Скрипты

| Скрипт | Назначение |
|--------|------------|
| `install.sh` | Установка ComfyUI, venv, plugins |
| `start.sh` | Запуск сервера (foreground / `--daemon`) |
| `stop.sh` | Остановка сервера |
| `status.sh` | Статус: процесс, модели, GPU |
| `check.sh` | Диагностика окружения |
| `download-models.sh` | Загрузка FLUX моделей |

## Быстрый старт

```bash
cd ~/projects/ai-plant

# 1. Установка
./scripts/comfyui/install.sh

# 2. Загрузка моделей (FLUX.1-schnell, ~10 GiB)
./scripts/comfyui/download-models.sh --minimal

# 3. Запуск
./scripts/comfyui/start.sh --daemon

# 4. Web UI
# http://<SERVER_IP>:8188

# 5. Статус
./scripts/comfyui/status.sh

# 6. Остановка
./scripts/comfyui/stop.sh
```

## Backend'ы

| Backend | Метод | Статус gfx1151 |
|---------|-------|----------------|
| Vulkan (GGUF) | ComfyUI-GGUF, квантизированные модели | работает |
| ROCm (PyTorch) | нативные safetensors | segfault |

Явный выбор backend'а:
```bash
./scripts/comfyui/vulkan/start.sh --daemon
./scripts/comfyui/rocm/start.sh --daemon     # segfault на gfx1151
```

## Модели

Хранятся в `~/models/` (общее хранилище с LLM):

```
~/models/
  diffusion/   -- GGUF или safetensors (unet/diffusion)
  clip/        -- text encoders (clip_l, t5xxl)
  vae/         -- VAE (ae.safetensors)
  loras/       -- LoRA
```

ComfyUI подключается через `extra_model_paths.yaml`.

## Документация

- [Установка ComfyUI](../../docs/use-cases/images/comfyui-setup.md)
- [Модели для изображений](../../docs/models/images.md)
