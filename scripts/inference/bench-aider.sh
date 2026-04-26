#!/bin/bash
# Aider Polyglot benchmark wrapper
# Запускает бенчмарк против локального llama-server в Docker'е (полный toolchain
# Python+Java+Rust+Go+Node+C++ в образе aider-polyglot-bench:latest).
#
# Режимы:
#   --quick   10 задач, --tries 1, ~20-30 мин   -- sanity check после правок
#   --smoke   20 задач, --tries 1, ~70-100 мин  -- повседневный baseline
#   --full    225 задач, --tries 2, 6-12 ч     -- полный прогон, leaderboard quality
#
# Пример:
#   ./bench-aider.sh --quick --languages python --model qwen3.6-35b --port 8085
#   ./bench-aider.sh --smoke --model qwen-coder-next --port 8081
#   ./bench-aider.sh --full  --model qwen3-coder-30b --port 8081
#
# Override-флаги (после mode):
#   --num-tests N        переопределить количество задач
#   --tries N            переопределить количество попыток
#   --languages LST      ограничить языки (cpp,go,java,javascript,python,rust)
#   --run-name NAME      переопределить имя прогона (default: <mode>-<model>-<timestamp>)
#   --cont               продолжить existing testdir (нужен --run-name); benchmark.py пропустит уже сделанные задачи
#
# Watchdog (защита от litellm retry-loop):
#   --task-timeout N     максимум секунд между завершёнными задачами (default 900 = 15 мин)
#   --total-timeout N    максимум секунд на весь прогон (default 21600 = 6 ч), 0 = unlimited
#   --max-resumes N      сколько раз auto-resume через --cont после watchdog kill (default 3)
#
# Watchdog убивает docker контейнер если:
#   - счётчик "test_cases:" не растёт в логе > task-timeout сек, либо
#   - общее время прогона > total-timeout сек
# После kill автоматически перезапускается с --cont (до max-resumes раз),
# пропуская задачу-зависалку и продолжая с следующей.
# Введён после прогона 2026-04-26 -- aider застрял в litellm retry-loop на 3 ч.
# См. docs/inference/optimization-backlog.md (A-005).
#
# Требования:
#   - Docker (для toolchain: Python, Java, Rust, Go, Node, C++)
#   - Image aider-polyglot-bench:latest собран:
#       cd ~/projects/aider && docker build -f benchmark/Dockerfile \
#         -t aider-polyglot-bench:latest .
#   - aider репо: ~/projects/aider/
#   - polyglot-benchmark dataset: ~/projects/aider/tmp.benchmarks/polyglot-benchmark/
#
# Документация: docs/llm-guide/benchmarks/runbooks/aider-polyglot.md

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common/config.sh"

# --- Defaults ---
MODE=""
MODEL=""
PORT="8085"
OUTPUT_DIR="/tmp"
LANGUAGES=""
NUM_TESTS_OVERRIDE=""
TRIES_OVERRIDE=""
RUN_NAME_OVERRIDE=""
CONT=0
TASK_TIMEOUT=900           # 15 мин без прогресса -> watchdog kill
TOTAL_TIMEOUT=21600        # 6 ч общий cap, 0 = unlimited
MAX_RESUMES=3              # auto-resume после watchdog kill

usage() {
    cat <<EOF
Использование: $0 --quick|--smoke|--full --model <name> [опции]

Режимы (определяют --num-tests и --tries):
  --quick    10 задач, --tries 1, ~20-30 мин   sanity check
  --smoke    20 задач, --tries 1, ~70-100 мин  повседневный baseline
  --full     225 задач, --tries 2, 6-12 ч     leaderboard quality

Обязательные:
  --model NAME       имя модели для логирования (qwen3.6-35b, qwen-coder-next, ...)

Override:
  --num-tests N      переопределить количество задач (после mode)
  --tries N          переопределить количество попыток
  --languages LST    ограничить языки (cpp,go,java,javascript,python,rust)
  --run-name NAME    переопределить имя прогона (default: <mode>-<model>-<timestamp>)
  --cont             продолжить existing testdir (нужен --run-name)
  --port PORT        порт llama-server (по умолчанию 8085)
  --output DIR       директория для логов (по умолчанию /tmp)

Watchdog:
  --task-timeout N   максимум секунд между завершёнными задачами (default ${TASK_TIMEOUT})
  --total-timeout N  максимум секунд на весь прогон (default ${TOTAL_TIMEOUT}, 0=unlimited)
  --max-resumes N    auto-resume через --cont после watchdog kill (default ${MAX_RESUMES}, 0 = выкл)

Документация: docs/llm-guide/benchmarks/runbooks/aider-polyglot.md
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --quick) MODE="quick"; shift;;
        --smoke) MODE="smoke"; shift;;
        --full)  MODE="full"; shift;;
        --model) MODEL="$2"; shift 2;;
        --port)  PORT="$2"; shift 2;;
        --output) OUTPUT_DIR="$2"; shift 2;;
        --languages) LANGUAGES="$2"; shift 2;;
        --num-tests) NUM_TESTS_OVERRIDE="$2"; shift 2;;
        --tries) TRIES_OVERRIDE="$2"; shift 2;;
        --run-name) RUN_NAME_OVERRIDE="$2"; shift 2;;
        --cont) CONT=1; shift;;
        --task-timeout) TASK_TIMEOUT="$2"; shift 2;;
        --total-timeout) TOTAL_TIMEOUT="$2"; shift 2;;
        --max-resumes) MAX_RESUMES="$2"; shift 2;;
        -h|--help) usage; exit 0;;
        *) echo "Неизвестный параметр: $1"; usage; exit 1;;
    esac
