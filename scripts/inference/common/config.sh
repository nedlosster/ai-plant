#!/bin/bash
# Общие переменные и функции для скриптов llama.cpp
# Подключение: source "$(dirname "$0")/../common/config.sh"
# Backend задаётся через AI_BACKEND (vulkan|rocm), ~/.config/ai-plant/backend или автодетект

# --- Выбор backend'а ---
detect_backend() {
    local llama="${LLAMA_DIR:-${HOME}/projects/llama.cpp}"
    if [[ -d "${llama}/build-hip" ]] && [[ -d "/opt/rocm" ]]; then
        echo "rocm"
    else
        echo "vulkan"
    fi
}

resolve_backend() {
    if [[ -n "${AI_BACKEND:-}" ]]; then
        echo "$AI_BACKEND"
    elif [[ -f "${HOME}/.config/ai-plant/backend" ]]; then
        cat "${HOME}/.config/ai-plant/backend"
    else
        detect_backend
    fi
}

BACKEND=$(resolve_backend)

# --- Пути ---
LLAMA_DIR="${LLAMA_DIR:-${HOME}/projects/llama.cpp}"
MODELS_DIR="${MODELS_DIR:-${HOME}/models}"
HF_CLI="${HOME}/.local/bin/hf"

case "$BACKEND" in
    rocm)
        BUILD_SUFFIX="build-hip"
        export ROCM_PATH="${ROCM_PATH:-/opt/rocm}"
        export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-11.5.1}"
        export PATH="${ROCM_PATH}/bin:${PATH}"
        export LD_LIBRARY_PATH="${ROCM_PATH}/lib:${LD_LIBRARY_PATH:-}"
        ;;
    vulkan|*)
        BUILD_SUFFIX="build"
        ;;
esac

BUILD_DIR="${LLAMA_DIR}/${BUILD_SUFFIX}"
LLAMA_SERVER="${BUILD_DIR}/bin/llama-server"
LLAMA_CLI="${BUILD_DIR}/bin/llama-cli"
LLAMA_BENCH="${BUILD_DIR}/bin/llama-bench"

# --- Параметры по умолчанию ---
DEFAULT_PORT_CHAT=8080
DEFAULT_PORT_FIM=8081
DEFAULT_NGL=99
DEFAULT_CTX_CHAT=32768
DEFAULT_CTX_FIM=4096
DEFAULT_HOST="0.0.0.0"

# --- sysfs GPU ---
GPU_CARD="${GPU_CARD:-card1}"
GPU_BUSY="/sys/class/drm/${GPU_CARD}/device/gpu_busy_percent"
VRAM_USED="/sys/class/drm/${GPU_CARD}/device/mem_info_vram_used"
VRAM_TOTAL="/sys/class/drm/${GPU_CARD}/device/mem_info_vram_total"
GPU_TEMP="/sys/class/drm/${GPU_CARD}/device/hwmon/hwmon*/temp1_input"
GPU_POWER="/sys/class/drm/${GPU_CARD}/device/hwmon/hwmon*/power1_average"
GPU_FREQ="/sys/class/drm/${GPU_CARD}/device/hwmon/hwmon*/freq1_input"

# --- Форматирование размера ---
human_size() {
    local bytes="${1:-0}"
    if (( bytes >= 1073741824 )); then
        echo "$(awk "BEGIN{printf \"%.1f\", $bytes/1073741824}") GiB"
    elif (( bytes >= 1048576 )); then
        echo "$(( bytes / 1048576 )) MiB"
    else
        echo "${bytes} B"
    fi
}

# --- Вывод списка моделей ---
list_models() {
    local dir="${1:-$MODELS_DIR}"
    local found=0

    # Одиночные .gguf
    while IFS= read -r f; do
        local size_h
        size_h=$(human_size "$(stat -c%s "$f" 2>/dev/null || echo 0)")
        printf "  %-55s %s\n" "${f#"$dir"/}" "$size_h"
        found=1
    done < <(find "$dir" -name "*.gguf" ! -name "*-of-*" -type f 2>/dev/null | sort)

    # Split-модели (только первый файл, суммарный размер)
    while IFS= read -r first; do
        local base="${first%-00001-of-*}"
        local total=0 parts=0
        while IFS= read -r part; do
            total=$(( total + $(stat -c%s "$part" 2>/dev/null || echo 0) ))
            (( parts++ )) || true
        done < <(find "$(dirname "$first")" -name "$(basename "$base")-*-of-*.gguf" -type f 2>/dev/null)
        local size_h
        size_h=$(human_size "$total")
        printf "  %-55s %s (%d частей)\n" "${first#"$dir"/}" "$size_h" "$parts"
        found=1
    done < <(find "$dir" -name "*-00001-of-*.gguf" -type f 2>/dev/null | sort)

    [[ $found -eq 0 ]] && echo "  (нет)"
}

