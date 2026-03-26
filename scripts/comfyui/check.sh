#!/bin/bash
# Диагностика окружения ComfyUI
# Backend: AI_BACKEND=vulkan|rocm (или автодетект)

set -euo pipefail
source "$(dirname "$0")/common/config.sh"

echo "=== Диагностика ComfyUI (backend: $BACKEND) ==="
echo ""

ERRORS=0

# [1] ComfyUI
printf "[1/7] ComfyUI:         "
if [[ -f "${COMFYUI_DIR}/main.py" ]]; then
    echo "OK ($COMFYUI_DIR)"
else
    echo "ОШИБКА (не установлен)"
    echo "  ./scripts/comfyui/install.sh"
    (( ERRORS++ )) || true
fi

# [2] venv
printf "[2/7] venv:            "
if [[ -x "$COMFYUI_PYTHON" ]]; then
    _pyver=$("$COMFYUI_PYTHON" --version 2>&1)
    echo "OK ($_pyver, $COMFYUI_VENV)"
else
    echo "ОШИБКА ($COMFYUI_VENV не найден)"
    (( ERRORS++ )) || true
fi

# [3] PyTorch
printf "[3/7] PyTorch:         "
if [[ -x "$COMFYUI_PYTHON" ]]; then
    _torch=$("$COMFYUI_PYTHON" -c "import torch; print(f'{torch.__version__}')" 2>&1) || _torch="не установлен"
    if [[ "$_torch" != *"не установлен"* ]] && [[ "$_torch" != *"Error"* ]]; then
        echo "OK ($_torch)"
    else
        echo "ОШИБКА ($_torch)"
        (( ERRORS++ )) || true
    fi
else
    echo "ПРОПУСК (нет venv)"
fi

# [4] ComfyUI-GGUF (только Vulkan)
printf "[4/7] ComfyUI-GGUF:    "
if [[ "$BACKEND" == "vulkan" ]]; then
    if [[ -d "$COMFYUI_GGUF_NODE" ]]; then
        echo "OK ($COMFYUI_GGUF_NODE)"
    else
        echo "ОШИБКА (не установлен)"
        (( ERRORS++ )) || true
    fi
else
    echo "ПРОПУСК (не требуется для ROCm)"
fi

# [5] Модели: diffusion
printf "[5/7] Модели diffusion: "
_count=$(find "$COMFYUI_UNET" -type f \( -name "*.gguf" -o -name "*.safetensors" \) 2>/dev/null | wc -l)
if (( _count > 0 )); then
    echo "OK ($_count моделей)"
else
    echo "ОШИБКА (нет моделей в $COMFYUI_UNET)"
    echo "  ./scripts/comfyui/download-models.sh --minimal"
    (( ERRORS++ )) || true
fi

# [6] Модели: text encoders
printf "[6/7] Text encoders:   "
_count=$(find "$COMFYUI_CLIP" -type f \( -name "*.gguf" -o -name "*.safetensors" \) 2>/dev/null | wc -l)
if (( _count > 0 )); then
    echo "OK ($_count файлов)"
else
    echo "ОШИБКА (нет в $COMFYUI_CLIP)"
    (( ERRORS++ )) || true
fi

# [7] GPU sysfs
printf "[7/7] GPU sysfs:       "
if [[ -f "$GPU_BUSY" ]]; then
    echo "OK ($(cat "$GPU_BUSY")%%, $(human_size "$(cat "$VRAM_USED")") VRAM)"
else
    echo "ОШИБКА (GPU sysfs не доступен)"
    (( ERRORS++ )) || true
fi

echo ""
if (( ERRORS == 0 )); then
    echo "Все проверки пройдены"
else
    echo "Ошибок: $ERRORS"
    exit 1
fi
