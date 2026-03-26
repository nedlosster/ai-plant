#!/bin/bash
# Общие переменные и функции для веб-интерфейсов
# Подключение: source "$(dirname "$0")/../config.sh" (из подпапок)

# --- Inference backend ---
LLAMA_PORT="${LLAMA_PORT:-8080}"
LLAMA_FIM_PORT="${LLAMA_FIM_PORT:-8081}"
LLAMA_API_URL="http://host.docker.internal:${LLAMA_PORT}/v1"

# --- Проверка Docker ---
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo "ОШИБКА: Docker не установлен"
        echo "  https://docs.docker.com/engine/install/ubuntu/"
        return 1
    fi
    if ! docker info &>/dev/null 2>&1; then
        echo "ОШИБКА: Docker daemon не запущен или нет прав"
        echo "  sudo systemctl start docker"
        echo "  sudo usermod -aG docker \$USER"
        return 1
    fi
}

# --- Проверка inference backend ---
check_inference() {
    if ! curl -s --connect-timeout 2 "http://localhost:${LLAMA_PORT}/health" 2>/dev/null | grep -q "ok"; then
        echo "ПРЕДУПРЕЖДЕНИЕ: inference не запущен на порту ${LLAMA_PORT}"
        echo "  Запустить: ./scripts/inference/start-server.sh <model.gguf> --daemon"
        echo ""
    fi
}

# --- Проверка контейнера ---
check_container() {
    local name="$1"
    local port="$2"
    printf "%-15s " "$name:"
    if docker ps -q -f name="$name" 2>/dev/null | grep -q .; then
        echo "запущен (http://localhost:${port})"
    else
        echo "остановлен"
    fi
}