# --- Поиск модели по имени ---
resolve_model() {
    local name="$1"
    local dir="${2:-$MODELS_DIR}"

    if [[ -f "$name" ]]; then
        echo "$name"
    elif [[ -f "${dir}/${name}" ]]; then
        echo "${dir}/${name}"
    else
        find "$dir" -name "$name" -type f 2>/dev/null | head -1
    fi
}

# --- Проверка llama-server ---
check_server_binary() {
    if [[ ! -x "$LLAMA_SERVER" ]]; then
        echo "ОШИБКА: llama-server не собран ($BUILD_SUFFIX)"
        echo "  Запустить: ./scripts/${BACKEND}/build.sh"
        return 1
    fi
}

# --- Проверка свободного порта ---
check_port_free() {
    local port="$1"
    if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
        echo "ОШИБКА: порт $port занят"
        ss -tlnp 2>/dev/null | grep ":${port} " | head -3
        echo "  Остановить: ./scripts/inference/stop-servers.sh"
        return 1
    fi
}

# --- Парсинг --daemon/-d из аргументов ---
parse_daemon_flag() {
    DAEMON=false
    local args=()
    for arg in "$@"; do
        if [[ "$arg" == "--daemon" ]] || [[ "$arg" == "-d" ]]; then
            DAEMON=true
        else
            args+=("$arg")
        fi
    done
    PARSED_ARGS=("${args[@]+"${args[@]}"}")
}

# --- Запуск llama-server ---
#
# Все llama-server флаги задаёт вызывающий скрипт (пресет) через массив ARGS:
#
#   ARGS=(
#       -m "$MODEL" --port 8081 -ngl 99 -c 65536
#       -fa on --host 0.0.0.0
#       --parallel 1 --cache-reuse 256 --jinja --no-mmap
#   )
#   launch_server 8081 "llama-server" "${ARGS[@]}"
#
# launch_server отвечает только за daemon/foreground и health check.
launch_server() {
    local port="$1"
    local log_prefix="$2"
    shift 2
    local log_file="/tmp/${log_prefix}-${port}.log"

    echo "Запуск llama-server:"
    echo "  Backend: $BACKEND ($BUILD_SUFFIX)"
    echo "  Порт:    $port"
    echo "  Аргументы:"
    printf '    %s\n' "$@"
    echo "  Режим:   $(if $DAEMON; then echo "daemon (лог: $log_file)"; else echo "foreground"; fi)"
    echo ""

    if $DAEMON; then
        nohup "$LLAMA_SERVER" "$@" > "$log_file" 2>&1 &
        local pid=$!
        echo "PID: $pid"
        echo "Лог: tail -f $log_file"
        for _ in $(seq 1 60); do
            if curl -s --connect-timeout 1 "http://localhost:${port}/health" 2>/dev/null | grep -q "ok"; then
                echo "Сервер запущен"
                return 0
            fi
            sleep 1
        done
        echo "ПРЕДУПРЕЖДЕНИЕ: сервер не ответил за 60 сек"
        echo "  Проверить: tail -f $log_file"
    else
        exec "$LLAMA_SERVER" "$@"
    fi
}

# --- run_server: обёртка с дефолтами для общих скриптов (start-server, start-fim) ---
# Пресеты не используют, они вызывают launch_server напрямую с явным ARGS.
run_server() {
    local model="$1"
    local port="$2"
    local ctx="$3"
    local log_prefix="$4"

    local jinja_flag=()
    [[ "${JINJA:-1}" != "0" ]] && jinja_flag=(--jinja)

    local args=(
        -m "$model" --port "$port" -ngl "$DEFAULT_NGL"
        -fa on -c "$ctx" --host "$DEFAULT_HOST"
        --parallel 4 --cache-reuse 256
        "${jinja_flag[@]}"
    )

    launch_server "$port" "$log_prefix" "${args[@]}"
}
