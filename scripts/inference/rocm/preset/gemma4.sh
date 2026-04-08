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

MODEL="${MODELS_DIR}/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf"
PORT=8081

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 32768               # контекст 32K (HIP-лимит памяти)
    -fa on                 # flash attention
    --parallel 1           # 1 слот -- защита от OOM
    --cache-reuse 256      # на Gemma 4 не работает (sliding window), но не ломает
    --jinja                # Jinja2 chat-template (function calling)
    --no-mmap              # модель сразу в RAM
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
