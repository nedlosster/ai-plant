#!/bin/bash
# Запуск FIM-сервера (автодополнение кода)
# Использование: ./scripts/inference/start-fim.sh <model.gguf> [port] [context] [--daemon]
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
[[ -z "$MODEL_PATH" ]] && { echo "ОШИБКА: модель не найдена: $1"; exit 1; }

PORT="${2:-$DEFAULT_PORT_FIM}"
CTX="${3:-$DEFAULT_CTX_FIM}"

check_server_binary || exit 1
check_port_free "$PORT" || exit 1

echo "FIM:    http://localhost:${PORT}/infill"
echo "Web UI: http://localhost:${PORT}"
echo ""
run_server "$MODEL_PATH" "$PORT" "$CTX" "llama-fim"
