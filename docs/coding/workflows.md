# AI-кодинг: практические workflow'ы

Как организовать AI-assisted разработку на платформе Strix Halo: комбинации моделей, агентов и инструментов для разных задач. Не теория -- конкретные конфигурации, проверенные на практике.

Профиль раздела -- [README.md](README.md). Каталог моделей -- [models/coding.md](../models/coding.md). Агенты -- [ai-agents/](../ai-agents/README.md).

---

## Принцип: layered AI stack

AI-инструменты не конкурируют, а дополняют друг друга. Три слоя:

```
Слой 3: Agent (complex tasks)     Claude Code, opencode, Aider
         Multi-file refactoring, architecture, debugging
         
Слой 2: IDE assistant (inline)    Cursor, Cline, Continue.dev
         Autocomplete, inline edit, explain, quick fix
         
Слой 1: FIM server (background)   llama-server + Qwen3-Coder 30B
         Tab completion, fill-in-the-middle, бесплатно 24/7
```

Каждый слой решает свою задачу. FIM работает постоянно (бесплатно, локально). IDE assistant -- по запросу (inline). Agent -- для крупных задач (multi-file, agentic loop).

---

## Workflow 1: FIM + CLI agent (основной)

Самый частый сценарий: autocomplete через FIM + agent для крупных задач.

### Настройка

Два llama-server параллельно:

```bash
# Терминал 1: FIM (порт 8080)
./scripts/inference/vulkan/preset/qwen3-coder-30b.sh -d --port 8080

# Терминал 2: Chat agent (порт 8081)
./scripts/inference/vulkan/preset/qwen3-coder-next.sh -d --port 8081
```

VRAM бюджет: 30B Q4 (~18 GiB) + Next 80B-A3B Q4 (~5 GiB) = ~23 GiB. Остаётся ~97 GiB для KV-cache и контекста.

### IDE (VS Code + Continue.dev)

```json
{
  "tabAutocompleteModel": {
    "provider": "openai",
    "apiBase": "http://192.168.1.77:8080/v1",
    "model": "qwen3-coder-30b"
  }
}
```

### CLI agent (opencode)

```yaml
providers:
  openai-compatible:
    apiBase: http://192.168.1.77:8081/v1
    model: qwen3-coder-next
```

### Когда использовать

| Задача | Инструмент | Модель |
|--------|-----------|--------|
| Tab completion | Continue.dev FIM | Qwen3-Coder 30B (порт 8080) |
| Быстрый inline edit | Continue.dev chat | Qwen3-Coder 30B |
| Рефакторинг 1-3 файла | opencode | Qwen3-Coder Next (порт 8081) |
| Рефакторинг 10+ файлов | Claude Code | Claude Opus 4.6 (cloud) |
| Code review | opencode/Aider | Qwen3-Coder Next |
| Debugging | Claude Code | Opus 4.6 (cloud) |

---

## Workflow 2: Cloud agent для сложных задач

Когда локальная модель не справляется -- переключение на cloud.

### Критерии переключения

- Задача требует reasoning на уровне >50% SWE-bench
- Multi-repo refactoring (>20 файлов)
- Architecture review / design
- Debugging unfamiliar codebase
- Генерация тестов для legacy code

### Claude Code (primary cloud agent)

```bash
# Проект с CLAUDE.md -- Claude Code подбирает контекст автоматически
claude

# Конкретная задача
claude "рефакторинг auth middleware: разделить на jwt-validation и session-management"
```

Стоимость: ~$0.50-2.00 за типичную сессию (Opus 4.6, ~10K-50K tokens).

### Fallback chain

1. Локальная модель (бесплатно) -- пробуем первой
2. Claude Code Sonnet ($3/M input) -- средние задачи
3. Claude Code Opus ($15/M input) -- сложные задачи
4. GPT-5.3 Codex ($10/M input) -- альтернатива Opus

---

## Workflow 3: Code review через agent

AI-assisted code review перед merge.

### Вариант A: opencode + локальная модель

```bash
# Review diff в текущей ветке
opencode "review changes since main: security, performance, style"
```

### Вариант B: Claude Code

