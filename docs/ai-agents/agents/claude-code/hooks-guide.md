# Hooks: safety и автоматизация

Руководство по Hooks в Claude Code: механизм гарантированного выполнения shell-команд на event'ы. Используется для safety (git guardrails, secret scanning) и автоматизации (auto-format, audit log, notifications).

Hooks стали публичным API в сентябре 2025. Детали в [news.md](news.md#сентябрь-2025----hooks-made-public).

## Что такое Hooks

**Hook** -- shell-команда, которая **гарантированно выполняется** на определённое событие в жизненном цикле Claude Code. В отличие от инструкций в CLAUDE.md (которые модель может проигнорировать), hooks выполняются всегда -- они работают на уровне harness, не модели.

Exit code команды определяет что происходит дальше:
- `0` -- action разрешено, Claude продолжает
- Не-ноль -- action заблокировано, Claude получает ошибку и вынужден искать альтернативу

Это даёт **жёсткие гарантии**, которые невозможны через prompt engineering.

## События (event types)

Hooks привязываются к конкретным событиям:

| Событие | Когда срабатывает | Typical use |
|---------|-------------------|-------------|
| `pre-tool-use` | Перед вызовом tool (Edit, Write, Bash, и т.д.) | **Guardrails**: блокировать опасное |
| `post-tool-use` | После вызова tool | Auto-format, audit log, notification |
| `user-prompt-submit` | Когда юзер отправляет промпт | Преобработка, логирование, enrichment |
| `stop` | Когда Claude завершает ответ | Cleanup, уведомление, summary |
| `subagent-stop` | Когда subagent завершил | Merge результатов |
| `notification` | Custom notifications из скриптов | Integrations |

## Формат конфигурации

Hooks настраиваются в `settings.json` (глобально в `~/.claude/settings.json` или в проекте `.claude/settings.json`):

```json
{
  "hooks": {
    "pre-tool-use": [
      {
        "matcher": {
          "tool_name": "Bash"
        },
        "command": "~/.claude/hooks/block-dangerous-git.sh"
      }
    ],
    "post-tool-use": [
      {
        "matcher": {
          "tool_name": "Edit"
        },
        "command": "~/.claude/hooks/auto-format.sh"
      }
    ]
  }
}
```

Переменные окружения доступны в hook:
- `$CLAUDE_TOOL_NAME` -- имя tool (Edit, Write, Bash, ...)
- `$CLAUDE_TOOL_ARGS` -- JSON с аргументами tool
- `$CLAUDE_PROJECT_DIR` -- корень проекта
- `$CLAUDE_SESSION_ID` -- ID текущей сессии

## Базовые use-cases

### 1. Git guardrails -- блокировать опасные команды

Самый распространённый use-case. Блокировать `git push --force` в main, `git reset --hard`, `git clean -fd`, `git branch -D`.

В проекте `ai-plant` есть готовый skill `/git-guardrails-claude-code` который настраивает всё это автоматически. Вручную:

`~/.claude/hooks/block-dangerous-git.sh`:

```bash
#!/bin/bash
# Блокирует опасные git-команды в защищённых ветках

TOOL_ARGS=$(cat)
CMD=$(echo "$TOOL_ARGS" | jq -r '.command // ""')

# Список опасных паттернов
BLOCK_PATTERNS=(
  "git push.*--force.*(main|master|prod)"
  "git reset --hard"
  "git clean -fd"
  "git clean -df"
  "git branch -D"
  "rm -rf"
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE"
)

for pattern in "${BLOCK_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qE "$pattern"; then
    echo "BLOCKED: опасный паттерн -- '$pattern'. Используй --no-verify или ручной git если уверен." >&2
    exit 1
  fi
done

exit 0
```

Конфиг в `settings.json`:

```json
{
  "hooks": {
    "pre-tool-use": [
      {
        "matcher": {"tool_name": "Bash"},
        "command": "~/.claude/hooks/block-dangerous-git.sh"
      }
    ]
  }
}
```

### 2. Auto-format после Edit

Автоматически форматировать код после каждого Edit:

`~/.claude/hooks/auto-format.sh`:

```bash
#!/bin/bash
TOOL_ARGS=$(cat)
FILE=$(echo "$TOOL_ARGS" | jq -r '.file_path // ""')

if [[ -z "$FILE" ]]; then
  exit 0
fi

case "$FILE" in
  *.ts|*.tsx|*.js|*.jsx)
    prettier --write "$FILE" 2>/dev/null
    ;;
  *.py)
    black "$FILE" 2>/dev/null
    ;;
  *.go)
    gofmt -w "$FILE"
    ;;
  *.rs)
    rustfmt "$FILE" 2>/dev/null
    ;;
esac

exit 0
```

После каждого Edit файл автоматически форматируется по project standards. Claude не нужно делать это сам.

### 3. Secret scanning -- блокировать коммит credentials

Проверять что в файлах нет API keys, passwords, tokens:

`~/.claude/hooks/block-secrets.sh`:

```bash
#!/bin/bash
TOOL_ARGS=$(cat)
FILE_PATH=$(echo "$TOOL_ARGS" | jq -r '.file_path // ""')
NEW_CONTENT=$(echo "$TOOL_ARGS" | jq -r '.new_string // .content // ""')

# Паттерны для API keys
PATTERNS=(
  'sk-[a-zA-Z0-9]{20,}'              # OpenAI
  'xoxb-[0-9]+-[0-9]+-[a-zA-Z0-9]+'  # Slack bot
  'AKIA[0-9A-Z]{16}'                  # AWS Access Key
  'ya29\.[0-9a-zA-Z_-]+'              # Google OAuth
  'ghp_[a-zA-Z0-9]{36}'               # GitHub Personal
  'Bearer eyJ[a-zA-Z0-9_-]+\.'        # JWT in Authorization
)

for pattern in "${PATTERNS[@]}"; do
  if echo "$NEW_CONTENT" | grep -qE "$pattern"; then
    echo "BLOCKED: обнаружен возможный secret в '$FILE_PATH'. Pattern: $pattern" >&2
    echo "Используй environment variables или .env файл (в .gitignore)" >&2
    exit 1
  fi
done

exit 0
```

### 4. Pre-commit linting

Запустить линтер перед `git commit`:

```bash
#!/bin/bash
TOOL_ARGS=$(cat)
CMD=$(echo "$TOOL_ARGS" | jq -r '.command // ""')

if [[ "$CMD" =~ ^git[[:space:]]+commit ]]; then
  cd "$CLAUDE_PROJECT_DIR"

  # Проверить что нет уязвимостей
  if [[ -f ".pre-commit-config.yaml" ]]; then
    pre-commit run --all-files || {
      echo "BLOCKED: pre-commit failed, исправь issues перед commit" >&2
      exit 1
    }
  fi

  # Проверить типы TypeScript если применимо
  if [[ -f "tsconfig.json" ]]; then
    npx tsc --noEmit || exit 1
  fi
fi

exit 0
```

## Продвинутые use-cases

### 1. Audit log всех tool calls

Логировать всё что делает Claude для compliance:

```bash
#!/bin/bash
# post-tool-use hook
TOOL_ARGS=$(cat)
LOG_FILE="$HOME/.claude/audit/$(date +%Y-%m-%d).jsonl"
mkdir -p "$(dirname "$LOG_FILE")"

jq -n \
  --arg session "$CLAUDE_SESSION_ID" \
  --arg tool "$CLAUDE_TOOL_NAME" \
  --arg project "$CLAUDE_PROJECT_DIR" \
  --arg timestamp "$(date -Iseconds)" \
  --argjson args "$TOOL_ARGS" \
  '{timestamp: $timestamp, session: $session, tool: $tool, project: $project, args: $args}' \
  >> "$LOG_FILE"

exit 0
```

Даёт полный аудит: что, когда, в каком проекте Claude делал. Для security review, compliance, debugging.

### 2. Rate limiting

Замедлить consecutive dangerous actions (не дать Claude запустить `rm -rf` десять раз за минуту):

```bash
#!/bin/bash
TOOL_ARGS=$(cat)
CMD=$(echo "$TOOL_ARGS" | jq -r '.command // ""')

# Только для опасных команд
if echo "$CMD" | grep -qE "(rm|drop|delete|truncate)"; then
  RATE_FILE="/tmp/claude-rate-limit-dangerous"
  LAST=$(cat "$RATE_FILE" 2>/dev/null || echo "0")
  NOW=$(date +%s)

  if (( NOW - LAST < 30 )); then
    echo "BLOCKED: rate limit -- подожди 30 сек между опасными операциями" >&2
    exit 1
  fi

  echo "$NOW" > "$RATE_FILE"
fi

exit 0
```

### 3. Notification на завершение task

Отправить push в Telegram/Slack когда Claude завершил:

```bash
#!/bin/bash
# stop event hook

TASK_SUMMARY="Claude завершил работу в $(basename $CLAUDE_PROJECT_DIR)"

curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
  -d chat_id="$TG_CHAT_ID" \
  -d text="$TASK_SUMMARY"

exit 0
```

Полезно когда Claude работает долго (например, Agent Teams на 4+ часа).

### 4. CI integration

Trigger CI build после git push:

```bash
#!/bin/bash
TOOL_ARGS=$(cat)
CMD=$(echo "$TOOL_ARGS" | jq -r '.command // ""')

if [[ "$CMD" =~ ^git[[:space:]]+push ]]; then
  # Trigger GitHub Actions workflow через API
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/actions/workflows/ci.yml/dispatches" \
    -d "{\"ref\":\"$BRANCH\"}"
fi

exit 0
```

## Принципы написания безопасных hooks

### 1. Exit codes -- контракт

Hook должен возвращать:
- `0` для allow
- Не-ноль для block (любое ненулевое значение)

**Не путать со stdout/stderr**:
- `stderr` -- видит пользователь как сообщение
- `stdout` -- игнорируется (обычно)

### 2. Idempotency

Hook может вызываться **многократно** в одной сессии. Должен быть idempotent -- не создавать side-effects которые ломаются при повторе.

Плохо:
```bash
echo "run $((++COUNTER))" >> /tmp/log
```

Хорошо:
```bash
echo "$(date -Iseconds) $CLAUDE_TOOL_NAME" >> /tmp/log
```

### 3. Fast execution

Hook блокирует Claude пока не завершится. Если hook медленный (>1 сек) -- это UX-проблема. Для долгих операций (CI trigger, notification) -- выносить в background:

```bash
#!/bin/bash
# Quick check inline
check_security || exit 1

# Slow operation в background
( send_notification & ) > /dev/null 2>&1
exit 0
```

### 4. Fail safe, не fail open

Если hook не смог проверить -- **блокировать** операцию, а не пропускать.

Плохо:
```bash
tool_version=$(some-tool --version 2>/dev/null || echo "0.0.0")
if [[ "$tool_version" < "1.0.0" ]]; then
  exit 1  # блокируем если старая версия
fi
exit 0    # если tool не нашли -- пропускаем (fail open!)
```

Хорошо:
```bash
tool_version=$(some-tool --version) || {
  echo "BLOCKED: не смог проверить версию some-tool" >&2
  exit 1
}
if [[ "$tool_version" < "1.0.0" ]]; then
  exit 1
fi
exit 0
```

### 5. Логировать всё что блокируешь

Когда hook блокирует -- в stderr подробно объяснить **почему** и **что делать дальше**. Claude должен понять и переориентироваться.

Плохо:
```bash
echo "blocked" >&2
exit 1
```

Хорошо:
```bash
echo "BLOCKED: команда '$CMD' содержит 'rm -rf' в root-пути." >&2
echo "Допустимые альтернативы:" >&2
echo "  - Удалять файлы по одному через rm" >&2
echo "  - Использовать git rm для tracked файлов" >&2
echo "  - Использовать ./scripts/cleanup.sh если нужна массовая очистка" >&2
exit 1
```

## Skill `/git-guardrails-claude-code` как пример

В ecosystem есть готовый skill для git-safety. Уже используется в проекте `ai-plant`:

```
~/.claude/skills/git-guardrails-claude-code/
├── SKILL.md
├── hooks/
│   ├── block-force-push.sh
│   ├── block-reset-hard.sh
│   ├── block-clean.sh
│   └── block-branch-delete.sh
└── install.sh
```

Skill при вызове:
1. Устанавливает hooks в `~/.claude/hooks/`
2. Обновляет `settings.json` -- добавляет hooks в `pre-tool-use`
3. Показывает какие именно операции теперь блокируются

Это паттерн **hook-as-skill**: skill инсталлирует и управляет набором hooks. Удобно для sharing через community.

## Debugging hooks

### 1. Проверить что hook registered

```bash
cat ~/.claude/settings.json | jq '.hooks'
```

Должны быть перечислены все hooks.

### 2. Ручной запуск hook

```bash
echo '{"command":"git push --force origin main"}' | ~/.claude/hooks/block-dangerous-git.sh
echo "Exit: $?"
```

Exit 1 ожидается = blocked. Exit 0 = allowed.

### 3. Verbose mode

Claude Code CLI имеет флаг `--verbose` который показывает какие hooks запускаются и их результат:

```bash
claude-code --verbose "сделай git push --force"
```

В логах появится:
```
[hook] pre-tool-use/block-dangerous-git.sh: BLOCKED
```

### 4. Dry-run

Некоторые skills поддерживают dry-run -- показать что бы произошло без фактического блокирования. Для кастомных hooks это делается через env var:

```bash
#!/bin/bash
if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY-RUN: would block if $CHECK" >&2
  exit 0
fi

# Normal logic...
```

### 5. Логирование

Добавить логирование в каждый hook в общий файл:

```bash
log() {
  echo "$(date -Iseconds) [$CLAUDE_SESSION_ID] $1" >> ~/.claude/hooks.log
}

log "START: $0 for tool=$CLAUDE_TOOL_NAME"
# ... hook logic ...
log "END: exit=$?"
```

Потом `tail -f ~/.claude/hooks.log` покажет активность hooks в реальном времени.

## Enterprise setup: shared hooks

Для команды -- hooks должны быть **синхронизированы** между разработчиками. Варианты:

### Через project-level `.claude/settings.json`

```
my-project/
├── .claude/
│   ├── settings.json       # ← commit в репо, все используют
│   └── hooks/
│       ├── block-secrets.sh
│       └── enforce-style.sh
```

Hooks в project `.claude/` автоматически подключаются когда Claude Code работает в этом проекте. Новый член команды клонирует репо -- hooks сразу активны.

### Через plugin

Плагин `my-team-guardrails` устанавливается через `claude plugin install`:

```
my-team-guardrails/
├── plugin.yaml
└── hooks/
    ├── block-prod-db.sh
    ├── require-ticket-ref.sh
    └── audit-log.sh
```

Команда: `claude plugin install github.com/my-org/team-guardrails`.

Плюс -- централизованное обновление через `claude plugin update`.

### Через mandatory setting

Enterprise-admin может зафиксировать обязательные hooks через organization-level settings которые не перезаписываются user-settings.

## Связанные статьи

- [README.md](README.md) -- профиль Claude Code
- [news.md](news.md) -- контекст Hooks в архитектуре
- [skills-guide.md](skills-guide.md) -- Skills (часто связаны с hooks)
- [mcp-setup.md](mcp-setup.md) -- MCP (альтернатива hooks для интеграций)
- [agent-teams.md](agent-teams.md) -- Hooks критичны в Team-режиме (много параллельных сессий)
- [Официальная документация Hooks](https://code.claude.com/docs/en/hooks)
- [Skill git-guardrails-claude-code](https://github.com/...) (есть в проекте `ai-plant`)
