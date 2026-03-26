#!/bin/bash
#
# Проверка "потерянных" документов в docs/
# Каждый .md файл (кроме README.md) должен быть упомянут хотя бы в одном README
# Exit code: 0 -- все файлы упомянуты, 1 -- есть потерянные
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCS_DIR="${PROJECT_ROOT}/docs"

ORPHANS=0

# Проверить каждый не-README файл
while IFS= read -r md_file; do
    filename="$(basename "$md_file")"

    # Пропуск README.md
    [[ "$filename" == "README.md" ]] && continue

    # Проверка: упоминается ли имя файла в каком-либо README
    if ! grep -rqF "$filename" --include="README.md" "$DOCS_DIR" 2>/dev/null; then
        rel_file="${md_file#"${PROJECT_ROOT}/"}"
        echo "НЕ УПОМЯНУТ В README: ${rel_file}"
        ((ORPHANS++)) || true
    fi
done < <(find "$DOCS_DIR" -name "*.md" -type f)

if [[ $ORPHANS -eq 0 ]]; then
    echo "Проверка потерянных файлов: все упомянуты в README"
    exit 0
else
    echo ""
    echo "Найдено потерянных файлов: ${ORPHANS}"
    exit 1
fi
