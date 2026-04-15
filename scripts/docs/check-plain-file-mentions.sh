#!/bin/bash
#
# Проверяет что упоминания .md файлов в docs/ -- **кликабельные** markdown-ссылки,
# а не plain text. То есть `[text](path.md)` или `path.md` в backticks,
# а не голое `path.md` или `docs/foo/bar.md` в тексте.
#
# Что детектирует (примеры плохого):
#   "См. docs/models/families/glm.md"              <- plain text file mention
#   "Смотри agents/claude-code/news.md"            <- plain text relative path
#   "Подробности в README.md раздела"              <- plain text .md reference
#
# Что разрешено (не детектирует):
#   "[GLM](families/glm.md)"                        <- кликабельная ссылка
#   "`docs/models/families/glm.md`"                 <- backticks (code-style)
#   "```bash\ngrep docs/foo.md\n```"                <- внутри code-блока
#   "URL: https://github.com/.../foo.md"            <- URL
#   frontmatter (начало файла до второго ---)
#
# Exit: 0 -- чисто, 1 -- найдены некликабельные упоминания
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCS_DIR="${PROJECT_ROOT}/docs"

VIOLATIONS=0

echo "Проверка plain-text упоминаний .md файлов в docs/"
echo "---"

# Обход каждого .md файла
while IFS= read -r md_file; do
    # Пропустить changelog -- там намеренно много упоминаний hash'ей и commit-тем
    [[ "$md_file" == *"/changelog.md" ]] && continue

    rel_file="${md_file#"${PROJECT_ROOT}/"}"

    # Чтение файла с обработкой состояний:
    # - in_code_block: мы внутри ``` ... ``` (пропускать)
    # - in_frontmatter: мы внутри --- ... --- (пропускать)
    awk -v file="$rel_file" '
        BEGIN {
            in_code_block = 0
            in_frontmatter = 0
            first_line = 1
            violations = 0
        }

        # Детектирование frontmatter (начинается и кончается ---)
        {
            if (first_line && $0 == "---") {
                in_frontmatter = 1
                first_line = 0
                next
            }
            first_line = 0
            if (in_frontmatter) {
                if ($0 == "---") in_frontmatter = 0
                next
            }
        }

        # Детектирование code-блоков (начало/конец ```)
        /^```/ {
            in_code_block = !in_code_block
            next
        }

        # Пропустить содержимое code-блоков
        in_code_block { next }

        # Пропустить строки-заголовки таблиц (| -- | -- |)
        /^\s*\|[-:| ]+\|\s*$/ { next }

        # Искать упоминания .md файлов которые НЕ в markdown-ссылке и НЕ в backticks
        {
            line = $0
            lineno = NR

            # Удалить все markdown-ссылки [...](...) -- их проверяет check-links.sh
            gsub(/\[[^]]*\]\([^)]*\)/, "", line)

            # Удалить всё содержимое backticks `...`
            gsub(/`[^`]*`/, "", line)

            # Удалить полные URL (http/https)
            gsub(/https?:\/\/[^[:space:])]+/, "", line)

            # После очистки -- ищем .md references
            # Паттерн: любое имя-файла.md (возможно с путём типа foo/bar.md или docs/foo/bar.md)
            # Которое не является просто именем в списке из README
            # Проблема: match() возвращает только первое вхождение, для простоты сверяемся со всей строкой
            while (match(line, /[[:alnum:]_-]+(\/[[:alnum:]_-]+)*\.md\b/)) {
                matched = substr(line, RSTART, RLENGTH)

                # Убрать найденное из строки чтобы итерировать дальше
                line = substr(line, 1, RSTART-1) " " substr(line, RSTART+RLENGTH)

                # Отфильтровать очевидные не-ссылки:
                # - README.md без пути (упоминание конвенции, не конкретного файла)
                # Но только если до и после нет слэша (абсолютно one-word)
                # Тут пропустим "README.md" как общее упоминание файла-индекса
                if (matched == "README.md") continue

                # - CLAUDE.md, AGENTS.md -- имена-конвенции, не конкретные пути
                if (matched == "CLAUDE.md" || matched == "AGENTS.md") continue

                # - Упоминание в словах "файл settings.json", "в .gitignore" -- тут не md

                # Выдать нарушение
                printf("  %s:%d  некликабельное: %s\n", file, lineno, matched)
                violations++
            }
        }

        END {
            exit (violations > 0 ? 1 : 0)
        }
    ' "$md_file" && : || ((VIOLATIONS += $?))
done < <(find "$DOCS_DIR" -name "*.md" -type f)

echo "---"
if [[ $VIOLATIONS -eq 0 ]]; then
    echo "Plain-text упоминаний .md не найдено: чисто"
    exit 0
else
    echo "Найдено файлов с нарушениями: $VIOLATIONS"
    echo ""
    echo "Правило: все упоминания внутренних .md файлов должны быть оформлены как"
    echo "  [text](path.md)     -- кликабельная ссылка"
    echo "  \`path.md\`          -- backticks (code-style, если ссылка сейчас неуместна)"
    echo ""
    echo "См. .claude/skills/doc-lifecycle/SKILL.md, секция \"Ссылки\""
    exit 1
fi
