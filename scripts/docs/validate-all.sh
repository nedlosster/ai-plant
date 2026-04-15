#!/bin/bash
#
# Полная валидация документации docs/
# Запускает все проверки последовательно
# Exit code: 0 -- все проверки пройдены, 1 -- есть ошибки
#

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_ERRORS=0

echo "=== Валидация документации docs/ ==="
echo ""

# 1. Проверка ссылок
echo "[1/4] Проверка markdown-ссылок..."
if bash "${SCRIPT_DIR}/check-links.sh"; then
    :
else
    ((TOTAL_ERRORS++)) || true
fi
echo ""

# 2. Проверка потерянных файлов
echo "[2/4] Проверка потерянных файлов..."
if bash "${SCRIPT_DIR}/check-orphans.sh"; then
    :
else
    ((TOTAL_ERRORS++)) || true
fi
echo ""

# 3. Проверка запрещенного контента
echo "[3/4] Проверка запрещенного контента..."
if bash "${SCRIPT_DIR}/check-forbidden.sh"; then
    :
else
    ((TOTAL_ERRORS++)) || true
fi
echo ""

# 4. Проверка некликабельных plain-text упоминаний .md
echo "[4/4] Проверка некликабельных упоминаний .md..."
if bash "${SCRIPT_DIR}/check-plain-file-mentions.sh"; then
    :
else
    ((TOTAL_ERRORS++)) || true
fi
echo ""

echo "=== Итог ==="
if [[ $TOTAL_ERRORS -eq 0 ]]; then
    echo "Все проверки пройдены"
    exit 0
else
    echo "Проверок с ошибками: ${TOTAL_ERRORS}"
    exit 1
fi
