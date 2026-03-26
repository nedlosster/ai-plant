#!/bin/bash
# Запуск ACE-Step 1.5 (Gradio UI)
# Использование: ./scripts/music/ace-step/start.sh [--daemon|-d]

set -euo pipefail
source "$(dirname "$0")/config.sh"

check_acestep || exit 1

# Парсинг --daemon
DAEMON=false
for arg in "$@"; do
    [[ "$arg" == "--daemon" || "$arg" == "-d" ]] && DAEMON=true
done

check_port_free "$ACESTEP_PORT" || exit 1

echo "Запуск ACE-Step 1.5:"
echo "  Gradio UI: http://localhost:${ACESTEP_PORT}"
echo "  DiT:       $ACESTEP_CONFIG_PATH"
echo "  LM:        $ACESTEP_LM_MODEL_PATH"
echo "  Модели:    $ACESTEP_MODELS_DIR"
echo "  Режим:     $(if $DAEMON; then echo 'daemon'; else echo 'foreground'; fi)"
echo ""

cd "$ACESTEP_DIR"

# Запуск через .venv/bin/python (не uv run -- uv сбрасывает ROCm torch)
ACESTEP_CMD=".venv/bin/python -m acestep.acestep_v15_pipeline --port $ACESTEP_PORT --server-name 0.0.0.0 --init_llm true --lm_model_path $ACESTEP_LM_MODEL_PATH"

if $DAEMON; then
    log_file="/tmp/ace-step-${ACESTEP_PORT}.log"
    nohup $ACESTEP_CMD > "$log_file" 2>&1 &
    pid=$!
    echo "PID: $pid"
    echo "Лог: tail -f $log_file"
    echo ""
    echo "Ожидание запуска..."
    for _ in $(seq 1 90); do
        if curl -s --connect-timeout 1 "http://localhost:${ACESTEP_PORT}" 2>/dev/null | grep -q "html" 2>/dev/null; then
            echo "Запущен: http://localhost:${ACESTEP_PORT}"
            exit 0
        fi
        sleep 1
    done
    echo "ПРЕДУПРЕЖДЕНИЕ: не ответил за 90 сек (загрузка моделей)"
    echo "  Логи: tail -f $log_file"
else
    exec $ACESTEP_CMD
fi
