#!/bin/bash
# Остановка Open WebUI

set -euo pipefail
source "$(dirname "$0")/config.sh"

if docker ps -q -f name="$OPENWEBUI_CONTAINER" 2>/dev/null | grep -q .; then
    echo "Остановка $OPENWEBUI_CONTAINER..."
    docker stop "$OPENWEBUI_CONTAINER" > /dev/null
    docker rm "$OPENWEBUI_CONTAINER" > /dev/null
    echo "Open WebUI остановлен"
else
    echo "Open WebUI не запущен"
fi
