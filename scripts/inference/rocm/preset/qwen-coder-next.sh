#!/bin/bash
# ROCm/HIP: Qwen3-Coder-Next 80B-A3B
#
# ВНИМАНИЕ: модель ~45 GiB, HIP видит только ~30 GiB GPU-памяти
# (KFD pool size). Возможен OOM на загрузке. Для этой модели
# предпочтителен Vulkan-бекенд: ../../vulkan/preset/qwen-coder-next.sh

set -euo pipefail
export AI_BACKEND=rocm
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

# --- Параметры запуска ---
MODEL="${MODELS_DIR}/Qwen3-Coder-Next-Q4_K_M/Qwen3-Coder-Next-Q4_K_M-00001-of-00004.gguf"
PORT=8081
CTX=256000
EXTRA_ARGS=()
# ---------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

run_server "$MODEL" "$PORT" "$CTX" "llama-server"
