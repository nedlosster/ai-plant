#!/bin/bash
# Запуск Open WebUI

set -euo pipefail
source "$(dirname "$0")/config.sh"

check_docker || exit 1
check_inference

if docker ps -q -f name="$OPENWEBUI_CONTAINER" 2>/dev/null | grep -q .; then
    echo "Open WebUI уже запущен: http://localhost:${OPENWEBUI_PORT}"
    exit 0
fi

docker rm -f "$OPENWEBUI_CONTAINER" 2>/dev/null || true
mkdir -p "$OPENWEBUI_DATA"

echo "Запуск Open WebUI (порт $OPENWEBUI_PORT)..."
docker run -d \
    -p "${OPENWEBUI_PORT}:8080" \
    -e OPENAI_API_BASE_URL="$LLAMA_API_URL" \
    -e OPENAI_API_KEY=none \
    -e WEBUI_AUTH=false \
    -v "${OPENWEBUI_DATA}:/app/backend/data" \
    --add-host=host.docker.internal:host-gateway \
    --name "$OPENWEBUI_CONTAINER" \
    --restart unless-stopped \
    "$OPENWEBUI_IMAGE" > /dev/null

echo "Open WebUI: http://localhost:${OPENWEBUI_PORT}"
echo "Backend:    ${LLAMA_API_URL}"
echo ""
echo "Ожидание запуска..."
for _ in $(seq 1 30); do
    if curl -s --connect-timeout 1 "http://localhost:${OPENWEBUI_PORT}" 2>/dev/null | grep -q "html"; then
        echo "Запущен"
        exit 0
    fi
    sleep 1
done
echo "ПРЕДУПРЕЖДЕНИЕ: не ответил за 30 сек (первый запуск может занять до 2 мин)"
echo "  Логи: docker logs $OPENWEBUI_CONTAINER"
