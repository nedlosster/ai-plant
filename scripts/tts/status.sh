#!/bin/bash
# Статус TTS-WebUI
# Использование: ./scripts/tts/status.sh

set -uo pipefail
source "$(dirname "$0")/config.sh"

echo "=== TTS-WebUI ==="

# Установка
if [[ -d "$TTS_DIR" ]]; then
    echo "Установлен:    $TTS_DIR"
    if [[ -d "$TTS_DIR/.git" ]]; then
        cd "$TTS_DIR"
        echo "Git:           $(git log --oneline -1 2>/dev/null || echo '?')"
    fi
else
    echo "НЕ установлен. Запустить: ./scripts/tts/install.sh"
    exit 0
fi

# Процесс
echo ""
PIDS=$(pgrep -af "server.py.*--port ${TTS_PORT}" 2>/dev/null || true)
if [[ -n "$PIDS" ]]; then
    echo "Сервер:        запущен"
    echo "$PIDS" | sed 's/^/  /'
else
    echo "Сервер:        остановлен"
fi

# Порт
echo ""
if curl -s --connect-timeout 2 "http://localhost:${TTS_PORT}" 2>/dev/null | grep -q "html" 2>/dev/null; then
    echo "Web UI:        http://localhost:${TTS_PORT} (доступен)"
else
    echo "Web UI:        http://localhost:${TTS_PORT} (не отвечает)"
fi

# Кэш моделей
echo ""
if [[ -d "$HF_HOME" ]]; then
    SIZE=$(du -sh "$HF_HOME" 2>/dev/null | cut -f1)
    echo "Кэш моделей:   $HF_HOME ($SIZE)"
fi
