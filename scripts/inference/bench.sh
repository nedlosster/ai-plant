#!/bin/bash
# Бенчмарк модели (prompt processing + token generation)
# Использование: ./scripts/inference/bench.sh <model.gguf> [prompt_tokens] [gen_tokens]
# Backend: AI_BACKEND=vulkan|rocm (или автодетект)

set -euo pipefail
source "$(dirname "$0")/common/config.sh"

if [[ $# -eq 0 ]]; then
    echo "Использование: $0 <model.gguf> [prompt_tokens] [gen_tokens]"
    echo ""
    echo "  prompt_tokens -- длина промпта (по умолчанию: 512)"
    echo "  gen_tokens    -- число генерируемых токенов (по умолчанию: 128)"
    echo ""
    echo "Доступные модели:"
    list_models
    exit 1
fi

MODEL_PATH=$(resolve_model "$1")
[[ -z "$MODEL_PATH" ]] && { echo "ОШИБКА: модель не найдена: $1"; exit 1; }

[[ ! -x "$LLAMA_BENCH" ]] && { echo "ОШИБКА: llama-bench не собран"; exit 1; }

PP="${2:-512}"
TG="${3:-128}"

echo "Бенчмарк: $(basename "$MODEL_PATH")"
echo "  pp=${PP}, tg=${TG}, ngl=${DEFAULT_NGL}"
echo ""

exec "$LLAMA_BENCH" -m "$MODEL_PATH" -ngl "$DEFAULT_NGL" -p "$PP" -n "$TG" -t 16