```bash
claude "review PR #42: focus on security vulnerabilities and edge cases"
```

### Вариант C: Aider (watch mode)

```bash
aider --watch  # автоматически комментирует при изменениях
```

### Чеклист для AI code review

- Security: injection, auth bypass, secrets in code
- Performance: N+1 queries, memory leaks, unnecessary allocations
- Correctness: edge cases, null handling, error paths
- Style: naming, structure, separation of concerns
- Tests: coverage gaps, missing edge case tests

---

## Workflow 4: Multi-agent (Agent Teams)

Для крупных задач: рефакторинг monorepo, multi-service migration.

### Claude Code Agent Teams

```bash
# Включить
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=true

# Запустить
claude --team feature-dev
```

Подробнее: [agent-teams.md](../ai-agents/agents/claude-code/agent-teams.md)

### Паттерн: Planner + Executors

```
Lead (Opus 4.6): анализ задачи, разбиение на подзадачи
  ├── Executor 1 (Sonnet 4.5): backend changes
  ├── Executor 2 (Sonnet 4.5): frontend changes
  └── Executor 3 (Sonnet 4.5): tests
Lead: merge, review, финализация
```

### Когда Agent Teams

- Задача разбивается на 3+ независимых частей
- Каждая часть занимает >30 минут у одного агента
- Нужна координация между частями (shared interfaces)

---

## Workflow 5: Генерация и запуск тестов

### TDD с AI agent

```bash
# 1. Описать что тестировать
claude "напиши тесты для UserService.authenticate: happy path, wrong password, locked account, expired token"

# 2. Запустить тесты (должны упасть)
pytest tests/test_user_service.py

# 3. Реализовать
claude "реализуй UserService.authenticate чтобы тесты прошли"

# 4. Проверить
pytest tests/test_user_service.py
```

### Regression testing

```bash
# После фикса бага -- добавить тест
claude "добавь тест воспроизводящий баг #123 (описание) и проверь что fix работает"
```

---

## Workflow 6: Documentation + code sync

### Обновление docs после code change

```bash
# После рефакторинга
claude "/doc-lifecycle code-change"
```

Скилл `/doc-lifecycle` автоматически находит затронутые документы по маппингу код -> docs.

---

## Модели: что куда

Сводная таблица "модель -> задача" для платформы Strix Halo:

| Задача | Модель | VRAM | Почему |
|--------|--------|------|--------|
| FIM autocomplete | Qwen3-Coder 30B-A3B | ~18 GiB | Быстрый, FIM native |
| Chat agent (local) | Qwen3-Coder Next | ~5 GiB | MoE, низкий VRAM |
| Heavy reasoning (local) | Qwen3.5-122B-A10B | ~71 GiB | Большой контекст, качество |
| Complex tasks (cloud) | Claude Opus 4.6 | -- | SWE-bench лидер |
| Budget cloud | Claude Sonnet 4.5 | -- | 3x дешевле Opus |
| Alternative cloud | GPT-5.3 Codex | -- | 85% SWE-bench |

### Параллельные конфигурации

| Конфигурация | Модели | Суммарный VRAM |
|--------------|--------|----------------|
| FIM + Chat | 30B + Next | ~23 GiB |
| FIM + Heavy | 30B + 122B | ~89 GiB |
| Chat only | Next | ~5 GiB |
| Maximum local | 122B-A10B | ~71 GiB |

---

## Антипаттерны

- **Использовать cloud для tab completion** -- дорого и медленно. FIM через локальный llama-server бесплатен
- **Один agent для всего** -- FIM для autocomplete, agent для multi-file, cloud для reasoning
- **Игнорировать контекст** -- CLAUDE.md, .cursorrules, system prompts экономят 50%+ токенов
- **Cloud без fallback** -- API падают. Локальная модель как backup
- **Agent Teams для простых задач** -- overhead координации. Один agent быстрее для <3 файлов
- **Доверять без review** -- AI code review не заменяет human review, дополняет

---

## Примеры и сценарии

Конкретные примеры для каждого типа задач.

### Автодополнение (FIM): пример

Курсор между `def parse_json` и `return result`:

```python
def parse_json(data: str) -> dict:
    # <-- курсор здесь -->
    return result
```

