# Function calling и tool use

## Содержание

- [Что такое function calling](#что-такое-function-calling)
- [Зачем нужно](#зачем-нужно)
- [Как работает: полный цикл](#как-работает-полный-цикл)
- [Structured output и JSON mode](#structured-output-и-json-mode)
- [Grammar-based sampling в llama-server](#grammar-based-sampling-в-llama-server)
- [Пример: weather tool](#пример-weather-tool)
- [Описание функций в промпте](#описание-функций-в-промпте)
- [Модели с поддержкой function calling](#модели-с-поддержкой-function-calling)
- [Реализация: Python-обертка](#реализация-python-обертка)
- [Множественные инструменты](#множественные-инструменты)
- [Параллельные вызовы](#параллельные-вызовы)
- [Обработка ошибок](#обработка-ошибок)
- [Связь с AI-агентами](#связь-с-ai-агентами)
- [Ограничения и подводные камни](#ограничения-и-подводные-камни)

---

## Что такое function calling

Function calling (tool use) -- способность LLM решать, какую функцию вызвать
и с какими аргументами, для выполнения задачи, которую модель не может
выполнить самостоятельно.

```
Модель НЕ МОЖЕТ:
  - Узнать текущую погоду
  - Выполнить вычисление 1847 * 293.5
  - Сделать HTTP-запрос
  - Прочитать файл с диска
  - Выполнить SQL-запрос

Модель МОЖЕТ:
  - Решить, что нужно узнать погоду
  - Сгенерировать вызов: get_weather(city="Moscow")
  - Получить результат и сформулировать ответ
```

Function calling -- это мост между генерацией текста и выполнением действий.

### Аналогия

```
Человек за столом:
  "Позвони в ресторан и закажи столик на 19:00 на двоих"
  |
  v
  Берет телефон (инструмент)
  Набирает номер (аргументы)
  Получает подтверждение (результат)
  Сообщает: "Столик забронирован" (ответ)

LLM с function calling:
  "Какая погода в Москве?"
  |
  v
  Выбирает: get_weather (инструмент)
  Генерирует: {"city": "Moscow"} (аргументы)
  Получает: {"temp": 12, "wind": 5} (результат)
  Отвечает: "В Москве 12 градусов, ветер 5 м/с" (ответ)
```


## Зачем нужно

### Расширение возможностей LLM

```
Без function calling:
  LLM = генератор текста
  Ограничен знаниями из обучения
  Не может взаимодействовать с внешним миром

С function calling:
  LLM = оркестратор, управляющий инструментами
  Доступ к актуальным данным
  Выполнение реальных действий
```

### Типичные инструменты

```
Категория      | Инструменты
---------------|------------------------------------------
Информация     | Погода, курсы валют, новости, поиск
Вычисления     | Калькулятор, интерпретатор Python
Данные         | SQL-запросы, API-вызовы, чтение файлов
Действия       | Отправка email, создание тикета, деплой
Интеграции     | Slack, Jira, GitHub, Telegram
Файловая система| Чтение, запись, поиск файлов
```


## Как работает: полный цикл

### Диаграмма

```
+----------+       +-----------+       +---------+       +----------+
|          |  (1)  |           |  (2)  |         |  (3)  |          |
| Пользователь |--->| LLM       |------>| Runtime |------>| Внешний  |
|          |       |           |       |         |       | сервис   |
+----------+       +-----------+       +---------+       +----------+
                        ^                   |
                        |        (4)        |
                        +-------------------+
                        |
                   (5)  v
                   +-----------+
                   |           |
                   | LLM       |------> Ответ пользователю (6)
                   |           |
                   +-----------+

Шаги:
(1) Пользователь задает вопрос
(2) LLM генерирует JSON с вызовом функции
(3) Runtime выполняет функцию
(4) Результат возвращается LLM
(5) LLM генерирует финальный ответ
(6) Ответ отправляется пользователю
```

### Пошаговый пример

```
Шаг 1: Пользователь
  "Сколько будет 1847 * 293.5?"

Шаг 2: LLM анализирует запрос
  Мысль: "Нужно вычислить. У меня есть инструмент calculator."
  Генерирует:
  {
    "function": "calculator",
    "arguments": {
      "expression": "1847 * 293.5"
    }
  }

Шаг 3: Runtime (ваш код)
  Парсит JSON
  Вызывает: eval("1847 * 293.5")
  Результат: 542094.5

Шаг 4: Результат вставляется в контекст LLM
  "Результат вычисления: 542094.5"

Шаг 5: LLM формулирует ответ
  "1847 * 293.5 = 542 094.5"

Шаг 6: Ответ пользователю
```

### Формат сообщений

```
messages = [
    {                                          # Системный промпт с описанием инструментов
        "role": "system",
        "content": "Ты -- ассистент. Доступные функции: ..."
    },
    {                                          # Вопрос пользователя
        "role": "user",
        "content": "Какая погода в Москве?"
    },
    {                                          # LLM вызывает функцию
        "role": "assistant",
        "content": null,
        "tool_calls": [{
            "function": {"name": "get_weather", "arguments": "{\"city\": \"Moscow\"}"}
        }]
    },
    {                                          # Результат функции
        "role": "tool",
        "content": "{\"temp\": 12, \"conditions\": \"rain\"}"
    },
    {                                          # Финальный ответ LLM
        "role": "assistant",
        "content": "В Москве 12 градусов, идет дождь."
    }
]
```


## Structured output и JSON mode

### Проблема

LLM генерирует текст. Для function calling нужен строгий JSON. Без
специальных мер модель может сгенерировать:

```
Невалидный JSON:
  {function: "get_weather", city: Moscow}     # Нет кавычек
  {"function": "get_weather", ...             # Незакрытая скобка
  Я вызову функцию get_weather для Москвы.   # Вообще не JSON
```

### JSON mode

Ограничение вывода модели валидным JSON. В llama-server:

```python
response = requests.post(
    "http://localhost:8080/v1/chat/completions",
    json={
        "messages": messages,
        "response_format": {"type": "json_object"},
        "temperature": 0.1
    }
)
# Гарантированно валидный JSON (но структура не гарантирована)
```

### JSON Schema

Более строгое ограничение -- JSON по заданной схеме:

```python
response = requests.post(
    "http://localhost:8080/v1/chat/completions",
    json={
        "messages": messages,
        "response_format": {
            "type": "json_schema",
            "json_schema": {
                "name": "function_call",
                "schema": {
                    "type": "object",
                    "properties": {
                        "function": {
                            "type": "string",
                            "enum": ["get_weather", "calculator", "search"]
                        },
                        "arguments": {
                            "type": "object"
                        }
                    },
                    "required": ["function", "arguments"]
                }
            }
        }
    }
)
# Гарантированно: {"function": "...", "arguments": {...}}
```


## Grammar-based sampling в llama-server

### GBNF-грамматики

llama-server поддерживает GBNF (GGML BNF) -- формат описания грамматик
для ограничения вывода. Модель физически не может сгенерировать текст,
не соответствующий грамматике.

### Пример GBNF для function calling

```
# Файл: function-call.gbnf
# Грамматика для вызова функций

root   ::= "{" ws "\"function\"" ws ":" ws function-name ws "," ws "\"arguments\"" ws ":" ws arguments ws "}"

function-name ::= "\"get_weather\"" | "\"calculator\"" | "\"search\""

arguments ::= "{" ws (argument ("," ws argument)*)? ws "}"

argument ::= "\"" [a-z_]+ "\"" ws ":" ws value

value ::= string | number | "true" | "false" | "null"

string ::= "\"" [^"\\]* "\""

number ::= "-"? [0-9]+ ("." [0-9]+)?

ws ::= [ \t\n]*
```

### Использование

```bash
# При запуске сервера
llama-server \
    --model ./models/qwen2.5-32b-q4_k_m.gguf \
    --grammar-file function-call.gbnf \
    --host 0.0.0.0 \
    --port 8080
```

Или через API (для отдельного запроса):

```python
response = requests.post(
    "http://localhost:8080/completion",
    json={
        "prompt": prompt,
        "grammar": open("function-call.gbnf").read(),
        "temperature": 0.1,
        "n_predict": 256
    }
)
```

### Преимущества grammar-based sampling

```
Метод              | Гарантия формата | Скорость | Совместимость
-------------------|------------------|----------|-------------
Промпт "ответь JSON"| Нет            | Нормальная| Любая модель
JSON mode          | JSON валиден     | -5-10%   | llama-server
JSON Schema        | Структура верна  | -10-15%  | llama-server
GBNF Grammar       | Полная гарантия  | -5-15%   | llama-server
```


## Пример: weather tool

Полный пример с инструментом для получения погоды.

### Описание инструмента

```python
# Описание инструмента для системного промпта
WEATHER_TOOL = {
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Получение текущей погоды для указанного города",
        "parameters": {
            "type": "object",
            "properties": {
                "city": {
                    "type": "string",
                    "description": "Название города (например, 'Moscow', 'London')"
                },
                "units": {
                    "type": "string",
                    "enum": ["celsius", "fahrenheit"],
                    "description": "Единицы измерения температуры"
                }
            },
            "required": ["city"]
        }
    }
}
```

### Реализация функции

```python
import requests


def get_weather(city: str, units: str = "celsius") -> dict:
    """
    Получение погоды через Open-Meteo API (бесплатный, без ключа).

    Для production заменить на OpenWeatherMap или аналог.
    """
    # Геокодинг: город -> координаты
    geo_response = requests.get(
        "https://geocoding-api.open-meteo.com/v1/search",
        params={"name": city, "count": 1}
    )
    geo_data = geo_response.json()

    if not geo_data.get("results"):
        return {"error": f"Город '{city}' не найден"}

    lat = geo_data["results"][0]["latitude"]
    lon = geo_data["results"][0]["longitude"]

    # Погода по координатам
    unit_param = "celsius" if units == "celsius" else "fahrenheit"
    weather_response = requests.get(
        "https://api.open-meteo.com/v1/forecast",
        params={
            "latitude": lat,
            "longitude": lon,
            "current": "temperature_2m,wind_speed_10m,relative_humidity_2m",
            "temperature_unit": unit_param
        }
    )
    weather = weather_response.json()["current"]

    return {
        "city": city,
        "temperature": weather["temperature_2m"],
        "wind_speed": weather["wind_speed_10m"],
        "humidity": weather["relative_humidity_2m"],
        "units": units
    }
```

### Полный цикл с llama-server

```python
import json
import requests


LLM_URL = "http://localhost:8080"

# Реестр доступных функций
TOOLS = {
    "get_weather": get_weather,
}

# Системный промпт с описанием инструментов
SYSTEM_PROMPT = """Ты -- ассистент с доступом к инструментам.

Доступные инструменты:

get_weather(city: str, units: str = "celsius") -> dict
  Получение текущей погоды для города.
  Аргументы:
    city -- название города (обязательный)
    units -- "celsius" или "fahrenheit" (по умолчанию "celsius")

Когда нужно вызвать инструмент, ответь ТОЛЬКО JSON:
{"function": "<имя>", "arguments": {<аргументы>}}

Когда инструмент не нужен -- отвечай обычным текстом.
Результат инструмента будет передан тебе для формулирования ответа."""


def call_llm(messages: list[dict]) -> str:
    """Вызов LLM и возврат текста ответа."""
    response = requests.post(
        f"{LLM_URL}/v1/chat/completions",
        json={
            "messages": messages,
            "temperature": 0.1,
            "max_tokens": 512
        }
    )
    return response.json()["choices"][0]["message"]["content"]


def is_tool_call(text: str) -> dict | None:
    """Проверка, является ли ответ вызовом инструмента."""
    text = text.strip()
    if text.startswith("{") and "function" in text:
        try:
            data = json.loads(text)
            if "function" in data and "arguments" in data:
                return data
        except json.JSONDecodeError:
            pass
    return None


def chat_with_tools(question: str) -> str:
    """Полный цикл: вопрос -> (возможный вызов инструмента) -> ответ."""
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": question}
    ]

    # Первый вызов LLM
    response_text = call_llm(messages)

    # Проверяем, нужен ли вызов инструмента
    tool_call = is_tool_call(response_text)

    if tool_call is None:
        # Ответ без инструмента
        return response_text

    # Выполняем инструмент
    func_name = tool_call["function"]
    func_args = tool_call["arguments"]

    if func_name not in TOOLS:
        return f"Неизвестный инструмент: {func_name}"

    result = TOOLS[func_name](**func_args)
    result_json = json.dumps(result, ensure_ascii=False)

    # Второй вызов LLM с результатом инструмента
    messages.append({"role": "assistant", "content": response_text})
    messages.append({"role": "user", "content": f"Результат {func_name}: {result_json}"})

    final_response = call_llm(messages)
    return final_response


# Использование
print(chat_with_tools("Какая погода в Москве?"))
# "В Москве 12 градусов, ветер 5 м/с, влажность 85%."

print(chat_with_tools("Привет!"))
# "Привет! Чем могу помочь?"
```


## Описание функций в промпте

### Формат описания

Для локальных моделей описание инструментов в системном промпте должно быть
максимально четким и структурированным.

### Вариант 1: текстовое описание

```
Доступные функции:

1. calculator(expression: str) -> float
   Вычисление математического выражения.
   Пример: calculator("2 + 2") -> 4.0

2. search(query: str, max_results: int = 5) -> list[dict]
   Поиск в базе знаний.
   Пример: search("python async") -> [{"title": "...", "url": "..."}]

3. run_sql(query: str) -> list[dict]
   Выполнение SQL-запроса (только SELECT).
   Таблицы: users(id, name, email), orders(id, user_id, amount, created_at)
   Пример: run_sql("SELECT name FROM users LIMIT 5") -> [{"name": "Alice"}, ...]
```

### Вариант 2: JSON Schema (OpenAI-совместимый)

```python
tools = [
    {
        "type": "function",
        "function": {
            "name": "calculator",
            "description": "Вычисление математического выражения",
            "parameters": {
                "type": "object",
                "properties": {
                    "expression": {
                        "type": "string",
                        "description": "Математическое выражение (например, '2 + 2')"
                    }
                },
                "required": ["expression"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "search",
            "description": "Поиск в базе знаний",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Поисковый запрос"
                    },
                    "max_results": {
                        "type": "integer",
                        "description": "Макс. количество результатов",
                        "default": 5
                    }
                },
                "required": ["query"]
            }
        }
    }
]
```

### Рекомендации для локальных моделей

```
1. Не более 5-7 инструментов одновременно
   Модель 32B надежно работает с 3-5 инструментами.
   При 10+ начинает путать аргументы.

2. Уникальные имена функций
   ПЛОХО: get_data, get_info, get_result
   ЛУЧШЕ: get_weather, search_docs, run_query

3. Примеры вызовов в описании
   Один пример вызова + ответа для каждой функции.

4. Явный формат вывода
   "Ответь ТОЛЬКО JSON: {\"function\": \"...\", \"arguments\": {...}}"
   Без этого модель может "обернуть" JSON в текст.

5. Описание, когда НЕ вызывать
   "Если вопрос не требует инструментов -- отвечай текстом."
```


## Модели с поддержкой function calling

### Нативная поддержка

Некоторые модели обучены на function calling и имеют специальные токены
для tool_calls в chat template:

```
Модель             | Формат tool_calls     | Качество FC
-------------------|-----------------------|------------
Qwen 2.5 (7B-72B) | <tool_call>...</tool_call> | Отличное
Llama 3.1 (8B-70B) | <|python_tag|>...     | Хорошее
Mistral (7B-22B)   | [TOOL_CALLS]...       | Хорошее
Hermes 2 Pro       | <tool_call>...</tool_call> | Хорошее
Functionary        | Специализированный    | Отличное
```

### Qwen 2.5 -- рекомендуемый выбор

Qwen 2.5 имеет лучшую поддержку function calling среди открытых моделей:

```
Qwen 2.5 chat template для tool_calls:

<|im_start|>system
You are a helpful assistant with access to the following tools:
[{"type": "function", "function": {"name": "get_weather", ...}}]
<|im_end|>
<|im_start|>user
Какая погода в Москве?
<|im_end|>
<|im_start|>assistant
<tool_call>
{"name": "get_weather", "arguments": {"city": "Moscow"}}
</tool_call>
<|im_end|>
<|im_start|>tool
{"temp": 12, "conditions": "rain"}
<|im_end|>
<|im_start|>assistant
В Москве 12 градусов, идет дождь.
<|im_end|>
```

### Использование нативного function calling с llama-server

```python
# llama-server автоматически обрабатывает tool_calls для совместимых моделей
response = requests.post(
    "http://localhost:8080/v1/chat/completions",
    json={
        "messages": [
            {"role": "system", "content": "Ты -- ассистент."},
            {"role": "user", "content": "Какая погода в Москве?"}
        ],
        "tools": [
            {
                "type": "function",
                "function": {
                    "name": "get_weather",
                    "description": "Получение погоды",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "city": {"type": "string"}
                        },
                        "required": ["city"]
                    }
                }
            }
        ],
        "tool_choice": "auto"  # "auto", "none", или {"type": "function", "function": {"name": "..."}}
    }
)

result = response.json()
choice = result["choices"][0]

if choice["finish_reason"] == "tool_calls":
    # Модель вызвала инструмент
    tool_call = choice["message"]["tool_calls"][0]
    func_name = tool_call["function"]["name"]
    func_args = json.loads(tool_call["function"]["arguments"])
    print(f"Вызов: {func_name}({func_args})")
else:
    # Обычный ответ
    print(choice["message"]["content"])
```


## Реализация: Python-обертка

Универсальная обертка для function calling с llama-server.

```python
"""
Обертка для function calling с llama-server.

Поддерживает:
- Регистрацию инструментов через декоратор
- Автоматический цикл вызовов
- Обработку ошибок
"""
import json
import inspect
import requests
from typing import Callable, Any
from dataclasses import dataclass, field


@dataclass
class Tool:
    """Описание инструмента."""
    name: str
    description: str
    parameters: dict
    function: Callable


class ToolRuntime:
    """Runtime для управления инструментами и взаимодействия с LLM."""

    def __init__(
        self,
        llm_url: str = "http://localhost:8080",
        system_prompt: str = "",
        max_tool_calls: int = 5
    ):
        self.llm_url = llm_url
        self.system_prompt = system_prompt
        self.max_tool_calls = max_tool_calls
        self.tools: dict[str, Tool] = {}

    def register(self, description: str = "") -> Callable:
        """Декоратор для регистрации функции как инструмента."""
        def decorator(func: Callable) -> Callable:
            # Автоматическое извлечение параметров из сигнатуры
            sig = inspect.signature(func)
            params = {
                "type": "object",
                "properties": {},
                "required": []
            }
            for param_name, param in sig.parameters.items():
                param_type = "string"  # По умолчанию
                if param.annotation == int:
                    param_type = "integer"
                elif param.annotation == float:
                    param_type = "number"
                elif param.annotation == bool:
                    param_type = "boolean"

                params["properties"][param_name] = {"type": param_type}
                if param.default == inspect.Parameter.empty:
                    params["required"].append(param_name)

            self.tools[func.__name__] = Tool(
                name=func.__name__,
                description=description or func.__doc__ or "",
                parameters=params,
                function=func
            )
            return func
        return decorator

    def _build_system_prompt(self) -> str:
        """Формирование системного промпта с описанием инструментов."""
        tools_desc = []
        for tool in self.tools.values():
            args = ", ".join(
                f"{name}: {prop['type']}"
                for name, prop in tool.parameters["properties"].items()
            )
            tools_desc.append(f"- {tool.name}({args}): {tool.description}")

        tools_text = "\n".join(tools_desc)

        return f"""{self.system_prompt}

Доступные инструменты:
{tools_text}

Для вызова инструмента ответь ТОЛЬКО JSON:
{{"function": "<имя>", "arguments": {{<аргументы>}}}}

Если инструмент не нужен -- отвечай обычным текстом."""

    def _call_llm(self, messages: list[dict]) -> str:
        """Вызов LLM."""
        response = requests.post(
            f"{self.llm_url}/v1/chat/completions",
            json={
                "messages": messages,
                "temperature": 0.1,
                "max_tokens": 1024
            }
        )
        return response.json()["choices"][0]["message"]["content"]

    def _parse_tool_call(self, text: str) -> dict | None:
        """Извлечение вызова инструмента из текста."""
        text = text.strip()
        # Поиск JSON в тексте
        start = text.find("{")
        end = text.rfind("}") + 1
        if start >= 0 and end > start:
            try:
                data = json.loads(text[start:end])
                if "function" in data and "arguments" in data:
                    return data
            except json.JSONDecodeError:
                pass
        return None

    def _execute_tool(self, tool_call: dict) -> str:
        """Выполнение инструмента."""
        func_name = tool_call["function"]
        func_args = tool_call["arguments"]

        if func_name not in self.tools:
            return json.dumps({"error": f"Инструмент '{func_name}' не найден"})

        try:
            result = self.tools[func_name].function(**func_args)
            return json.dumps(result, ensure_ascii=False, default=str)
        except Exception as e:
            return json.dumps({"error": str(e)})

    def run(self, question: str) -> str:
        """Полный цикл: вопрос -> (вызовы инструментов) -> ответ."""
        messages = [
            {"role": "system", "content": self._build_system_prompt()},
            {"role": "user", "content": question}
        ]

        for _ in range(self.max_tool_calls):
            response_text = self._call_llm(messages)
            tool_call = self._parse_tool_call(response_text)

            if tool_call is None:
                return response_text

            # Выполняем инструмент
            result = self._execute_tool(tool_call)
            messages.append({"role": "assistant", "content": response_text})
            messages.append({
                "role": "user",
                "content": f"Результат {tool_call['function']}: {result}"
            })

        return "Превышено максимальное количество вызовов инструментов"


# --- Пример использования ---

runtime = ToolRuntime(
    llm_url="http://localhost:8080",
    system_prompt="Ты -- ассистент. Отвечай по-русски."
)


@runtime.register(description="Вычисление математического выражения")
def calculator(expression: str) -> dict:
    """Безопасное вычисление."""
    # Разрешаем только безопасные операции
    allowed = set("0123456789+-*/().% ")
    if not all(c in allowed for c in expression):
        return {"error": "Недопустимые символы в выражении"}
    try:
        result = eval(expression)  # В production использовать ast.literal_eval или sympy
        return {"result": result}
    except Exception as e:
        return {"error": str(e)}


@runtime.register(description="Получение текущего времени")
def get_time() -> dict:
    """Возврат текущего времени."""
    from datetime import datetime
    now = datetime.now()
    return {"time": now.strftime("%H:%M:%S"), "date": now.strftime("%Y-%m-%d")}


# Запуск
print(runtime.run("Сколько будет 2^10 * 3?"))
print(runtime.run("Который час?"))
print(runtime.run("Расскажи о Python"))  # Без вызова инструмента
```


## Множественные инструменты

### Последовательные вызовы

Модель может вызвать несколько инструментов последовательно:

```
Пользователь: "Какая погода в Москве и Лондоне? Конвертируй разницу в фаренгейты."

Шаг 1: LLM -> get_weather(city="Moscow") -> 12 C
Шаг 2: LLM -> get_weather(city="London") -> 8 C
Шаг 3: LLM -> calculator("(12 - 8) * 9/5") -> 7.2 F
Шаг 4: LLM -> "В Москве 12 C, в Лондоне 8 C. Разница: 4 C (7.2 F)."
```

### Маршрутизация (tool selection)

При большом количестве инструментов модель может ошибиться в выборе.
Решение -- маршрутизация:

```python
def route_tools(question: str, all_tools: dict[str, Tool]) -> list[str]:
    """
    Предварительный выбор релевантных инструментов.

    Вместо передачи всех 20 инструментов -- отбираем 3-5 наиболее вероятных.
    """
    # Простая маршрутизация по ключевым словам
    routes = {
        "погода": ["get_weather"],
        "температура": ["get_weather"],
        "посчитай": ["calculator"],
        "сколько": ["calculator"],
        "найди": ["search", "search_docs"],
        "файл": ["read_file", "write_file"],
        "sql": ["run_sql"],
        "время": ["get_time"],
    }

    selected = set()
    question_lower = question.lower()
    for keyword, tools in routes.items():
        if keyword in question_lower:
            selected.update(tools)

    # Если ничего не выбрано -- даем все
    if not selected:
        return list(all_tools.keys())

    return list(selected)
```


## Параллельные вызовы

Некоторые модели поддерживают параллельные вызовы инструментов (одновременно
несколько вызовов в одном ответе):

```
Пользователь: "Покажи погоду в Москве, Лондоне и Токио"

Без параллельных вызовов (3 шага):
  Шаг 1: get_weather("Moscow")
  Шаг 2: get_weather("London")
  Шаг 3: get_weather("Tokyo")

С параллельными вызовами (1 шаг):
  [
    get_weather("Moscow"),
    get_weather("London"),
    get_weather("Tokyo")
  ]
```

```python
import concurrent.futures


def execute_parallel(tool_calls: list[dict], tools: dict) -> list[dict]:
    """Параллельное выполнение нескольких вызовов инструментов."""
    results = []

    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        futures = {}
        for call in tool_calls:
            func_name = call["function"]
            func_args = call["arguments"]
            if func_name in tools:
                future = executor.submit(tools[func_name].function, **func_args)
                futures[future] = call

        for future in concurrent.futures.as_completed(futures):
            call = futures[future]
            try:
                result = future.result()
                results.append({
                    "function": call["function"],
                    "result": result
                })
            except Exception as e:
                results.append({
                    "function": call["function"],
                    "error": str(e)
                })

    return results
```


## Обработка ошибок

### Типы ошибок

```
Ошибка                          | Причина                    | Решение
--------------------------------|----------------------------|---------------------------
Невалидный JSON                 | Модель не следует формату  | Grammar/JSON Schema
Неизвестная функция             | Модель выдумала инструмент | Проверка имени
Неверные аргументы              | Модель перепутала типы     | Валидация аргументов
Ошибка выполнения               | Внешний сервис упал        | Retry + fallback
Зацикливание                    | Модель вызывает одно и то же| Лимит вызовов
```

### Стратегия обработки

```python
def safe_execute(
    tool_call: dict,
    tools: dict,
    max_retries: int = 2
) -> str:
    """Безопасное выполнение инструмента с повторными попытками."""
    func_name = tool_call.get("function", "")
    func_args = tool_call.get("arguments", {})

    # 1. Проверка существования функции
    if func_name not in tools:
        return json.dumps({
            "error": f"Функция '{func_name}' не найдена",
            "available": list(tools.keys())
        })

    # 2. Валидация аргументов
    tool = tools[func_name]
    required = tool.parameters.get("required", [])
    for param in required:
        if param not in func_args:
            return json.dumps({
                "error": f"Отсутствует обязательный аргумент: {param}",
                "required": required
            })

    # 3. Выполнение с retry
    last_error = None
    for attempt in range(max_retries + 1):
        try:
            result = tool.function(**func_args)
            return json.dumps(result, ensure_ascii=False, default=str)
        except Exception as e:
            last_error = e
            if attempt < max_retries:
                continue

    return json.dumps({"error": f"Ошибка после {max_retries + 1} попыток: {last_error}"})
```


## Связь с AI-агентами

Function calling -- основа AI-агентов. Агент = LLM + набор инструментов +
цикл reasoning/acting.

### Примеры агентов

```
Агент           | Инструменты                    | Задача
----------------|--------------------------------|----------------------------
Aider           | read_file, write_file, shell   | Программирование
SWE-agent       | edit, search, test, git        | Исправление багов
AutoGPT         | search, browse, code, file     | Произвольные задачи
Data analyst    | sql, plot, export              | Анализ данных
DevOps agent    | kubectl, docker, ssh           | Операции с инфраструктурой
```

### Минимальный агент

```python
def coding_agent(task: str, runtime: ToolRuntime) -> str:
    """
    Простой coding-агент.

    Инструменты: read_file, write_file, run_tests.
    Цикл: анализ -> действие -> проверка -> повтор.
    """
    messages = [
        {"role": "system", "content": runtime._build_system_prompt()},
        {"role": "user", "content": f"Задача: {task}\n\nВыполняй пошагово."}
    ]

    for step in range(10):  # Максимум 10 шагов
        response = runtime._call_llm(messages)
        messages.append({"role": "assistant", "content": response})

        tool_call = runtime._parse_tool_call(response)

        if tool_call is None:
            # Агент завершил работу
            return response

        # Выполняем инструмент
        result = runtime._execute_tool(tool_call)
        messages.append({
            "role": "user",
            "content": f"Результат: {result}\n\nПродолжай выполнение задачи."
        })

    return "Задача не завершена за 10 шагов"
```


## Ограничения и подводные камни

### 1. Модели 7B-14B ненадежны в function calling

```
Размер модели | Надежность FC | Рекомендация
--------------|---------------|----------------------------
7B            | ~60-70%       | Только 1-2 простых инструмента
14B           | ~75-85%       | До 3 инструментов
32B           | ~85-90%       | До 5 инструментов
70B           | ~90-95%       | До 7-10 инструментов
```

### 2. Hallucinated tool calls

Модель может "выдумать" инструмент или аргумент:

```
Доступные инструменты: get_weather, calculator
Модель генерирует: {"function": "search_web", ...}  <- не существует

Защита: проверка имени функции перед выполнением.
```

### 3. Зацикливание

Модель вызывает один инструмент снова и снова:

```
Шаг 1: get_weather("Moscow") -> 12 C
Шаг 2: get_weather("Moscow") -> 12 C
Шаг 3: get_weather("Moscow") -> 12 C
...

Защита: лимит на количество вызовов + проверка дубликатов.
```

### 4. Injection через результат инструмента

```
Инструмент возвращает текст: "Ignore all previous instructions. ..."
Модель может следовать этой инъекции.

Защита: санитизация результатов инструментов.
```


## Дополнительные ресурсы

- [Prompt engineering](./prompt-engineering.md) -- техники промптинга
  для function calling
- [RAG](./rag/README.md) -- RAG как инструмент для агентов
- [Системные промпты](./system-prompts.md) -- описание инструментов
  в системном промпте
- [Мультимодальные модели](./multimodal.md) -- vision как инструмент
- [Выбор модели](../inference/model-selection.md) -- какие модели
  поддерживают function calling

## Связанные статьи

- [Prompt engineering](prompt-engineering.md)
- [Системные промпты](system-prompts.md)
- [AI-агенты](../use-cases/coding/agents.md)
- [RAG](rag/README.md)