done

[[ -z "$MODE" ]]  && { echo "ОШИБКА: укажи --quick|--smoke|--full"; usage; exit 1; }
[[ -z "$MODEL" ]] && { echo "ОШИБКА: укажи --model <имя>"; usage; exit 1; }
[[ $CONT -eq 1 && -z "$RUN_NAME_OVERRIDE" ]] && { echo "ОШИБКА: --cont требует --run-name <existing-run-name>"; exit 1; }

# --- Mode → defaults для num-tests и tries ---
case "$MODE" in
    quick) DEFAULT_NUM_TESTS=10;  DEFAULT_TRIES=1;;
    smoke) DEFAULT_NUM_TESTS=20;  DEFAULT_TRIES=1;;
    full)  DEFAULT_NUM_TESTS=0;   DEFAULT_TRIES=2;;  # 0 = no --num-tests => все 225
esac

# Применить override либо default
NUM_TESTS="${NUM_TESTS_OVERRIDE:-$DEFAULT_NUM_TESTS}"
TRIES="${TRIES_OVERRIDE:-$DEFAULT_TRIES}"

# --- Проверка инфраструктуры ---
AIDER_REPO="${HOME}/projects/aider"
EXERCISES_DIR="${AIDER_REPO}/tmp.benchmarks/polyglot-benchmark"
DOCKER_IMAGE="aider-polyglot-bench:latest"

if ! command -v docker >/dev/null 2>&1; then
    echo "ОШИБКА: docker не установлен"
    exit 1
fi

if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
    echo "ОШИБКА: docker image отсутствует: $DOCKER_IMAGE"
    echo "Build: cd $AIDER_REPO && docker build -f benchmark/Dockerfile -t $DOCKER_IMAGE ."
    exit 1
fi

if [[ ! -d "$AIDER_REPO/benchmark" ]]; then
    echo "ОШИБКА: aider репо не найден: $AIDER_REPO"
    echo "Клонировать: git clone https://github.com/Aider-AI/aider $AIDER_REPO"
    exit 1
fi

if [[ ! -d "$EXERCISES_DIR" ]]; then
    echo "ОШИБКА: polyglot-benchmark отсутствует: $EXERCISES_DIR"
    echo "Клонировать: cd $AIDER_REPO && git clone https://github.com/Aider-AI/polyglot-benchmark tmp.benchmarks/polyglot-benchmark"
    exit 1
fi

# --- Проверка llama-server жив ---
if ! curl -fs "http://localhost:${PORT}/v1/models" >/dev/null 2>&1; then
    echo "ОШИБКА: llama-server не отвечает на порту ${PORT}"
    echo "Запустить: ./scripts/inference/vulkan/preset/${MODEL}.sh -d --port ${PORT}"
    exit 1
fi

# --- Запуск ---
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RUN_NAME="${RUN_NAME_OVERRIDE:-${MODE}-${MODEL}-${TIMESTAMP}}"
LOG="${OUTPUT_DIR}/bench-aider-${MODEL}-${MODE}-${TIMESTAMP}.log"
WATCHDOG_FLAG="${OUTPUT_DIR}/.watchdog-killed-${TIMESTAMP}"

# OpenAI-compat endpoint
API_BASE="http://localhost:${PORT}/v1"

# Состояние: USE_CONT определяет какой флаг (--new или --cont) использовать
USE_CONT=$CONT

echo "=== Aider Polyglot ${MODE^^} -- ${MODEL} ==="
echo "Порт:       ${PORT}"
echo "Run:        ${RUN_NAME}"
echo "Лог:        ${LOG}"
echo "Mode:       ${MODE} (--num-tests ${NUM_TESTS:-225}, --tries ${TRIES})"
[[ -n "$LANGUAGES" ]] && echo "Languages:  ${LANGUAGES}"
[[ $CONT -eq 1 ]] && echo "Старт:      --cont (продолжение существующего ${RUN_NAME})"
echo "Watchdog:   task-timeout=${TASK_TIMEOUT}s, total-timeout=${TOTAL_TIMEOUT}s, max-resumes=${MAX_RESUMES}"
echo ""

START=$(date +%s)
ATTEMPT=1
MAX_ATTEMPTS=$((MAX_RESUMES + 1))
EXIT_CODE=0

