#!/bin/bash
# Vulkan: Qwen3.6-35B-A3B Q4_K_M (multimodal MoE coder)
#
# Default daily agent на платформе с релиза 16 апреля 2026.
# Sparse MoE 35B total / 3B active с встроенным vision encoder.
# SWE-bench Verified 73.4%, оценка ~80 tok/s tg, ~700-1000 prefill.
# mmproj F16 подключается отдельным флагом --mmproj.
#
# Cache-reuse не используется по двум причинам:
#   1. Hybrid Gated DeltaNet (recurrent state) -- llama.cpp игнорирует
#      `--cache-reuse N` со строкой "forcing full prompt re-processing".
#   2. Multimodal -- llama.cpp явно отключает: "cache_reuse is not supported
#      by multimodal, it will be disabled".
# Отслеживание: docs/inference/optimization-backlog.md (U-001), llama.cpp PR 13194.
#
# Оптимизации (применены 2026-04-29):
# - --cache-type-k q8_0 / --cache-type-v q8_0 -- KV cache 2.5 GiB → 1.25 GiB, потеря <0.5%
# - --keep 1500 -- защита system prompt при context shift в multi-turn agent сессиях
# - --no-mmap -- модель 20.6 GiB + mmproj 858 MB сразу в RAM (стабильнее latency)

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf"
MMPROJ="${MODELS_DIR}/mmproj-Qwen3.6-35B-A3B-F16.gguf"
PORT=8085

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --mmproj "$MMPROJ"     # vision-проектор (Qwen3.6 multimodal)
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 131072              # контекст 128K
    -fa on                 # flash attention
    --parallel 4           # 4 слота (MoE A3B даёт скорость)
    --batch-size 4096      # увеличен с default 2048 -- меньше overhead на Vulkan dispatch
    --ubatch-size 4096     # увеличен с default 512 -- ускоряет prompt processing на 20-30%
    --cache-type-k q8_0    # KV cache K quantization: 2.5 GiB → 1.25 GiB, потеря <0.5%
    --cache-type-v q8_0    # KV cache V quantization: то же
    --keep 1500            # сохранять первые 1500 токенов system prompt при context shift
    --no-mmap              # модель сразу в RAM, без mmap-overhead
    --jinja                # Jinja2 chat-template (function calling)
    --reasoning off        # отключаем thinking-режим (Qwen3.6 встроенный)
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }
[[ -f "$MMPROJ" ]] || { echo "ОШИБКА: mmproj не найден: $MMPROJ"; echo "  Загрузить: ./scripts/inference/download-model.sh unsloth/Qwen3.6-35B-A3B-GGUF --include '*mmproj*F16*'"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
