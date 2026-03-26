# AI-агенты для кодинга

Платформа: llama-server на порту 8080, Qwen2.5-Coder-32B или Qwen3-Coder-Next.

## Сравнение агентов

| Агент | Интерфейс | Модели | Multi-file | Git | Лицензия |
|-------|-----------|--------|-----------|-----|----------|
| **Aider** | терминал | любой OpenAI API | да | да (auto-commit) | Apache 2.0 |
| **SWE-agent** | терминал | любой OpenAI API | да | да (Docker) | MIT |
| **OpenHands** | веб-UI | любой OpenAI API | да | да | MIT |
| **Mistral Vibe** | терминал | Devstral | да | да | Apache 2.0 |
| **OpenCode** | TUI | любой OpenAI API | да | да | MIT |
| **Roo Code** | VS Code | любой OpenAI API | да | нет | Apache 2.0 |

## Aider

Терминальный AI для парного программирования. Работает с git, координирует правки в нескольких файлах, автоматически коммитит изменения.

### Установка

```bash
pip install aider-chat
```

### Подключение к локальному серверу

```bash
aider \
    --model openai/qwen2.5-coder-32b \
    --openai-api-base http://<SERVER_IP>:8080/v1 \
    --openai-api-key not-needed
```

### Основные команды

```
/add file.py             # Добавить файл в контекст
/drop file.py            # Убрать файл из контекста
/ask "как работает X?"   # Вопрос без изменения кода
/diff                    # Показать diff последних изменений
/undo                    # Отменить последний коммит
/run pytest              # Запустить команду
/lint                    # Линтер
/test                    # Запуск тестов
/review                  # Code review
```

### Пример сессии

```bash
$ aider --model openai/qwen2.5-coder-32b --openai-api-base http://<SERVER_IP>:8080/v1 --openai-api-key x

> /add src/parser.py src/validator.py

> Добавь валидацию email в validator.py. Используй regex. Добавь unit-тесты.

# Aider анализирует файлы, предлагает изменения, создает git commit
```

### Конфигурация (.aider.conf.yml)

```yaml
model: openai/qwen2.5-coder-32b
openai-api-base: http://<SERVER_IP>:8080/v1
openai-api-key: not-needed
auto-commits: true
auto-lint: true
```

### Рейтинг моделей в Aider

Aider поддерживает лидерборд. Лучшие open-source (март 2026):
- DeepSeek-V3.2-Exp (Reasoner): 74.2%
- Qwen2.5-Coder-32B: 73.7%

## SWE-agent

Агент для автоматического решения GitHub issues. Использует Docker для безопасного исполнения кода.

### Установка

```bash
pip install sweagent
```

### Подключение к локальному серверу

```bash
sweagent run \
    --model openai:qwen2.5-coder-32b \
    --env.repo.github_url https://github.com/user/repo \
    --env.repo.branch main \
    --env.instance_id "issue-123"
```

Конфигурация API:

```yaml
# ~/.swe-agent/config.yaml
model:
  name: openai/qwen2.5-coder-32b
  api_base: http://<SERVER_IP>:8080/v1
  per_instance_cost_limit: 0
```

### Ограничения с локальными моделями

- Требует модели с хорошим instruction-following
- Модели <32B могут зацикливаться на сложных задачах
- Рекомендуется Qwen3-Coder-Next 80B MoE для серьезных задач

## OpenHands (ex-OpenDevin)

Платформа для AI-агентов с веб-интерфейсом. Агенты пишут код, работают с терминалом и браузером.

### Установка (Docker)

```bash
docker pull docker.all-hands.dev/all-hands-ai/runtime:0.39-nikolaik

docker run -it --rm \
    -p 3000:3000 \
    -e LLM_API_KEY=not-needed \
    -e LLM_BASE_URL=http://<SERVER_IP>:8080/v1 \
    -e LLM_MODEL=qwen2.5-coder-32b \
    docker.all-hands.dev/all-hands-ai/openhands:main
```

Веб-UI: `http://localhost:3000`.

### Ограничения

- Требует frontier-уровня моделей для сложных задач
- Локальные модели 32B работают на простых задачах
- Для SWE-bench уровня нужен 70B+ или cloud API

## Mistral Vibe CLI

Терминальный агент от Mistral. Оптимизирован для Devstral.

### Установка

```bash
pip install mistral-vibe
```

### Использование с локальным сервером

```bash
# Запустить llama-server с Devstral Small 2
llama-server -m devstral-small-2-q4_k_m.gguf --port 8080 -ngl 99 -c 65536

# Запуск агента
MISTRAL_API_KEY=not-needed \
MISTRAL_API_BASE=http://<SERVER_IP>:8080/v1 \
vibe "Добавь обработку ошибок в src/api.py"
```

### Возможности

- Мульти-файловая оркестрация
- Git-интеграция
- Поиск по коду
- Контекст до 256K токенов (Devstral)

## Что выбрать

| Задача | Агент |
|--------|-------|
| Ежедневный рефакторинг | **Aider** -- простой, git-интеграция |
| Решение issues | **SWE-agent** -- Docker-изоляция |
| Веб-UI для команды | **OpenHands** -- браузерный интерфейс |
| Навигация по большому проекту | **Mistral Vibe** -- 256K контекст |
| IDE-интеграция | **Cline / Roo Code** (см. [ide-integration.md](ide-integration.md)) |
| TUI | **OpenCode** (см. [ide-integration.md](ide-integration.md)) |

Для начала: **Aider** -- минимальный порог входа, максимальная практичность.

## Связанные статьи

- [Настройка сервера](server-setup.md)
- [Модели для кодинга](models.md)
- [Сценарии](scenarios.md)
- [Function calling](../../llm-guide/function-calling.md)
