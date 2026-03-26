#!/bin/bash
# Установка Lobe Chat (pull Docker-образа)

set -euo pipefail
source "$(dirname "$0")/config.sh"

check_docker || exit 1

echo "Загрузка Lobe Chat..."
docker pull "$LOBECHAT_IMAGE"

echo ""
echo "Запуск: ./scripts/webui/lobe-chat/start.sh"
