#!/bin/bash
# Установка ComfyUI + зависимости + plugins
# Backend: AI_BACKEND=vulkan|rocm (или автодетект)
# Использование: ./scripts/comfyui/install.sh [--clean]

set -euo pipefail
source "$(dirname "$0")/common/config.sh"

CLEAN=false
[[ "${1:-}" == "--clean" ]] && CLEAN=true

echo "=== Установка ComfyUI (backend: $BACKEND) ==="
echo ""

# --- 1. Клонирование ComfyUI ---
if [[ ! -d "$COMFYUI_DIR" ]]; then
    echo "[1/6] Клонирование ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
else
    echo "[1/6] ComfyUI: уже установлен ($COMFYUI_DIR)"
    cd "$COMFYUI_DIR" && git pull --ff-only 2>/dev/null || true
fi

# --- 2. Виртуальное окружение ---
if $CLEAN && [[ -d "$COMFYUI_VENV" ]]; then
    echo "[2/6] Удаление старого venv ($COMFYUI_VENV)..."
    rm -rf "$COMFYUI_VENV"
fi

if [[ ! -d "$COMFYUI_VENV" ]]; then
    echo "[2/6] Создание venv ($COMFYUI_VENV)..."
    python3 -m venv "$COMFYUI_VENV"
else
    echo "[2/6] venv: существует ($COMFYUI_VENV)"
fi

# --- 3. PyTorch ---
echo "[3/6] Установка PyTorch (backend: $BACKEND)..."
case "$BACKEND" in
    rocm)
        "$COMFYUI_PIP" install --upgrade pip
        "$COMFYUI_PIP" install torch torchvision torchaudio \
            --index-url "$TORCH_INDEX"
        ;;
    vulkan|*)
        "$COMFYUI_PIP" install --upgrade pip
        "$COMFYUI_PIP" install torch torchvision torchaudio
        ;;
esac

# --- 4. Зависимости ComfyUI ---
echo "[4/6] Установка зависимостей ComfyUI..."
cd "$COMFYUI_DIR"
"$COMFYUI_PIP" install -r requirements.txt

# --- 5. ComfyUI-GGUF (для Vulkan backend) ---
if [[ "$BACKEND" == "vulkan" ]] || [[ "$BACKEND" == "" ]]; then
    if [[ ! -d "$COMFYUI_GGUF_NODE" ]]; then
        echo "[5/6] Установка ComfyUI-GGUF..."
        git clone https://github.com/city96/ComfyUI-GGUF.git "$COMFYUI_GGUF_NODE"
    else
        echo "[5/6] ComfyUI-GGUF: обновление..."
        cd "$COMFYUI_GGUF_NODE" && git pull --ff-only 2>/dev/null || true
    fi
    if [[ -f "${COMFYUI_GGUF_NODE}/requirements.txt" ]]; then
        "$COMFYUI_PIP" install -r "${COMFYUI_GGUF_NODE}/requirements.txt"
    fi
else
    echo "[5/6] ComfyUI-GGUF: не требуется для ROCm backend"
fi

# --- 6. Структура моделей и extra_model_paths.yaml ---
echo "[6/6] Структура моделей..."
mkdir -p "$COMFYUI_UNET" "$COMFYUI_CLIP" "$COMFYUI_VAE" "$COMFYUI_LORAS"
generate_extra_paths
echo "  extra_model_paths.yaml: $COMFYUI_EXTRA_PATHS"

echo ""
echo "=== Установка завершена ==="
echo "  ComfyUI:     $COMFYUI_DIR"
echo "  venv:        $COMFYUI_VENV"
echo "  Backend:     $BACKEND"
echo "  Модели:      $MODELS_DIR/{diffusion,clip,vae,loras}"
echo ""
echo "Следующий шаг: ./scripts/comfyui/download-models.sh --minimal"
