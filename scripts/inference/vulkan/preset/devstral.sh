#!/bin/bash
# Vulkan: Devstral 2 24B Instruct Q4_K_M (dense, SWE-bench 72.2%, FIM+agent)

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Devstral-Small-2-24B-Instruct-2512-Q4_K_M.gguf"
PORT=8083

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 131072              # контекст 128K (dense 24B, 256K доступен но расход VRAM)
    -fa on                 # flash attention
    --parallel 2           # 2 слота (dense экономия VRAM)
    --cache-reuse 256      # KV-cache shifting
    --jinja                # Jinja2 chat-template для function calling
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
