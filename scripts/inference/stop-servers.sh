#!/bin/bash
# Остановка всех llama-server

set -euo pipefail

if ! pgrep -f llama-server > /dev/null 2>&1; then
    echo "Нет запущенных llama-server"
    exit 0
fi

echo "Запущенные:"
pgrep -af llama-server
echo ""

echo "Остановка..."
pkill -f llama-server 2>/dev/null || true
sleep 1

if pgrep -f llama-server > /dev/null 2>&1; then
    echo "Принудительная остановка (SIGKILL)..."
    pkill -9 -f llama-server 2>/dev/null || true
fi

echo "Серверы остановлены"
