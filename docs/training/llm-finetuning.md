# Fine-tuning LLM

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти), ROCm 7.x. Предварительно: [environment.md](environment.md), [datasets.md](datasets.md).

## Выбор инструмента

| Инструмент | Интерфейс | Сложность | Поддержка AMD |
|-----------|-----------|-----------|---------------|
| **Unsloth** | Python API | низкая | да (специальные wheels) |
| **LLaMA-Factory** | Web UI + CLI | низкая | да (ROCm docs) |
| **Axolotl** | YAML config | средняя | да (community) |
| **transformers + PEFT** | Python API | средняя | да (backend-агностичен) |

Для начала рекомендуется **Unsloth** (минимальный код) или **LLaMA-Factory** (Web UI).

## Unsloth: LoRA fine-tuning

### Минимальный пример

```python
import os
os.environ["HSA_OVERRIDE_GFX_VERSION"] = "11.5.0"
os.environ["TORCH_COMPILE_DISABLE"] = "1"

from unsloth import FastLanguageModel
from trl import SFTTrainer
from transformers import TrainingArguments
from datasets import load_dataset

# Загрузка модели
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/Qwen2.5-7B-Instruct",
    max_seq_length=4096,
    load_in_4bit=False,  # 16-bit LoRA (4-bit нестабилен на AMD)
)

# Добавление LoRA-адаптеров
model = FastLanguageModel.get_peft_model(
    model,
    r=16,                          # ранг адаптера
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                     "gate_proj", "up_proj", "down_proj"],
    lora_alpha=32,
    lora_dropout=0.05,
    use_gradient_checkpointing="unsloth",
)

# Загрузка датасета
dataset = load_dataset("json", data_files="train.jsonl", split="train")

# Форматирование (Unsloth chat template)
def format_chat(example):
    text = tokenizer.apply_chat_template(
        example["messages"], tokenize=False, add_generation_prompt=False
    )
    return {"text": text}

dataset = dataset.map(format_chat)

# Training
trainer = SFTTrainer(
    model=model,
    train_dataset=dataset,
    dataset_text_field="text",
    max_seq_length=4096,
    args=TrainingArguments(
        output_dir="./output",
        per_device_train_batch_size=1,
        gradient_accumulation_steps=8,
        num_train_epochs=2,
        learning_rate=2e-4,
        fp16=True,
        logging_steps=10,
        save_steps=100,
        warmup_steps=10,
        optim="adamw_8bit",
    ),
)

trainer.train()

# Сохранение LoRA-адаптера
model.save_pretrained("./output/lora-adapter")
tokenizer.save_pretrained("./output/lora-adapter")
```

### Экспорт в GGUF

```python
# Merge LoRA + экспорт в GGUF для llama.cpp
model.save_pretrained_merged(
    "./output/merged",
    tokenizer,
    save_method="merged_16bit",
)

# Или сразу в GGUF
model.save_pretrained_gguf(
    "./output/gguf",
    tokenizer,
    quantization_method="q4_k_m",
)
```

## LLaMA-Factory: Web UI

### Установка

```bash
git clone https://github.com/hiyouga/LLaMA-Factory.git
cd LLaMA-Factory
pip install -e .
```

### Запуск Web UI

```bash
export HSA_OVERRIDE_GFX_VERSION=11.5.0
export TORCH_COMPILE_DISABLE=1
llamaboard
```

Открыть `http://localhost:7860`. Интерфейс позволяет:
- Выбрать модель из HuggingFace
- Загрузить датасет
- Настроить параметры (LoRA rank, lr, epochs)
- Запустить training
- Мониторинг loss в реальном времени

### CLI

```bash
export HSA_OVERRIDE_GFX_VERSION=11.5.0

llamafactory-cli train \
    --model_name_or_path Qwen/Qwen2.5-7B-Instruct \
    --dataset my_dataset \
    --finetuning_type lora \
    --lora_rank 16 \
    --output_dir ./output \
    --per_device_train_batch_size 1 \
    --gradient_accumulation_steps 8 \
    --num_train_epochs 2 \
    --learning_rate 2e-4
```

