# Fine-tuning Diffusion-моделей

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), ROCm 7.x. Training LoRA для Stable Diffusion и FLUX.

## Возможности платформы

120 GiB GPU-доступной памяти -- одна из немногих consumer-платформ, способных делать full fine-tuning FLUX.

| Модель | LoRA | Full FT | Примечание |
|--------|------|---------|------------|
| SD 1.5 | 6-8 GiB | 12-16 GiB | Легко |
| SDXL | 12-16 GiB | 24-32 GiB | Комфортно |
| FLUX.1 (512x512) | 20-24 GiB | 40-50 GiB | Укладывается |
| FLUX.1 (1024x1024) | 30-40 GiB | 60-80 GiB | Только Strix Halo / A100+ |

## Инструменты

| Инструмент | Поддержка AMD | Описание |
|-----------|---------------|----------|
| **SimpleTuner** | да (ROCm) | Стабильный, FLUX/SD training |
| **kohya_ss (sd-scripts)** | да (ROCm 6.2+) | Широкий функционал, SD/SDXL/FLUX |
| **AI-Toolkit (Ostris)** | частично | Быстрее SimpleTuner на 20-30% |

## SimpleTuner: FLUX LoRA

Рекомендуемый инструмент для training на AMD. Стабильная работа, явная поддержка ROCm.

### Установка

```bash
git clone https://github.com/bghira/SimpleTuner.git
cd SimpleTuner

python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt
```

### Подготовка данных

Структура директории с изображениями:

```
datasets/my-concept/
  image001.png
  image001.txt        # Описание (caption)
  image002.jpg
  image002.txt
  ...
```

Файл `.txt` -- текстовое описание соответствующего изображения. Минимум 10-20 изображений для LoRA.

### Конфигурация

```bash
# Копирование шаблона конфигурации
cp config/examples/flux_lora.json config/my-training.json
```

Основные параметры в `config/my-training.json`:

```json
{
  "model_name_or_path": "black-forest-labs/FLUX.1-dev",
  "instance_data_dir": "./datasets/my-concept",
  "output_dir": "./output/my-lora",
  "resolution": 512,
  "train_batch_size": 1,
  "gradient_accumulation_steps": 4,
  "learning_rate": 1e-4,
  "max_train_steps": 1000,
  "lora_rank": 16,
  "mixed_precision": "bf16"
}
```

### Запуск

```bash
export HSA_OVERRIDE_GFX_VERSION=11.5.0
python train.py --config config/my-training.json
```

## kohya_ss: SD/SDXL/FLUX LoRA

### Установка

```bash
git clone https://github.com/kohya-ss/sd-scripts.git
cd sd-scripts

python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt
# Для ROCm:
pip install torch torchvision --index-url https://download.pytorch.org/whl/rocm6.2
```

### Подготовка данных

```
datasets/
  10_my-concept/        # "10" -- повторений на эпоху, "my-concept" -- trigger word
    image001.png
    image001.txt
    image002.png
    image002.txt
```

### Training SD 1.5 / SDXL LoRA

```bash
export HSA_OVERRIDE_GFX_VERSION=11.5.0

accelerate launch --mixed_precision bf16 train_network.py \
    --pretrained_model_name_or_path runwayml/stable-diffusion-v1-5 \
    --train_data_dir ./datasets/ \
    --output_dir ./output/sd15-lora \
    --network_module networks.lora \
    --network_dim 16 \
    --network_alpha 16 \
    --resolution 512 \
    --train_batch_size 1 \
    --learning_rate 1e-4 \
    --max_train_epochs 10 \
    --mixed_precision bf16 \
    --save_every_n_epochs 2
```

### Training FLUX LoRA

```bash
export HSA_OVERRIDE_GFX_VERSION=11.5.0

accelerate launch --mixed_precision bf16 flux_train_network.py \
    --pretrained_model_name_or_path black-forest-labs/FLUX.1-dev \
    --train_data_dir ./datasets/ \
    --output_dir ./output/flux-lora \
    --network_module networks.lora_flux \
    --network_dim 16 \
    --network_alpha 16 \
    --resolution 512,512 \
    --train_batch_size 1 \
    --learning_rate 1e-4 \
    --max_train_steps 1000 \
    --mixed_precision bf16 \
    --optimizer_type adafactor \
    --cache_latents
```

## Captioning (создание описаний)

Автоматическое создание текстовых описаний для изображений:

```bash
# Через BLIP2 или Florence
pip install transformers

python3 -c "
from transformers import AutoProcessor, AutoModelForCausalLM
from PIL import Image
import glob, os

model = AutoModelForCausalLM.from_pretrained('microsoft/Florence-2-large', trust_remote_code=True)
processor = AutoProcessor.from_pretrained('microsoft/Florence-2-large', trust_remote_code=True)

for img_path in glob.glob('datasets/my-concept/*.png'):
    image = Image.open(img_path)
    inputs = processor(text='<DETAILED_CAPTION>', images=image, return_tensors='pt')
    generated = model.generate(**inputs, max_new_tokens=200)
    caption = processor.batch_decode(generated, skip_special_tokens=True)[0]

    txt_path = img_path.rsplit('.', 1)[0] + '.txt'
    with open(txt_path, 'w') as f:
        f.write(caption)
    print(f'{os.path.basename(img_path)}: {caption[:80]}...')
"
```

## Результат training

LoRA-адаптер сохраняется как `.safetensors` файл (~10-100 MiB).

### Использование в ComfyUI

Скопировать `.safetensors` в `ComfyUI/models/loras/`, добавить узел "Load LoRA" в workflow.

### Использование в Automatic1111 / Forge

Скопировать в `models/Lora/`, выбрать в интерфейсе.

## Рекомендации

1. **Начать с SD 1.5** -- быстрый training (6-8 GiB), простой пайплайн
2. **SDXL** -- лучшее качество при 1024x1024, комфортно на 120 GiB
3. **FLUX** -- лучшее качество, но training медленнее и сложнее
4. **Минимум 10-20 изображений** для LoRA-адаптера
5. **Качество captioning** критично -- плохие описания = плохой LoRA
6. **Regularization images** -- добавить 200+ изображений общего класса для предотвращения overfitting

## Связанные статьи

- [Подготовка окружения](environment.md)
- [Модели для картинок](../models/images.md)
- [LoRA](../use-cases/images/lora-guide.md)
- [Известные проблемы](known-issues.md)
