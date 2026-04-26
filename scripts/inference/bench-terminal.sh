#!/bin/bash
# Terminal-Bench 2.0 wrapper
# Запускает бенчмарк против локального llama-server.
#
# Использование:
#   ./bench-terminal.sh --model qwen3.6-35b --port 8085
#
# 56 задач, ~1-2 ч на платформе.
#
# Требования: Python 3.10+, venv ~/.venvs/aider-bench с установленным terminal-bench, Docker
# Документация: docs/llm-guide/benchmarks/runbooks/terminal-bench.md

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common/config.sh"

MODEL=""
PORT="8085"
OUTPUT_DIR="/tmp"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model) MODEL="$2"; shift 2;;
        --port)  PORT="$2"; shift 2;;
        --output) OUTPUT_DIR="$2"; shift 2;;
        -h|--help)
            echo "Использование: $0 --model <name> [--port 8085] [--output /tmp]"
            echo ""
            echo "  --model   имя модели для логирования"
            echo "  --port    порт llama-server (по умолчанию 8085)"
            echo ""
            echo "Документация: docs/llm-guide/benchmarks/runbooks/terminal-bench.md"
            exit 0
            ;;
        *) echo "Неизвестный параметр: $1"; exit 1;;
    esac
done

[[ -z "$MODEL" ]] && { echo "ОШИБКА: укажи --model <имя>"; exit 1; }

# --- Проверка Docker ---
if ! docker ps >/dev/null 2>&1; then
    echo "ОШИБКА: Docker недоступен"
    echo "Установить или дать права: sudo usermod -aG docker \$USER"
    exit 1
fi

# --- Проверка venv ---
VENV="${HOME}/.venvs/aider-bench"
if [[ ! -d "$VENV" ]]; then
    echo "ОШИБКА: venv не найден: $VENV"
    echo "Создать: python3 -m venv $VENV && source $VENV/bin/activate && pip install terminal-bench"
    exit 1
fi

# --- Проверка llama-server ---
if ! curl -fs "http://localhost:${PORT}/v1/models" >/dev/null 2>&1; then
    echo "ОШИБКА: llama-server не отвечает на порту ${PORT}"
    echo "Запустить: ./scripts/inference/vulkan/preset/${MODEL}.sh -d --port ${PORT}"
    exit 1
fi

# --- Запуск ---
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG="${OUTPUT_DIR}/bench-terminal-${MODEL}-${TIMESTAMP}.log"

echo "=== Terminal-Bench 2.0 -- ${MODEL} ==="
echo "Порт: ${PORT}"
echo "Лог:  ${LOG}"
echo ""

export OPENAI_API_BASE="http://localhost:${PORT}/v1"
export OPENAI_API_KEY="dummy"

source "${VENV}/bin/activate"

START=$(date +%s)
terminal-bench run \
    --model "openai/${MODEL}" \
    --base-url "${OPENAI_API_BASE}" \
    --tasks-dir "${HOME}/.cache/terminal-bench/tasks" \
    2>&1 | tee "$LOG"
END=$(date +%s)

DURATION=$((END - START))
echo ""
echo "=== Завершено за $((DURATION / 3600))h $(((DURATION % 3600) / 60))m ==="
echo "Лог: $LOG"
echo ""
echo "Не забудь добавить запись в docs/llm-guide/benchmarks/results.md"
