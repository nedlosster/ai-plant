#!/bin/bash
# Vulkan: Qwen3.6-27B Q4_K_M (DENSE, hybrid Gated DeltaNet)
#
# Особенности:
#   - Dense 27B (vs MoE A3B у 35B-A3B / 30B-A3B / Coder Next)
#   - Hybrid Gated DeltaNet -- cache-reuse архитектурно blocked
#   - Лидер open-weight SWE-V (77.2%) на момент апреля 2026
#     (опережает Devstral 2 72.2% и Coder Next 70.6%)
#   - Memory-bound по характеру: ~15 tok/s оценка на Strix Halo
#     (vs 50-90 tok/s у MoE A3B той же эпохи)
#
# Конфигурация:
#   - Q4_K_M (~16 GB) -- помещается с большим запасом в 120 GiB unified
#   - text-only (без mmproj) -- cache-sensitive workloads, как 35B-text
#     mmproj-BF16.gguf доступен (889 MB) для multimodal-вариантов отдельно
#   - --keep 1500 -- защита system prompt от context shift eviction
#   - --batch-size/--ubatch-size 4096 -- PP optimization на Vulkan
#   - --no-mmap -- dense 16 GB сразу в RAM, минимум I/O overhead
#
# CLI:
#   ./qwen3.6-27b.sh -d                  # default --keep 1500
#   ./qwen3.6-27b.sh -d --no-keep        # отключить --keep
#   ./qwen3.6-27b.sh -d --keep 2000      # переопределить значение

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3.6-27B-Q4_K_M.gguf"
PORT=8086

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
    --parallel 4           # 4 слота
    --batch-size 4096      # PP optimization
    --ubatch-size 4096     # ускоряет prompt processing на 20-30%
    --no-mmap              # dense 16 GB сразу в RAM
    --jinja                # Jinja2 chat-template (function calling)
)

# --keep N -- сохранить первые N токенов system promptа от eviction (default 1500)
[[ "$KEEP_TOKENS" -gt 0 ]] && ARGS+=(--keep "$KEEP_TOKENS")

# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1

parse_daemon_flag "${REMAINING_ARGS[@]}"

echo "Qwen3.6-27B dense (text-only): --keep=${KEEP_TOKENS}, hybrid Gated DeltaNet"
launch_server "$PORT" "llama-server" "${ARGS[@]}"
