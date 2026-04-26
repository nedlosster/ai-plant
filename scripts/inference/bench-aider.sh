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
# Требования: Python 3.10+, venv ~/.venvs/aider-bench с установленным aider-chat
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

# --- Проверка venv ---
VENV="${HOME}/.venvs/aider-bench"
if [[ ! -d "$VENV" ]]; then
    echo "ОШИБКА: venv не найден: $VENV"
    echo "Создать: python3 -m venv $VENV && source $VENV/bin/activate && pip install aider-chat"
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
LOG="${OUTPUT_DIR}/bench-aider-${MODEL}-${MODE}-${TIMESTAMP}.log"

echo "=== Aider Polyglot ${MODE^^} -- ${MODEL} ==="
echo "Порт: ${PORT}"
echo "Лог:  ${LOG}"
echo ""

# Параметры subset для smoke
NUM_TESTS=""
[[ "$MODE" == "smoke" ]] && NUM_TESTS="--num-tests 50 --random-seed 42"

# OpenAI-compat endpoint
export OPENAI_API_BASE="http://localhost:${PORT}/v1"
export OPENAI_API_KEY="dummy"

# Активируем venv и запускаем
source "${VENV}/bin/activate"

START=$(date +%s)
aider --benchmark polyglot \
      --model "openai/${MODEL}" \
      ${NUM_TESTS} \
      --no-stream \
      --auto-test \
      2>&1 | tee "$LOG"
END=$(date +%s)

DURATION=$((END - START))
echo ""
echo "=== Завершено за $((DURATION / 3600))h $(((DURATION % 3600) / 60))m ==="
echo "Лог: $LOG"
echo ""
echo "Не забудь добавить запись в docs/llm-guide/benchmarks/results.md"
echo "(шаблон в самом файле)"
