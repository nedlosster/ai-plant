#!/bin/bash
# Запуск llama-server (chat API)
# Использование: ./scripts/inference/start-server.sh <model.gguf> [port] [context] [--daemon]
# Backend: AI_BACKEND=vulkan|rocm (или автодетект)

set -euo pipefail
source "$(dirname "$0")/common/config.sh"

parse_daemon_flag "$@"
set -- "${PARSED_ARGS[@]+"${PARSED_ARGS[@]}"}"

if [[ $# -eq 0 ]]; then
    echo "Использование: $0 <model.gguf> [port] [context] [--daemon/-d]"
    echo ""
    echo "Доступные модели:"
    list_models
    exit 1
fi

MODEL_PATH=$(resolve_model "$1")
[[ -z "$MODEL_PATH" ]] && { echo "ОШИБКА: модель не найдена: $1"; list_models; exit 1; }

PORT="${2:-$DEFAULT_PORT_CHAT}"
CTX="${3:-$DEFAULT_CTX_CHAT}"

check_server_binary || exit 1
check_port_free "$PORT" || exit 1

echo "API:    http://localhost:${PORT}/v1/chat/completions"
echo "Web UI: http://localhost:${PORT}"
echo ""
run_server "$MODEL_PATH" "$PORT" "$CTX" "llama-server"
