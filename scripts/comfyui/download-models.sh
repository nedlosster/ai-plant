#!/bin/bash
# Загрузка моделей для ComfyUI
# Использование: ./scripts/comfyui/download-models.sh [--minimal|--flux-schnell|--flux-dev|--all]

set -euo pipefail
source "$(dirname "$0")/common/config.sh"

# --- Загрузка через wget (надёжнее hf cli для больших файлов) ---
hf_wget() {
    local url="$1"
    local dir="$2"
    local filename="$3"
    local filepath="${dir}/${filename}"

    mkdir -p "$dir"
    if [[ -f "$filepath" ]]; then
        echo "  Пропуск (существует): $filename ($(human_size "$(stat -c%s "$filepath")"))"
        return 0
    fi
    echo "  Загрузка: $filename -> $dir"
    wget -c "$url" -O "$filepath"
}

# --- HuggingFace URL ---
HF="https://huggingface.co"

# --- Наборы моделей ---

download_text_encoders() {
    echo "--- Text encoders ---"
    # CLIP-L (235 MiB)
    hf_wget "${HF}/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" \
        "$COMFYUI_CLIP" "clip_l.safetensors"
    # T5-XXL Q8 GGUF (4.7 GiB)
    hf_wget "${HF}/city96/t5-v1_1-xxl-encoder-gguf/resolve/main/t5-v1_1-xxl-encoder-Q8_0.gguf" \
        "$COMFYUI_CLIP" "t5-v1_1-xxl-encoder-Q8_0.gguf"
}

download_vae() {
    echo "--- VAE ---"
    # ae.safetensors (160 MiB, публичный источник)
    hf_wget "${HF}/camenduru/FLUX.1-dev-diffusers/resolve/main/vae/diffusion_pytorch_model.safetensors" \
        "$COMFYUI_VAE" "ae.safetensors"
}

download_flux_schnell() {
    echo "--- FLUX.1-schnell Q4 (быстрая генерация, ~6.3 GiB) ---"
    hf_wget "${HF}/city96/FLUX.1-schnell-gguf/resolve/main/flux1-schnell-Q4_K_S.gguf" \
        "$COMFYUI_UNET" "flux1-schnell-Q4_K_S.gguf"
    download_text_encoders
    download_vae
}

download_flux_dev() {
    echo "--- FLUX.1-dev Q8 (качественная генерация, ~11.5 GiB) ---"
    hf_wget "${HF}/city96/FLUX.1-dev-gguf/resolve/main/flux1-dev-Q8_0.gguf" \
        "$COMFYUI_UNET" "flux1-dev-Q8_0.gguf"
    download_text_encoders
    download_vae
}

# --- Справка ---

usage() {
    echo "Загрузка моделей для ComfyUI"
    echo ""
    echo "Использование: $0 [НАБОР]"
    echo ""
    echo "  --minimal       FLUX.1-schnell Q4 + encoders + VAE (~11.5 GiB)"
    echo "  --flux-schnell  то же что --minimal"
    echo "  --flux-dev      FLUX.1-dev Q8 + encoders + VAE (~16.5 GiB)"
    echo "  --all           schnell + dev (~23 GiB)"
    echo ""
    echo "Модели: $MODELS_DIR/{diffusion,clip,vae}"
}

# --- Создание директорий ---
mkdir -p "$COMFYUI_UNET" "$COMFYUI_CLIP" "$COMFYUI_VAE" "$COMFYUI_LORAS"

# --- Выбор набора ---
case "${1:---minimal}" in
    --minimal|--flux-schnell)
        download_flux_schnell
        ;;
    --flux-dev)
        download_flux_dev
        ;;
    --all)
        download_flux_schnell
        download_flux_dev
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    *)
        echo "Неизвестный набор: $1"
        usage
        exit 1
        ;;
esac

echo ""
echo "=== Загрузка завершена ==="
echo ""
list_comfyui_models
