#!/bin/bash
# Пресет: Gemma 4 26B-A4B на порту 8081 с безопасными параметрами
#
# Backend-agnostic. Использовать через обёртки:
#   ./scripts/inference/vulkan/gemma4.sh
#   ./scripts/inference/rocm/gemma4.sh
#
# Особенности (защита от OOM):
# - Контекст 64K: Gemma 4 не поддерживает cache shifting,
#   sliding window attention требует RAM на checkpoints
#   (32 чекпоинта × ~300-765 MiB на 64K-256K = OOM)
# - --parallel 1: один слот, чтобы не множить KV cache
# - --no-mmap: модель сразу в анонимной RAM, без mmap-overhead

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"

MODEL="${MODELS_DIR}/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf"
PORT=8081
CTX=65536
EXTRA_ARGS=(--parallel 1 --no-mmap)

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"

run_server "$MODEL" "$PORT" "$CTX" "llama-server"
