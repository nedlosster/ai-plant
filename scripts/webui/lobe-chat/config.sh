#!/bin/bash
# Lobe Chat: переменные
# Подключение: source "$(dirname "$0")/config.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"

LOBECHAT_PORT="${LOBECHAT_PORT:-3211}"
LOBECHAT_CONTAINER="lobe-chat"
LOBECHAT_IMAGE="lobehub/lobe-chat"
