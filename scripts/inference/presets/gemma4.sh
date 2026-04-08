#!/bin/bash
# Запуск Gemma 4 26B-A4B на порту 8081 с безопасными параметрами
#
# Особенности и причины ограничений:
# - Контекст 64K (не 256K) -- Gemma 4 не поддерживает cache shifting,
#   плюс sliding window attention требует больше RAM на checkpoints
#   (32 чекпоинта × 765 MiB = 24 GiB только на снимки -- OOM)
# - --parallel 1 -- один слот, чтобы не множить KV cache на 4
# - --no-mmap -- модель сразу в RAM, без виртуальной памяти под mmap
# - --jinja наследуется из run_server (нужен для function calling Gemma 4)
#
# Использование: ./scripts/inference/presets/gemma4.sh [--daemon|-d]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/config.sh"

MODEL="${MODELS_DIR}/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf"
PORT=8081
CTX=65536

if [[ ! -f "$MODEL" ]]; then
    echo "ОШИБКА: модель не найдена: $MODEL"
    exit 1
fi

check_server_binary || exit 1
check_port_free "$PORT" || exit 1

parse_daemon_flag "$@"

# Кастомный запуск (не через run_server) -- нужны спец. флаги для Gemma 4
LOG_FILE="/tmp/llama-server-${PORT}.log"

echo "Запуск llama-server (Gemma 4, безопасный пресет):"
echo "  Backend:    $BACKEND ($BUILD_SUFFIX)"
echo "  Модель:     $(basename "$MODEL")"
echo "  Порт:       $PORT"
echo "  Контекст:   $CTX (64K -- ограничение из-за sliding window)"
echo "  Слоты:      1 (--parallel 1)"
echo "  mmap:       выкл (--no-mmap)"
echo "  GPU:        $DEFAULT_NGL слоев"
echo "  Режим:      $(if $DAEMON; then echo "daemon (лог: $LOG_FILE)"; else echo "foreground"; fi)"
echo ""

if $DAEMON; then
    nohup "$LLAMA_SERVER" \
        -m "$MODEL" --port "$PORT" -ngl "$DEFAULT_NGL" \
        -fa on -c "$CTX" --host "$DEFAULT_HOST" \
        --parallel 1 --no-mmap --jinja \
        > "$LOG_FILE" 2>&1 &
    pid=$!
    echo "PID: $pid"
    echo "Лог: tail -f $LOG_FILE"
    for _ in $(seq 1 60); do
        if curl -s --connect-timeout 1 "http://localhost:${PORT}/health" 2>/dev/null | grep -q "ok"; then
            echo "Сервер запущен"
            exit 0
        fi
        sleep 1
    done
    echo "ПРЕДУПРЕЖДЕНИЕ: сервер не ответил за 60 сек"
    echo "  Проверить: tail -f $LOG_FILE"
else
    exec "$LLAMA_SERVER" \
        -m "$MODEL" --port "$PORT" -ngl "$DEFAULT_NGL" \
        -fa on -c "$CTX" --host "$DEFAULT_HOST" \
        --parallel 1 --no-mmap --jinja
fi
