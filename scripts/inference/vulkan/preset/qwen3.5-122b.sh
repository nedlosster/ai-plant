#!/bin/bash
# Vulkan: Qwen3.5 122B-A10B Q4_K_M (MoE, самая большая)
# 71 GiB модель + KV-cache -- помещается в 120 GiB Vulkan, но не в HIP

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Q4_K_M/Qwen3.5-122B-A10B-Q4_K_M-00001-of-00003.gguf"
PORT=8081

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 65536               # контекст 64K (модель уже занимает 71 GiB)
    -fa on                 # flash attention
    --parallel 2           # 2 слота -- запас памяти на KV
    --cache-reuse 256      # KV-cache shifting
    --jinja                # Jinja2 chat-template
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
