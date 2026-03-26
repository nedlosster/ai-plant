# OpenCode vs Claude Code: детальное сравнение

Оба инструмента -- терминальные AI-агенты для работы с кодом. Принципиальное различие: Claude Code привязан к моделям Anthropic, OpenCode работает с любыми OpenAI-совместимыми API.

## Общее сравнение

| Критерий | Claude Code | OpenCode |
|----------|-------------|----------|
| Разработчик | Anthropic | OpenCode AI (open-source) |
| Лицензия | проприетарный | MIT |
| Язык | TypeScript | Go |
| TUI фреймворк | Ink (React) | Bubble Tea |
| Модели | Claude (Opus, Sonnet, Haiku) | любые OpenAI-совместимые |
| Локальные модели | нет | да |
| Приватность | данные через Anthropic API | полностью локально |
| Стоимость | подписка ($20-100/мес) | бесплатно |

## Инструменты (tools)

| Инструмент | Claude Code | OpenCode |
|-----------|-------------|----------|
| Bash | да | да |
| Read | да | да |
| Write | да | да |
| Edit | да (exact match replace) | да (patch) |
| Grep | да (встроенный) | нет (через bash) |
| Glob | да (встроенный) | нет (через bash) |
| WebSearch | да | нет |
| WebFetch | да | нет |
| Notebook | да (Jupyter) | нет |
| Agent (subagent) | да | да (@mention) |

Claude Code имеет больше встроенных инструментов. OpenCode компенсирует это через bash и MCP-серверы.

## Агенты и режимы

### Claude Code

- **Обычный режим** -- полный доступ ко всем инструментам
- **Plan mode** -- только чтение, проектирование решений
- **Subagents** -- автоматически запускаемые подагенты (Explore, Plan, general-purpose)
- **Skills** -- slash-команды из `.claude/skills/` с markdown-инструкциями

### OpenCode

- **Build agent** -- полный доступ (bash, read, write, edit)
- **Plan agent** -- только чтение
- **Кастомные агенты** -- markdown-файлы в `.opencode/agents/`
- **@mention** -- вызов другого агента из текущего

Ключевое отличие: Claude Code автоматически запускает subagents для исследования кодовой базы. OpenCode требует явного вызова через @mention.

## Кастомизация

### Правила проекта

| | Claude Code | OpenCode |
|-|-------------|----------|
| Файл | `CLAUDE.md` (в корне проекта) | `instructions` в opencode.json или `.opencode/instructions.md` |
| Глобальный | `~/.claude/CLAUDE.md` | `~/.config/opencode/opencode.json` |
| Формат | Markdown (свободный) | Текст (строка или файл) |
| Вложенные | да (CLAUDE.md в подпапках) | нет |

Claude Code загружает CLAUDE.md автоматически из текущей и родительских директорий. OpenCode требует явного указания файла.

### Skills vs кастомные агенты

**Claude Code skills** (`.claude/skills/SKILL.md`):
```markdown
---
name: test
description: Запуск тестов
user-invocable: true
argument-hint: [local|all]
---

# Тестирование

## Алгоритм
1. Определить тип теста из аргумента
2. Запустить pytest/go test
3. Проанализировать результат
```

Вызов: `/test local`

**OpenCode кастомный агент** (`.opencode/agents/tester.md`):
```markdown
---
name: tester
model: llama/chat
tools:
  bash: true
  read: true
  write: true
  edit: true
---

Ты -- QA-инженер. Определи тестовый фреймворк из проекта.
Напиши и запусти тесты.
```

Вызов: `@tester напиши тесты для auth module`

Отличия:
- Skills -- одноразовые скрипты с параметрами, агент выполняет инструкции из файла
- Кастомные агенты -- постоянные роли, общаются как отдельная личность
- Skills могут быть вызваны slash-командой, агенты -- через @mention

### Permissions

**Claude Code:**
```json
// settings.json
{
  "permissions": {
    "allow": ["Bash(git *)"],
    "deny": ["Bash(rm -rf *)"]
  }
}
```

**OpenCode:**
```json
// opencode.json
{
  "permission": {
    "allow": ["Bash(git *)"],
    "deny": ["Bash(rm -rf *)"]
  }
}
```

Синтаксис практически идентичен. Оба поддерживают glob-паттерны.

### Хуки (hooks)

Claude Code поддерживает хуки -- shell-команды, выполняемые автоматически при событиях:

```json
{
  "hooks": {
    "PreToolUse": [{ "matcher": "Bash", "command": "echo 'executing bash'" }],
    "PostToolUse": [{ "matcher": "Write", "command": "./lint.sh" }]
  }
}
```

OpenCode не имеет встроенных хуков. Альтернатива -- инструкции в системном промпте:

```
После каждого изменения файла запускай: bash -c './scripts/lint.sh'
```

Это менее надёжно, так как зависит от модели.

### MCP-серверы

Оба поддерживают MCP (Model Context Protocol):

**Claude Code:**
```json
// settings.json
{
  "mcpServers": {
    "github": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"] }
  }
}
```

**OpenCode:**
```json
// opencode.json
{
  "mcp": {
    "github": { "command": ["npx", "-y", "@modelcontextprotocol/server-github"] }
  }
}
```

Синтаксис немного отличается (массив vs отдельные args), но функциональность одинакова.

## Memory и контекст

| | Claude Code | OpenCode |
|-|-------------|----------|
| Автоматическая memory | да (файловая система `.claude/memory/`) | нет |
| Сжатие контекста | да (автоматическое) | нет |
| Контекстное окно | до 1M токенов | 8K-128K (зависит от модели) |
| Кэширование промптов | да (prompt caching API) | нет |

Claude Code управляет контекстом значительно лучше благодаря большому окну и автоматическому сжатию. OpenCode с локальными моделями требует ручного управления контекстом.

## Качество работы

На практике (субъективные наблюдения):

| Задача | Claude Code (Opus) | OpenCode (Qwen3-Coder 30B) |
|--------|-------------------|----------------------------|
| Простые правки | отлично | хорошо |
| Рефакторинг | отлично | удовлетворительно |
| Новые фичи | отлично | удовлетворительно (декомпозиция) |
| Code review | отлично | хорошо |
| Архитектурные решения | отлично | слабо |
| Tool calling | надёжное | нестабильное |
| Многофайловые изменения | отлично | удовлетворительно |
| Отладка | отлично | удовлетворительно |

## Когда что использовать

| Сценарий | Рекомендация |
|----------|-------------|
| Сложная архитектура, большой рефакторинг | Claude Code |
| Приватный код, офлайн | OpenCode |
| Бюджет ограничен | OpenCode |
| Максимальное качество | Claude Code |
| Эксперименты с моделями | OpenCode |
| CI/CD интеграция | оба (headless mode) |
| Обучение, практика | OpenCode (бесплатно) |

## Миграция между инструментами

### CLAUDE.md -> OpenCode instructions

```
CLAUDE.md содержимое -> .opencode/instructions.md
```

Формат совместим (markdown), но OpenCode не поддерживает вложенные CLAUDE.md из подпапок.

### Skills -> кастомные агенты

```
.claude/skills/test/SKILL.md -> .opencode/agents/tester.md
```

Нужно адаптировать frontmatter (name, description -> name, model, tools) и переписать инструкции под формат агента.

## Связанные статьи

- [Стратегии работы](strategies.md) -- приёмы для OpenCode с локальными моделями
- [Кастомизация](customization.md) -- правила, agents, MCP
- [AI-агенты](../agents.md) -- обзор всех агентов
