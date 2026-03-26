#!/bin/bash
# Мониторинг GPU в реальном времени
# Использование: ./scripts/inference/monitor.sh [interval]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common/config.sh"

INTERVAL="${1:-1}"

echo "Мониторинг GPU (интервал: ${INTERVAL}s, Ctrl+C для выхода)"
echo ""
printf "%-8s  %-6s  %-15s  %-6s  %-6s  %-8s\n" "Время" "GPU%" "VRAM (MiB)" "Temp" "Power" "Freq"
printf "%-8s  %-6s  %-15s  %-6s  %-6s  %-8s\n" "--------" "------" "---------------" "------" "------" "--------"

while true; do
    ts=$(date +%H:%M:%S)
    gpu=$(cat "$GPU_BUSY" 2>/dev/null || echo "?")
    vram_used=$(($(cat "$VRAM_USED" 2>/dev/null || echo 0) / 1048576))
    vram_total=$(($(cat "$VRAM_TOTAL" 2>/dev/null || echo 1) / 1048576))
    temp=$(($(cat $GPU_TEMP 2>/dev/null || echo 0) / 1000))
    power=$(($(cat $GPU_POWER 2>/dev/null || echo 0) / 1000000))
    freq=$(($(cat $GPU_FREQ 2>/dev/null || echo 0) / 1000000))

    printf "%-8s  %4s%%  %6d / %-6d  %4dC  %4dW  %5d MHz\n" \
        "$ts" "$gpu" "$vram_used" "$vram_total" "$temp" "$power" "$freq"

    sleep "$INTERVAL"
done
