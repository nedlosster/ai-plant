# Terminal-Bench 2.0: runbook

Описание Terminal-Bench, методология, runbook для запуска на платформе.

Профиль раздела -- [README.md](README.md). Каталог результатов -- [results.md](../results.md).

## Что это

Terminal-Bench -- бенчмарк от Stanford NLP / RFC team для оценки **agent tool use в shell-окружении**. В отличие от Aider Polyglot (только code edit), Terminal-Bench меряет насколько модель эффективно работает с командной строкой: запускает команды, читает вывод, итерирует.

**Покрытие**: 56 заданий разделённых на категории:
- bash scripting (loops, conditionals, pipes)
- file ops (find, grep, sed, awk)
- debugging (анализ stack traces, отладка скриптов)
- git operations (rebase, merge conflicts, hooks)
- text manipulation (regex, transformations)
- system queries (process, network, disk)

**Публичный leaderboard**: [terminal-bench.com](https://www.terminal-bench.com)
- Frontier closed: Claude Mythos Preview ~90%, Opus 4.7 ~85%, GPT-5.3 ~80%
- Open-source: Xiaomi MiMo V2.5-Pro 86.7% (текущий лидер!), Kimi K2.6 ~70%
- Qwen 3.6-35B-A3B: 51.5% (опубликовано в карточке модели)

**Метрика**: % полностью завершённых заданий (binary pass/fail на финальное состояние filesystem/git).

## Методология

### Поток одного задания

1. Создаётся изолированный Docker контейнер с pre-configured environment
2. Agent видит описание задания + начальное состояние терминала
3. Agent выполняет команды (через tool calls в OpenAI-compat API)
4. После каждой команды получает stdout/stderr
5. Агент решает что задание завершено и сигнализирует stop
6. Harness проверяет финальное состояние:
   - Существование/содержимое файлов
   - Git history
   - Output последней команды
7. Pass/fail на основе автоматических проверок

### Что оценивает

- **Tool use proficiency**: правильные имена команд, флаги, синтаксис
- **Error recovery**: умение читать ошибки и итерировать
- **Multi-step planning**: декомпозиция комплексных задач
- **Shell idioms**: знание common patterns (find -exec, xargs, awk pipes)

### Что НЕ оценивает

- Code quality (только финальный output)
- Креативность (есть конкретный expected result)
- Edge cases которые тесты не покрывают

## Подготовка

### Установка Terminal-Bench

```bash
ssh -A -p 2277 nedlosster@79.164.89.150
cd ~/projects/ai-plant

# Venv (можно тот же что для Aider)
source ~/.venvs/aider-bench/bin/activate

# Установка terminal-bench
pip install terminal-bench

# Или из source
git clone https://github.com/laude-institute/terminal-bench
cd terminal-bench && pip install -e .
```

### Docker

Terminal-Bench требует Docker для изоляции каждого задания:

```bash
# Проверить что Docker работает
docker --version
docker ps

# Если нужно -- добавить пользователя в группу docker
sudo usermod -aG docker $USER
# Перелогиниться
```

### Запуск llama-server с tool calling

Для tool use модель должна корректно генерировать function calls:

```bash
# Запустить с --jinja (обязательно для tool calls)
./scripts/inference/vulkan/preset/qwen3.6-35b.sh -d --port 8085

# Проверить tool calling работает
curl http://localhost:8085/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.6-35b-a3b",
    "messages": [{"role": "user", "content": "List files in current directory"}],
    "tools": [{"type": "function", "function": {"name": "shell", "parameters": {...}}}]
  }'
```

## Запуск (56 задач, 1-2 ч)

```bash
cd ~/projects/ai-plant

# Простой запуск
./scripts/inference/bench-terminal.sh --model qwen3.6-35b --port 8085

# В tmux на ночь
tmux new-session -d -s terminal-bench \
  './scripts/inference/bench-terminal.sh --model qwen3.6-35b --port 8085 \
   2>&1 | tee /tmp/terminal-bench-$(date +%Y%m%d-%H%M).log'
```

Скрипт:
1. Проверяет Docker и llama-server доступны
2. Клонирует/обновляет terminal-bench репо
3. Запускает eval с правильными параметрами
4. Парсит результат, выводит сводку
5. Предлагает добавить в [`../results.md`](../results.md)

### Прогресс

Logs показывают:
```
Task 1/56: bash-loops-fizzbuzz... PASS (45s, 8 commands)
Task 2/56: git-rebase-conflict... FAIL (timeout)
Task 3/56: find-large-files... PASS (12s, 3 commands)
...
```

## Интерпретация

### Категорийный breakdown

Хорошие модели показывают равномерные результаты по категориям. Плохие сосредоточены в одной:
- **Только bash scripting высоко** -- модель memorize шаблоны, слабая в реальной отладке
- **Только git высоко** -- много git в data mix, не agent capability
- **Debugging слабо везде** -- модель плохо читает ошибки, неэффективно итерирует

### Что значит "51.5% pass rate" для Qwen 3.6-35B-A3B

В контексте платформы:
- **>80%** (frontier) -- agent можно отпускать в open-loop с минимальным надзором
- **50-70%** (open-source local) -- работает с человеческим step-by-step approval
- **<40%** -- слишком ненадёжно для production agent loop

### Сравнение с публичной цифрой

Если local result сильно расходится с публичной (>10 п.п.):
- Проверить tool calling format -- llama-server и Qwen используют совместимый, но edge cases есть
- Проверить timeout -- большие задания могут не успевать (увеличить limit)
- Проверить Docker isolation -- проблемы с network/permissions

## Troubleshooting

### Docker permissions

**Симптом**: `permission denied while trying to connect to the Docker daemon socket`.

**Решение**:
```bash
sudo usermod -aG docker $USER
# Перелогиниться или newgrp docker
```

### Timeout на сложных заданиях

**Симптом**: задания типа `git-rebase-complex` падают с timeout.

**Причины**:
- Долгий agent loop (10+ команд)
- Slow generation на платформе
- Default timeout слишком жёсткий

**Решение**: увеличить timeout в bench-terminal.sh (например, 5 мин на задание вместо 2).

### Tool call format issues

**Симптом**: модель пишет команды в обычном тексте, а не через tool calls.

**Причины**:
- `--jinja` не включен в llama-server
- Chat template без tools section
- Модель плохо обучена на tool use

**Решение**:
- Проверить запуск llama-server: должен быть `--jinja`
- Если модель не FC-native -- использовать Qwen3-Coder Next или Qwen 3.6-35B-A3B

### Docker disk space

**Симптом**: Docker images съедают всё свободное место.

**Решение**:
```bash
docker system prune -a  # очистить unused
# Перенести Docker root на внешний SSD если нужно
```

## Связанные статьи

- [README.md](README.md) -- индекс runbooks
- [aider-polyglot.md](aider-polyglot.md) -- альтернативная метрика (code edit-loop)
- [results.md](../results.md) -- журнал результатов
- [runs/](../runs/README.md) -- полные статьи прогонов
- [coding/workflows.md](../../../coding/workflows.md) -- какие модели использовать
- [inference/optimization-backlog.md](../../../inference/optimization-backlog.md) -- идеи оптимизации (A-NNN параметры benchmark, B-NNN параметры llama-server)
- [Terminal-Bench home](https://www.terminal-bench.com) -- официальный сайт + leaderboard
