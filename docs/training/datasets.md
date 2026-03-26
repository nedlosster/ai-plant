# Подготовка данных для fine-tuning

## Форматы датасетов

### Alpaca (instruction-following, single-turn)

Формат для задач с четкой инструкцией: классификация, суммаризация, перевод, генерация кода.

```json
{"instruction": "Переведи на английский", "input": "Привет мир", "output": "Hello world"}
{"instruction": "Суммаризируй текст", "input": "Длинный текст...", "output": "Краткое содержание..."}
{"instruction": "Напиши функцию сортировки", "input": "", "output": "def sort(arr): ..."}
```

Поле `input` опционально. Если пусто -- задача определяется только `instruction`.

### ShareGPT (multi-turn, conversational)

Формат для многоходовых диалогов. Роли: `human`, `gpt`.

```json
{
  "conversations": [
    {"from": "human", "value": "Что такое LoRA?"},
    {"from": "gpt", "value": "LoRA (Low-Rank Adaptation) -- метод fine-tuning..."},
    {"from": "human", "value": "А чем QLoRA отличается?"},
    {"from": "gpt", "value": "QLoRA добавляет квантизацию базовой модели..."}
  ]
}
```

### ChatML / OpenAI (role-based)

Стандарт de facto для большинства современных моделей. Роли: `system`, `user`, `assistant`.

```json
{
  "messages": [
    {"role": "system", "content": "Ты -- опытный Python-разработчик."},
    {"role": "user", "content": "Напиши функцию для парсинга JSON."},
    {"role": "assistant", "content": "```python\nimport json\n\ndef parse_json(data: str) -> dict:\n    return json.loads(data)\n```"}
  ]
}
```

Модели Qwen, Llama 3, Gemma используют ChatML или его вариации.

### DPO (preference pairs)

Для alignment-задач. Пары (chosen, rejected) для одного промпта.

```json
{
  "prompt": "Объясни квантовую физику простыми словами.",
  "chosen": "Квантовая физика изучает поведение частиц на субатомном уровне...",
  "rejected": "Ну, это когда маленькие штуки делают странные вещи, типа того..."
}
```

### JSONL

Каждая строка файла -- отдельный JSON-объект. Предпочтительный формат для больших датасетов.

```
data.jsonl:
{"messages": [{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]}
{"messages": [{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]}
```

## Объем данных

| Задача | Минимум | Оптимум | Примечание |
|--------|---------|---------|------------|
| Instruction tuning | 500-1,000 | 5,000-50,000 | Качество важнее количества |
| Domain adaptation | 1,000-5,000 | 10,000-100,000 | Специализированные данные домена |
| Style transfer | 100-500 | 1,000-5,000 | Малый датасет + LoRA |
| DPO alignment | 1,000+ пар | 5,000-20,000 пар | Пары (chosen, rejected) |
| Code fine-tuning | 1,000-10,000 | 50,000+ | Пары (задача, решение) |

Правило: лучше 1,000 качественных примеров, чем 100,000 шумных. Фильтрация и чистка данных критичны.

## Создание датасета

### Из существующих данных

```python
from datasets import Dataset
import json

# Загрузка JSONL
data = []
with open("data.jsonl") as f:
    for line in f:
        data.append(json.loads(line))

dataset = Dataset.from_list(data)
print(dataset)
print(dataset[0])
```

### Из HuggingFace Hub

```python
from datasets import load_dataset

# Готовые датасеты
dataset = load_dataset("tatsu-lab/alpaca")                    # Alpaca-формат
dataset = load_dataset("Open-Orca/OpenOrca")                   # Instruction following
dataset = load_dataset("mlabonne/orpo-dpo-mix-40k")            # DPO-пары
dataset = load_dataset("sahil2801/CodeAlpaca-20k")             # Код
```

### Конвертация форматов

```python
# Alpaca -> ChatML
def alpaca_to_chatml(example):
    messages = []
    if example.get("input"):
        user_msg = f"{example['instruction']}\n\n{example['input']}"
    else:
        user_msg = example["instruction"]
    messages.append({"role": "user", "content": user_msg})
    messages.append({"role": "assistant", "content": example["output"]})
    return {"messages": messages}

dataset = dataset.map(alpaca_to_chatml)
```

### Фильтрация и чистка

```python
# Удаление коротких примеров
dataset = dataset.filter(lambda x: len(x["output"]) > 50)

# Удаление дубликатов
dataset = dataset.unique("instruction")

# Разделение на train/test
split = dataset.train_test_split(test_size=0.1)
train_dataset = split["train"]
eval_dataset = split["test"]
```

## Шаблоны промптов (chat templates)

Каждая модель имеет свой формат. Библиотека `transformers` автоматически применяет шаблон через `tokenizer.apply_chat_template()`.

```python
from transformers import AutoTokenizer

tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-7B-Instruct")

messages = [
    {"role": "system", "content": "Ты ассистент."},
    {"role": "user", "content": "Привет"},
]

# Автоматическое форматирование
text = tokenizer.apply_chat_template(messages, tokenize=False)
print(text)
```

При fine-tuning через Unsloth, Axolotl или LLaMA-Factory шаблоны применяются автоматически.

## Инструменты подготовки

| Инструмент | Назначение |
|-----------|-----------|
| HuggingFace Datasets | Загрузка, фильтрация, маппинг, сохранение |
| pandas | Обработка табличных данных, конвертация CSV/Excel -> JSONL |
| Argilla | Разметка данных с UI (self-hosted) |
| Label Studio | Разметка данных (альтернатива Argilla) |

## Структура проекта для training

```
training/
  datasets/
    my-dataset/
      train.jsonl
      eval.jsonl
  configs/
    lora-7b.yaml        # Конфигурация Axolotl
  outputs/
    my-model-lora/      # Результат training (адаптер)
      adapter_config.json
      adapter_model.safetensors
```

## Связанные статьи

- [Fine-tuning LLM](llm-finetuning.md)
- [Обзор методов](methods.md)
- [RLHF и alignment](alignment.md)
