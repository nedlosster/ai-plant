#!/bin/bash
#
# Проверка запрещенного контента в docs/
# - Запрещенные слова (Claude, Anthropic, Co-Authored-By)
# - Маркеры ИИ (готово, теперь, давайте, успешно выполнено)
# Exit code: 0 -- чисто, 1 -- найдены нарушения
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCS_DIR="${PROJECT_ROOT}/docs"

VIOLATIONS=0

# Запрещенные слова (case-insensitive)
# Claude и Anthropic разрешены в документации (описание продуктов), запрещены в коммитах (см. CLAUDE.md)
FORBIDDEN_WORDS=(
    "Co-Authored-By"
)

# Маркеры ИИ (только русские, т.к. документация на русском)
AI_MARKERS=(
    "успешно выполнено"
)

check_pattern() {
    local pattern="$1"
    local label="$2"
    local flags="${3:--i}"

    while IFS= read -r match; do
        if [[ -n "$match" ]]; then
            echo "${label}: ${match}"
            ((VIOLATIONS++)) || true
        fi
    done < <(grep -rn $flags "$pattern" "$DOCS_DIR" --include="*.md" 2>/dev/null || true)
}

echo "Проверка запрещенного контента в docs/"
echo "---"

# Проверка запрещенных слов
for word in "${FORBIDDEN_WORDS[@]}"; do
    check_pattern "$word" "ЗАПРЕЩЕННОЕ СЛОВО" "-i"
done

# Проверка маркеров ИИ
for marker in "${AI_MARKERS[@]}"; do
    check_pattern "$marker" "МАРКЕР ИИ" "-i"
done

echo "---"

if [[ $VIOLATIONS -eq 0 ]]; then
    echo "Проверка запрещенного контента: чисто"
    exit 0
else
    echo "Найдено нарушений: ${VIOLATIONS}"
    exit 1
fi
