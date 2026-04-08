#!/bin/bash
# ROCm/HIP: Qwen2.5-Coder 1.5B Instruct Q8_0 (FIM/автодополнение)

set -euo pipefail
export AI_BACKEND=rocm
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen2.5-Coder-1.5B-Instruct-Q8_0.gguf"
PORT=8080

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 8192                # контекст 8K (FIM-сценарий)
    -fa on                 # flash attention
    --parallel 2           # 2 слота
    --cache-reuse 256      # KV-cache shifting
    --jinja                # Jinja2 chat-template
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-fim" "${ARGS[@]}"
