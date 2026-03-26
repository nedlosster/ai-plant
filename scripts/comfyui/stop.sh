#!/bin/bash
# Остановка ComfyUI сервера

set -euo pipefail
source "$(dirname "$0")/common/config.sh"

if pgrep -f "python.*main.py.*--port.*${COMFYUI_PORT}" > /dev/null 2>&1; then
    echo "Остановка ComfyUI (порт $COMFYUI_PORT)..."
    pkill -f "python.*main.py.*--port.*${COMFYUI_PORT}" || true
    sleep 1
    # Проверка
    if pgrep -f "python.*main.py.*--port.*${COMFYUI_PORT}" > /dev/null 2>&1; then
        echo "Принудительная остановка..."
        pkill -9 -f "python.*main.py.*--port.*${COMFYUI_PORT}" || true
    fi
    echo "ComfyUI остановлен"
elif pgrep -f "python.*main.py.*comfyui\|python.*main.py.*--listen" > /dev/null 2>&1; then
    echo "Остановка ComfyUI (процесс найден)..."
    pkill -f "python.*main.py.*--listen" || true
    echo "ComfyUI остановлен"
else
    echo "ComfyUI не запущен"
fi
