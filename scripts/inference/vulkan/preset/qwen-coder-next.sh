#!/bin/bash
# Vulkan: Qwen3-Coder-Next 80B-A3B (стабильно с opencode)
#
# Hybrid-архитектура (Gated DeltaNet + full attention) -- recurrent state не
# поддерживает cache-reuse в текущем llama.cpp. Любой `--cache-reuse N`
# молча игнорируется со строкой "forcing full prompt re-processing due to
# lack of cache data" в логе. Не указываем флаг чтобы не вводить в заблуждение.
# Отслеживание: docs/inference/optimization-backlog.md (U-001), llama.cpp PR 13194.
#
# Оптимизация PP (важно из-за hybrid memory -- много full re-processing'а):
# - --batch-size 4096 + --ubatch-size 4096 -- ускоряет prompt processing на 20-30%
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
