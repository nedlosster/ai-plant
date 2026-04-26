#!/bin/bash
# Aider Polyglot benchmark wrapper
# Запускает бенчмарк против локального llama-server.
#
# Использование:
#   ./bench-aider.sh --smoke --model qwen3.6-35b --port 8085
#   ./bench-aider.sh --full  --model qwen-coder-next --port 8081
#
# Smoke: 50 случайных задач (~1.5 ч)
# Full:  225 задач (~6-12 ч)
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

# --- Параметры ---
MODE=""
MODEL=""
PORT="8085"
OUTPUT_DIR="/tmp"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --smoke) MODE="smoke"; shift;;
        --full)  MODE="full"; shift;;
        --model) MODEL="$2"; shift 2;;
        --port)  PORT="$2"; shift 2;;
        --output) OUTPUT_DIR="$2"; shift 2;;
        -h|--help)
            echo "Использование: $0 --smoke|--full --model <name> [--port 8085] [--output /tmp]"
            echo ""
            echo "  --smoke   50 случайных задач (~1.5 ч)"
            echo "  --full    225 задач (~6-12 ч)"
            echo "  --model   имя модели для логирования (qwen3.6-35b, qwen-coder-next, ...)"
            echo "  --port    порт llama-server (по умолчанию 8085)"
            echo ""
            echo "Документация: docs/llm-guide/benchmarks/runbooks/aider-polyglot.md"
            exit 0
            ;;
        *) echo "Неизвестный параметр: $1"; exit 1;;
    esac
done

[[ -z "$MODE" ]]  && { echo "ОШИБКА: укажи --smoke или --full"; exit 1; }
[[ -z "$MODEL" ]] && { echo "ОШИБКА: укажи --model <имя>"; exit 1; }

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
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RUN_NAME="${MODE}-${MODEL}-${TIMESTAMP}"
LOG="${OUTPUT_DIR}/bench-aider-${MODEL}-${MODE}-${TIMESTAMP}.log"

echo "=== Aider Polyglot ${MODE^^} -- ${MODEL} ==="
echo "Порт: ${PORT}"
echo "Run:  ${RUN_NAME}"
echo "Лог:  ${LOG}"
echo ""

# Параметры subset для smoke
NUM_TESTS_ARG=""
[[ "$MODE" == "smoke" ]] && NUM_TESTS_ARG="--num-tests 50"

# OpenAI-compat endpoint (litellm prefix openai/ -- использовать любое имя модели)
# Контейнер использует --network host, поэтому localhost = host
API_BASE="http://localhost:${PORT}/v1"

START=$(date +%s)
docker run --rm \
    --network host \
    --user "$(id -u):$(id -g)" \
    -v "${AIDER_REPO}:/aider" \
    -e OPENAI_API_BASE="$API_BASE" \
    -e OPENAI_API_KEY="dummy" \
    -e AIDER_DOCKER=1 \
    -e HOME=/tmp \
    -w /aider \
    "$DOCKER_IMAGE" \
    python3 ./benchmark/benchmark.py "$RUN_NAME" \
        --model "openai/${MODEL}" \
        --edit-format whole \
        --threads 1 \
        --tries 2 \
        --new \
        --exercises-dir polyglot-benchmark \
        ${NUM_TESTS_ARG} \
    2>&1 | tee "$LOG"
END=$(date +%s)

DURATION=$((END - START))
echo ""
echo "=== Завершено за $((DURATION / 3600))h $(((DURATION % 3600) / 60))m ==="
echo "Лог: $LOG"
echo ""
echo "Не забудь добавить запись в docs/llm-guide/benchmarks/results.md"
echo "(шаблон в самом файле)"
