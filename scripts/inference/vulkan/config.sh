#!/bin/bash
# Vulkan backend: переменные и функции
# Подключение: source "$(dirname "$0")/config.sh"

export AI_BACKEND=vulkan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/config.sh"
