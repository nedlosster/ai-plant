#!/bin/bash
# ROCm/HIP: Qwen3-Coder-Next 80B-A3B
#
# Модель ~45 GiB. С fix ttm.pages_limit=31457280 KFD видит 120 GiB.
# ROCm 7.2.1, gfx1151 нативно (HSA_OVERRIDE_GFX_VERSION=11.5.1).

set -euo pipefail
export AI_BACKEND=rocm
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3-Coder-Next-Q4_K_M/Qwen3-Coder-Next-Q4_K_M-00001-of-00004.gguf"
PORT=8081

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 256000              # контекст 256K
    -fa on                 # flash attention
    --parallel 4           # 4 слота
    --cache-reuse 256      # KV-cache shifting
    --jinja                # Jinja2 chat-template
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
