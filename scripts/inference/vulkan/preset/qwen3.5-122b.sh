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
# Характеристики (по llama-server log на b8717):
#   - 122B total / 10B active (top-8 из 128 экспертов)
#   - general.architecture = qwen35moe (49 layers offload)
#   - **HYBRID Gated DeltaNet**: только 12 attention layers из 49,
#     остальные 37 -- recurrent SSM. Это значит:
#     - cache-reuse intra-task работает через встроенный checkpoint
#       механизм llama-server (см. логи: "created/restored context checkpoint")
#     - inter-task cache архитектурно blocked (как у Coder Next, 35B-text)
#       до merge llama.cpp PR #19670
#   - n_ctx_train = 262144 (256K native)
#   - n_embd = 3072, head_count_kv = 2 (агрессивный GQA)
#   - SWE-bench Verified ожидание ~75% (по public leaderboard 2026)
#
# Расширение контекста с 128K до 256K (применено 2026-04-29):
#   Native maximum модели = 262144 (256K). KV cache на 12 attention layers
#   очень компактный: ~25 KiB/token на slot с q8_0. На 256K + parallel 2:
#   - модель 71 GiB
#   - KV cache: 256K × 2 slots × 25 KiB ≈ 6.4 GiB
#   - Итого ~78 GiB из 120 GiB unified -- запас 42 GiB
#
# Оптимизации (применены 2026-04-29):
# - --batch-size 4096 + --ubatch-size 4096 -- ускоряет prompt processing 20-30%
# - --cache-reuse 256 -- intra-task через встроенный checkpoint механизм
# - --cache-type-k q8_0 / --cache-type-v q8_0 -- KV cache 50% памяти, потеря <0.5%
# - --keep 1500 -- защита system prompt при context shift
# - --no-mmap -- модель 71 GiB сразу в RAM (стабильнее latency, меньше I/O)
# - --reasoning off -- встроенный thinking-режим Qwen3.5 ломает aider whole edit format

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
    -c 262144              # контекст 256K (native train, помещается с большим запасом)
    -fa on                 # flash attention
    --parallel 2           # 2 слота -- запас памяти на KV (большая модель)
    --batch-size 4096      # PP optimization
    --ubatch-size 4096     # ускоряет prompt processing 20-30%
    --cache-reuse 256      # intra-task multi-turn re-use через встроенный checkpoint
    --cache-type-k q8_0    # KV cache K quantization: 50% памяти, потеря <0.5%
    --cache-type-v q8_0    # KV cache V quantization
    --keep 1500            # защита system prompt при context shift
    --no-mmap              # модель 71 GiB сразу в RAM
    --jinja                # Jinja2 chat-template (function calling)
    --reasoning off        # отключаем thinking-режим (Qwen3.5 встроенный)
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
