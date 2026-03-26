# Драйвер amdgpu: настройка и диагностика

Платформа: Radeon 8060S (gfx1151, RDNA 3.5), ядро 6.19.8, драйвер amdgpu (in-tree).

## Текущее состояние

Снято 2026-03-26:

| Параметр | Значение |
|----------|---------|
| Драйвер | amdgpu (in-tree, ядро 6.19.8) |
| DRM версия | 3.64.0 |
| PCI адрес | 0000:bc:00.0 |
| PCI ID | 1002:1586 (rev c1) |
| PCIe | Gen4 x16 (16.0 GT/s) |
| VRAM всего | 96 GiB (103079215104 байт) |
| VRAM использовано | ~276 MiB (idle) |
| GPU загрузка | 0% (idle) |
| Температура | 30 C (edge) |
| Потребление | ~19W (idle, PPT) |
| Частота GPU (sclk) | 603 MHz (idle) / 2900 MHz (max) |
| Частота памяти (mclk) | 400 MHz (idle) / 1000 MHz (max) |
| Compute rings | 8 (comp_1.0.0 -- comp_1.3.1) |
| KFD | 1 узел, device 1002:1586 |
| Устройства | /dev/dri/card1, /dev/dri/renderD128 |

## IP-блоки

amdgpu состоит из набора IP-блоков, каждый отвечает за свою подсистему:

| N | IP-блок | Реализация | Назначение |
|---|---------|-----------|------------|
| 0 | common_v1_0_0 | soc21_common | Общая инфраструктура SoC |
| 1 | gmc_v11_0_0 | gmc_v11_0 | Graphics Memory Controller -- управление VRAM и GTT |
| 2 | ih_v6_0_0 | ih_v6_1 | Interrupt Handler -- обработка прерываний GPU |
| 3 | psp_v13_0_0 | psp | Platform Security Processor -- загрузка firmware, TMZ |
| 4 | smu_v14_0_0 | smu | System Management Unit -- частоты, напряжения, термалы |
| 5 | dce_v1_0_0 | dm | Display Core (DCN 3.5.1) -- дисплейный вывод |
| 6 | gfx_v11_0_0 | gfx_v11_0 | Graphics/Compute Engine -- шейдеры, compute |
| 7 | sdma_v6_0_0 | sdma_v6_0 | System DMA -- копирование памяти |
| 8 | vcn_v4_0_5 | vcn_v4_0_5 | Video Core Next -- аппаратное кодирование/декодирование |
| 9 | jpeg_v4_0_5 | jpeg_v4_0_5 | JPEG Engine -- аппаратное декодирование JPEG |
| 10 | mes_v11_0_0 | mes_v11_0 | Micro Engine Scheduler -- планировщик задач GPU |
| 11 | vpe_v6_1_0 | vpe_v6_1 | Video Processing Engine |
| 12 | isp_v4_1_1 | isp_ip | Image Signal Processor |

### Compute-конфигурация

```
SE 2, SH per SE 2, CU per SH 10, active_cu_number 40
```

- 2 Shader Engines, по 2 Shader Array, по 10 CU = 40 CU
- 8 compute rings (comp_1.0.0 -- comp_1.3.1) + 1 gfx ring + 1 sdma ring

## Firmware

| Компонент | Версия | Примечание |
|-----------|--------|-----------|
| DMUB | 0x09004000 | Display MicroController Unit Buddy -- управление дисплеем |
| VCN (inst 0, 1) | ENC: 1.24 DEC: 9 | Video Core Next, 2 инстанса |
| PSP | psp_v13_0_0 | Platform Security Processor |
| SMU | smu_v14_0_0 | System Management Unit |
| VBIOS | 113-STRXLGEN-001 | Video BIOS (Fetched from VFCT) |

Firmware загружается из `/lib/firmware/amdgpu/` при инициализации драйвера. Обновление firmware -- через пакет `linux-firmware`.

## Параметры модуля

Текущие значения (`/sys/module/amdgpu/parameters/`):

| Параметр | Значение | Описание |
|----------|---------|----------|
| gttsize | 131072 | GTT размер в MiB (128 GiB) |
| dc | 1 | Display Core включен |
| vm_update_mode | 3 | Обновление VM page tables через CPU+SDMA |
| runpm | -1 | Runtime PM: auto (на этом GPU -- disabled) |
| gpu_recovery | -1 | Auto: восстановление GPU при зависании |

Параметры задаются через GRUB (`/etc/default/grub`):

```
GRUB_CMDLINE_LINUX_DEFAULT="amdgpu.gttsize=131072 amdgpu.vm_update_mode=3 amdgpu.dc=1 consoleblank=0 amdgpu.runpm=0 ttm.pages_limit=31457280"
```

### Справочник параметров

| Параметр | Значения | Назначение |
|----------|---------|------------|
| `dc` | 0/1 | Display Core. 0 -- отключен (нет дисплея, только compute), 1 -- включен |
| `dcdebugmask` | битовая маска | Отладка DC. 0x10 -- отключить PSR |
| `gttsize` | MiB | Размер GTT. Для unified memory с 96 GiB VRAM -- 131072 |
| `vm_update_mode` | 0-3 | 0: CPU, 1: SDMA, 2: CPU+SDMA (default), 3: CPU+SDMA (forced) |
| `runpm` | -1/0/1 | Runtime PM. -1: auto, 0: отключен, 1: включен |
| `gpu_recovery` | -1/0/1 | GPU reset при зависании. -1: auto, 0: отключен, 1: включен |
| `noretry` | 0/1 | Retry при page fault. 0: с retry, 1: без retry |
| `ppfeaturemask` | hex | Битовая маска функций PowerPlay (управление частотами) |

