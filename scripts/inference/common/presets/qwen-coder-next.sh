#!/bin/bash
# Пресет: Qwen3-Coder-Next 80B-A3B на порту 8081 с контекстом 256K
#
# Backend-agnostic. Использовать через обёртки:
#   ./scripts/inference/vulkan/qwen-coder-next.sh
#   ./scripts/inference/rocm/qwen-coder-next.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"

MODEL="${MODELS_DIR}/Qwen3-Coder-Next-Q4_K_M/Qwen3-Coder-Next-Q4_K_M-00001-of-00004.gguf"
PORT=8081
CTX=256000

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"

run_server "$MODEL" "$PORT" "$CTX" "llama-server"
