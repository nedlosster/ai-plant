#!/bin/bash
# Статус ComfyUI: процесс, модели, GPU
# Backend: AI_BACKEND=vulkan|rocm (или автодетект)

set -euo pipefail
source "$(dirname "$0")/common/config.sh"

echo "=== ComfyUI (backend: $BACKEND) ==="

# --- Процесс ---
printf "Статус:      "
if pgrep -f "python.*main.py.*--listen" > /dev/null 2>&1; then
    _pid=$(pgrep -f "python.*main.py.*--listen" | head -1)
    printf "запущен (PID: %s)\n" "$_pid"
    # Health check
    printf "Порт:        %s" "$COMFYUI_PORT"
    if curl -s --connect-timeout 1 "http://localhost:${COMFYUI_PORT}/system_stats" &>/dev/null; then
        printf " (OK)\n"
    else
        printf " (не отвечает)\n"
    fi
else
    echo "остановлен"
fi

# --- ComfyUI ---
printf "Каталог:     %s" "$COMFYUI_DIR"
if [[ -f "${COMFYUI_DIR}/main.py" ]]; then
    echo " (установлен)"
else
    echo " (не установлен)"
fi

printf "venv:        %s" "$COMFYUI_VENV"
if [[ -x "$COMFYUI_PYTHON" ]]; then
    echo " (OK)"
else
    echo " (не создан)"
fi

if [[ "$BACKEND" == "vulkan" ]]; then
    printf "GGUF plugin: "
    if [[ -d "$COMFYUI_GGUF_NODE" ]]; then
        echo "установлен"
    else
        echo "не установлен"
    fi
fi

# --- GPU ---
echo ""
echo "=== GPU ==="
if [[ -f "$GPU_BUSY" ]]; then
    printf "Загрузка:    %s%%\n" "$(cat "$GPU_BUSY")"
    printf "VRAM:        %s / %s\n" \
        "$(human_size "$(cat "$VRAM_USED")")" \
        "$(human_size "$(cat "$VRAM_TOTAL")")"
    printf "Температура: %dC\n" "$(( $(cat $GPU_TEMP) / 1000 ))"
    printf "Мощность:    %dW\n" "$(( $(cat $GPU_POWER) / 1000000 ))"
fi

# --- Модели ---
echo ""
echo "=== Модели ==="
list_comfyui_models
