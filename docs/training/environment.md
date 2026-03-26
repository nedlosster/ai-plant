# Подготовка окружения для training

Платформа: Radeon 8060S (gfx1151), Ubuntu 24.04.4, ядро 6.19.8+.

## Статус поддержки

gfx1151 (Strix Halo) требует специальных сборок PyTorch. Официальные wheels с pytorch.org не работают ("HIP error: invalid device function"). Стабильные комбинации:

| Компонент | Версия |
|-----------|--------|
| Ядро | >= 6.18.4 (рекомендуется 6.19.8+) |
| ROCm | 7.2.1+ или 7.11.0 |
| Python | 3.10--3.12 (не 3.13+) |
| PyTorch | community wheels для gfx1151 |

## Вариант 1: Docker-toolbox (рекомендуемый)

Готовый Docker-образ с настроенным окружением для Strix Halo.

```bash
git clone https://github.com/shantur/amd-strix-halo-fine-tuning-toolboxes.git
cd amd-strix-halo-fine-tuning-toolboxes

# Сборка образа
docker build -t strix-training .

# Запуск
docker run -it --device=/dev/kfd --device=/dev/dri \
    --group-add video --group-add render \
    -v ~/models:/models \
    -v ~/datasets:/datasets \
    strix-training bash
```

Внутри контейнера: PyTorch + ROCm + Unsloth + PEFT + TRL.

## Вариант 2: Ручная установка

### Предварительные требования

```bash
# Группы
sudo usermod -aG video,render $USER

# udev-правила для GPU
cat <<'EOF' | sudo tee /etc/udev/rules.d/70-amdgpu.rules
SUBSYSTEM=="kfd", GROUP="render", MODE="0666"
SUBSYSTEM=="drm", KERNEL=="card[0-9]*", GROUP="render", MODE="0666"
SUBSYSTEM=="drm", KERNEL=="renderD[0-9]*", GROUP="render", MODE="0666"
EOF
sudo udevadm control --reload-rules
```

### Установка ROCm

См. [docs/inference/rocm-setup.md](../inference/rocm-setup.md). Для training критично:

```bash
# Обязательно для gfx1151
export HSA_OVERRIDE_GFX_VERSION=11.5.0
export ROCM_PATH=/opt/rocm
export PATH=$ROCM_PATH/bin:$PATH
export LD_LIBRARY_PATH=$ROCM_PATH/lib:$LD_LIBRARY_PATH
```

### Установка PyTorch для gfx1151

```bash
# Создание виртуального окружения
python3 -m venv ~/training-env
source ~/training-env/bin/activate

# PyTorch с ROCm (community wheels)
# Проверить актуальные ссылки на:
# - github.com/ROCm/TheRock/discussions/655
# - github.com/kyuz0/amd-strix-halo-llm-finetuning
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2

# Проверка
python3 -c "
import torch
print('PyTorch:', torch.__version__)
print('HIP available:', torch.cuda.is_available())
print('Device:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A')
print('VRAM:', torch.cuda.get_device_properties(0).total_memory // 1024**3, 'GiB' if torch.cuda.is_available() else 'N/A')
"
```

Если `torch.cuda.is_available()` возвращает `False` -- проверить HSA_OVERRIDE_GFX_VERSION и версию ROCm.

### Установка инструментов training

```bash
# PEFT (LoRA/QLoRA)
pip install peft

# TRL (DPO, GRPO, SFT)
pip install trl

# Unsloth (оптимизированный training)
pip install unsloth

# HuggingFace transformers + datasets
pip install transformers datasets accelerate

# bitsandbytes для AMD (preview, нестабилен)
# pip install bitsandbytes  # осторожно, может вызвать проблемы
```

### Параметры ядра для training

Добавить в `/etc/default/grub`:

```
GRUB_CMDLINE_LINUX_DEFAULT="... amdgpu.gttsize=131072"
```

GTT 128 GiB необходим для корректной работы unified memory при training.

### Обязательные переменные окружения

```bash
# ~/.bashrc или /etc/profile.d/rocm-training.sh

export HSA_OVERRIDE_GFX_VERSION=11.5.0
export ROCM_PATH=/opt/rocm
export PATH=$ROCM_PATH/bin:$PATH
export LD_LIBRARY_PATH=$ROCM_PATH/lib:$LD_LIBRARY_PATH

# Отключение torch.compile (вызывает NaN на gfx1151)
export TORCH_COMPILE_DISABLE=1

# Ограничение параллелизма Triton (стабильность)
export TRITON_MAX_PARALLEL_JOBS=1
```

## Проверка окружения

```bash
# GPU определяется ROCm
rocminfo | grep -E 'Name:|Marketing'

# PyTorch видит GPU
python3 -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"

# VRAM доступна
python3 -c "import torch; print(f'{torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GiB')"

# Простой тест compute
python3 -c "
import torch
x = torch.randn(1000, 1000, device='cuda')
y = torch.matmul(x, x)
print('Compute test: OK')
"
```

## Инструменты training

### Unsloth

Оптимизированный training с автоматическим управлением памятью. Рекомендуется для начала.

### LLaMA-Factory

Web UI (LLAMABOARD) для fine-tuning. Поддерживает AMD ROCm. Удобен для экспериментов без кода.

```bash
git clone https://github.com/hiyouga/LLaMA-Factory.git
cd LLaMA-Factory
pip install -e .

# Запуск Web UI
HSA_OVERRIDE_GFX_VERSION=11.5.0 llamaboard
```

### Axolotl

YAML-конфигурация для training. Поддерживает все методы (LoRA, QLoRA, full FT, DPO).

```bash
git clone https://github.com/axolotl-ai-cloud/axolotl.git
cd axolotl
pip install -e .
```

Подробнее в [llm-finetuning.md](llm-finetuning.md).

## Связанные статьи

- [Fine-tuning LLM](llm-finetuning.md)
- [Fine-tuning Diffusion](diffusion-finetuning.md)
- [Известные проблемы](known-issues.md)
- [Установка ROCm](../inference/rocm-setup.md)
