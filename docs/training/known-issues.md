# Известные проблемы training на Strix Halo

Платформа: Radeon 8060S (gfx1151), ROCm 7.x. Актуально на март 2026.

## Критические проблемы

### hipMemcpy bottleneck

**Симптом**: Training в 5-10x медленнее ожидаемого. GPU загрузка < 20%.

**Причина**: При рабочем наборе >15 GiB 82-95% времени тратится на host-device memory copy (`hipMemcpy`). PyTorch ROCm неоптимально управляет unified memory на Strix Halo.

**Статус**: PyTorch issue #171687, "In Progress".

**Workaround**:
- Уменьшить batch size и sequence length
- Использовать gradient checkpointing (уменьшает пиковое потребление)
- Для моделей < 15 GiB проблема не проявляется

### NaN loss при training Gemma-3

**Симптом**: Loss становится NaN после нескольких шагов.

**Причина**: Triton/ROCm компилятор генерирует нестабильный код для Gemma-3 архитектуры на gfx1151.

**Решение**:
```bash
export TORCH_COMPILE_DISABLE=1
```

Или в Unsloth -- исправлено в PR #4109 (отключение torch.compile для Gemma3 на HIP).

### bitsandbytes 4-bit нестабилен

**Симптом**: QLoRA с `load_in_4bit=True` -- ошибки, некорректные веса, или скрытое переключение на 16-bit.

**Причина**: bitsandbytes на AMD ROCm в preview-состоянии. Blocksize должен быть 128 (не 64), предквантизированные модели загружаются в BF16.

**Решение**: Использовать LoRA 16-bit вместо QLoRA:
```python
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="...",
    load_in_4bit=False,  # 16-bit
)
```

VRAM больше, но результат стабильный.

### Flash Attention не работает для training

**Симптом**: Ошибка при включении FlashAttention2 или FA для training.

**Причина**: FA2 для training не портирован на RDNA 3.5. Работает только для inference.

**Решение**:
```python
# В transformers
model = AutoModelForCausalLM.from_pretrained(
    "...",
    attn_implementation="eager",  # не "flash_attention_2"
)
```

В Axolotl: `flash_attention: false`.

## Проблемы производительности

### GPU остается на низких частотах

**Симптом**: GPU frequency ~800 MHz при training вместо ожидаемых 2900 MHz.

**Причина**: ROCm issue #5750 -- GPU не переходит в high-performance state.

**Workaround**:
```bash
# Принудительно высокая частота
echo high | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level

# Или конкретный уровень
echo 2 | sudo tee /sys/class/drm/card1/device/pp_dpm_sclk
```

### Медленный первый запуск

**Симптом**: Первый training-шаг занимает минуты.

**Причина**: JIT-компиляция HIP-ядер, загрузка модели, кэширование.

**Решение**: Нормально. Последующие шаги будут быстрее. Не прерывать.

### OOM при больших batch size

**Симптом**: `RuntimeError: HIP out of memory`.

**Решение**:
```python
# Уменьшить batch size
per_device_train_batch_size=1

# Включить gradient checkpointing
gradient_checkpointing=True
# Или в Unsloth:
use_gradient_checkpointing="unsloth"

# Уменьшить sequence length
max_seq_length=2048  # вместо 4096

# Увеличить gradient accumulation для сохранения effective batch size
gradient_accumulation_steps=16
```

## Проблемы установки

### PyTorch wheels не совместимы

**Симптом**: `HIP error: invalid device function` при `import torch`.

**Причина**: Официальные PyTorch wheels не скомпилированы для gfx1151.

**Решение**: Использовать community wheels или Docker-toolbox:
- github.com/shantur/amd-strix-halo-fine-tuning-toolboxes
- github.com/ROCm/TheRock/discussions/655

### Конфликт ROCm DKMS и in-tree amdgpu

**Симптом**: GPU не определяется после установки ROCm.

**Причина**: ROCm устанавливает DKMS-модуль amdgpu, конфликтующий с mainline-ядром.

**Решение**: `amdgpu-install --no-dkms` или `sudo apt remove amdgpu-dkms`.

### Python 3.13+ не поддерживается

**Симптом**: Ошибки при установке ROCm wheels.

**Причина**: ROCm wheels собраны для Python 3.10--3.12.

**Решение**: Использовать Python 3.12.

## Диагностика

```bash
# Проверка GPU видимости
rocminfo | grep -E 'Name:|Marketing'

# Проверка PyTorch
python3 -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"

# VRAM
python3 -c "import torch; print(f'{torch.cuda.memory_allocated()/1e9:.1f} / {torch.cuda.get_device_properties(0).total_memory/1e9:.1f} GiB')"

# GPU частота во время training
watch -n 1 'cat /sys/class/drm/card1/device/pp_dpm_sclk'

# GPU загрузка
watch -n 1 'cat /sys/class/drm/card1/device/gpu_busy_percent'

# Температура
watch -n 1 'echo "$(($(cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input) / 1000))C"'
```

## Обязательные переменные окружения

```bash
# Все вместе -- добавить в ~/.bashrc или скрипт запуска
export HSA_OVERRIDE_GFX_VERSION=11.5.0
export TORCH_COMPILE_DISABLE=1
export TRITON_MAX_PARALLEL_JOBS=1
export ROCM_PATH=/opt/rocm
export PATH=$ROCM_PATH/bin:$PATH
export LD_LIBRARY_PATH=$ROCM_PATH/lib:$LD_LIBRARY_PATH
```

## Ресурсы

- kyuz0/amd-strix-halo-llm-finetuning -- полный гайд с бенчмарками
- shantur/amd-strix-halo-fine-tuning-toolboxes -- Docker-toolbox
- Framework Community: Finetuning on Strix Halo -- подробные тесты
- ROCm Strix Halo Optimization -- официальная документация AMD
- PyTorch issue #171687 -- hipMemcpy bottleneck tracker
- ROCm issue #5750 -- GPU idle clocks

## Связанные статьи

- [Подготовка окружения](environment.md)
- [Fine-tuning LLM](llm-finetuning.md)
- [Fine-tuning Diffusion](diffusion-finetuning.md)
- [Диагностика inference](../inference/troubleshooting.md)
