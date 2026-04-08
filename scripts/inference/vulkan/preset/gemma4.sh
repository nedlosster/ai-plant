#!/bin/bash
# Vulkan: Gemma 4 26B-A4B (безопасные параметры)
#
# Защита от OOM (sliding window + checkpoints):
# --parallel 1   -- один слот вместо 4
# --no-mmap      -- модель сразу в RAM, без mmap-overhead
# -c 65536       -- меньше памяти на context checkpoints

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf"
PORT=8081

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 65536               # контекст 64K
    -fa on                 # flash attention
    --parallel 1           # 1 слот -- защита от OOM
    --cache-reuse 256      # на Gemma 4 не работает (sliding window), но не ломает
    --jinja                # Jinja2 chat-template (function calling Gemma 4)
    --no-mmap              # модель сразу в RAM, без mmap-overhead
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
