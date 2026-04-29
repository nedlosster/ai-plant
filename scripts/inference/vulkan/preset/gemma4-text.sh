#!/bin/bash
# Vulkan: Gemma 4 26B-A4B (TEXT-ONLY вариант для cache-sensitive workloads / coding bench)
#
# Отличия от gemma4.sh (multimodal):
#   1. Без `--mmproj` -- multimodal vision pipeline отключён.
#      Это убирает llama.cpp lock "cache_reuse is not supported by multimodal,
#      it will be disabled". Один из двух блокеров cache-reuse снят.
#   2. По умолчанию `--keep 1500` -- сохранить первые 1500 токенов system promptа
#      от eviction при context shift в multi-turn agent сессиях.
#   3. Порт 8083 -- параллельно с multimodal gemma4.sh на 8081 (если хватит VRAM)
#
# ВАЖНО: cache-reuse полноценно НЕ работает даже без mmproj -- остаётся второй
# блокер: Sliding Window Attention (SWA). В логе будет "forcing full prompt
# re-processing". Этот вариант нужен для:
#   - Aider / aider-polyglot бенчмарков (без vision, retry-loop с error feedback)
#   - opencode coding workflows (text-only, function calling по коду)
#   - Comparison vs Qwen3.6-35B-A3B / Coder Next на agent-coding tasks
#
# Архитектура (qwen35moe-style hybrid -- проверить llama-server log):
#   26B total / 4B active MoE с SWA
#   Контекст 256K (max), preset на 128K для совместимости с aider workflow
#
# CLI:
#   ./gemma4-text.sh -d                  # default --keep 1500
#   ./gemma4-text.sh -d --no-keep        # отключить --keep
#   ./gemma4-text.sh -d --keep 2000      # переопределить значение

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf"
PORT=8083

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

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 131072              # контекст 128K (для aider достаточно, можно расширить до 256K)
    -fa on                 # flash attention
    --parallel 4           # 4 слота
    --batch-size 4096      # PP optimization
    --ubatch-size 4096     # ускоряет prompt processing на 20-30%
    --cache-reuse 256      # использует встроенный checkpoint механизм llama-server
    --cache-type-k q8_0    # KV cache K quantization: ~50% памяти, потеря <0.5%
    --cache-type-v q8_0    # KV cache V quantization: то же
    --no-mmap              # модель ~22 GiB сразу в RAM
    --jinja                # Jinja2 chat-template (function calling)
)

[[ "$KEEP_TOKENS" -gt 0 ]] && ARGS+=(--keep "$KEEP_TOKENS")

# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1

parse_daemon_flag "${REMAINING_ARGS[@]}"

echo "Gemma 4 26B-A4B TEXT-ONLY: --mmproj отключён, --keep=${KEEP_TOKENS}"
launch_server "$PORT" "llama-server" "${ARGS[@]}"
