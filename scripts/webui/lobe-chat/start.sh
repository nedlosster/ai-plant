#!/bin/bash
# Запуск Lobe Chat

set -euo pipefail
source "$(dirname "$0")/config.sh"

check_docker || exit 1
check_inference

if docker ps -q -f name="$LOBECHAT_CONTAINER" 2>/dev/null | grep -q .; then
    echo "Lobe Chat уже запущен: http://localhost:${LOBECHAT_PORT}"
    exit 0
fi

docker rm -f "$LOBECHAT_CONTAINER" 2>/dev/null || true

echo "Запуск Lobe Chat (порт $LOBECHAT_PORT)..."
docker run -d \
    -p "${LOBECHAT_PORT}:3210" \
    -e OPENAI_PROXY_URL="$LLAMA_API_URL" \
    -e OPENAI_API_KEY=none \
    --add-host=host.docker.internal:host-gateway \
    --name "$LOBECHAT_CONTAINER" \
    --restart unless-stopped \
    "$LOBECHAT_IMAGE" > /dev/null

echo "Lobe Chat: http://localhost:${LOBECHAT_PORT}"
echo "Backend:   ${LLAMA_API_URL}"
echo ""
echo "Ожидание запуска..."
for _ in $(seq 1 30); do
    if curl -s --connect-timeout 1 "http://localhost:${LOBECHAT_PORT}" 2>/dev/null | grep -q "html"; then
        echo "Запущен"
        exit 0
    fi
    sleep 1
done
echo "ПРЕДУПРЕЖДЕНИЕ: не ответил за 30 сек"
echo "  Логи: docker logs $LOBECHAT_CONTAINER"
