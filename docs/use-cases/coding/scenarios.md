# Сценарии AI-кодинга

Практические примеры использования локального AI для задач разработки.

## Автодополнение (FIM)

**Инструменты**: Continue.dev, llama.vscode
**Модель**: Qwen2.5-Coder-1.5B (FIM, порт 8081)
**Эндпоинт**: `/infill`

Модель предсказывает код в текущей позиции курсора на основе prefix (код выше) и suffix (код ниже).

### Пример

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

### Настройка

- Задержка 200-300ms (debounce) -- не отвлекает при быстром наборе
- Максимум 1024 токенов контекста -- баланс скорости и качества
- Температура 0.0-0.1 -- детерминированные предсказания

## Chat: генерация кода

**Инструменты**: Continue.dev (Ctrl+L), Cline
**Модель**: Qwen2.5-Coder-32B (порт 8080)

### Примеры запросов

```
Напиши Python-скрипт для мониторинга GPU через sysfs. Читать: gpu_busy_percent,
mem_info_vram_used, temp1_input. Вывод в формате: "GPU: X% VRAM: Y MiB Temp: ZC".
Обновление каждую секунду.
```

```
Напиши FastAPI эндпоинт для загрузки файлов. Максимум 100 MiB, только .pdf и .docx.
Сохранение в /uploads/ с uuid-именем. Возврат JSON с id и размером.
```

```
Перепиши эту функцию с использованием asyncio. Сохрани интерфейс.
```

## Chat: объяснение кода

Выделить код в IDE -> Ctrl+Shift+L (добавить в контекст) -> задать вопрос.

### Примеры запросов

```
Объясни что делает этот код. Какие edge cases не обработаны?
```

```
Какая сложность этого алгоритма? Можно ли оптимизировать?
```

```
В чем разница между этим подходом и использованием dataclass?
```

## Рефакторинг

**Инструменты**: Aider (терминал), Cline/Roo Code (IDE)
**Модель**: Qwen2.5-Coder-32B

### Aider: рефакторинг через терминал

```bash
aider --model openai/qwen2.5-coder-32b --openai-api-base http://<SERVER_IP>:8080/v1 --openai-api-key x

> /add src/database.py src/models.py src/routes.py

> Замени все raw SQL-запросы на SQLAlchemy ORM. Сохрани текущее поведение.
```

### Cline: рефакторинг через IDE

В Cline (Plan mode):

```
Разбей файл src/utils.py на отдельные модули:
- src/utils/string_helpers.py
- src/utils/file_helpers.py
- src/utils/date_helpers.py
Обнови все import-ы в проекте.
```

## Code review

**Инструменты**: Roo Code (Security Reviewer mode), Aider (/review)

### Aider

```bash
> /review src/auth.py

# Aider проанализирует код и укажет на:
# - потенциальные уязвимости
# - нарушения best practices
# - предложения по улучшению
```

### Roo Code

Переключиться в режим "Security Reviewer" -> выделить код -> запросить review.

### Промпт для ручного review через chat

```
Проведи code review этого файла. Обрати внимание на:
1. SQL-инъекции и XSS
2. Обработку ошибок
3. Race conditions
4. Утечки ресурсов (файлы, соединения)
5. Несоответствие типов
```

## Генерация тестов

**Инструменты**: Aider, Cline, Roo Code (Test Writer mode)
**Модель**: Qwen2.5-Coder-32B

### Aider

```bash
> /add src/calculator.py

> Напиши unit-тесты (pytest) для calculator.py. Покрой: нормальные случаи,
> граничные значения, деление на ноль, некорректные типы.
```

### Промпт для генерации тестов

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

## Документирование

**Инструменты**: Aider, Continue.dev (edit mode)

### Aider: docstrings

```bash
> /add src/api.py

> Добавь Google-style docstrings ко всем публичным функциям и классам.
> Включи описание параметров, возвращаемого значения и примеры использования.
```

### Continue.dev: inline-редактирование

Выделить функцию -> Ctrl+I:

```
Добавь docstring с описанием параметров и return type.
```

## Debugging

**Инструменты**: Continue.dev (chat), Cline
**Модель**: Qwen2.5-Coder-32B

### Анализ трейсбека

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

### Поиск бага

```
Функция calculate_total() возвращает неправильный результат для
входных данных [1.1, 2.2, 3.3]. Ожидаемый результат 6.6,
фактический 6.600000000000001. Как исправить?
```

## Общие рекомендации

1. **Начинать с малого** -- одна задача за раз, не "перепиши весь проект"
2. **Передавать контекст** -- добавлять релевантные файлы, не весь проект
3. **Проверять результат** -- AI может генерировать синтаксически правильный, но логически неверный код
4. **Итерировать** -- если результат не устраивает, уточнить запрос
5. **Температура 0.0-0.3** -- для кода детерминированность важнее креативности
6. **Git** -- коммитить перед рефакторингом через AI (Aider делает это автоматически)

## Связанные статьи

- [AI-агенты](agents.md)
- [Промпт-инжиниринг](prompts.md)
- [IDE-интеграция](ide-integration.md)
- [Модели для кодинга](models.md)
