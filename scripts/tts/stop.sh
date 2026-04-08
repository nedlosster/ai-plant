#!/bin/bash
# Остановка TTS-WebUI
# Использование: ./scripts/tts/stop.sh

set -euo pipefail
source "$(dirname "$0")/config.sh"

PIDS=$(pgrep -f "server.py.*--port ${TTS_PORT}" 2>/dev/null || true)

if [[ -z "$PIDS" ]]; then
    echo "TTS-WebUI не запущен (порт $TTS_PORT свободен)"
    exit 0
fi

echo "Остановка TTS-WebUI (PIDs: $PIDS)..."
echo "$PIDS" | xargs -r kill

sleep 2

# Проверка
if pgrep -f "server.py.*--port ${TTS_PORT}" >/dev/null 2>&1; then
    echo "Не удалось остановить мягко, отправляю SIGKILL..."
    pgrep -f "server.py.*--port ${TTS_PORT}" | xargs -r kill -9
fi

echo "TTS-WebUI остановлен"
