#!/bin/bash
# Запуск TTS-WebUI (Gradio)
# Использование: ./scripts/tts/start.sh [--daemon|-d]

set -euo pipefail
source "$(dirname "$0")/config.sh"

check_tts || exit 1
check_port_free "$TTS_PORT" || exit 1

# Парсинг --daemon
DAEMON=false
for arg in "$@"; do
    [[ "$arg" == "--daemon" || "$arg" == "-d" ]] && DAEMON=true
done

echo "Запуск TTS-WebUI:"
echo "  Gradio UI:   http://localhost:${TTS_PORT}"
echo "  Директория:  $TTS_DIR"
echo "  Кэш моделей: $HF_HOME"
echo "  ROCm:        HSA_OVERRIDE=$HSA_OVERRIDE_GFX_VERSION"
echo "  Режим:       $(if $DAEMON; then echo 'daemon'; else echo 'foreground'; fi)"
echo ""

cd "$TTS_DIR"

# TTS-WebUI ставит conda-env в installer_files/env/.
# Запуск через bin/python (НЕ через uv) -- сохранение ROCm torch.
TTS_PYTHON="$TTS_DIR/installer_files/env/bin/python"
if [[ ! -x "$TTS_PYTHON" ]]; then
    echo "ПРЕДУПРЕЖДЕНИЕ: $TTS_PYTHON не найден -- использую системный python"
    TTS_PYTHON="python3"
fi

# В TTS-WebUI основной запуск через server.py с указанием порта
TTS_CMD="$TTS_PYTHON server.py --port $TTS_PORT --listen"

if $DAEMON; then
    LOG_FILE="/tmp/tts-webui-${TTS_PORT}.log"
    nohup $TTS_CMD > "$LOG_FILE" 2>&1 &
    PID=$!
    echo "PID: $PID"
    echo "Лог: tail -f $LOG_FILE"
    echo ""
    echo "Ожидание запуска (загрузка моделей)..."
    for _ in $(seq 1 120); do
        if curl -s --connect-timeout 1 "http://localhost:${TTS_PORT}" 2>/dev/null | grep -q "html" 2>/dev/null; then
            echo "Запущен: http://localhost:${TTS_PORT}"
            exit 0
        fi
        sleep 1
    done
    echo "ПРЕДУПРЕЖДЕНИЕ: не ответил за 120 сек (загрузка моделей идёт долго)"
    echo "  Логи: tail -f $LOG_FILE"
else
    exec $TTS_CMD
fi
