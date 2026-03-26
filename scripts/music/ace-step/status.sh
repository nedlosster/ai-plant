#!/bin/bash
# Статус ACE-Step

set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "=== ACE-Step 1.5 ==="

printf "Процесс:  "
if pgrep -f "acestep" > /dev/null 2>&1; then
    echo "запущен (PID: $(pgrep -f 'acestep' | head -1))"
else
    echo "остановлен"
fi

printf "Gradio:   "
if curl -s --connect-timeout 2 "http://localhost:${ACESTEP_PORT}" 2>/dev/null | grep -q "html" 2>/dev/null; then
    echo "http://localhost:${ACESTEP_PORT}"
else
    echo "недоступен"
fi

printf "DiT:      %s\n" "$ACESTEP_CONFIG_PATH"
printf "LM:       %s\n" "$ACESTEP_LM_MODEL_PATH"
printf "Модели:   %s\n" "$ACESTEP_MODELS_DIR"

if [[ -d "$ACESTEP_DIR" ]]; then
    printf "Директория: %s\n" "$ACESTEP_DIR"
else
    printf "Директория: не установлен\n"
fi