## Мониторинг через sysfs

### VRAM

```bash
# Общий объем VRAM (байты)
cat /sys/class/drm/card1/device/mem_info_vram_total
# 103079215104 (96 GiB)

# Использовано VRAM (байты)
cat /sys/class/drm/card1/device/mem_info_vram_used

# GTT использовано
cat /sys/class/drm/card1/device/mem_info_gtt_used
```

### Загрузка GPU

```bash
# Процент загрузки GPU (0-100)
cat /sys/class/drm/card1/device/gpu_busy_percent
```

### Температура и питание (hwmon)

```bash
# Температура GPU (edge), в millidegrees (30000 = 30C)
cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input

# Потребление (PPT), в microwatts (19064000 = ~19W)
cat /sys/class/drm/card1/device/hwmon/hwmon*/power1_average

# Напряжение GPU (vddgfx), в millivolts
cat /sys/class/drm/card1/device/hwmon/hwmon*/in0_input

# Напряжение NB (vddnb), в millivolts
cat /sys/class/drm/card1/device/hwmon/hwmon*/in1_input

# Частота GPU (sclk), в Hz
cat /sys/class/drm/card1/device/hwmon/hwmon*/freq1_input
```

### Частоты

```bash
# Доступные частоты GPU с текущей отмечены *
cat /sys/class/drm/card1/device/pp_dpm_sclk
# 0: 600Mhz
# 1: 603Mhz *
# 2: 2900Mhz

# Доступные частоты памяти
cat /sys/class/drm/card1/device/pp_dpm_mclk
# 0: 400Mhz
# 1: 800Mhz
# 2: 1000Mhz
```

### Скрипт мониторинга

```bash
#!/bin/bash
# Непрерывный мониторинг GPU
while true; do
    gpu=$(cat /sys/class/drm/card1/device/gpu_busy_percent)
    vram_used=$(cat /sys/class/drm/card1/device/mem_info_vram_used)
    vram_mib=$((vram_used / 1048576))
    temp=$(cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input)
    temp_c=$((temp / 1000))
    power=$(cat /sys/class/drm/card1/device/hwmon/hwmon*/power1_average)
    power_w=$((power / 1000000))
    sclk=$(cat /sys/class/drm/card1/device/hwmon/hwmon*/freq1_input)
    sclk_mhz=$((sclk / 1000000))
    printf "GPU: %3d%%  VRAM: %5d MiB  Temp: %dC  Power: %dW  Freq: %d MHz\n" \
        "$gpu" "$vram_mib" "$temp_c" "$power_w" "$sclk_mhz"
    sleep 1
done
```

## Права доступа

```bash
# Устройства DRM
ls -la /dev/dri/
# card1      -> группа video
# renderD128 -> группа render

# Пользователь должен быть в группах video и render
sudo usermod -aG video,render $USER
```

renderD128 нужен для Vulkan и ROCm (compute без X11). card1 нужен для display и KMS.

## Диагностика

### Проверка работоспособности

```bash
# Драйвер загружен
lsmod | grep amdgpu

# GPU видится
lspci -s bc:00.0 -v

# IP-блоки загружены
journalctl -b 0 -k | grep 'detected ip block'

# Ошибки amdgpu
journalctl -b 0 -k | grep -iE 'amdgpu.*error|amdgpu.*fail'

# KFD (для ROCm/HIP)
journalctl -b 0 -k | grep kfd
```

### Типичные проблемы

**`probe with driver amdgpu failed with error -22`**
- Причина: `nomodeset` в параметрах ядра блокирует инициализацию GPU
- Решение: убрать `nomodeset` из GRUB

**`drmmode_do_crtc_dpms cannot get last vblank counter`**
- Причина: баг DCN 3.5.1 при DPMS на мониторах 2K+ через HDMI
- Решение: принудительный 1080p через `/etc/X11/xorg.conf.d/10-monitor.conf`
- Подробности: [gpu-kernel-setup.md](gpu-kernel-setup.md)

**`gnome-shell segfault` при загрузке с `nomodeset` или `dc=0`**
- Причина: GNOME Shell требует GPU-ускорение, без Display Core -- только simpledrm
- Решение: включить `amdgpu.dc=1`, использовать X11 (`WaylandEnable=false`)

**GPU зависание (fence timeout)**
- Диагностика: `journalctl -b 0 -k | grep -i 'fence\|timeout\|reset'`
- Решение: проверить `gpu_recovery` параметр, обновить ядро/firmware

**Vulkan: Permission denied на renderD128**
- Причина: пользователь не в группе `render`
- Решение: `sudo usermod -aG render $USER`, перелогиниться

## Версионирование

| Компонент | Как проверить |
|-----------|--------------|
| Версия драйвера | `modinfo amdgpu \| grep vermagic` |
| DRM версия | `journalctl -b 0 -k \| grep 'Initialized amdgpu'` |
| Firmware | `journalctl -b 0 -k \| grep -iE 'DMUB\|VCN\|firmware'` |
| linux-firmware пакет | `dpkg -l linux-firmware` |
| Ядро | `uname -r` |

## Связанные статьи

- [Настройка ядра](gpu-kernel-setup.md)
- [Процессор](processor.md)
- [Установка ROCm](../inference/rocm-setup.md)
- [Диагностика](../inference/troubleshooting.md)
