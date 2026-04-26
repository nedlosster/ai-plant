#!/bin/bash
# ROCm/HIP: Qwen3.6-35B-A3B Q4_K_M (multimodal MoE coder)
#
# 35B total / 3B active, vision encoder через mmproj.
# Помещается в HIP (~21 GiB total). Контекст ограничен HIP-лимитом.
# Внимание: ROCm 7+ имеет regression на gfx1151, может потребоваться
# workaround `-mllvm --amdgpu-unroll-threshold-local=600` при сборке.

set -euo pipefail
export AI_BACKEND=rocm
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf"
MMPROJ="${MODELS_DIR}/mmproj-Qwen3.6-35B-A3B-F16.gguf"
PORT=8085

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --mmproj "$MMPROJ"     # vision-проектор (Qwen3.6 multimodal)
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 65536               # контекст 64K (HIP-лимит)
    -fa on                 # flash attention
    --parallel 2           # 2 слота -- запас памяти
    --cache-reuse 256      # KV-cache shifting
    --jinja                # Jinja2 chat-template (function calling)
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }
[[ -f "$MMPROJ" ]] || { echo "ОШИБКА: mmproj не найден: $MMPROJ"; echo "  Загрузить: ./scripts/inference/download-model.sh unsloth/Qwen3.6-35B-A3B-GGUF --include '*mmproj*F16*'"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
