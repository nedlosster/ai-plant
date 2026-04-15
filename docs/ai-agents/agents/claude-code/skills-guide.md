# Skills: практическое руководство

Глубокий гайд по Skills в Claude Code: что это, как писать качественные skills, best practices, ecosystem и debugging. Skills -- один из ключевых механизмов расширения, они дают slash-command интерфейс к переиспользуемым навыкам.

Общий контекст механизма Skills в архитектуре -- в [news.md](news.md#архитектура-полного-стека-claude-code-состояние-на-апрель-2026).

## Что такое Skills и зачем

**Skill** -- это markdown-файл с frontmatter и body, описывающий **переиспользуемую задачу или навык**. Каждый skill автоматически получает slash-command интерфейс: `/skill-name [args]`.

Примеры skills в проекте `ai-plant`:
- `/refresh-news [news|agents|models|hardware]` -- обновление новостных статей через веб-поиск
- `/doc-lifecycle [new-doc|review|validate|code-change]` -- управление жизненным циклом docs
- `/diagram` -- создание и рендеринг Mermaid-диаграмм
- `/models-catalog [add-family|add-model|sync-status]` -- управление каталогом моделей

### Чем Skills отличаются от других механизмов

| Механизм | Что делает | Когда использовать |
|----------|------------|---------------------|
| **Skill** | Промпт + инструкции + возможно tools. Получает `/slash-command`. Загружается по триггеру или явному вызову | **Повторяющаяся задача** с известной структурой |
| **Subagent** | Изолированная sub-сессия с собственным tool set | **Делегирование** подзадачи с изоляцией контекста |
| **Hook** | Shell-команда на event (pre/post tool use). Exit code = allow/block | **Enforce** стандартов, safety guardrails |
| **MCP server** | Внешний процесс, экспонирующий tools/resources | **Интеграция** с внешними системами (GitHub, DB, Slack) |
| **Plugin** | Упаковка Skills + Hooks + MCP | **Distribution** team-стандартов |

**Правило выбора**:
- Знаешь **как делать** задачу и хочешь зафиксировать -- Skill
- Задача требует **изолированный контекст** для выполнения -- Subagent
- Нужно **гарантированно** выполнить что-то на event -- Hook
- Нужен доступ к **внешней системе** -- MCP
- Хочешь **шарить** набор фич с командой -- Plugin

## Структура Skill-файла

Skills лежат в:
- **Глобальные**: `~/.claude/skills/<skill-name>/SKILL.md`
- **Проектные**: `<project>/.claude/skills/<skill-name>/SKILL.md`

Проектные перекрывают глобальные при одинаковом имени.

### Анатомия Skill

```markdown
---
name: skill-name
description: "Краткое описание -- используется Claude для решения когда вызвать skill"
user-invocable: true
argument-hint: [arg1 | arg2 | arg3]
---

# Заголовок skill

## Когда использовать

| Триггер | Сценарий |
|---------|----------|
| Фраза X | Сделать Y |

## Инструкции

Аргумент: `$ARGUMENTS` -- один из `arg1`, `arg2`, `arg3`.
Если не передан -- спросить у пользователя.

## Алгоритм

1. Шаг первый
2. Шаг второй
3. Шаг третий

## Критические правила (stylelint / compliance / и т.д.)

- Правило 1
- Правило 2

## Шаблоны / примеры

<готовые блоки текста, шаблоны code, и т.д.>

## Финальный отчёт

После завершения вывести: ...
```

### Frontmatter fields

| Поле | Обязательное | Назначение |
|------|--------------|------------|
| `name` | да | Имя skill (совпадает с папкой). Определяет slash-command |
| `description` | да | Описание для model-routing. **Самое важное поле** -- Claude выбирает skill на основе этого |
| `user-invocable` | рекомендуется | `true` -- юзер может вызвать через `/name`; `false` -- только automatic triggering |
| `argument-hint` | опционально | Hint для UI и для self-documentation |
| `tools` | опционально | Ограничение tool set (whitelist) |
| `disallowedTools` | опционально | Черный список tools |

### Пример минимального Skill

`.claude/skills/git-commit-conventional/SKILL.md`:

```markdown
---
name: git-commit-conventional
description: "Создать git commit с сообщением по Conventional Commits (feat/fix/docs/chore). Запускать когда пользователь просит commit."
user-invocable: true
argument-hint: [краткое описание изменений]
---

# Conventional Commits

## Инструкции

1. Запустить `git status` и `git diff --cached` чтобы понять что staged
2. Определить тип по изменениям:
   - `feat`: новая функциональность
   - `fix`: bugfix
   - `docs`: изменения только в docs/
   - `chore`: рефакторинг без изменения поведения
   - `test`: только тесты
3. Составить сообщение формата: `<type>(<scope>): <description>`
4. Показать сообщение пользователю, спросить ОК
5. После подтверждения -- `git commit -m "..."`

## Правила

- Не добавлять trailer про co-authoring AI в сообщение
- Не использовать слова-маркеры ИИ: "теперь", "готово", "успешно"
- Длина первой строки -- до 72 символов
- Если нужно больше -- добавлять body через пустую строку
```

## Best practices: 7 правил качественного Skill

### 1. One skill, one thing

Skill должен решать **одну конкретную задачу**. Плохо: "универсальный помощник по git". Хорошо: `/git-commit-conventional`, `/git-rebase-interactive`, `/git-cherry-pick-batch` -- каждый отдельно.

Небольшие focused skills:
- легче model routing -- Claude выбирает правильный по description
- легче тестировать и итерировать
- легче шарить с командой

### 2. Description -- key to routing

`description` -- это то, что Claude видит когда решает вызвать ли skill. Должно быть:
- **Конкретным**: когда skill применяется, в каком контексте
- **С ключевыми словами**: термины из user-prompt'ов
- **До 200 символов**: лаконично

Плохо:
```yaml
description: "Хороший skill для git операций"
```

Хорошо:
```yaml
description: "Создать git commit с сообщением по Conventional Commits. Триггер: 'commit', 'закоммить', 'сделай коммит'. Валидирует формат feat/fix/docs/chore"
```

### 3. Явные triggers в теле skill

Первая секция после заголовка -- "Когда использовать". Таблица `Триггер → Сценарий`. Помогает Claude увереннее выбрать skill, помогает пользователю понять когда вызывать.

### 4. Arguments pattern

Два подхода к аргументам:

**Flexible args** (`$ARGUMENTS` как плейсхолдер):

```markdown
Аргумент: `$ARGUMENTS` -- краткое описание изменений для commit.
```

Юзер: `/git-commit-conventional fix memory leak in cache`

Skill получает `$ARGUMENTS = "fix memory leak in cache"`.

**Preset args** (enum):

```markdown
Аргумент: один из `agents | models | hardware | benchmarks | news | all`.
Если не передан -- спросить.
```

Юзер: `/refresh-news models`

Используй preset когда возможно -- меньше ambiguity, лучше model routing.

### 5. Tools restrictions

Для safety skills -- ограничить tools:

```yaml
---
name: code-review
description: "Ревью кода без изменений. Read-only."
tools: [Read, Grep, Glob]
disallowedTools: [Edit, Write, Bash]
---
```

Skill не сможет ничего изменить, только читать и грепать. Полезно для review / audit skills.

### 6. Критические правила в отдельной секции

Если в skill есть ОБЯЗАТЕЛЬНЫЕ правила стиля/compliance -- вынести в "Критические правила". Claude видит это при routing и точно соблюдает.

Пример:

```markdown
## Критические правила (КРИТИЧНО)

- Язык: русский. Технические термины -- латиницей
- Без иконок и эмодзи
- Без маркеров ИИ: "теперь", "готово", "успешно"
- НЕ делать `git commit` без явного разрешения пользователя
```

### 7. Финальный отчёт

Если skill выполняет долгую работу -- в конце вывести структурированный отчёт:

```markdown
## Финальный отчёт

### Блок 1. Что сделано
<таблица>

### Блок 2. Что не удалось
<список>

### Блок 3. Следующие шаги
<чеклист>
```

Помогает пользователю быстро понять результат, особенно когда skill идёт долго (несколько минут).

## Организация skills

### Naming: kebab-case

Имя skill и имя папки в **kebab-case**:
- Хорошо: `git-commit-conventional`, `refresh-news`, `models-catalog`
- Плохо: `gitCommit`, `Refresh_News`, `MODELS`

Slash-command автоматически совпадает с именем: `/git-commit-conventional`.

### Категории

Для большого набора skills -- неявная группировка через префиксы:
- `/git-*` -- git-операции
- `/review-*` -- review-задачи
- `/refresh-*` -- обновление чего-то
- `/new-*` -- создание чего-то

Это упрощает discovery для пользователя.

### Project vs Global

| Scope | Где хранить | Когда использовать |
|-------|-------------|---------------------|
| **Global** | `~/.claude/skills/<name>/` | Личные skills, работающие во всех проектах (commit conventions, personal workflow) |
| **Project** | `<project>/.claude/skills/<name>/` | Project-specific (терминология, правила, инфра-команды) |

При конфликте -- project побеждает. Это позволяет override глобального skill для конкретного проекта.

## Ecosystem: популярные community skills

Основные источники:
- **[awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)** -- curated каталог skills/hooks/plugins
- **HuggingFace Spaces** -- некоторые публикуют skills там
- **GitHub topic `claude-code-skill`**

Категории популярных skills:

### Safety / guardrails

- **[git-guardrails-claude-code](https://github.com/...)** -- hooks для блокировки опасных git-команд. Уже используется в проекте `ai-plant` (`.claude/skills/git-guardrails-claude-code/`)
- **secrets-scan** -- блокирует запись файлов с API keys / credentials
- **prod-protection** -- дополнительные подтверждения для prod-операций

### Code review / quality

- **review-pr** -- ревью PR по стандартам (correctness/security/performance/style)
- **simplify** -- упрощение сложного кода, проверка на reuse
- **reducing-entropy** -- минимизация codebase size (только по запросу)

### Git / workflow

- **commit** -- Conventional Commits composer
- **new-branch** -- создание feature-branch с worktree
- **triage-issue** -- триаж bug'а с TDD-планом и созданием GitHub issue

### Documentation

- **doc-lifecycle** -- управление [`docs/`](../../../../docs/README.md) (new, review, validate)
- **edit-article** -- правка статей с улучшением структуры
- **write-a-prd** -- создание PRD через интервью пользователя
- **knowledge-base** -- ведение wiki

### Specific workflows

- **tdd** -- red-green-refactor цикл
- **c4-architecture** -- генерация C4-диаграмм
- **mermaid-diagrams** -- создание Mermaid-диаграмм
- **humanizer** -- удаление признаков AI-generated текста

## Skills в проекте ai-plant

В этом проекте используется **4 проектных skills** и **15+ глобальных**:

| Skill | Scope | Что делает |
|-------|-------|------------|
| `/new-branch` | project | Создание feature-ветки с worktree |
| `/diagram` | project | Mermaid-диаграммы в [`docs/diagrams/`](../../../diagrams/) |
| `/pdf` | project | Экспорт markdown в PDF |
| `/doc-lifecycle` | project | Управление [`docs/`](../../../README.md) (создание, ревью, валидация) |
| `/llama-cpp` | project | Сборка/обновление llama.cpp на inference-сервере |
| `/models-catalog` | project | Ведение [`docs/models/families/`](../../../models/families/README.md) |
| `/refresh-news` | project | Обновление новостных статей через веб-поиск |

Глобальные (отрывок):
- `/commit`, `/review-pr`, `/new-branch`
- `/doc-lifecycle`, `/edit-article`, `/write-a-prd`
- `/tdd`, `/c4-architecture`, `/mermaid-diagrams`
- `/humanizer`, `/reducing-entropy`, `/simplify`

Эти skills -- результат того, что Claude Code примерно 11 месяцев активно используется. Каждый skill -- результат замечания "я третий раз делаю X, сохраню паттерн".

## Debugging: как проверить что Skill работает

### 1. Проверить что Claude его видит

При старте Claude Code в логах должен быть список загруженных skills. Или можно запросить:

```
Покажи все доступные мне skills
```

Claude выведет список с descriptions.

### 2. Проверить что routing работает

Сформулировать запрос из trigger-слов описанных в `description`. Claude должен предложить использовать skill или автоматически его вызвать (если `user-invocable: true` и контекст явно совпадает).

### 3. Явный вызов

Явно: `/skill-name [args]`. Если работает -- skill существует и корректен. Если нет -- проверить:
- Имя папки = `name` в frontmatter
- `SKILL.md` существует и валидный markdown с frontmatter
- Нет синтаксических ошибок в frontmatter (YAML должен парсится)

### 4. Проверить что skill действительно применяется

Часто skill **не вызывается автоматически** хотя должен. Причины:
- `description` не совпадает с промптом пользователя
- Есть другой skill с похожим description, Claude выбрал его
- `user-invocable: false`

Решение: улучшить `description` с более специфичными keywords.

### 5. Итерация по skill

После правки SKILL.md -- **перезапустить Claude Code** чтобы перечитал skills. Hot-reload обычно не работает.

## Sharing skills: plugins и git-репозитории

### Через plugins

Упаковать несколько skills в plugin:

```
my-team-plugin/
├── plugin.yaml           # metadata плагина
├── skills/
│   ├── commit/SKILL.md
│   ├── review/SKILL.md
│   └── deploy/SKILL.md
├── hooks/
│   └── pre-push.sh
└── mcp/
    └── internal-api/
```

Установка у команды: `claude plugin install <plugin-repo-url>`.

Плюсы:
- Team standards в одном месте
- Versioning через git tags
- Updates через `claude plugin update`

### Через git-репозитории

Для простых cases -- просто держать skills в отдельном git-репо:

```bash
cd ~/.claude/skills/
git clone https://github.com/my-org/claude-skills.git
```

Skills сразу доступны. Обновление -- `git pull`.

## Связанные статьи

- [README.md](README.md) -- профиль Claude Code
- [news.md](news.md) -- хроника, контекст механизма Skills
- [hooks-guide.md](hooks-guide.md) -- Hooks (часто пересекается со skills)
- [mcp-setup.md](mcp-setup.md) -- MCP (альтернативный способ интеграции)
- [agent-teams.md](agent-teams.md) -- Teams (skills передаются в team сессии)
- [Официальная документация Skills](https://code.claude.com/docs/en/skills)
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) -- каталог community skills
- [Agent Skills: The Cheat Codes (Medium)](https://medium.com/jonathans-musings/agent-skills-the-cheat-codes-for-claude-code-b8679f0c3c4d)
