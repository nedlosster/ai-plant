#!/bin/bash
#
# Проверяет что упоминания файлов и папок в docs/ -- кликабельные markdown-ссылки.
# Backticks НЕ являются заменой ссылке (они не кликабельны).
#
# Что детектирует (примеры плохого):
#   "См. docs/models/families/glm.md"              <- plain text .md
#   "Расширен `docs/models/families/glm.md`"       <- backticks .md
#   "Папка `docs/ai-agents/agents/claude-code/`"   <- backticks директория
#   "Раздел docs/apps/"                            <- plain text директория
#
# Что разрешено:
#   "[GLM](families/glm.md)"                        <- кликабельная ссылка
#   "[`docs/foo.md`](foo.md)"                       <- ссылка с code-style текстом
#   "[папка apps/](apps/README.md)"                 <- ссылка на папку
#   "```bash\nls docs/\n```"                        <- внутри code-блока
#   "URL: https://github.com/.../foo.md"            <- URL
#   "README.md / CLAUDE.md / SKILL.md"              <- голые имена-конвенции (без пути)
#   ".claude/skills/foo/SKILL.md"                   <- gitignored путь
#   frontmatter
#
# Алгоритм:
#   1. awk извлекает кандидатов (.md или path/ ) из тела статьи
#   2. bash проверяет существование candidate в PROJECT_ROOT (как файл/папка)
#   3. если существует -- это реальный путь, должен быть кликабельным
#
# Exit: 0 -- чисто, 1 -- найдены некликабельные упоминания
#

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCS_DIR="${PROJECT_ROOT}/docs"

VIOLATIONS=0
TOTAL_BAD=0

echo "Проверка некликабельных упоминаний файлов и папок в docs/"
echo "---"

extract_candidates() {
    # Принимает .md файл, печатает candidates в формате "lineno|matched|clean"
    local md_file="$1"
    awk '
        BEGIN {
            in_code_block = 0
            in_frontmatter = 0
            first_line = 1
        }
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
        /^```/ {
            in_code_block = !in_code_block
            next
        }
        in_code_block { next }
        /^[[:space:]]*\|[-:| ]+\|[[:space:]]*$/ { next }
        {
            line = $0
            lineno = NR

            # Удалить markdown-ссылки [text](path) -- кликабельны, OK
            gsub(/\[[^]]*\]\([^)]*\)/, "", line)
            # Удалить URL (http/https)
            gsub(/https?:\/\/[^[:space:])]+/, "", line)

            # Поиск кандидатов:
            #   1) `?path.md`?      -- любой .md
            #   2) `?dir/sub/`?     -- путь оканчивающийся на /
            while (match(line, /`?[[:alnum:]_.][[:alnum:]_./-]*(\.md|\/)`?/)) {
                matched = substr(line, RSTART, RLENGTH)
                line = substr(line, 1, RSTART-1) " " substr(line, RSTART+RLENGTH)

                clean = matched
                gsub(/`/, "", clean)

                # Whitelist: голые имена-конвенции (без пути)
                if (clean == "README.md" || clean == "CLAUDE.md" || \
                    clean == "AGENTS.md" || clean == "SKILL.md" || \
                    clean == "MEMORY.md") continue

                # Whitelist: gitignored .claude/* (нельзя сделать кликабельным)
                if (clean ~ /^\.claude\//) continue

                printf("%d|%s|%s\n", lineno, matched, clean)
            }
        }
    ' "$md_file"
}

while IFS= read -r md_file; do
    rel_file="${md_file#"${PROJECT_ROOT}/"}"
    src_dir="$(dirname "$md_file")"
    file_violations=""

    while IFS='|' read -r lineno matched clean; do
        [[ -z "${lineno:-}" ]] && continue

        # Проверка существования: путь относительно PROJECT_ROOT, DOCS_DIR
        # или относительно директории самого исходного файла (для ../, ./)
        if [[ -e "${PROJECT_ROOT}/${clean}" ]] || \
           [[ -e "${DOCS_DIR}/${clean}" ]] || \
           [[ -e "${src_dir}/${clean}" ]]; then
            file_violations+="  ${rel_file}:${lineno}  некликабельное: ${matched}"$'\n'
        elif [[ "$clean" == *.md ]]; then
            # .md mention которого нет в проекте -- вероятно опечатка ИЛИ placeholder
            # Помечаем только если выглядит как попытка ссылки на проект (содержит /)
            if [[ "$clean" == */* ]]; then
                file_violations+="  ${rel_file}:${lineno}  некликабельное (битый путь?): ${matched}"$'\n'
            fi
        fi
    done < <(extract_candidates "$md_file")

    if [[ -n "$file_violations" ]]; then
        printf "%s" "$file_violations"
        ((VIOLATIONS++)) || true
        bad=$(printf "%s" "$file_violations" | grep -c '^' || true)
        ((TOTAL_BAD += bad)) || true
    fi
done < <(find "$DOCS_DIR" -name "*.md" -type f)

echo "---"
if [[ $VIOLATIONS -eq 0 ]]; then
    echo "Некликабельных упоминаний не найдено: чисто"
    exit 0
else
    echo "Файлов с нарушениями: ${VIOLATIONS}, всего нарушений: ${TOTAL_BAD}"
    echo ""
    echo "Правило: все упоминания внутренних файлов и папок проекта должны"
    echo "быть оформлены как кликабельные markdown-ссылки:"
    echo "  [text](path.md)              -- ссылка на файл"
    echo "  [\`path.md\`](path.md)         -- ссылка с code-style текстом"
    echo "  [папка apps/](apps/README.md) -- ссылка на папку (через её README)"
    echo ""
    echo "Backticks БЕЗ ссылки -- НЕ являются заменой (они не кликабельны)."
    echo "См. .claude/skills/doc-lifecycle/SKILL.md, секция \"Ссылки\""
    exit 1
fi
