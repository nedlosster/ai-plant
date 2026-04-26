#!/bin/bash
# Aider Polyglot Suite -- последовательный прогон по очереди agent-coding моделей.
#
# Использование:
#   ./bench-aider-suite.sh                                            # smoke (20 задач/модель) на 3 default-пресетах
#   ./bench-aider-suite.sh --quick                                    # quick (10 задач) на 3 default-пресетах
#   ./bench-aider-suite.sh --full                                     # full 225 задач (6-12 ч/модель)
#   ./bench-aider-suite.sh --include qwen3.6-35b,devstral             # конкретные пресеты
#   ./bench-aider-suite.sh --exclude qwen-coder-next                  # все default кроме одного
#   ./bench-aider-suite.sh --quick --languages python                 # 10 python задач/модель -- проверка пайплайна
#
# Между моделями автоматически stop/start llama-server. Watchdog в bench-aider.sh
# защищает от зависания (default 15 мин/задача, 6 ч на модель).
# Идемпотентен: можно перезапускать.
#
# Документация:
#   - .claude/skills/ops-engineer/SKILL.md (runbook bench-suite-aider)
#   - docs/llm-guide/benchmarks/runbooks/aider-polyglot.md

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common/config.sh"

# --- Default очередь моделей (по приоритету для agent-coding) ---
DEFAULT_PRESETS=(qwen3.6-35b qwen-coder-next qwen3-coder-30b)

# --- Параметры ---
MODE="smoke"
INCLUDE=""
EXCLUDE=""
LANGUAGES=""
TASK_TIMEOUT=""    # пусто = default из bench-aider.sh (900)
TOTAL_TIMEOUT=""   # пусто = default из bench-aider.sh (21600)

while [[ $# -gt 0 ]]; do
    case "$1" in
        --quick) MODE="quick"; shift;;
        --smoke) MODE="smoke"; shift;;
        --full)  MODE="full"; shift;;
        --include) INCLUDE="$2"; shift 2;;
        --exclude) EXCLUDE="$2"; shift 2;;
        --languages) LANGUAGES="$2"; shift 2;;
        --task-timeout) TASK_TIMEOUT="$2"; shift 2;;
        --total-timeout) TOTAL_TIMEOUT="$2"; shift 2;;
        -h|--help)
            cat <<HLP
Использование: $0 [--quick|--smoke|--full] [--include p1,p2,...] [--exclude p] [--languages LST]

Режимы (передаются в bench-aider.sh):
  --quick         10 задач/модель, --tries 1 (~30 мин/модель)  -- sanity check
  --smoke         20 задач/модель, --tries 1 (~80 мин/модель)  -- по умолчанию
  --full          225 задач/модель, --tries 2 (6-12 ч/модель)  -- leaderboard quality

Очередь моделей:
  --include       список пресетов через запятую. По умолчанию: ${DEFAULT_PRESETS[*]}
  --exclude       исключить пресет из default-очереди
  --languages     ограничить языки на каждом прогоне (cpp,go,java,javascript,python,rust)

Watchdog (передаются в bench-aider.sh):
  --task-timeout  максимум секунд между задачами (default 900 = 15 мин)
  --total-timeout максимум секунд на модель (default 21600 = 6 ч)

Примеры:
  $0                                                # smoke на 3 default моделях
  $0 --quick --include qwen3.6-35b                  # 10 задач для проверки пайплайна
  $0 --include qwen3.6-35b,devstral
  $0 --exclude qwen-coder-next
  $0 --full --include qwen3.6-35b
  $0 --quick --languages python --include qwen3.6-35b   # debug Python-задач

Требования: Docker image aider-polyglot-bench:latest + polyglot-benchmark dataset.
См. SKILL.md ops-engineer и docs/llm-guide/benchmarks/runbooks/aider-polyglot.md
HLP
            exit 0
            ;;
        *) echo "Неизвестный параметр: $1"; exit 1;;
    esac
