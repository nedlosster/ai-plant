# Установка ROCm для Radeon 8060S (gfx1151)

Платформа: Radeon 8060S (gfx1151, RDNA 3.5), ядро 6.19.8, Ubuntu 24.04.4.

## ROCm: GPU compute от AMD

ROCm (Radeon Open Compute) -- открытая платформа AMD для GPGPU-вычислений, аналог CUDA от NVIDIA. Первый релиз в 2016 году, изначально для серверных GPU (Instinct MI-серия). Включает компилятор HIP (аналог CUDA C++), runtime (HSA), математические библиотеки (rocBLAS, MIOpen) и инструменты профилирования. HIP-код может компилироваться и для NVIDIA GPU, что упрощает портирование CUDA-приложений.

Ключевая проблема ROCm -- ограниченная матрица поддержки GPU. AMD официально поддерживает только серверные (Instinct MI250/MI300) и отдельные десктопные GPU (RX 7900 XTX). Потребительские и мобильные чипы, включая APU с unified memory (Strix Halo, Phoenix), часто отсутствуют. Для таких GPU используется переменная `HSA_OVERRIDE_GFX_VERSION`, маскирующая реальный GPU ID под ближайший поддерживаемый. Это позволяет запустить ROCm, но не гарантирует стабильность -- HIP-ядра, оптимизированные для другой архитектуры, могут падать.

Для Radeon 8060S (gfx1151) ROCm 6.4 устанавливается и проходит базовые проверки (rocminfo, hipcc), но при инференсе HIP-ядра падают с segfault. Проблема VRAM (15.5 GiB вместо полного объёма) решена через `ttm.pages_limit=31457280` -- KFD видит 120 GiB ([подробности](../platform/vram-allocation.md)). Для рабочего inference на данной платформе рекомендуется Vulkan backend. Подробное сравнение: [backends-comparison.md](backends-comparison.md).

## Статус поддержки gfx1151

gfx1151 (RDNA 3.5, Strix Halo) **отсутствует** в официальной матрице ROCm, но работает через HSA_OVERRIDE_GFX_VERSION=11.5.0. ROCm определяет GPU как `gfx1150`.

Протестировано: **ROCm 6.4.0** -- rocminfo, rocm-smi, hipcc работают.

## HSA_OVERRIDE_GFX_VERSION

Переменная окружения, указывающая ROCm какой ISA использовать вместо реального GPU ID.

```bash
export HSA_OVERRIDE_GFX_VERSION=11.5.0   # gfx1150 (RDNA 3.5, рекомендуется)
```

Альтернатива: `11.0.0` (gfx1100, RDNA 3) -- при проблемах с 11.5.0.

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

### 3. Установка amdgpu-install 6.4

```bash
wget -q https://repo.radeon.com/amdgpu-install/6.4/ubuntu/noble/amdgpu-install_6.4.60400-1_all.deb \
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
export HSA_OVERRIDE_GFX_VERSION=11.5.0
EOF

source /etc/profile.d/rocm.sh
```

## Проверка

```bash
# Версия ROCm
cat /opt/rocm/.info/version
# 6.4.0-47

# GPU определяется
rocminfo | grep -E 'Name:|Marketing'
# Name: gfx1150
# Marketing Name: AMD Radeon Graphics

# HIP компилятор
hipcc --version
# HIP version: 6.4.43482

# Мониторинг
rocm-smi
```

Ожидаемый вывод `rocm-smi`:

```
Device  Node  Temp    Power    SCLK  MCLK  VRAM%  GPU%
0       1     33.0C   11.1W   None  None   0%     0%
```

## Известные проблемы

**"GPU not supported" в rocminfo**
- HSA_OVERRIDE_GFX_VERSION не установлена
- Решение: `export HSA_OVERRIDE_GFX_VERSION=11.5.0`
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
| `install.sh` | Установка ROCm 6.4 (с sudo) |
| `check.sh` | Проверка: ROCm, GPU, HIP, rocm-smi |
| `status.sh` | Статус GPU через rocm-smi + sysfs |
| `build.sh` | Сборка llama.cpp с HIP backend |

## Статус gfx1151 (Strix Halo)

HIP backend собирается, но не работает полноценно. Три проблемы:

### 1. Segfault при инференсе (llama.cpp HIP)

Маленькие модели (1.5B Q8_0, 1.5 GiB) помещаются в VRAM, но HIP-ядра падают.
`HSA_OVERRIDE_GFX_VERSION=11.5.0` маскирует gfx1151 под gfx1150, но ядра
несовместимы с реальным gfx1151.

### 2. VRAM: решено через ttm.pages_limit (2026-03-27)

По умолчанию KFD видит только 15.5 GiB GPU VRAM из-за ограничения IP Discovery firmware-таблицы. Решение -- параметр ядра `ttm.pages_limit=31457280` (120 GiB в 4K-страницах).

После применения:

```
| Уровень              | VRAM      | Статус  |
|----------------------|-----------|---------|
| BIOS (UMA)           | 96 GiB    | ok      |
| amdgpu sysfs         | 96 GiB    | ok      |
| Vulkan (Mesa RADV)   | 96 GiB    | ok      |
| KFD topology (ROCm)  | 120 GiB   | ok      |
| TTM pages_limit      | 120 GiB   | ok      |
```

Параметр добавлен в GRUB. Подробности: [vram-allocation.md](../platform/vram-allocation.md).

### 3. PyTorch ROCm: ограничен segfault

PyTorch с ROCm определяет GPU и видит 120 GiB VRAM (после ttm.pages_limit). Но инференс невозможен из-за segfault HIP-ядер на gfx1151 (проблема 1).

Замечание: `uv run` пересинхронизирует зависимости и заменяет ROCm torch на CPU-версию.
Использовать `.venv/bin/python` напрямую, не `uv run`.

### Зафиксировано

ROCm 6.4.0-47, PyTorch 2.7.1+rocm6.2.4, llama.cpp b8541, ядро 6.19.8. 2026-03-27.

### Отслеживание

- https://repo.radeon.com/amdgpu-install/ -- репозиторий релизов ROCm
- https://rocm.docs.amd.com/en/latest/release/versions.html -- release notes
- https://github.com/ggerganov/llama.cpp/issues -- issues по gfx1150/gfx1151
- https://github.com/ROCm/TheRock/discussions/655 -- PyTorch wheels для Strix Halo
- https://github.com/ROCm/ROCK-Kernel-Driver/issues -- KFD issues

## Связанные статьи

- [llama.cpp + ROCm](rocm-llama-cpp.md)
- [Настройка ядра](../platform/gpu-kernel-setup.md)
- [Драйвер amdgpu](../platform/amdgpu-driver.md)
- [Диагностика](troubleshooting.md)
