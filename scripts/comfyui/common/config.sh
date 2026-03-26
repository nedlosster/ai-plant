#!/bin/bash
# Общие переменные и функции для ComfyUI
# Подключение: source "$(dirname "$0")/../common/config.sh"
# Переиспользует inference-слой: backend, GPU sysfs, human_size, check_port_free

# --- Inference-слой (backend, GPU, утилиты) ---
_COMFYUI_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_COMFYUI_COMMON_DIR}/../../inference/common/config.sh"

# --- ComfyUI: пути ---
COMFYUI_DIR="${COMFYUI_DIR:-${HOME}/projects/ComfyUI}"
COMFYUI_PORT="${COMFYUI_PORT:-8188}"
COMFYUI_LISTEN="${COMFYUI_LISTEN:-0.0.0.0}"
COMFYUI_CUSTOM_NODES="${COMFYUI_DIR}/custom_nodes"
COMFYUI_GGUF_NODE="${COMFYUI_CUSTOM_NODES}/ComfyUI-GGUF"
COMFYUI_LOG="/tmp/comfyui-${COMFYUI_PORT}.log"
COMFYUI_EXTRA_PATHS="${COMFYUI_DIR}/extra_model_paths.yaml"

# --- venv по backend'у ---
case "$BACKEND" in
    rocm)
        COMFYUI_VENV="${COMFYUI_DIR}/venv-rocm"
        TORCH_INDEX="https://download.pytorch.org/whl/rocm6.2"
        ;;
    vulkan|*)
        COMFYUI_VENV="${COMFYUI_DIR}/venv-vulkan"
        TORCH_INDEX=""
        ;;
esac
COMFYUI_PYTHON="${COMFYUI_VENV}/bin/python"
COMFYUI_PIP="${COMFYUI_VENV}/bin/pip"

# --- Модели в ~/models/ (общее хранилище с LLM) ---
COMFYUI_UNET="${MODELS_DIR}/diffusion"
COMFYUI_CLIP="${MODELS_DIR}/clip"
COMFYUI_VAE="${MODELS_DIR}/vae"
COMFYUI_LORAS="${MODELS_DIR}/loras"

# --- Проверки ---

check_comfyui() {
    if [[ ! -f "${COMFYUI_DIR}/main.py" ]]; then
        echo "ОШИБКА: ComfyUI не найден (${COMFYUI_DIR})"
        echo "  Установить: ./scripts/comfyui/install.sh"
        return 1
    fi
}

check_comfyui_venv() {
    if [[ ! -x "$COMFYUI_PYTHON" ]]; then
        echo "ОШИБКА: venv не создан (${COMFYUI_VENV})"
        echo "  Установить: ./scripts/comfyui/install.sh"
        return 1
    fi
}

check_gguf_node() {
    if [[ ! -d "$COMFYUI_GGUF_NODE" ]]; then
        echo "ОШИБКА: ComfyUI-GGUF не установлен (${COMFYUI_GGUF_NODE})"
        echo "  Установить: ./scripts/comfyui/install.sh"
        return 1
    fi
}

# --- Список моделей ComfyUI ---

list_comfyui_models() {
    echo "  Diffusion:"
    if [[ -d "$COMFYUI_UNET" ]]; then
        while IFS= read -r f; do
            printf "    %-50s %s\n" "$(basename "$f")" "$(human_size "$(stat -c%s "$f" 2>/dev/null || echo 0)")"
        done < <(find "$COMFYUI_UNET" -type f \( -name "*.gguf" -o -name "*.safetensors" \) 2>/dev/null | sort)
    fi
    [[ ! -d "$COMFYUI_UNET" ]] && echo "    (нет)"

    echo "  Text encoders:"
    if [[ -d "$COMFYUI_CLIP" ]]; then
        while IFS= read -r f; do
            printf "    %-50s %s\n" "$(basename "$f")" "$(human_size "$(stat -c%s "$f" 2>/dev/null || echo 0)")"
        done < <(find "$COMFYUI_CLIP" -type f \( -name "*.gguf" -o -name "*.safetensors" \) 2>/dev/null | sort)
    fi
    [[ ! -d "$COMFYUI_CLIP" ]] && echo "    (нет)"

    echo "  VAE:"
    if [[ -d "$COMFYUI_VAE" ]]; then
        while IFS= read -r f; do
            printf "    %-50s %s\n" "$(basename "$f")" "$(human_size "$(stat -c%s "$f" 2>/dev/null || echo 0)")"
        done < <(find "$COMFYUI_VAE" -type f \( -name "*.gguf" -o -name "*.safetensors" \) 2>/dev/null | sort)
    fi
    [[ ! -d "$COMFYUI_VAE" ]] && echo "    (нет)"

    echo "  LoRA:"
    if [[ -d "$COMFYUI_LORAS" ]]; then
        local count
        count=$(find "$COMFYUI_LORAS" -type f 2>/dev/null | wc -l)
        echo "    ${count} файлов"
    else
        echo "    (нет)"
    fi
}

# --- Генерация extra_model_paths.yaml ---

generate_extra_paths() {
    cat > "$COMFYUI_EXTRA_PATHS" << YAML
# Внешние пути к моделям (~/models/)
# Генерируется скриптом install.sh
ai_plant:
    diffusion_models: ${COMFYUI_UNET}
    text_encoders: ${COMFYUI_CLIP}
    vae: ${COMFYUI_VAE}
    loras: ${COMFYUI_LORAS}
YAML
}
