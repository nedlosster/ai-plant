#!/bin/bash
# Vulkan: Qwen3.6-35B-A3B Q4_K_M (multimodal MoE coder)
#
# Default daily agent на платформе с релиза 16 апреля 2026.
# Sparse MoE 35B total / 3B active с встроенным vision encoder.
# SWE-bench Verified 73.4%, оценка ~80 tok/s tg, ~700-1000 prefill.
# mmproj F16 подключается отдельным флагом --mmproj.

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf"
MMPROJ="${MODELS_DIR}/mmproj-Qwen3.6-35B-A3B-F16.gguf"
PORT=8085

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --mmproj "$MMPROJ"     # vision-проектор (Qwen3.6 multimodal)
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 131072              # контекст 128K
    -fa on                 # flash attention
    --parallel 4           # 4 слота (MoE A3B даёт скорость)
    --cache-reuse 256      # KV-cache shifting (multi-turn opencode)
    --jinja                # Jinja2 chat-template (function calling)
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }
[[ -f "$MMPROJ" ]] || { echo "ОШИБКА: mmproj не найден: $MMPROJ"; echo "  Загрузить: ./scripts/inference/download-model.sh unsloth/Qwen3.6-35B-A3B-GGUF --include '*mmproj*F16*'"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
