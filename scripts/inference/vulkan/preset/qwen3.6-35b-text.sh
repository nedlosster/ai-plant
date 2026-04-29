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
# Архитектура (по llama-server log на b8717):
#   general.architecture = qwen35moe (40 blocks, 256 experts, 8 used, hybrid с SSM)
#   only 10 / 40 layers full attention (остальные 30 -- recurrent SSM Gated DeltaNet)
#   n_swa = 0 -- sliding window attention НЕ используется
#   KV cache мал: 2.5 GiB (32768 cells × 10 attention layers × 4 seqs)
#
# Cache reuse статус (наблюдения из логов 2026-04-28):
#   - Встроенный slot context checkpoint механизм llama-server работает:
#     "restored context checkpoint", "created context checkpoint N of 32".
#     Это base feature, доступная в llama-server независимо от PR'ов.
#     PR #20819 (persist через /slots save-restore) -- ОТДЕЛЬНАЯ фича для
#     router-mode swap между моделями, на 2026-04-29 OPEN, не merged.
#   - Между tasks (или после смены exercise) cache invalidates:
#     "forcing full prompt re-processing due to lack of cache data
#      (likely due to SWA or hybrid/recurrent memory)"
#   - PR #19670 (hybrid memory snapshot для inter-task) -- OPEN, ждём.
#   См. docs/inference/optimization-backlog.md (U-001).
#
# Безопасные оптимизации (применены 2026-04-28):
#   1. --cache-reuse 256 -- использует встроенный checkpoint механизм llama-server
#      для intra-task multi-turn cache. Эффект: меньше pp recomputation на retry
#      внутри одной задачи.
#   2. --cache-type-k q8_0 / --cache-type-v q8_0 -- KV cache quantization.
#      KV cache 2.5 GiB → 1.25 GiB. Незначительная потеря точности (<0.5%),
#      может улучшить L2/L3 cache hit rate. Безопасно для inference.
#   3. --mlock -- запретить swap модели в дисковую подкачку. Гарантирует
#      residency в LPDDR5. У нас 120 GiB unified, безопасно.
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
    --cache-reuse 256      # intra-task multi-turn re-use через slot checkpoints (PR #20819)
    --cache-type-k q8_0    # KV cache K quantization: 2.5 GiB → 1.25 GiB, потеря <0.5%
    --cache-type-v q8_0    # KV cache V quantization: то же
    --mlock                # запрет swap модели в подкачку (residency в LPDDR5)
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

echo "TEXT-ONLY preset: --mmproj отключён, --keep=${KEEP_TOKENS}, KV q8_0, cache-reuse 256, mlock"
launch_server "$PORT" "llama-server" "${ARGS[@]}"
