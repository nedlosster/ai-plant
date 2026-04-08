#!/bin/bash
# ROCm/HIP: Gemma 4 26B-A4B
#
# ВНИМАНИЕ: HIP видит ~30 GiB GPU-памяти. Gemma 4 + 64K context +
# checkpoints периодически уходит в ROCm OOM. Контекст ужат до 32K.
# Для стабильности рекомендуется Vulkan: ../../vulkan/preset/gemma4.sh

set -euo pipefail
export AI_BACKEND=rocm
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

# --- Параметры запуска ---
MODEL="${MODELS_DIR}/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf"
PORT=8081
CTX=32768
EXTRA_ARGS=(--parallel 1 --no-mmap)
# ---------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

run_server "$MODEL" "$PORT" "$CTX" "llama-server"
