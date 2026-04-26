# Aider Polyglot benchmark: runbook

Описание Aider Polyglot, методология, пошаговый запуск smoke и full на платформе. Платформа: Strix Halo + llama-server (Vulkan).

Профиль раздела -- [README.md](README.md). Каталог результатов -- [results.md](../results.md).

## Что это

Aider Polyglot -- бенчмарк от команды [Aider](https://aider.chat) для оценки coding-моделей в **edit-loop сценарии**: модель получает задачу из Exercism, пишет/редактирует код, запускаются тесты, при падении модель видит ошибку и итерирует.

**Покрытие**: 225 задач из Exercism на 6 языках:
- Python (тесты pytest)
- JavaScript (тесты jest/mocha)
- Go (тесты go test)
- Rust (тесты cargo test)
- Java (тесты JUnit)
- C++ (тесты Catch2/google-test)

**Публичный leaderboard**: [aider.chat/docs/leaderboards/](https://aider.chat/docs/leaderboards/) -- сравнить с Claude Opus 4.7, GPT-5.3 Codex, Kimi K2.6, Gemini 3.1 Pro.

**Метрики**:
- **Pass rate (single-shot)**: % задач решённых с первого захода
- **Pass rate (with retry)**: % с двумя попытками (если первая упала -- модель видит ошибку)
- **Edit format adherence**: насколько правильно модель генерирует diff'ы (метрика качества instruction following)
- **Per-language breakdown**: показывает где модель сильна/слаба

## Методология

### Поток одной задачи

1. Aider читает test файлы (видит спецификацию через assertions)
2. Aider читает stub файла с TODO (что нужно реализовать)
3. Aider формирует prompt + system prompt + test context
4. Модель генерирует diff (или whole-file edit)
5. Aider применяет edit, запускает тесты в isolated process
6. Если тесты прошли -- pass; если упали -- модель видит вывод и пробует снова (до 2 итераций)

### Edit format

Aider поддерживает несколько форматов:
- **diff** (default для capable моделей) -- модель генерирует unified diff
- **whole** (fallback) -- модель пишет весь файл целиком

Качественные модели справляются с diff. Если модель часто фолбечит на whole -- это влияет на скорость и точность. Aider логирует "edit format warnings".

### Что НЕ оценивает

- Архитектурные решения (задачи -- single-file)
- Multi-file refactoring
- Long-context (задачи короткие, обычно <2K токенов)
- Tool use beyond file edit (запуск shell, web search и т.д. -- для этого Terminal-Bench)

### Сравнение с публичными цифрами

Публичные результаты Aider Polyglot обычно используют:
- Frontier модели через API (Opus 4.7, GPT-5.3, Gemini 3.1 Pro): 60-85%
- Open-source модели: Qwen3-Coder Next ~40%, Kimi K2.6 ~50%, Qwen 3.6-Plus ~55%

Local Q4_K_M обычно **на 3-7 п.п. ниже** API-результатов из-за квантизации. Это нормально.

## Подготовка

### Установка Docker image и polyglot-benchmark

В aider 0.86+ benchmark вынесен из CLI и требует toolchain для 6 языков (Python, JS, Go, Rust, Java, C++). Используется готовый Dockerfile из репо aider -- собирается образ со всеми компиляторами.

```bash
ssh -A -p 2277 nedlosster@79.164.89.150
cd ~/projects/ai-plant

# 1. Клонировать репо aider в ~/projects/aider/
git clone https://github.com/Aider-AI/aider.git ~/projects/aider

# 2. Клонировать polyglot-benchmark dataset
mkdir -p ~/projects/aider/tmp.benchmarks
cd ~/projects/aider/tmp.benchmarks
git clone https://github.com/Aider-AI/polyglot-benchmark

# 3. Собрать Docker image (~10-15 минут, размер ~7.3 GB)
cd ~/projects/aider
tmux new-session -d -s aider-build \
  'docker build -f benchmark/Dockerfile -t aider-polyglot-bench:latest . 2>&1 | tee /tmp/aider-docker-build.log'
# Ждать завершения: tmux attach -t aider-build (Ctrl+B D = detach)

# 4. Проверить image
docker images aider-polyglot-bench
docker run --rm aider-polyglot-bench:latest python3 -c 'import aider; print(aider.__version__)'

# 5. Проверить toolchain (опционально)
docker run --rm aider-polyglot-bench:latest bash -c '
  python3 --version; java --version | head -1; cargo --version
  go version; node --version; gcc --version | head -1'
```

Toolchain в image: Python 3.11, OpenJDK 21, Cargo (Rust), Go 1.21, Node 20, GCC 11.

### Запуск через Docker

`bench-aider.sh` автоматически использует docker run с правильными флагами:
- `--network host` -- доступ к llama-server на host:8085
- `--user $(id -u):$(id -g)` -- избегание git ownership safety conflict
- `-v ~/projects/aider:/aider` -- mount репо
- `-e AIDER_DOCKER=1` -- aider safety bypass (мы в реальном Docker)
- `-e HOME=/tmp` -- writable home для unprivileged user

### Запуск llama-server

Модель должна быть доступна через OpenAI-compat endpoint:

```bash
# Стартует Qwen3.6-35B-A3B на порту 8085 (daemon mode)
./scripts/inference/vulkan/preset/qwen3.6-35b.sh -d --port 8085

# Проверить что сервер отвечает
./scripts/inference/status.sh
curl http://localhost:8085/v1/models
```

### Конфигурация Aider

Aider настраивается через переменные окружения или флаги:

```bash
export OPENAI_API_BASE=http://localhost:8085/v1
export OPENAI_API_KEY=dummy  # llama-server не требует, но Aider требует переменную
```

## Smoke test runbook (50 задач, ~1.5 ч)

### Запуск

```bash
cd ~/projects/ai-plant
./scripts/inference/bench-aider.sh --smoke --model qwen3.6-35b --port 8085
```

Скрипт:
1. Проверяет что llama-server жив на порту 8085
2. Активирует venv aider-bench
3. Запускает Aider с `--polyglot --num-tests 50 --random-seed 42` (для воспроизводимости subset)
4. Логирует в `/tmp/bench-aider-qwen3.6-35b-<timestamp>.log`
5. Парсит результат, выводит сводку

### Что ожидать в выводе

```
Polyglot benchmark complete
Tasks: 50
Passed: 38 / 50 (76.0%)
By language:
  python: 9/10 (90%)
  javascript: 7/8 (87.5%)
  go: 6/8 (75%)
  rust: 5/8 (62.5%)
  java: 6/8 (75%)
  cpp: 5/8 (62.5%)
Edit format: 47/50 diff, 3/50 fallback to whole
Avg time per task: 95s
Total time: 1h 19m
```

### Sanity check vs leaderboard

Сверь свой smoke result с публичной цифрой ±5 п.п.:
- Если smoke 76% и публичная Aider Polyglot для Qwen3.6-35B-A3B 73% -- норма
- Если smoke 30%, а публичная 73% -- что-то не так с конфигурацией (edit format, prompt template, llama-server параметры)

Чек-лист если расхождение >10%:
- Проверь что используется `--jinja` в llama-server (иначе chat template ломается)
- Проверь что Q4_K_M а не Q3 / Q2 (агрессивная квантизация ухудшает edit format)
- Проверь edit format warnings -- если их >20%, модель плохо генерирует diff'ы

## Full benchmark runbook (225 задач, 6-12 ч)

### Запуск в tmux

```bash
ssh -A -p 2277 nedlosster@79.164.89.150
cd ~/projects/ai-plant

# Создать сессию tmux
tmux new-session -d -s aider-full \
  './scripts/inference/bench-aider.sh --full --model qwen3.6-35b --port 8085 \
   2>&1 | tee /tmp/aider-full-$(date +%Y%m%d-%H%M).log'

# Подключиться к сессии для просмотра прогресса
tmux attach -t aider-full

# Detach: Ctrl+B, затем D
```

### Мониторинг

```bash
# В другом терминале
./scripts/inference/monitor.sh  # GPU/CPU/память

# Прогресс бенчмарка
tail -f /tmp/aider-full-*.log
```

### Сохранение результатов

После завершения скрипт автоматически предлагает добавить запись в [`../results.md`](../results.md). Если согласен -- ответить `y`, скрипт сформирует запись и допишет в конец.

Шаблон записи (см. [results.md](../results.md)):

```markdown
## YYYY-MM-DD: Aider Polyglot full -- Qwen3.6-35B-A3B

**Среда**: Strix Halo, Vulkan b8717, Q4_K_M, llama-server `--parallel 4`
**Задач**: 225/225
**Время**: 8h 42m
**Pass rate**: 167/225 = 74.2% (single-shot)
**По языкам**:
- Python: 38/40 (95%)
- JavaScript: 32/35 (91%)
- Go: 27/35 (77%)
- Rust: 24/35 (68%)
- Java: 26/40 (65%)
- C++: 20/40 (50%)
**Edit format warnings**: 18 (whole-file fallback на 8% задач)
**Заметки**: ...
```

## Сравнение нескольких моделей

### Последовательный прогон

```bash
# Очередь моделей
for preset in qwen3.6-35b qwen-coder-next devstral qwen3-coder-30b; do
  # Стартовать сервер
  ./scripts/inference/vulkan/preset/${preset}.sh -d --port 8085

  # Подождать готовности
  sleep 30

  # Прогнать smoke
  ./scripts/inference/bench-aider.sh --smoke --model ${preset} --port 8085

  # Остановить сервер
  ./scripts/inference/stop-servers.sh
done
```

Время: 4 модели × 1.5 ч = 6 часов smoke runs.

### Параллельный prep (две модели одновременно если влезет VRAM)

Не рекомендуется -- llama-server на одной GPU плохо делит compute. Параллель только если разные backends (Vulkan + ROCm).

## Интерпретация результатов

### Per-language breakdown

Качественные паттерны:
- **Python > JS > Go > Java > C++ > Rust** -- типичный порядок для open моделей. Python в data mix больше всего.
- **Rust часто слабее** -- borrow checker, lifetime, generics требуют точности
- **C++ слабее** -- header/source split, template metaprogramming
- **Java слабее** -- многословный синтаксис, специфичный JVM
- Если модель имеет специфический baseline по Rust/C++ -- это сигнал что fine-tune был beyond Python

### Edit format warnings

- **<5%** -- отлично, модель уверенно генерирует diff'ы
- **5-15%** -- нормально, иногда фолбечит на whole для сложных edit'ов
- **>15%** -- проблемы. Модель плохо понимает diff format. Проверь chat template.

### Что значит "73% pass rate"

В контексте платформы:
- **70-80%** -- продуктивна для daily coding agent, можно полагаться на single-shot
- **60-70%** -- работает с человеческим review
- **<60%** -- слишком много мусора в выводе, неудобно для interactive use

## Troubleshooting

### llama-server timeout

**Симптом**: Aider зависает на задаче, потом ругается timeout.

**Причины**:
- Контекст переполнен (Aider добавляет history)
- Модель в long-tail генерации
- llama-server параллель забита

**Решение**:
- Снизить контекст в пресете (`-c 32768` вместо 128K)
- `--parallel 2` вместо 4 для стабильности

### Out of memory (OOM)

**Симптом**: llama-server падает на сложной задаче.

**Причины**: KV-cache раздулся при долгом контексте.

**Решение**:
- `-c 32768` (32K контекста хватит для exercism задач)
- Q4_K_S вместо Q4_K_M (агрессивнее квантизация)

### Long-context issues (>2K промпта)

**Симптом**: модель забывает test context, генерирует код не отвечающий тестам.

**Причины**: short-context bias модели.

**Решение**: для small models (1.5B, 3B-A) ожидаемо. Использовать модели от 24B+.

### Edit format fallback

**Симптом**: высокий % whole-file rewrites.

**Причины**:
- Chat template не соответствует ожиданиям модели
- `--jinja` отключён в llama-server
- Слишком агрессивная квантизация (Q3, Q2)

**Решение**:
- Включить `--jinja` в пресете
- Использовать Q4_K_M или выше

## Связанные статьи

- [README.md](README.md) -- индекс runbooks
- [terminal-bench.md](terminal-bench.md) -- альтернативная метрика (tool use)
- [results.md](../results.md) -- журнал результатов
- [runs/](../runs/README.md) -- полные статьи прогонов
- [swe-bench.md](../swe-bench.md) -- теория SWE-bench (для контекста публичных цифр)
- [coding/workflows.md](../../../coding/workflows.md) -- какие модели использовать для какой задачи
- [inference/optimization-backlog.md](../../../inference/optimization-backlog.md) -- идеи оптимизации (A-NNN параметры benchmark, B-NNN параметры llama-server)
- [Aider home](https://aider.chat) -- официальный сайт
- [Aider leaderboard](https://aider.chat/docs/leaderboards/) -- публичные результаты
