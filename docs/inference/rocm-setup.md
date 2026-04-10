# Установка ROCm для Radeon 8060S (gfx1151)

Платформа: Radeon 8060S (gfx1151, RDNA 3.5), ядро 6.19.8, Ubuntu 24.04.4.

## ROCm: GPU compute от AMD

ROCm (Radeon Open Compute) -- открытая платформа AMD для GPGPU-вычислений, аналог CUDA от NVIDIA. Первый релиз в 2016 году, изначально для серверных GPU (Instinct MI-серия). Включает компилятор HIP (аналог CUDA C++), runtime (HSA), математические библиотеки (rocBLAS, MIOpen) и инструменты профилирования. HIP-код может компилироваться и для NVIDIA GPU, что упрощает портирование CUDA-приложений.

Ключевая проблема ROCm -- ограниченная матрица поддержки GPU. AMD официально поддерживает только серверные (Instinct MI250/MI300) и отдельные десктопные GPU (RX 7900 XTX). Потребительские и мобильные чипы, включая APU с unified memory (Strix Halo, Phoenix), часто отсутствуют. Для таких GPU используется переменная `HSA_OVERRIDE_GFX_VERSION`, маскирующая реальный GPU ID под ближайший поддерживаемый. Это позволяет запустить ROCm, но не гарантирует стабильность -- HIP-ядра, оптимизированные для другой архитектуры, могут падать.

Для Radeon 8060S (gfx1151) ROCm 7.2.1 работает стабильно: GPU определяется нативно как gfx1151, HIP-инференс через llama.cpp функционирует без segfault. Проблема VRAM (15.5 GiB вместо полного объёма) решена через `ttm.pages_limit=31457280` -- KFD видит 120 GiB ([подробности](../platform/vram-allocation.md)). Подробное сравнение бэкендов: [backends-comparison.md](backends-comparison.md).

## Статус поддержки gfx1151