while [[ $ATTEMPT -le $MAX_ATTEMPTS ]]; do
    rm -f "$WATCHDOG_FLAG"

    # Сборка аргументов benchmark.py
    if [[ $USE_CONT -eq 1 ]]; then
        TESTDIR_FLAG="--cont"
        ATTEMPT_LABEL="resume #${ATTEMPT}/${MAX_ATTEMPTS}"
    else
        TESTDIR_FLAG="--new"
        ATTEMPT_LABEL="initial attempt"
    fi

    BENCH_ARGS=(
        "$RUN_NAME"
        --model "openai/${MODEL}"
        --edit-format whole
        --threads 1
        --tries "$TRIES"
        "$TESTDIR_FLAG"
        --exercises-dir polyglot-benchmark
    )
    [[ "$NUM_TESTS" -gt 0 ]] && BENCH_ARGS+=(--num-tests "$NUM_TESTS")
    [[ -n "$LANGUAGES" ]] && BENCH_ARGS+=(--languages "$LANGUAGES")

    CONTAINER="aider-bench-$$-${ATTEMPT}"

    echo ""
    echo "=== ${ATTEMPT_LABEL} -- container=${CONTAINER} (${TESTDIR_FLAG}) ==="

    # --- Запуск docker run в фоне ---
    docker run --rm --name "$CONTAINER" \
        --network host \
        --user "$(id -u):$(id -g)" \
        -v "${AIDER_REPO}:/aider" \
        -e OPENAI_API_BASE="$API_BASE" \
        -e OPENAI_API_KEY="dummy" \
        -e AIDER_DOCKER=1 \
        -e HOME=/tmp \
        -w /aider \
        "$DOCKER_IMAGE" \
        python3 ./benchmark/benchmark.py "${BENCH_ARGS[@]}" \
        > >(tee -a "$LOG") 2>&1 &
    DOCKER_PID=$!

    # --- Watchdog в фоне ---
    (
        LAST_PROGRESS=$(date +%s)
        LAST_COUNT=0
        while kill -0 "$DOCKER_PID" 2>/dev/null; do
            sleep 30
            NOW=$(date +%s)

            # Total timeout (если включён, !=0)
            if [[ "$TOTAL_TIMEOUT" -gt 0 ]] && (( NOW - START > TOTAL_TIMEOUT )); then
                echo "WATCHDOG: total timeout ${TOTAL_TIMEOUT}s reached, killing $CONTAINER" >&2
                docker kill "$CONTAINER" 2>/dev/null || true
                touch "$WATCHDOG_FLAG"
                break
            fi

            # Progress timeout
            CURRENT_COUNT=$(grep -c "^  test_cases:" "$LOG" 2>/dev/null || echo 0)
            if (( CURRENT_COUNT > LAST_COUNT )); then
                LAST_PROGRESS=$NOW
                LAST_COUNT=$CURRENT_COUNT
            fi
            if (( NOW - LAST_PROGRESS > TASK_TIMEOUT )); then
                echo "WATCHDOG: no progress for ${TASK_TIMEOUT}s, killing $CONTAINER (last test_cases=$LAST_COUNT)" >&2
                docker kill "$CONTAINER" 2>/dev/null || true
                touch "$WATCHDOG_FLAG"
                break
            fi
        done
    ) &
    WATCHDOG_PID=$!

    # Ждём завершения docker (либо нормально, либо kill watchdog'ом)
    wait "$DOCKER_PID" 2>/dev/null
    EXIT_CODE=$?
    kill "$WATCHDOG_PID" 2>/dev/null || true
    wait "$WATCHDOG_PID" 2>/dev/null || true

    # Проверка результата
    if [[ $EXIT_CODE -eq 0 ]]; then
        echo ""
        echo "=== Прогон завершён нормально (attempt ${ATTEMPT}/${MAX_ATTEMPTS}) ==="
        break
    fi

    if [[ -f "$WATCHDOG_FLAG" ]] && [[ $ATTEMPT -lt $MAX_ATTEMPTS ]]; then
        echo ""
        echo "=== Watchdog kill detected, auto-resume через --cont (attempt $((ATTEMPT+1))/${MAX_ATTEMPTS}) ==="
        rm -f "$WATCHDOG_FLAG"
        sleep 5
        ATTEMPT=$((ATTEMPT + 1))
        USE_CONT=1  # после watchdog kill всегда continue
        continue
    fi

    echo ""
    echo "=== Прогон прерван без auto-resume (exit ${EXIT_CODE}, attempt ${ATTEMPT}/${MAX_ATTEMPTS}) ==="
    break
done

END=$(date +%s)
DURATION=$((END - START))

echo ""
echo "=== Total: $((DURATION / 3600))h $(((DURATION % 3600) / 60))m, attempts=${ATTEMPT}/${MAX_ATTEMPTS}, last exit=${EXIT_CODE} ==="
echo "Лог: $LOG"
echo ""

# Финальные агрегаты (если есть)
LAST_AGG=$(grep -B1 -A12 '^  test_cases:' "$LOG" 2>/dev/null | tail -25)
if [[ -n "$LAST_AGG" ]]; then
    echo "=== Финальные агрегаты ==="
    echo "$LAST_AGG"
    echo ""
fi

echo "Не забудь добавить запись в docs/llm-guide/benchmarks/results.md"
echo "и создать статью в docs/llm-guide/benchmarks/runs/ (см. SKILL.md ops-engineer)"

exit $EXIT_CODE
