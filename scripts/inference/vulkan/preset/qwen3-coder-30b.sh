#!/bin/bash
# Vulkan: Qwen3-Coder-30B-A3B Instruct Q4_K_M (MoE, специализирован на коде)
#
# Cache-reuse РАБОТАЕТ: standard MoE attention без Gated DeltaNet recurrent
# state, без mmproj. Единственная active-coder модель платформы где
# `--cache-reuse 256` действительно переиспользует префикс между запросами.
# Эталонный baseline для A/B тестов влияния cache-reuse на agent-coding
# производительность. См. docs/inference/optimization-backlog.md (M-001).

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
    --cache-reuse 256      # KV-cache shifting
    --jinja                # Jinja2 chat-template
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
