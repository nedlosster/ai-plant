#!/bin/bash
#
# Проверка markdown-ссылок в docs/
# Находит все [текст](путь.md) и проверяет существование целевых файлов
# Exit code: 0 -- все ссылки корректны, 1 -- есть битые
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCS_DIR="${PROJECT_ROOT}/docs"

ERRORS=0

while IFS= read -r md_file; do
    file_dir="$(dirname "$md_file")"

    # Извлечение ссылок через grep + проверка файлов
    while IFS=: read -r line_num match; do
        # Извлечь путь из (путь.md)
        link="$(echo "$match" | grep -oP '\]\(\K[^)]+' | head -1)"

        [[ -z "$link" ]] && continue
        # Пропуск URL
        [[ "$link" == http* ]] && continue
        # Пропуск якорей
        [[ "$link" == \#* ]] && continue
        # Только .md ссылки
        [[ "$link" != *.md* ]] && continue
        # Убрать якорь
        link="${link%%#*}"

        # Разрешение пути
        target="${file_dir}/${link}"
        if [[ ! -f "$target" ]]; then
            # Попробовать нормализовать путь
            resolved="$(cd "$(dirname "$target")" 2>/dev/null && echo "$(pwd)/$(basename "$target")")" || resolved=""
            if [[ -z "$resolved" ]] || [[ ! -f "$resolved" ]]; then
                rel_file="${md_file#"${PROJECT_ROOT}/"}"
                echo "БИТАЯ ССЫЛКА: ${rel_file}:${line_num} -> ${link}"
                ((ERRORS++)) || true
            fi
        fi
    done < <(grep -n '\[.*\](.*\.md' "$md_file" 2>/dev/null || true)
done < <(find "$DOCS_DIR" -name "*.md" -type f)

if [[ $ERRORS -eq 0 ]]; then
    echo "Проверка ссылок: все корректны"
    exit 0
else
    echo ""
    echo "Найдено битых ссылок: ${ERRORS}"
    exit 1
fi
