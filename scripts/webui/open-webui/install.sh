#!/bin/bash
# Установка Open WebUI (pull Docker-образа)

set -euo pipefail
source "$(dirname "$0")/config.sh"

check_docker || exit 1

echo "Загрузка Open WebUI..."
docker pull "$OPENWEBUI_IMAGE"

echo ""
echo "Запуск: ./scripts/webui/open-webui/start.sh"