done

# --- Формирование очереди PRESETS ---
if [[ -n "$INCLUDE" ]]; then
    IFS=',' read -ra PRESETS <<< "$INCLUDE"
else
    PRESETS=("${DEFAULT_PRESETS[@]}")
fi

if [[ -n "$EXCLUDE" ]]; then
    IFS=',' read -ra EXCLUDE_ARR <<< "$EXCLUDE"
    FILTERED=()
    for p in "${PRESETS[@]}"; do
        skip=0
        for e in "${EXCLUDE_ARR[@]}"; do
            [[ "$p" == "$e" ]] && skip=1 && break
        done
        [[ $skip -eq 0 ]] && FILTERED+=("$p")
    done
    PRESETS=("${FILTERED[@]}")
fi

[[ ${#PRESETS[@]} -eq 0 ]] && { echo "ОШИБКА: пустая очередь моделей"; exit 1; }

# --- Pre-flight checks ---
log_ts() { echo "[$(date +%H:%M:%S)] $*"; }

# Docker image (бенчмарк уходит в контейнер с полным toolchain)
DOCKER_IMAGE="aider-polyglot-bench:latest"
if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
    echo "ОШИБКА: docker image отсутствует: $DOCKER_IMAGE"
    echo "  Build: cd ~/projects/aider && docker build -f benchmark/Dockerfile -t $DOCKER_IMAGE ."
    exit 1
fi

PRESET_DIR="${SCRIPT_DIR}/vulkan/preset"
log_ts "Pre-flight check: пресеты и модели"
for p in "${PRESETS[@]}"; do
    PFILE="${PRESET_DIR}/${p}.sh"
    [[ -f "$PFILE" ]] || { echo "ОШИБКА: пресет не найден: $PFILE"; exit 1; }
    # Извлечь MODEL=... и проверить файл
    MODEL_LINE=$(grep -m1 '^MODEL=' "$PFILE" | sed 's/MODEL=//; s/"//g')
    MODEL_PATH=$(eval echo "$MODEL_LINE")  # развернуть ${MODELS_DIR}
    [[ -f "$MODEL_PATH" ]] || { echo "ОШИБКА: модель для пресета '$p' не найдена: $MODEL_PATH"; exit 1; }
    echo "  $p -> $(basename "$MODEL_PATH") ($(du -sh "$MODEL_PATH" | cut -f1))"
done

# --- Output dir ---
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUT="/tmp/aider-suite-${TIMESTAMP}"
mkdir -p "$OUT"
log_ts "Output: $OUT"

SUITE_LOG="${OUT}/suite.log"
exec > >(tee -a "$SUITE_LOG") 2>&1

log_ts "Mode: ${MODE^^}"
log_ts "Очередь: ${PRESETS[*]}"
log_ts ""

# --- Helpers ---
extract_port() {
    local pfile="$1"
    grep -m1 '^PORT=' "$pfile" | cut -d= -f2 | tr -d '"'
}

wait_health() {
    local port="$1"
    local timeout=120
    for i in $(seq 1 $timeout); do
        if curl -fs -m 2 "http://localhost:${port}/v1/models" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    return 1
}

stop_servers() {
    "${SCRIPT_DIR}/stop-servers.sh" >/dev/null 2>&1 || true
    sleep 5
}

# --- Pipeline ---
SUITE_START=$(date +%s)
declare -A RESULTS  # preset -> "passed/total time-mm:ss"

for preset in "${PRESETS[@]}"; do
    PRESET_FILE="${PRESET_DIR}/${preset}.sh"
    PORT=$(extract_port "$PRESET_FILE")

    log_ts "===== ${preset} (порт ${PORT}) ====="
    log_ts "Stop предыдущих серверов..."
    stop_servers

    log_ts "Старт llama-server: $PRESET_FILE -d"
    if ! bash "$PRESET_FILE" -d >>"$SUITE_LOG" 2>&1; then
        log_ts "ОШИБКА старта пресета '$preset', пропуск"
        RESULTS["$preset"]="START_FAILED"
        continue
    fi

    log_ts "Healthcheck (до 120 сек)..."
    if ! wait_health "$PORT"; then
        log_ts "ОШИБКА: healthcheck не прошёл за 120 сек, пропуск '$preset'"
        stop_servers
        RESULTS["$preset"]="HEALTH_FAILED"
        continue
    fi
    log_ts "OK: сервер $preset готов на порту $PORT"

    BENCH_START=$(date +%s)
    BENCH_LOG="${OUT}/${preset}.log"

    # Сборка аргументов для bench-aider.sh
    BENCH_OPTS=(--"$MODE" --model "$preset" --port "$PORT" --output "$OUT")
    [[ -n "$LANGUAGES" ]] && BENCH_OPTS+=(--languages "$LANGUAGES")
    [[ -n "$TASK_TIMEOUT" ]] && BENCH_OPTS+=(--task-timeout "$TASK_TIMEOUT")
    [[ -n "$TOTAL_TIMEOUT" ]] && BENCH_OPTS+=(--total-timeout "$TOTAL_TIMEOUT")

    log_ts "Запуск bench-aider ${BENCH_OPTS[*]}"

    if "${SCRIPT_DIR}/bench-aider.sh" "${BENCH_OPTS[@]}" \
        > >(tee -a "$BENCH_LOG") 2>&1; then
        BENCH_END=$(date +%s)
        DURATION=$((BENCH_END - BENCH_START))
        # Парсинг pass-rate -- грубо из лога
        PASSED=$(grep -oE 'Passed: [0-9]+' "$BENCH_LOG" | tail -1 | awk '{print $2}' || echo "?")
        TOTAL=$(grep -oE 'Tasks: [0-9]+|Tests: [0-9]+' "$BENCH_LOG" | tail -1 | awk '{print $2}' || echo "?")
        RESULTS["$preset"]="${PASSED}/${TOTAL} $((DURATION / 60))m"
        log_ts "Готово: $preset = ${RESULTS[$preset]}"
    else
        log_ts "ОШИБКА: bench-aider упал на '$preset'"
        RESULTS["$preset"]="BENCH_FAILED"
    fi

    log_ts "Stop $preset..."
    stop_servers
done

# --- Финальный SUMMARY ---
SUITE_END=$(date +%s)
TOTAL_TIME=$((SUITE_END - SUITE_START))
TOTAL_H=$((TOTAL_TIME / 3600))
TOTAL_M=$(((TOTAL_TIME % 3600) / 60))

SUMMARY="${OUT}/SUMMARY.md"
{
    echo "# Aider Polyglot Suite Summary"
    echo ""
    echo "**Дата**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**Mode**: ${MODE}"
    echo "**Модели**: ${PRESETS[*]}"
    echo "**Total time**: ${TOTAL_H}h ${TOTAL_M}m"
    echo "**Лог**: \`${OUT}/suite.log\`"
    echo ""
    echo "## Результаты"
    echo ""
    echo "| Модель | Результат |"
    echo "|--------|-----------|"
    for preset in "${PRESETS[@]}"; do
        echo "| ${preset} | ${RESULTS[$preset]:-NO_DATA} |"
    done
    echo ""
    echo "## Логи per model"
    echo ""
    for preset in "${PRESETS[@]}"; do
        echo "- ${preset}: \`${OUT}/${preset}.log\`"
    done
} > "$SUMMARY"

log_ts ""
log_ts "===== ЗАВЕРШЕНО за ${TOTAL_H}h ${TOTAL_M}m ====="
log_ts "Summary: $SUMMARY"
echo ""
cat "$SUMMARY"
echo ""
echo "Чтобы добавить в журнал результатов:"
echo "  cat $SUMMARY"
echo "  # затем вручную скопировать таблицу в docs/llm-guide/benchmarks/results.md"
