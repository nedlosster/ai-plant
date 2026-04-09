#!/bin/bash
# Vulkan: Qwen2.5-Omni 7B Q4_K_M (vision + audio + text)
#
# Универсальная multimodal-модель: понимает картинки И аудио.
# Talker-Thinker архитектура: один поток для текста, другой для речи.
# Маленькая (~5 GiB), быстрая, хорошо помещается параллельно с другими моделями.

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen2.5-Omni-7B-Q4_K_M.gguf"
MMPROJ="${MODELS_DIR}/mmproj-Qwen2.5-Omni-7B-Q8_0.gguf"   # Q8_0 (1.4 GB), есть и F16 (2.5 GB)
PORT=8081

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --mmproj "$MMPROJ"     # vision/audio проектор
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 65536               # контекст 64K
    -fa on                 # flash attention
    --parallel 4           # 4 слота
    --cache-reuse 256      # KV-cache shifting
    --jinja                # Jinja2 chat-template
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }
[[ -f "$MMPROJ" ]] || { echo "ОШИБКА: mmproj не найден: $MMPROJ"; echo "  Загрузить: ./scripts/inference/download-model.sh ggml-org/Qwen2.5-Omni-7B-GGUF --include '*mmproj*Q8_0*'"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
