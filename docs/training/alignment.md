# RLHF и alignment

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), ROCm 7.x. Предварительно: [methods.md](methods.md), [llm-finetuning.md](llm-finetuning.md).

## Что такое alignment

Alignment -- приведение поведения модели в соответствие с ожиданиями пользователя. После SFT (supervised fine-tuning) модель генерирует ответы, но не всегда в нужном стиле или качестве. Alignment корректирует это.

Типичный пайплайн:
```
Pre-trained model -> SFT (instruction tuning) -> Alignment (DPO/GRPO)
```

## DPO (Direct Preference Optimization)

Прямая оптимизация по предпочтениям. Не требует reward model (в отличие от классического RLHF).

### Принцип

Модель обучается на парах (chosen, rejected): для одного промпта -- хороший и плохой ответ. Оптимизирует вероятность chosen относительно rejected.

### Подготовка данных

```json
{
  "prompt": "Объясни теорию относительности.",
  "chosen": "Теория относительности Эйнштейна описывает взаимосвязь пространства и времени. Специальная теория (1905) постулирует...",
  "rejected": "Ну типа все относительно, понимаешь? Эйнштейн там чё-то придумал про время и пространство..."
}
```

Источники DPO-данных:
- Ручная разметка (максимальное качество)
- Генерация парами моделей разного качества
- Существующие датасеты: `mlabonne/orpo-dpo-mix-40k`, `argilla/dpo-mix-7k`

### Training через TRL

```python
import os
os.environ["HSA_OVERRIDE_GFX_VERSION"] = "11.5.0"
os.environ["TORCH_COMPILE_DISABLE"] = "1"

from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import LoraConfig
from trl import DPOConfig, DPOTrainer
from datasets import load_dataset

# Модель (после SFT)
model_name = "Qwen/Qwen2.5-7B-Instruct"
model = AutoModelForCausalLM.from_pretrained(model_name, torch_dtype="bfloat16", device_map="auto")
tokenizer = AutoTokenizer.from_pretrained(model_name)
tokenizer.pad_token = tokenizer.eos_token

# LoRA
peft_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["q_proj", "v_proj", "k_proj", "o_proj"],
    lora_dropout=0.05,
    task_type="CAUSAL_LM",
)

# Данные
dataset = load_dataset("argilla/dpo-mix-7k", split="train[:1000]")

# DPO training
training_args = DPOConfig(
    output_dir="./output/dpo",
    per_device_train_batch_size=1,
    gradient_accumulation_steps=8,
    num_train_epochs=1,
    learning_rate=5e-5,
    bf16=True,
    logging_steps=10,
    max_length=1024,
    max_prompt_length=512,
)

trainer = DPOTrainer(
    model=model,
    args=training_args,
    train_dataset=dataset,
    processing_class=tokenizer,
    peft_config=peft_config,
)

trainer.train()
trainer.save_model("./output/dpo/adapter")
```

## GRPO (Group Relative Policy Optimization)

Вариант без отдельной reward model и без пар предпочтений. Модель генерирует группу ответов на один промпт, ранжирует их, обучается на лучших.

### Принцип

1. Для каждого промпта модель генерирует N ответов (группа)
2. Ответы ранжируются по reward (правильность, качество)
3. Модель обучается увеличивать вероятность лучших ответов группы

Особенно полезен для reasoning-задач (математика, логика, код).

### Training через TRL

```python
import os
os.environ["HSA_OVERRIDE_GFX_VERSION"] = "11.5.0"
os.environ["TORCH_COMPILE_DISABLE"] = "1"

from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import LoraConfig
from trl import GRPOConfig, GRPOTrainer
from datasets import load_dataset

model_name = "Qwen/Qwen2.5-7B-Instruct"
model = AutoModelForCausalLM.from_pretrained(model_name, torch_dtype="bfloat16", device_map="auto")
tokenizer = AutoTokenizer.from_pretrained(model_name)
tokenizer.pad_token = tokenizer.eos_token

peft_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["q_proj", "v_proj", "k_proj", "o_proj"],
    lora_dropout=0.05,
    task_type="CAUSAL_LM",
)

# Датасет с промптами (без ответов -- модель генерирует сама)
dataset = load_dataset("openai/gsm8k", "main", split="train[:500]")
dataset = dataset.rename_column("question", "prompt")

# Reward-функция (пример для математики)
def reward_fn(completions, prompts):
    # Проверка правильности ответа
    rewards = []
    for completion in completions:
        if "####" in completion:  # GSM8K формат ответа
            rewards.append(1.0)
        else:
            rewards.append(-1.0)
    return rewards

training_args = GRPOConfig(
    output_dir="./output/grpo",
    per_device_train_batch_size=1,
    gradient_accumulation_steps=4,
    num_train_epochs=1,
    learning_rate=1e-5,
    bf16=True,
    num_generations=4,  # Размер группы
)

trainer = GRPOTrainer(
    model=model,
    args=training_args,
    train_dataset=dataset,
    processing_class=tokenizer,
    peft_config=peft_config,
    reward_funcs=reward_fn,
)

trainer.train()
```

## ORPO (Odds Ratio Preference Optimization)

Объединяет SFT и alignment в один шаг. Не нужна отдельная фаза SFT.

```python
from trl import ORPOConfig, ORPOTrainer

training_args = ORPOConfig(
    output_dir="./output/orpo",
    per_device_train_batch_size=1,
    gradient_accumulation_steps=8,
    num_train_epochs=1,
    learning_rate=5e-5,
    bf16=True,
    beta=0.1,  # Вес preference loss
)
```

## Что выбрать

| Метод | Данные | Сложность | Применение |
|-------|--------|-----------|-----------|
| **DPO** | Пары (chosen, rejected) | низкая | Стиль, безопасность, качество ответов |
| **GRPO** | Только промпты + reward fn | средняя | Reasoning, математика, код |
| **ORPO** | Пары + instruction data | низкая | Когда нет отдельной SFT-модели |

Рекомендация для начала: **DPO** -- простой в реализации, существуют готовые датасеты, хороший результат.

## VRAM

Alignment требует примерно столько же VRAM, сколько SFT с LoRA. DPO загружает reference model (замороженную копию), но она shared через page tables unified memory.

| Модель | DPO + LoRA | GRPO + LoRA |
|--------|-----------|------------|
| 7B | ~20 GiB | ~18 GiB |
| 13B | ~35 GiB | ~30 GiB |
| 30B | ~75 GiB | ~65 GiB |

## Связанные статьи

- [Обзор методов](methods.md)
- [Fine-tuning LLM](llm-finetuning.md)
- [Подготовка данных](datasets.md)
