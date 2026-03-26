#!/bin/bash
# Статус веб-интерфейсов и inference backend (как зависимости)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Общий config (Docker, inference check, check_container)
source "${SCRIPT_DIR}/config.sh"

# Переменные контейнеров
OPENWEBUI_PORT="${OPENWEBUI_PORT:-3210}"
OPENWEBUI_CONTAINER="open-webui"
LOBECHAT_PORT="${LOBECHAT_PORT:-3211}"
LOBECHAT_CONTAINER="lobe-chat"

echo "=== Inference (backend) ==="
for port in $LLAMA_PORT $LLAMA_FIM_PORT; do
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
check_container "$OPENWEBUI_CONTAINER" "$OPENWEBUI_PORT"
check_container "$LOBECHAT_CONTAINER" "$LOBECHAT_PORT"