## Axolotl: YAML-конфигурация

### Пример конфигурации

```yaml
# configs/qwen-7b-lora.yaml
base_model: Qwen/Qwen2.5-7B-Instruct
model_type: AutoModelForCausalLM

load_in_8bit: false
load_in_4bit: false

adapter: lora
lora_r: 16
lora_alpha: 32
lora_dropout: 0.05
lora_target_modules:
  - q_proj
  - v_proj
  - k_proj
  - o_proj
  - gate_proj
  - up_proj
  - down_proj

datasets:
  - path: data/train.jsonl
    type: sharegpt

sequence_len: 4096
val_set_size: 0.05

output_dir: ./output

micro_batch_size: 1
gradient_accumulation_steps: 8
num_epochs: 2
learning_rate: 2e-4
optimizer: adamw_torch
lr_scheduler: cosine
warmup_steps: 10

bf16: true
tf32: false
gradient_checkpointing: true

flash_attention: false  # eager на AMD
```

### Запуск

```bash
export HSA_OVERRIDE_GFX_VERSION=11.5.0
export TORCH_COMPILE_DISABLE=1

accelerate launch -m axolotl.cli.train configs/qwen-7b-lora.yaml
```

## Параметры training

### Базовые

| Параметр | Рекомендация | Описание |
|----------|-------------|----------|
| `per_device_train_batch_size` | 1-2 | Ограничен VRAM |
| `gradient_accumulation_steps` | 4-16 | Эффективный batch = batch_size * accumulation |
| `learning_rate` | 1e-4 -- 2e-4 | Стандарт для LoRA |
| `num_train_epochs` | 1-3 | 1-2 для больших датасетов, 2-3 для малых |
| `warmup_steps` | 10-50 | Разогрев lr |
| `max_seq_length` | 2048-4096 | Длина контекста. Больше = больше VRAM |

### Специфичные для AMD

| Параметр | Значение | Зачем |
|----------|---------|-------|
| `flash_attention` / `attn_implementation` | `false` / `"eager"` | FlashAttention не работает для training на gfx1151 |
| `bf16` | `true` | BF16 поддерживается RDNA 3.5 |
| `tf32` | `false` | TF32 -- только NVIDIA |
| `torch_compile` | `false` | Вызывает NaN на gfx1151 |

## Мониторинг training

```bash
# VRAM во время training
watch -n 1 'echo "VRAM: $(($(cat /sys/class/drm/card1/device/mem_info_vram_used) / 1048576)) MiB / $(($(cat /sys/class/drm/card1/device/mem_info_vram_total) / 1048576)) MiB"'

# GPU загрузка
watch -n 1 'cat /sys/class/drm/card1/device/gpu_busy_percent'

# Loss -- в логах trainer или через tensorboard
tensorboard --logdir ./output/runs
```

## Результат training

После завершения в `output_dir/`:

```
output/
  lora-adapter/
    adapter_config.json         # Конфигурация LoRA
    adapter_model.safetensors   # Веса адаптера (~100-500 MiB)
  checkpoint-100/               # Промежуточные чекпоинты
  checkpoint-200/
  training_args.bin
  trainer_state.json            # Loss, lr по шагам
```

### Использование адаптера

```python
# Inference с LoRA-адаптером
from peft import PeftModel
from transformers import AutoModelForCausalLM, AutoTokenizer

base_model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2.5-7B-Instruct")
model = PeftModel.from_pretrained(base_model, "./output/lora-adapter")
tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-7B-Instruct")
```

### Merge и экспорт

```python
# Объединение LoRA с базовой моделью
merged_model = model.merge_and_unload()
merged_model.save_pretrained("./output/merged")

# Конвертация в GGUF для llama.cpp
# python llama.cpp/convert_hf_to_gguf.py ./output/merged --outtype q4_k_m
```

## Связанные статьи

- [Обзор методов](methods.md)
- [Подготовка данных](datasets.md)
- [Подготовка окружения](environment.md)
- [RLHF и alignment](alignment.md)
- [Известные проблемы](known-issues.md)
