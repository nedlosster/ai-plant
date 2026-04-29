#!/bin/bash
# Vulkan: Qwen3.6-35B-A3B UD-Q5_K_M (TEXT-ONLY, более точный квант для quality A/B)
#
# Цель preset'а: A/B сравнение качества vs Q4_K_M (наш текущий default 35B-text).
# Ожидание: +3-5pp pass_rate_2 на aider polyglot smoke 20 + --tries 2.
# Если delta значимая -- переключить default для daily agent на Q5_K_M.
#
# Параметры идентичны qwen3.6-35b-text.sh (порт другой, чтобы можно крутить
# параллельно для side-by-side comparison).
#
# Размер: ~26.5 GiB (vs 22.1 GiB у UD-Q4_K_M). Помещается с большим запасом
# в 120 GiB unified.
#
# Скачивание (модель пока не на сервере):
#   ./scripts/inference/download-model.sh unsloth/Qwen3.6-35B-A3B-GGUF \
#     --include '*UD-Q5_K_M*'
#
# CLI:
#   ./qwen3.6-35b-text-q5.sh -d                  # default --keep 1500
#   ./qwen3.6-35b-text-q5.sh -d --no-keep        # отключить --keep
#   ./qwen3.6-35b-text-q5.sh -d --keep 2000      # переопределить значение

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3.6-35B-A3B-UD-Q5_K_M.gguf"
PORT=8087  # отличный от 8084 (Q4_K_M) -- для параллельного A/B запуска

# --- CLI parser для локальных опций ---
KEEP_TOKENS=1500
REMAINING_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-keep) KEEP_TOKENS=0; shift;;
        --keep)    KEEP_TOKENS="$2"; shift 2;;
        *)         REMAINING_ARGS+=("$1"); shift;;
    esac
done

# --- llama-server параметры (идентично qwen3.6-35b-text.sh) ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 131072              # контекст 128K
    -fa on                 # flash attention
    --parallel 4           # 4 слота
    --batch-size 4096      # PP optimization
    --ubatch-size 4096     # ускоряет prompt processing 20-30%
    --cache-reuse 256      # intra-task multi-turn re-use через slot checkpoints
    --cache-type-k q8_0    # KV cache K quantization
    --cache-type-v q8_0    # KV cache V quantization
    --mlock                # запрет swap модели в подкачку
    --jinja                # Jinja2 chat-template (function calling)
)

[[ "$KEEP_TOKENS" -gt 0 ]] && ARGS+=(--keep "$KEEP_TOKENS")

# ---------------------------------

if [[ ! -f "$MODEL" ]]; then
    echo "ОШИБКА: модель не найдена: $MODEL"
    echo ""
    echo "Скачать через:"
    echo "  ./scripts/inference/download-model.sh unsloth/Qwen3.6-35B-A3B-GGUF \\"
    echo "    --include '*UD-Q5_K_M*'"
    echo ""
    echo "Размер ~26.5 GiB, помещается в 120 GiB unified."
    exit 1
fi

check_server_binary || exit 1
check_port_free "$PORT" || exit 1

parse_daemon_flag "${REMAINING_ARGS[@]}"

echo "Qwen3.6-35B-A3B Q5_K_M TEXT-ONLY: --mmproj отключён, --keep=${KEEP_TOKENS}"
launch_server "$PORT" "llama-server" "${ARGS[@]}"
