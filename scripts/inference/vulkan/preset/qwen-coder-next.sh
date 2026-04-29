#!/bin/bash
# Vulkan: Qwen3-Coder-Next 80B-A3B (стабильно с opencode)
#
# Hybrid-архитектура (Gated DeltaNet + full attention). Inter-task cache-reuse
# blocked: recurrent state не сохраняется. Лог содержит "forcing full prompt
# re-processing due to lack of cache data". PR #19670 (hybrid memory snapshot)
# upstream pending.
#
# НО intra-task cache работает через slot context checkpoints (PR #20819):
# "restored context checkpoint" / "created context checkpoint N of 32".
# Поэтому --cache-reuse 256 имеет смысл -- ускоряет multi-turn внутри одной задачи.
# См. docs/inference/optimization-backlog.md (U-001), llama.cpp PR 13194/19670/20819.
#
# Оптимизация PP (важно из-за hybrid memory -- много full re-processing'а):
# - --batch-size 4096 + --ubatch-size 4096 -- ускоряет prompt processing на 20-30%
# - --cache-reuse 256 -- intra-task через slot checkpoints (PR #20819)
# - --cache-type-k q8_0 / --cache-type-v q8_0 -- KV cache на 256K: ~10 GiB → ~5 GiB,
#   потеря точности <0.5%, важно для --parallel 4 на больших контекстах
# - --keep 1500 -- system prompt персистентен через context shift в multi-turn
# - --no-mmap -- модель сразу в RAM (45 GiB на 120 GiB unified), стабильнее latency
# Эмпирически замерено на full прогоне 2026-04-27 (cache hit rate 32% intra-task).

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3-Coder-Next-Q4_K_M/Qwen3-Coder-Next-Q4_K_M-00001-of-00004.gguf"
PORT=8081

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 256000              # контекст 256K
    -fa on                 # flash attention
    --parallel 4           # 4 слота для параллельных запросов
    --batch-size 4096      # увеличен с default 2048 -- меньше overhead на Vulkan dispatch
    --ubatch-size 4096     # увеличен с default 512 -- ускоряет prompt processing на 20-30%
    --cache-reuse 256      # intra-task multi-turn re-use через slot checkpoints (PR #20819)
    --cache-type-k q8_0    # KV cache K quantization: на 256K ~10 GiB → ~5 GiB, потеря <0.5%
    --cache-type-v q8_0    # KV cache V quantization: то же
    --keep 1500            # сохранять первые 1500 токенов system prompt при context shift
    --no-mmap              # модель сразу в RAM, без mmap-overhead (45 GiB на 120 GiB unified)
    --jinja                # Jinja2 chat-template (function calling)
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
