#!/bin/bash
# Остановка ACE-Step

set -euo pipefail

if pgrep -f "acestep" > /dev/null 2>&1; then
    echo "Остановка ACE-Step..."
    pkill -f "acestep" 2>/dev/null || true
    sleep 2
    if pgrep -f "acestep" > /dev/null 2>&1; then
        echo "Принудительная остановка (SIGKILL)..."
        pkill -9 -f "acestep" 2>/dev/null || true
    fi
    echo "ACE-Step остановлен"
else
    echo "ACE-Step не запущен"
fi
