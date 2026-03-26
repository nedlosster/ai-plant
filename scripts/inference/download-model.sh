#!/bin/bash
# Загрузка модели из HuggingFace
# Использование: ./scripts/inference/download-model.sh <hf-repo> [--include <pattern>]

set -euo pipefail
source "$(dirname "$0")/common/config.sh"

if [[ $# -eq 0 ]]; then
    echo "Использование: $0 <hf-repo> [--include <pattern>]"
    echo ""
    echo "Примеры:"
    echo "  $0 unsloth/Qwen3.5-27B-GGUF --include '*Q4_K_M*'"
    echo "  $0 bartowski/QwQ-32B-GGUF --include '*Q4_K_M*'"
    echo "  $0 bartowski/Llama-3.1-8B-Instruct-GGUF --include '*Q4_K_M*'"
    echo ""
    echo "Модели: $MODELS_DIR"
    echo ""
    echo "Установленные:"
    list_models
    exit 1
fi

REPO="$1"
shift

# Поиск hf CLI
HF_CMD=""
if command -v hf &>/dev/null; then
    HF_CMD="hf"
elif [[ -x "$HF_CLI" ]]; then
    HF_CMD="$HF_CLI"
else
    echo "hf CLI не найден. Установка..."
    pip install --break-system-packages huggingface-hub 2>&1 | tail -3
    [[ -x "$HF_CLI" ]] && HF_CMD="$HF_CLI" || { echo "ОШИБКА: установка не удалась"; exit 1; }
fi

mkdir -p "$MODELS_DIR"
echo "Загрузка: $REPO -> $MODELS_DIR"
echo ""

$HF_CMD download "$REPO" "$@" --local-dir "$MODELS_DIR"

echo ""
echo "Модели:"
list_models
