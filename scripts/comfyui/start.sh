#!/bin/bash
# Запуск ComfyUI сервера
# Использование: ./scripts/comfyui/start.sh [--daemon|-d] [--port PORT]

set -euo pipefail
source "$(dirname "$0")/common/config.sh"

parse_daemon_flag "$@"
set -- "${PARSED_ARGS[@]+"${PARSED_ARGS[@]}"}"

# Парсинг --port
PORT="$COMFYUI_PORT"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port) PORT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

check_comfyui || exit 1
check_comfyui_venv || exit 1
check_port_free "$PORT" || exit 1

# ROCm: переменные окружения
EXTRA_ENV=""
if [[ "$BACKEND" == "rocm" ]]; then
    EXTRA_ENV="HSA_OVERRIDE_GFX_VERSION=${HSA_OVERRIDE_GFX_VERSION}"
fi

echo "Запуск ComfyUI:"
echo "  Backend:  $BACKEND"
echo "  Порт:     $PORT"
echo "  venv:     $COMFYUI_VENV"
echo "  Режим:    $(if $DAEMON; then echo "daemon (лог: $COMFYUI_LOG)"; else echo "foreground"; fi)"
echo ""

# Vulkan backend: ComfyUI-GGUF использует ggml Vulkan, PyTorch не нужен для GPU
# Флаг --cpu отключает PyTorch CUDA/ROCm (предотвращает ошибку torch.cuda.current_device)
COMFYUI_EXTRA_ARGS=""
if [[ "$BACKEND" == "vulkan" ]]; then
    COMFYUI_EXTRA_ARGS="--cpu"
fi

cd "$COMFYUI_DIR"

if $DAEMON; then
    nohup env $EXTRA_ENV "$COMFYUI_PYTHON" main.py \
        --listen "$COMFYUI_LISTEN" --port "$PORT" \
        --extra-model-paths-config "$COMFYUI_EXTRA_PATHS" \
        $COMFYUI_EXTRA_ARGS \
        > "$COMFYUI_LOG" 2>&1 &
    _pid=$!
    echo "PID: $_pid"
    echo "Лог: tail -f $COMFYUI_LOG"
    # Ожидание запуска
    for _ in $(seq 1 60); do
        if curl -s --connect-timeout 1 "http://localhost:${PORT}/system_stats" &>/dev/null; then
            echo "Сервер запущен: http://localhost:${PORT}"
            exit 0
        fi
        sleep 1
    done
    echo "ПРЕДУПРЕЖДЕНИЕ: сервер не ответил за 60 сек"
    echo "  Проверить: tail -f $COMFYUI_LOG"
else
    exec env $EXTRA_ENV "$COMFYUI_PYTHON" main.py \
        --listen "$COMFYUI_LISTEN" --port "$PORT" \
        --extra-model-paths-config "$COMFYUI_EXTRA_PATHS" \
        $COMFYUI_EXTRA_ARGS
fi
