#!/bin/bash
# Vulkan: InternVL3-38B Instruct Q4_K_M + mmproj (vision, MMMU 72.2, math/charts/reasoning)

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/InternVL3-38B-Instruct-Q4_K_M.gguf"
MMPROJ="${MODELS_DIR}/mmproj-InternVL3-38B-Instruct-BF16.gguf"
PORT=8084

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --mmproj "$MMPROJ"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 32768               # контекст 32K (dense 38B + 10.5 GiB mmproj -- экономия VRAM)
    -fa on                 # flash attention
    --parallel 1           # 1 слот (экономия VRAM: модель 19 GiB + mmproj 10.5 GiB)
    --jinja                # Jinja2 chat-template
    --no-mmap              # прямая загрузка (mmproj стабильнее)
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }
[[ -f "$MMPROJ" ]] || { echo "ОШИБКА: mmproj не найден: $MMPROJ"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
