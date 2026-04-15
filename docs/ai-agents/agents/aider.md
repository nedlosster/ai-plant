# Aider (Paul Gauthier, 2023-2026)

> Зрелый CLI-агент с git-first философией, architect mode, лучшая поддержка локальных моделей.

**Тип**: CLI (terminal)
**Лицензия**: Apache 2.0
**Backend**: Multi-provider (OpenAI / Anthropic / OpenAI-compatible / local)
**Совместим с локальным llama-server**: **да** -- одна из лучших поддержек
**Цена**: Free open-source

## Обзор

Aider -- классика CLI-агентов от Paul Gauthier. **39K+ stars, 4.1M+ installs**, обрабатывает 15B+ токенов/неделю глобально. Существует с 2023, что делает его одним из самых зрелых open-source инструментов.

Главная фишка -- **git-first философия**: каждая AI-правка автоматически коммитится с описательным сообщением. Это даёт reviewable history, легко откатывать, идеально для code review через git diff. Aider буквально интегрирован в git workflow -- работает как ещё один контрибьютор.

Очень популярен для работы с локальными моделями: документация акцентирует поддержку Ollama, llama.cpp, vLLM. На нашей платформе подключается через `OPENAI_BASE_URL` к llama-server.

## Возможности

- **Git auto-commit** -- каждая правка коммитится автоматически с meaningful message
- **Architect mode** -- одна модель планирует, другая реализует (можно использовать разные модели)
- **Linting + testing loop** -- запускает линтер и тесты, итерирует по ошибкам
- **Repo map** -- автоматическое индексирование кодовой базы для контекста
- **Multi-file edits** -- одновременные изменения с пониманием связей
- **Voice input** -- голосовой ввод задач
- **Conventions file** -- проектные правила (`CONVENTIONS.md`)
- **Watch mode** -- agent следит за файлами и реагирует на комментарии-промпты
- **Multi-provider** -- любой OpenAI/Anthropic/OpenAI-compatible

## Сильные стороны

- **Git auto-commit** -- каждая правка ревьюабельна
- **Architect mode** -- разделение планирования и реализации
- **Зрелый проект** -- 2+ лет в production, стабильный
- **Отличная поддержка локальных моделей** -- одна из лучших в категории
- **Активное развитие** -- еженедельные релизы
- **Repo map** -- автоматический контекст без ручного выбора файлов
- **Watch mode** -- inline-промпты в комментариях кода
- **CLI-only** -- без зависимостей от IDE

## Слабые стороны / ограничения

- **Только CLI** -- нет GUI/TUI (только terminal output)
- **Нет параллельных агентов** -- единый последовательный workflow
- **Repo map медленный** на очень больших проектах
- **Конфигурация через CLI/env** -- нет богатого config-файла как у opencode
- **Нет MCP support** (на момент 2026 -- может появится)
- **Меньше "agentic"** чем opencode/Claude Code -- больше fixed workflow

## Базовые сценарии

- "Добавь функцию X в файл Y"
- "Исправь все warnings в этом проекте"
- "Сгенерируй тесты для модуля Z"
- Inline через комментарии в коде (watch mode)

## Сложные сценарии

- **Architect mode для сложных задач**:
  - Architect модель (Claude Opus / GPT-5): планирование архитектуры
  - Coder модель (Qwen3-Coder Next локально): реализация
  - Экономия: сложное мышление в платной модели, рутина в локальной
- **Linting + testing loop**: agent правит → запускает тесты → видит ошибки → правит снова → пока зелёно
- **Repo refactoring** через repo map с автоматическим контекстом
- **Watch mode для встроенных правок**:
  ```python
  # ai! Add input validation here
  def process(data):
      ...
  ```
  Agent читает комментарий и предлагает правку
- **Voice-driven coding** -- "сделай этот endpoint POST с rate limiting"

## Установка / запуск

```bash
# Установка
pip install aider-install
aider-install

# Запуск с локальным llama-server
aider \
    --model openai/qwen3-coder-next \
    --openai-api-base http://192.168.1.77:8081/v1 \
    --openai-api-key local

# Architect mode (разные модели для plan и code)
aider \
    --architect \
    --model anthropic/claude-opus-4.6 \
    --editor-model openai/qwen3-coder-next \
    --editor-api-base http://192.168.1.77:8081/v1
```

## Конфигурация

`.aider.conf.yml` в корне проекта:

```yaml
model: openai/qwen3-coder-next
openai-api-base: http://192.168.1.77:8081/v1
openai-api-key: local
auto-commits: true
git: true
lint: true
test-cmd: "npm test"
```

`CONVENTIONS.md` -- проектные правила, читаются автоматически.

## Бенчмарки

| Бенч | Значение |
|------|----------|
| Aider polyglot benchmark | топ open-source с GPT-5 и Claude |
| SWE-bench | зависит от модели |

Aider публикует [собственный leaderboard](https://aider.chat/docs/leaderboards/) -- мониторит как разные модели работают в нём.

## Анонсы и открытия

- **2026-Q2** -- интеграция с Qwen3.6-Plus (1M context)
- **2026-Q1** -- расширение voice mode
- **2025-Q4** -- watch mode improvements
- **2025-Q3** -- architect mode стал основным
- **2024** -- 4M+ installs milestone
- **Continuous** -- еженедельные релизы

## Ссылки

- [Официальный сайт](https://aider.chat/)
- [GitHub: paul-gauthier/aider](https://github.com/paul-gauthier/aider)
- [Документация](https://aider.chat/docs/)
- [Leaderboard](https://aider.chat/docs/leaderboards/) -- модели в Aider polyglot benchmark
- [Discord](https://discord.gg/Tv2uQnR88V)

## Связано

- **Альтернативы (CLI)**: [opencode](opencode.md), [qwen-code](qwen-code.md), [claude-code](claude-code/README.md) для commercial
- **Альтернативы (IDE)**: [cline](cline.md), [continue-dev](continue-dev.md)
- **Лучшие модели для пары**: [qwen3-coder](../../models/families/qwen3-coder.md), [claude-code](claude-code/README.md) для architect mode
- **Платформа**: [coding.md](../../models/coding.md)
- **Концепты**: [../README.md](../README.md)
