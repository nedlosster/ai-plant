#!/bin/bash
# Vulkan: Gemma 4 26B-A4B (multimodal, vision через mmproj)
#
# Sliding Window Attention (SWA) -- cache-reuse в llama.cpp не поддержан для
# SWA-моделей. Любой `--cache-reuse N` молча игнорируется со строкой
# "forcing full prompt re-processing due to lack of cache data" в логе.
# Не указываем флаг чтобы не вводить в заблуждение.
# Отслеживание: docs/inference/optimization-backlog.md (U-001), llama.cpp PR 13194.
#
# --no-mmap      -- модель сразу в RAM, без mmap-overhead

set -euo pipefail
export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common/config.sh"

MODEL="${MODELS_DIR}/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf"
MMPROJ="${MODELS_DIR}/mmproj-BF16.gguf"   # vision-проектор для multimodal
PORT=8081

# --- llama-server параметры ---
ARGS=(
    -m "$MODEL"
    --mmproj "$MMPROJ"     # vision-проектор (Gemma 4 multimodal)
    --port "$PORT"
    --host 0.0.0.0
    -ngl 99                # все слои на GPU
    -c 250000              # контекст 250K (расширен с 64K, на платформе хватает unified memory)
    -fa on                 # flash attention
    --parallel 4           # 4 слота для параллельных запросов
    --jinja                # Jinja2 chat-template (function calling Gemma 4)
    --no-mmap              # модель сразу в RAM, без mmap-overhead
)
# ---------------------------------

[[ -f "$MODEL" ]] || { echo "ОШИБКА: модель не найдена: $MODEL"; exit 1; }
[[ -f "$MMPROJ" ]] || { echo "ОШИБКА: mmproj не найден: $MMPROJ"; echo "  Загрузить: ./scripts/inference/download-model.sh unsloth/gemma-4-26B-A4B-it-GGUF --include 'mmproj-BF16.gguf'"; exit 1; }

check_server_binary || exit 1
check_port_free "$PORT" || exit 1
parse_daemon_flag "$@"   # принимает --daemon|-d

launch_server "$PORT" "llama-server" "${ARGS[@]}"
