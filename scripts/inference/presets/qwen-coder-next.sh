#!/bin/bash
# Запуск Qwen3-Coder-Next 80B-A3B на порту 8081 с контекстом 256K
# Стабильная конфигурация: подтверждено в работе с opencode
#
# Использование: ./scripts/inference/presets/qwen-coder-next.sh [--daemon|-d]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3-Coder-Next-Q4_K_M/Qwen3-Coder-Next-Q4_K_M-00001-of-00004.gguf"
PORT=8081
CTX=256000

if [[ ! -f "$MODEL" ]]; then
    echo "ОШИБКА: модель не найдена: $MODEL"
    exit 1
fi

check_server_binary || exit 1
check_port_free "$PORT" || exit 1

parse_daemon_flag "$@"

run_server "$MODEL" "$PORT" "$CTX" "llama-server"
