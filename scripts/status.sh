#!/bin/bash
# Общий статус системы: GPU, inference, веб-интерфейсы, модели

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source inference config (нижний слой)
source "${SCRIPT_DIR}/inference/common/config.sh"

echo "=== GPU ==="
if [[ -f "$GPU_BUSY" ]]; then
    printf "Загрузка: %s%%, VRAM: %s / %s, " \
        "$(cat "$GPU_BUSY")" \
        "$(human_size "$(cat "$VRAM_USED")")" \
        "$(human_size "$(cat "$VRAM_TOTAL")")"
    printf "%dC, %dW, %d MHz\n" \
        "$(( $(cat $GPU_TEMP) / 1000 ))" \
        "$(( $(cat $GPU_POWER) / 1000000 ))" \
        "$(( $(cat $GPU_FREQ) / 1000000 ))"
else
    echo "GPU sysfs не доступен"
fi

echo ""
echo "=== Inference (backend: $BACKEND) ==="
if [[ -x "$LLAMA_CLI" ]]; then
    "$LLAMA_CLI" --version 2>&1 | grep 'version:' | head -1
fi
for port in $DEFAULT_PORT_CHAT $DEFAULT_PORT_FIM; do
    printf "  :%-5s " "$port"
    health=$(curl -s --connect-timeout 1 "http://localhost:${port}/health" 2>/dev/null || echo "")
    if echo "$health" | grep -q "ok" 2>/dev/null; then
        model=$(pgrep -af "llama-server.*--port $port" 2>/dev/null | grep -oP '(?<=-m )\S+' | xargs -r basename || true)
        echo "OK${model:+ ($model)}  Web UI: http://localhost:${port}"
    else
        echo "не запущен"
    fi
done

echo ""
echo "=== Веб-интерфейсы ==="
if command -v docker &>/dev/null; then
    source "${SCRIPT_DIR}/webui/config.sh"
    # Переменные контейнеров (не source'ить подпапки -- SCRIPT_DIR конфликт)
    OPENWEBUI_PORT="${OPENWEBUI_PORT:-3210}"
    OPENWEBUI_CONTAINER="open-webui"
    LOBECHAT_PORT="${LOBECHAT_PORT:-3211}"
    LOBECHAT_CONTAINER="lobe-chat"
    check_container "$OPENWEBUI_CONTAINER" "$OPENWEBUI_PORT"
    check_container "$LOBECHAT_CONTAINER" "$LOBECHAT_PORT"
else
    echo "Docker не установлен"
fi

echo ""
echo "=== ComfyUI ==="
COMFYUI_PORT="${COMFYUI_PORT:-8188}"
printf "  :%-5s " "$COMFYUI_PORT"
if curl -s --connect-timeout 1 "http://localhost:${COMFYUI_PORT}/system_stats" &>/dev/null; then
    echo "OK  Web UI: http://localhost:${COMFYUI_PORT}"
else
    echo "не запущен"
fi

echo ""
echo "=== Музыка ==="
printf "ACE-Step:       "
if pgrep -f "acestep" > /dev/null 2>&1; then
    ACESTEP_PORT="${ACESTEP_PORT:-7860}"
    echo "запущен (http://localhost:${ACESTEP_PORT})"
else
    echo "остановлен"
fi

echo ""
echo "=== Модели ==="
if [[ -d "$MODELS_DIR" ]]; then
    list_models
else
    echo "  $MODELS_DIR не существует"
fi
