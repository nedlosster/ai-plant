#!/bin/bash
# Остановка Lobe Chat

set -euo pipefail
source "$(dirname "$0")/config.sh"

if docker ps -q -f name="$LOBECHAT_CONTAINER" 2>/dev/null | grep -q .; then
    echo "Остановка $LOBECHAT_CONTAINER..."
    docker stop "$LOBECHAT_CONTAINER" > /dev/null
    docker rm "$LOBECHAT_CONTAINER" > /dev/null
    echo "Lobe Chat остановлен"
else
    echo "Lobe Chat не запущен"
fi