gfx1151 (RDNA 3.5, Strix Halo) **отсутствует** в официальной матрице ROCm, но де-факто поддерживается с ROCm 7.2.1. GPU определяется нативно как `gfx1151`. AMD опубликовала [официальную страницу оптимизации для Strix Halo](https://rocm.docs.amd.com/en/latest/how-to/system-optimization/strixhalo.html).

Протестировано: **ROCm 7.2.1** -- rocminfo, rocm-smi, hipcc, llama.cpp HIP inference работают стабильно.

## HSA_OVERRIDE_GFX_VERSION

Переменная окружения, указывающая ROCm какой ISA использовать вместо реального GPU ID.

```bash
export HSA_OVERRIDE_GFX_VERSION=11.5.1   # gfx1151 (RDNA 3.5, рекомендуется для ROCm 7.2.1)
```

Альтернатива: `11.5.0` (gfx1150) -- для старых версий ROCm 6.x.

## Установка

### 1. Предварительные требования

```bash
# Группы (если не добавлены)
sudo usermod -aG video,render $USER
```

### 2. Очистка старых версий

```bash
# Проверка
apt list --installed 2>/dev/null | grep -iE 'rocm|hip|amdgpu-install'

# Удаление старых
sudo apt purge -y amdgpu-install 2>/dev/null
sudo rm -rf /opt/rocm*
```

### 3. Установка amdgpu-install 7.2.1

```bash
wget -q https://repo.radeon.com/amdgpu-install/7.2.1/ubuntu/noble/amdgpu-install_7.2.1.70201-1_all.deb \
    -O /tmp/amdgpu-install.deb
sudo dpkg -i /tmp/amdgpu-install.deb
sudo apt update
```

### 4. Установка ROCm

```bash
# Полный стек ROCm без DKMS (amdgpu уже в mainline-ядре)
sudo amdgpu-install --usecase=rocm --no-dkms -y
```

`--no-dkms` обязателен: DKMS-модуль конфликтует с in-tree amdgpu из ядра 6.19.8.

### 5. Настройка окружения

```bash
sudo tee /etc/profile.d/rocm.sh > /dev/null << 'EOF'
export ROCM_PATH=/opt/rocm
export PATH=$ROCM_PATH/bin:$PATH
export LD_LIBRARY_PATH=$ROCM_PATH/lib:$LD_LIBRARY_PATH
export HSA_OVERRIDE_GFX_VERSION=11.5.1
EOF

source /etc/profile.d/rocm.sh
```

## Проверка

```bash
# Версия ROCm
cat /opt/rocm/.info/version
# 7.2.1

# GPU определяется нативно как gfx1151
rocminfo | grep -E 'Name:|Marketing'
# Name: gfx1151
# Marketing Name: AMD Radeon Graphics

# HIP компилятор
hipcc --version
# HIP version: 7.2.53211

# Мониторинг
rocm-smi
```

Ожидаемый вывод `rocm-smi`:

```
Device  Node  Temp    Power    SCLK  MCLK  VRAM%  GPU%
0       1     40.0C   37.0W   N/A   1000Mhz  0%   1%
```

## Известные проблемы

**"GPU not supported" в rocminfo**
- HSA_OVERRIDE_GFX_VERSION не установлена
- Решение: `export HSA_OVERRIDE_GFX_VERSION=11.5.1`
- Проверка: `echo $HSA_OVERRIDE_GFX_VERSION`

**Конфликт amdgpu DKMS и in-tree**
- amdgpu-install устанавливает DKMS-модуль, конфликтующий с ядром 6.19.8
- Решение: `--no-dkms` при установке, или `sudo apt remove amdgpu-dkms`

**PwrCap: Unsupported в rocm-smi**
- Нормально для gfx1151 -- power cap не поддерживается EC данной платформы

**SCLK/MCLK: None в rocm-smi**
- ROCm не может читать частоты для gfx1151 -- использовать sysfs: `cat /sys/class/drm/card1/device/pp_dpm_sclk`

## Откат

```bash
sudo apt purge -y rocm-* hip-* amdgpu-install
sudo rm -rf /opt/rocm*
sudo rm -f /etc/profile.d/rocm.sh
sudo apt autoremove -y
```

## Скрипты автоматизации

Готовые скрипты в `scripts/inference/rocm/`: [документация](../../scripts/inference/rocm/README.md)

| Скрипт | Назначение |
|--------|-----------|
| `install.sh` | Установка ROCm 7.2.1 (с sudo) |
| `check.sh` | Проверка: ROCm, GPU, HIP, rocm-smi |
| `status.sh` | Статус GPU через rocm-smi + sysfs |
| `build.sh` | Сборка llama.cpp с HIP backend |

## Статус gfx1151 (Strix Halo)

### HIP inference: работает (ROCm 7.2.1)

С ROCm 7.2.1 HIP-инференс через llama.cpp работает стабильно. GPU определяется нативно как gfx1151, segfault устранён. Сборка llama.cpp с `-DAMDGPU_TARGETS="gfx1151"`.

Бенчмарк (llama.cpp b8541, llama-bench pp512/tg128, 2026-04-06):

| Модель | Vulkan pp/tg | HIP pp/tg | HIP/Vulkan tg |
|--------|-------------|-----------|---------------|
| 1.5B Q8_0 (dense) | 5242 / 121 | 5140 / 105 | -13% |
| 27B Q4_K_M (dense) | 305 / 12.6 | 297 / 11.3 | -10% |
| 30B MoE Q4_K_M | 1029 / 86 | 899 / 59 | -31% |

Vulkan быстрее HIP во всех тестах. На MoE-моделях разрыв наибольший.

### VRAM: решено через ttm.pages_limit (2026-03-27)

По умолчанию KFD видит только 15.5 GiB GPU VRAM из-за ограничения IP Discovery firmware-таблицы. Решение -- параметр ядра `ttm.pages_limit=31457280` (120 GiB в 4K-страницах).

После применения:

| Уровень              | VRAM      | Статус  |
|----------------------|-----------|---------|
| BIOS (UMA)           | 96 GiB    | ok      |
| amdgpu sysfs         | 96 GiB    | ok      |
| Vulkan (Mesa RADV)   | 96 GiB    | ok      |
| KFD topology (ROCm)  | 120 GiB   | ok      |
| TTM pages_limit      | 120 GiB   | ok      |

Параметр добавлен в GRUB. Подробности: [vram-allocation.md](../platform/vram-allocation.md).

### PyTorch ROCm

PyTorch с ROCm определяет GPU и видит 120 GiB VRAM. Для gfx1151 использовать wheels с `rocm.nightlies.amd.com/v2/gfx1151/` (стандартные nightly могут давать segfault).

Замечание: `uv run` пересинхронизирует зависимости и заменяет ROCm torch на CPU-версию.
Использовать `.venv/bin/python` напрямую, не `uv run`.

### HIP inference: ограничение по VRAM-аллокации (2026-04-09)

При BIOS carved-out VRAM = 96 GiB HIP runtime не может выделить единый буфер >30-35 GiB для модели. `cudaMalloc failed: out of memory` при попытке загрузить Qwen3-Coder Next (45 GiB) даже при 95 GiB свободной VRAM.

Причина: архитектура unified memory APU + большой carved-out сегмент конфликтуют с HIP runtime allocation model. [AMD рекомендует](https://rocm.docs.amd.com/en/latest/how-to/system-optimization/strixhalo.html) держать carved-out VRAM маленьким (0.5-4 GiB) и использовать shared TTM/GTT. На дискретных GPU этой проблемы нет.

**Практический лимит для нашей платформы (BIOS carved-out 96 GiB)**:
- Модели до ~30 GiB (Q4_K_M) -- загружаются через HIP
- Модели 35+ GiB -- OOM при `hipMalloc`
- Workaround: частичный offload (`-ngl 30-40`) -- работает, но медленно

**Модели, протестированные на HIP**:

| Модель | Размер Q4 | HIP | Результат |
|--------|-----------|-----|-----------|
| Qwen3-Coder 30B-A3B | 17 GiB | ok | 63.5 tok/s tg |
| Qwen2.5-Coder 1.5B Q8 | 1.5 GiB | ok | ~105 tok/s tg |
| Qwen3-Coder Next 80B-A3B | 45 GiB | **OOM** | cudaMalloc failed |

### Бенчмарк ROCm vs Vulkan: Qwen3-Coder 30B-A3B (2026-04-09)

llama-server, Q4_K_M, ctx 32K, parallel 1:

| Метрика | Vulkan | ROCm (HIP) | Разница |
|---------|--------|------------|---------|
| prompt processing | 1036 tok/s | 441 tok/s | Vulkan 2.3x быстрее |
| token generation | 86 tok/s | 63.5 tok/s | Vulkan 1.4x быстрее |

Вывод: **Vulkan остаётся рекомендованным backend для inference** на Strix Halo. ROCm/HIP использовать для задач, требующих HIP-специфичные features (PyTorch, training, ACE-Step).

### Зафиксировано

ROCm 7.2.1, HIP 7.2.53211, llama.cpp b8717, ядро 6.19.8. 2026-04-09.

### Отслеживание

- https://repo.radeon.com/amdgpu-install/ -- репозиторий релизов ROCm
- https://rocm.docs.amd.com/en/latest/about/release-notes.html -- release notes
- https://rocm.docs.amd.com/en/latest/how-to/system-optimization/strixhalo.html -- оптимизация Strix Halo
- https://github.com/ROCm/ROCm/issues/5853 -- segfault gfx1151 (закрыт)
- https://github.com/ROCm/TheRock/discussions/655 -- PyTorch wheels для Strix Halo

## Связанные статьи

- [llama.cpp + ROCm](rocm-llama-cpp.md)
- [Настройка ядра](../platform/gpu-kernel-setup.md)
- [Драйвер amdgpu](../platform/amdgpu-driver.md)
- [Диагностика](troubleshooting.md)
