#!/bin/bash
# Vulkan: Qwen3-VL 30B-A3B Instruct Q4_K_M (multimodal MoE)
#
# Vision-флагман от Qwen для OCR, document understanding, video.
# MoE с 3B активных параметров -- скорость как у Qwen3-Coder.
# mmproj F16 (~1 GB) подключается отдельным флагом --mmproj.

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3VL-30B-A3B-Instruct-Q4_K_M.gguf"
MMPROJ="${MODELS_DIR}/mmproj-Qwen3VL-30B-A3B-Instruct-F16.gguf"
PORT=8081

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --mmproj "$MMPROJ"     # vision-проектор (Qwen3-VL multimodal)
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 131072              # контекст 128K
    -fa on                 # flash attention
    --parallel 4           # 4 слота (MoE A3B даёт скорость)
    --cache-reuse 256      # KV-cache shifting
    --jinja                # Jinja2 chat-template (function calling)
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }
[[ -f "$MMPROJ" ]] || { echo "ОШИБКА: mmproj не найден: $MMPROJ"; echo "  Загрузить: ./scripts/inference/download-model.sh Qwen/Qwen3-VL-30B-A3B-Instruct-GGUF --include '*mmproj*F16*'"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
