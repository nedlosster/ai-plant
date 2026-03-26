#!/bin/bash
# Open WebUI: переменные
# Подключение: source "$(dirname "$0")/config.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"

OPENWEBUI_PORT="${OPENWEBUI_PORT:-3210}"
OPENWEBUI_CONTAINER="open-webui"
OPENWEBUI_IMAGE="ghcr.io/open-webui/open-webui:main"
OPENWEBUI_DATA="${HOME}/.open-webui"
