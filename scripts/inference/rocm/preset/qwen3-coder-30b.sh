#!/bin/bash
# ROCm/HIP: Qwen3-Coder-30B-A3B Instruct Q4_K_M (MoE)
# Модель 18 GiB, MoE с активацией 3B параметров, помещается в HIP

set -euo pipefail
export AI_BACKEND=rocm
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf"
PORT=8081

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 65536               # контекст 64K (HIP-лимит)
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