Модель вставляет:

```python
def parse_json(data: str) -> dict:
    try:
        result = json.loads(data)
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON: {e}")
    return result
```

Параметры FIM: debounce 200-300ms, максимум 1024 токенов контекста, температура 0.0-0.1.

### Chat: генерация кода

Примеры запросов:

```
Напиши Python-скрипт для мониторинга GPU через sysfs. Читать: gpu_busy_percent,
mem_info_vram_used, temp1_input. Вывод в формате: "GPU: X% VRAM: Y MiB Temp: ZC".
Обновление каждую секунду.
```

```
Напиши FastAPI эндпоинт для загрузки файлов. Максимум 100 MiB, только .pdf и .docx.
Сохранение в /uploads/ с uuid-именем. Возврат JSON с id и размером.
```

### Chat: объяснение кода

Выделить код в IDE -> Ctrl+Shift+L (добавить в контекст) -> задать вопрос.

```
Объясни что делает этот код. Какие edge cases не обработаны?
```

```
Какая сложность этого алгоритма? Можно ли оптимизировать?
```

### Рефакторинг: примеры

Aider (терминал):

```bash
aider --model openai/qwen2.5-coder-32b --openai-api-base http://<SERVER_IP>:8080/v1 --openai-api-key x

> /add src/database.py src/models.py src/routes.py

> Замени все raw SQL-запросы на SQLAlchemy ORM. Сохрани текущее поведение.
```

Cline (Plan mode):

```
Разбей файл src/utils.py на отдельные модули:
- src/utils/string_helpers.py
- src/utils/file_helpers.py
- src/utils/date_helpers.py
Обнови все import-ы в проекте.
```

### Code review: промпт

```
Проведи code review этого файла. Обрати внимание на:
1. SQL-инъекции и XSS
2. Обработку ошибок
3. Race conditions
4. Утечки ресурсов (файлы, соединения)
5. Несоответствие типов
```

### Генерация тестов: промпт

```
Сгенерируй тесты для функции parse_config(). Используй pytest + fixtures.
Покрой:
- Валидный YAML
- Пустой файл
- Несуществующий файл
- Невалидный YAML (синтаксическая ошибка)
- Отсутствующие обязательные поля
- Значения за пределами допустимого диапазона
```

### Документирование: inline-редактирование

Continue.dev: выделить функцию -> Ctrl+I:

```
Добавь docstring с описанием параметров и return type.
```

Aider:

```bash
> /add src/api.py

> Добавь Google-style docstrings ко всем публичным функциям и классам.
> Включи описание параметров, возвращаемого значения и примеры использования.
```

### Debugging: анализ трейсбека

Вставить трейсбек в чат:

```
Вот ошибка при запуске:

Traceback (most recent call last):
  File "src/main.py", line 45, in process_request
    result = parser.parse(data)
  File "src/parser.py", line 23, in parse
    return json.loads(data.decode('utf-8'))
AttributeError: 'dict' object has no attribute 'decode'

Файл src/main.py вызывает parser.parse() из обработчика FastAPI.
В чем проблема и как исправить?
```

### Общие рекомендации

1. **Начинать с малого** -- одна задача за раз, не "перепиши весь проект"
2. **Передавать контекст** -- добавлять релевантные файлы, не весь проект
3. **Проверять результат** -- AI может генерировать синтаксически правильный, но логически неверный код
4. **Итерировать** -- если результат не устраивает, уточнить запрос
5. **Температура 0.0-0.3** -- для кода детерминированность важнее креативности
6. **Git** -- коммитить перед рефакторингом через AI (Aider делает это автоматически)

---

## Связанные статьи

- [README.md](README.md) -- обзор раздела
- [news.md](news.md) -- хроника событий
- [resources.md](resources.md) -- блоги и community
- [Модели для кодинга](../models/coding.md) -- каталог, бенчмарки
- [Agent Teams](../ai-agents/agents/claude-code/agent-teams.md) -- multi-agent strategy
- [opencode](../ai-agents/agents/opencode.md) -- CLI agent
- [Inference стек](../inference/README.md) -- как запускать модели
