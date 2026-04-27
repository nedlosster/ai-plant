#!/bin/bash
# Vulkan: Qwen3.6-35B-A3B Q4_K_M (TEXT-ONLY вариант, для cache-sensitive workloads)
#
# Отличия от qwen3.6-35b.sh:
#   1. Без `--mmproj` -- multimodal vision pipeline отключён.
#      Это убирает llama.cpp lock "cache_reuse is not supported by multimodal,
#      it will be disabled". Один из двух блокеров cache-reuse снят.
#   2. По умолчанию `--keep 1500` -- сохранить первые 1500 токенов system promptа
#      от eviction при context shift (важно для multi-turn agent сессий).
#   3. Порт 8084 -- чтобы можно было крутить параллельно с multimodal qwen3.6-35b
#      на 8085 (если хватит VRAM, ~42 GiB на оба).
#
# ВАЖНО: cache-reuse полноценно НЕ работает даже без mmproj -- остаётся второй
# блокер: hybrid Gated DeltaNet recurrent state не сохраняется между запросами.
# В логе всё равно будет "forcing full prompt re-processing". Этот вариант
# даёт лишь ~10% ускорения PP за счёт отсутствия mmproj projection pass.
# Полное решение -- ждать llama.cpp PR #20376/#20819.
# См. docs/inference/optimization-backlog.md (U-001).
#
# CLI:
#   ./qwen3.6-35b-text.sh -d                  # default --keep 1500
#   ./qwen3.6-35b-text.sh -d --no-keep        # отключить --keep
#   ./qwen3.6-35b-text.sh -d --keep 2000      # переопределить значение

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf"
PORT=8084

# --- CLI parser для локальных опций (до передачи в parse_daemon_flag) ---
KEEP_TOKENS=1500
REMAINING_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-keep) KEEP_TOKENS=0; shift;;
        --keep)    KEEP_TOKENS="$2"; shift 2;;
        *)         REMAINING_ARGS+=("$1"); shift;;
    esac
done

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 131072              # контекст 128K
    -fa on                 # flash attention
    --parallel 4           # 4 слота (MoE A3B даёт скорость)
    --batch-size 4096      # увеличен с default 2048 -- меньше overhead на Vulkan dispatch
    --ubatch-size 4096     # увеличен с default 512 -- ускоряет prompt processing на 20-30%
    --jinja                # Jinja2 chat-template (function calling)
)

# --keep N -- сохранить первые N токенов system promptа от eviction (default 1500, --no-keep отключает)
[[ "$KEEP_TOKENS" -gt 0 ]] && ARGS+=(--keep "$KEEP_TOKENS")

# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1

# Передаём оставшиеся args (например -d) в parse_daemon_flag
parse_daemon_flag "${REMAINING_ARGS[@]}"

echo "TEXT-ONLY preset: --mmproj отключён, --keep=${KEEP_TOKENS}"
launch_server "$PORT" "llama-server" "${ARGS[@]}"
