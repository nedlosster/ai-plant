#!/bin/bash
# Vulkan: Gemma 4 26B-A4B (безопасные параметры)
#
# Защита от OOM (sliding window + checkpoints):
# --parallel 1   -- один слот вместо 4
# --no-mmap      -- модель сразу в RAM, без mmap-overhead
# CTX=64K        -- меньше памяти на context checkpoints

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

# --- Параметры запуска ---
MODEL="${MODELS_DIR}/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf"
PORT=8081
CTX=65536
EXTRA_ARGS=(--parallel 1 --no-mmap)
# ---------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

run_server "$MODEL" "$PORT" "$CTX" "llama-server"
