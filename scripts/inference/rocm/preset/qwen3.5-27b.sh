#!/bin/bash
# ROCm/HIP: Qwen3.5 27B Q4_K_M (dense)
# Модель 16 GiB + KV ~4 GiB = ~20 GiB, помещается в HIP-лимит ~30 GiB

set -euo pipefail
export AI_BACKEND=rocm
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3.5-27B-Q4_K_M.gguf"
PORT=8081

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 32768               # контекст 32K (HIP-лимит памяти)
    -fa on                 # flash attention
    --parallel 2           # 2 слота -- запас памяти
    --cache-reuse 256      # KV-cache shifting
    --jinja                # Jinja2 chat-template
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
