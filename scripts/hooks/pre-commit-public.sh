#!/bin/bash
# Pre-commit hook: проверка на утечку персональных данных
# Установка: cp scripts/hooks/pre-commit-public.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
# Или: git config core.hooksPath scripts/hooks && mv pre-commit-public.sh pre-commit

set -euo pipefail

# Паттерны персональных данных (regex)
PATTERNS=(
    '192\.168\.[0-9]+\.[0-9]+'         # приватные IP-адреса
    '/home/[a-z][a-z0-9_-]+/'          # абсолютные домашние пути
    'nedlosster'                         # username
    'nedlo@'                             # email
)

# Файлы, в которых паттерны допустимы (исключения)
EXCLUDE_FILES=(
    'scripts/hooks/pre-commit-public.sh'  # этот скрипт
    '.mailmap'                             # git mailmap
)

ERRORS=0

for pattern in "${PATTERNS[@]}"; do
    # Проверка staged-файлов (только добавленные/измененные строки)
    while IFS= read -r file; do
        # Пропуск исключений
        skip=false
        for excl in "${EXCLUDE_FILES[@]}"; do
            if [[ "$file" == "$excl" ]]; then
                skip=true
                break
            fi
        done
        $skip && continue

        # Проверка staged-содержимого (не файла на диске, а того, что уходит в коммит)
        if git diff --cached -- "$file" | grep -qP "^\+.*${pattern}"; then
            echo "БЛОКИРОВКА: паттерн '${pattern}' в staged-изменениях файла: $file"
            git diff --cached -- "$file" | grep -nP "^\+.*${pattern}" | head -5
            echo ""
            ERRORS=$((ERRORS + 1))
        fi
    done < <(git diff --cached --name-only --diff-filter=ACM)
done

if [[ $ERRORS -gt 0 ]]; then
    echo "---"
    echo "Коммит заблокирован: обнаружены персональные данные ($ERRORS совпадений)"
    echo "Используй плейсхолдеры: <SERVER_IP>, <user>, ~/  вместо реальных данных"
    exit 1
fi
