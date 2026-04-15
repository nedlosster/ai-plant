# Установка и настройка ComfyUI на Strix Halo

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), Vulkan через ComfyUI-GGUF.

**См. также**: [профиль платформы ComfyUI](../../apps/comfyui/README.md) -- архитектура, философия, ecosystem.

## Архитектура

ComfyUI -- node-based UI для генерации изображений. На Strix Halo (gfx1151) работает через ComfyUI-GGUF -- плагин, загружающий квантизированные diffusion-модели в формате GGUF. Compute выполняется через ggml Vulkan backend.

```
ComfyUI (Python, Web UI :8188)
    |
    +-- ComfyUI-GGUF (custom node)
    |       |
    |       +-- GGUF-модели (FLUX, SD) -- квантизированные (Q4/Q8)
    |       +-- GGUF text encoders (t5xxl Q8)
    |       +-- ggml Vulkan backend
    |
    +-- Стандартные модели (safetensors)
            +-- VAE (ae.safetensors)
            +-- CLIP (clip_l.safetensors)
```

## Предварительные требования

```bash
# python3-venv (Ubuntu)
sudo apt install python3.12-venv
```

## Быстрая установка (через скрипты)

```bash
cd ~/projects/ai-plant

# 1. Установка ComfyUI + venv + ComfyUI-GGUF
./scripts/comfyui/vulkan/install.sh

# 2. Загрузка FLUX.1-schnell + encoders + VAE (~11.5 GiB, через wget)
./scripts/comfyui/vulkan/download-models.sh --minimal

# 3. Диагностика
./scripts/comfyui/vulkan/check.sh

# 4. Запуск
./scripts/comfyui/vulkan/start.sh --daemon

# 5. Web UI
# http://<SERVER_IP>:8188
```

## Ручная установка

### 1. ComfyUI

```bash
git clone https://github.com/comfyanonymous/ComfyUI.git ~/projects/ComfyUI
cd ~/projects/ComfyUI
python3 -m venv venv-vulkan
source venv-vulkan/bin/activate
pip install torch torchvision torchaudio
pip install -r requirements.txt
```

### 2. ComfyUI-GGUF

```bash
cd ~/projects/ComfyUI/custom_nodes
git clone https://github.com/city96/ComfyUI-GGUF.git
pip install -r ComfyUI-GGUF/requirements.txt
```

### 3. Модели

Модели хранятся в `~/models` (общее хранилище с LLM):

```bash
mkdir -p ~/models/{diffusion,clip,vae,loras}
```

ComfyUI подключается через `extra_model_paths.yaml` в корне ComfyUI:

```yaml
ai_plant:
    diffusion_models: ~/models/diffusion
    text_encoders: ~/models/clip
    vae: ~/models/vae
    loras: ~/models/loras
```

### 4. Загрузка моделей FLUX.1

```bash
# FLUX.1-schnell Q4 (~7 GiB, быстрая генерация)
huggingface-cli download city96/FLUX.1-schnell-gguf \
    --include "flux1-schnell-Q4_K_S.gguf" --local-dir ~/models/diffusion

# FLUX.1-dev Q8 (~12 GiB, качественная генерация)
huggingface-cli download city96/FLUX.1-dev-gguf \
    --include "flux1-dev-Q8_0.gguf" --local-dir ~/models/diffusion

# Text encoder: CLIP-L
huggingface-cli download comfyanonymous/flux_text_encoders \
    --include "clip_l.safetensors" --local-dir ~/models/clip

# Text encoder: T5-XXL (GGUF Q8, экономия VRAM)
huggingface-cli download city96/t5-v1_1-xxl-encoder-gguf \
    --include "t5-v1_1-xxl-encoder-Q8_0.gguf" --local-dir ~/models/clip

# VAE
huggingface-cli download black-forest-labs/FLUX.1-schnell \
    --include "ae.safetensors" --local-dir ~/models/vae
```

### 5. Запуск

```bash
cd ~/projects/ComfyUI
source venv-vulkan/bin/activate
# --cpu: PyTorch в CPU-режиме (GPU compute через ComfyUI-GGUF / ggml Vulkan)
python main.py --listen 0.0.0.0 --port 8188 --cpu \
    --extra-model-paths-config extra_model_paths.yaml
```

