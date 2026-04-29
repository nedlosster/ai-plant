#!/bin/bash
# Vulkan: Qwen3.5 122B-A10B Q4_K_M (самая большая MoE на платформе)
#
# 71 GiB модель + KV-cache. Помещается в 120 GiB Vulkan unified memory,
# но не в HIP (hipMalloc лимит ~30-35 GiB единый буфер).
#
# A10B = 10B active parameters -- значимо больше чем у A3B (Qwen3.6-35B,
# Coder Next). Single-shot качество значительно выше за счёт большего
# active compute. Trade-off: tg ~30-40 tok/s vs ~58 tok/s у A3B.
#
# Характеристики:
#   - 122B total / 10B active (top-8 из 128 экспертов)
#   - Standard MoE attention (НЕ hybrid Gated DeltaNet) -- cache-reuse работает!
#   - Это ВАЖНО -- единственная топ-модель на платформе с full cache reuse
#     между запросами. Coder Next / 35B-text имеют hybrid blocking.
#   - SWE-bench Verified ожидание ~75% (по public leaderboard 2026)
#
# Оптимизации (применены 2026-04-29):
# - --batch-size 4096 + --ubatch-size 4096 -- ускоряет prompt processing 20-30%
# - --cache-reuse 256 -- РАБОТАЕТ полностью (full attention MoE)
# - --cache-type-k q8_0 / --cache-type-v q8_0 -- KV cache на 128K: ~5 GiB → ~2.5 GiB
# - --keep 1500 -- защита system prompt при context shift
# - --no-mmap -- модель 71 GiB сразу в RAM (стабильнее latency, меньше I/O)

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Q4_K_M/Qwen3.5-122B-A10B-Q4_K_M-00001-of-00003.gguf"
PORT=8081

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 131072              # контекст 128K (модель 71 GiB + KV ~2.5 GiB c q8 = 73.5 GiB на 120 GiB)
    -fa on                 # flash attention
    --parallel 2           # 2 слота -- запас памяти на KV (большая модель)
    --batch-size 4096      # PP optimization
    --ubatch-size 4096     # ускоряет prompt processing 20-30%
    --cache-reuse 256      # KV-cache shifting (full attention MoE -- работает 100%)
    --cache-type-k q8_0    # KV cache K quantization: 50% памяти, потеря <0.5%
    --cache-type-v q8_0    # KV cache V quantization
    --keep 1500            # защита system prompt при context shift
    --no-mmap              # модель 71 GiB сразу в RAM
    --jinja                # Jinja2 chat-template (function calling)
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
