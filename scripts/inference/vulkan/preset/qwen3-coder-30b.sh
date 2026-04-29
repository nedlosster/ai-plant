#!/bin/bash
# Vulkan: Qwen3-Coder-30B-A3B Instruct Q4_K_M (MoE, специализирован на коде)
#
# Cache-reuse РАБОТАЕТ: standard MoE attention без Gated DeltaNet recurrent
# state, без mmproj. Единственная active-coder модель платформы где
# `--cache-reuse 256` действительно переиспользует префикс между запросами.
# Эталонный baseline для A/B тестов влияния cache-reuse на agent-coding
# производительность. См. docs/inference/optimization-backlog.md (M-001).
#
# Оптимизации (применены 2026-04-29 -- ранее были в default 30B-A3B preset
# не включены, эмпирически выровнено по naming с qwen3.6-35b-text):
# - --batch-size 4096 + --ubatch-size 4096 -- ускоряет prompt processing на 20-30%
# - --cache-type-k q8_0 / --cache-type-v q8_0 -- KV cache 2.5 GiB → 1.25 GiB, потеря <0.5%
# - --keep 1500 -- система promptа от eviction при context shift в multi-turn
# - --no-mmap -- модель 18 GiB сразу в RAM, без mmap-overhead

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf"
PORT=8081

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 131072              # контекст 128K
    -fa on                 # flash attention
    --parallel 4           # 4 слота
    --batch-size 4096      # увеличен с default 2048 -- меньше overhead на Vulkan dispatch
    --ubatch-size 4096     # увеличен с default 512 -- ускоряет prompt processing на 20-30%
    --cache-reuse 256      # KV-cache shifting (full attention, работает 100%)
    --cache-type-k q8_0    # KV cache K quantization: 2.5 GiB → 1.25 GiB, потеря <0.5%
    --cache-type-v q8_0    # KV cache V quantization: то же
    --keep 1500            # сохранять первые 1500 токенов system prompt при context shift
    --no-mmap              # модель 18 GiB сразу в RAM, без mmap-overhead
    --jinja                # Jinja2 chat-template
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