Web UI: `http://<SERVER_IP>:8188`

## VRAM при генерации

| Модель | Разрешение | VRAM (GGUF) | Время (оценка) |
|--------|------------|-------------|----------------|
| FLUX.1-schnell Q4 | 1024x1024 | ~12 GiB | ~15-30 сек |
| FLUX.1-schnell Q4 | 512x512 | ~8 GiB | ~5-10 сек |
| FLUX.1-dev Q8 | 1024x1024 | ~18 GiB | ~30-60 сек |

120 GiB позволяет генерировать в высоком разрешении без ограничений. Параллельная работа с llama-server (~20 GiB) без проблем.

## Workflow для GGUF-моделей

В ComfyUI Web UI для GGUF-моделей используются специальные ноды из ComfyUI-GGUF:

1. **UnetLoaderGGUF** -- загрузка diffusion-модели (вместо стандартного CheckpointLoader)
2. **CLIPLoaderGGUF** -- загрузка text encoder в GGUF (t5xxl)
3. Стандартные ноды: **CLIPLoader** (clip_l.safetensors), **VAELoader** (ae.safetensors)

Workflow txt2img для FLUX.1-schnell:
```
CLIPLoaderGGUF (t5xxl Q8) -> CLIPTextEncode (prompt)
CLIPLoader (clip_l)        -> CLIPTextEncode (prompt)
UnetLoaderGGUF (schnell Q4) -> KSampler
VAELoader (ae)              -> VAEDecode -> SaveImage
```

## Управление

| Команда | Назначение |
|---------|------------|
| [`./scripts/comfyui/start.sh`](../../../scripts/comfyui/start.sh) `--daemon` | Запуск в фоне |
| [`./scripts/comfyui/stop.sh`](../../../scripts/comfyui/stop.sh) | Остановка |
| [`./scripts/comfyui/status.sh`](../../../scripts/comfyui/status.sh) | Статус, модели, GPU |
| [`./scripts/comfyui/check.sh`](../../../scripts/comfyui/check.sh) | Диагностика |
| [`./scripts/status.sh`](../../../scripts/status.sh) | Общий статус (inference + ComfyUI) |

## Backend'ы

| Backend | Метод | Статус gfx1151 |
|---------|-------|----------------|
| **Vulkan (GGUF)** | ComfyUI-GGUF, квантизированные модели | работает |
| ROCm (PyTorch) | нативные safetensors (fp16/bf16) | segfault |

Vulkan (GGUF) -- рабочий backend. ROCm заработает при исправлении segfault на gfx1151. Скрипты готовы к обоим backend'ам:

```bash
./scripts/comfyui/vulkan/start.sh --daemon    # Vulkan (GGUF)
./scripts/comfyui/rocm/start.sh --daemon      # ROCm (когда заработает)
```

## Известные проблемы

### python3.12-venv

Ubuntu 24.04 не включает `ensurepip` по умолчанию. Без `python3.12-venv` создание venv падает.

```bash
sudo apt install python3.12-venv
```

### torch.cuda.current_device() crash

ComfyUI при запуске вызывает `torch.cuda.current_device()`. На Vulkan-backend (CPU-only PyTorch) это вызывает crash. Решение: флаг `--cpu` (добавлен в start.sh автоматически для vulkan backend).

### FLUX.1 VAE -- gated repository

ae.safetensors из `black-forest-labs/FLUX.1-schnell` требует HF-токен (gated repo). Скрипт download-models.sh использует публичный источник (`camenduru/FLUX.1-dev-diffusers`).

### huggingface-cli зависает на больших файлах

При загрузке файлов >1 GiB `hf download` может зависать на lock-файлах или терять соединение. Скрипт download-models.sh использует wget с resume (`-c`).

## Связанные статьи

- [Модели для изображений](../../models/images.md)
- [Генерация изображений: quickstart](quickstart.md)
- [Workflows](workflows.md)
- [Настройка VRAM](../../platform/vram-allocation.md)
