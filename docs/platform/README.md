# Платформа ai-server: Meigao MS-S1 MAX (AMD Strix Halo)

## Обзор

Inference-сервер на базе мини-ПК Meigao MS-S1 MAX с процессором AMD Ryzen AI MAX+ 395. Платформа Strix Halo объединяет CPU, GPU (RDNA 3.5) и NPU (XDNA 2) на одном чипе с unified memory -- единым пулом LPDDR5 для всех подсистем.

| Параметр | Значение |
|----------|----------|
| Корпус | Meigao MS-S1 MAX |
| Плата | Meigao SHWSA v1.0 |
| BIOS | AMI 1.06 (04.01.2026) |
| CPU | AMD Ryzen AI MAX+ 395 (16C/32T, до 5.2 GHz) |
| GPU | Radeon 8060S (RDNA 3.5, 40 CU, gfx1151) |
| NPU | XDNA 2 (50 TOPS INT8) |
| RAM физическая | 128 GiB LPDDR5 8000 MT/s (256 GB/s), unified |
| GPU-доступная память | **120 GiB** (carved-out 96 GiB + GTT, через `ttm.pages_limit`) |
| CPU RAM (MemTotal) | ~31 GiB (128 GiB минус carved-out 96 GiB) |
| Хранилище | Crucial CT2000P310SSD8 NVMe, 1.8 TiB |
| ОС | Ubuntu 24.04.4 LTS |
| Ядро | 6.19.8 (mainline) |

## Архитектура памяти

В отличие от дискретных GPU, Radeon 8060S не имеет собственной видеопамяти. Весь объем LPDDR5 (128 GiB физически, ~96 GiB доступно ОС) делится между CPU и GPU:

```
LPDDR5 128 GiB (96 GiB доступно)
  |
  +-- Carved-out VRAM (BIOS UMA): 96 GiB
  |   Зарезервировано для GPU, недоступно CPU.
  |
  +-- GTT (Graphics Translation Table): 128 GiB
  |   Системная RAM, доступная GPU через page tables.
  |   Параметр: amdgpu.gttsize=131072
  |
  +-- TTM pages_limit: 120 GiB (31457280 страниц)
  |   Снимает ограничение KFD firmware на 15.5 GiB.
  |   GPU-приложения могут аллоцировать до 120 GiB.
  |
  +-- CPU MemTotal: ~31 GiB
      Остаток после carved-out.
```

Carved-out и GTT физически одна и та же LPDDR5 -- разницы в скорости нет (256 GB/s). Разница в управлении через memory manager (TTM).

Преимущества для инференса:
- 120 GiB GPU-доступной памяти без дорогой HBM/GDDR6
- Нет накладных расходов на PCIe-трансфер между CPU и GPU
- MoE-модели 122B (Q4_K_M, 71 GiB) целиком на GPU
- 70B Q8_0 + ctx 32k (~90 GiB) -- с запасом

Ограничения:
- Пропускная способность LPDDR5 (256 GB/s) ниже, чем HBM/GDDR6 у дискретных GPU
- 40 CU -- ниже вычислительная мощность по сравнению с Radeon PRO/Instinct
- Баланс памяти: carved-out 96 GiB оставляет только ~31 GiB для CPU

## Особенности платформы

Strix Halo -- новая платформа (начало 2026). Поддержка в Linux развивается:

- **Ядро**: стоковое ядро Ubuntu 24.04 (6.8.x) не поддерживает gfx1151. Требуется mainline >= 6.18, рекомендуется 6.19.8+
- **Display Core**: DCN 3.5.1 -- в `multi-user.target` дисплей не инициализируется (display pipeline неактивен). Решение: `graphical.target` по умолчанию ([text-mode.md](text-mode.md))
- **Firmware**: требуется обновленный пакет linux-firmware с поддержкой gfx1151
- **ROCm 6.4.0**: установлен, KFD видит 120 GiB, но HIP-ядра падают с segfault на gfx1151
- **Vulkan**: основной рабочий backend (Mesa RADV, API 1.4.318, driver 25.2.8)

## Текущая конфигурация

Параметры ядра (`/etc/default/grub`):
```
GRUB_CMDLINE_LINUX_DEFAULT="amdgpu.gttsize=131072 amdgpu.vm_update_mode=3 amdgpu.dc=1 consoleblank=0 amdgpu.runpm=0 ttm.pages_limit=31457280"
```

| Параметр | Назначение |
|----------|------------|
| `amdgpu.gttsize=131072` | GTT 128 GiB |
| `amdgpu.vm_update_mode=3` | Page tables через CPU+SDMA |
| `amdgpu.dc=1` | Display Core включен |
| `consoleblank=0` | Запрет гашения консоли |
| `amdgpu.runpm=0` | Отключение runtime PM для GPU |
| `ttm.pages_limit=31457280` | TTM лимит 120 GiB (4K-страницы) |

Systemd default: `graphical.target` (GDM + Xorg, для инициализации дисплея).

Ядра:
- 6.19.8-061908-generic -- основное
- 6.18.18-061818-generic -- резервное

Доступ:
```bash
ssh -A -p <SSH_PORT> <user>@<host>
```

## Документация

| Документ | Содержание |
|----------|-----------|
| [processor.md](processor.md) | AMD Ryzen AI MAX+ 395: Zen 5, RDNA 3.5, XDNA 2 -- архитектура, бенчмарки, сравнение |
| [server-spec.md](server-spec.md) | Спецификация сервера: CPU, GPU, NPU, память, сеть, доступ |
| [gpu-kernel-setup.md](gpu-kernel-setup.md) | Настройка ядра и графики: параметры GRUB, DCN 3.5.1 workarounds, X11, диагностика |
| [bios-setup.md](bios-setup.md) | Настройка BIOS под инференс: UMA/VRAM, C-states, Resizable BAR, энергосбережение |
| [amdgpu-driver.md](amdgpu-driver.md) | Драйвер amdgpu: IP-блоки, firmware, sysfs-мониторинг, параметры модуля |
| [vram-allocation.md](vram-allocation.md) | Настройка VRAM до 120 GiB: BIOS, ядро, TTM, KFD, верификация |
| [text-mode.md](text-mode.md) | Переключение GUI/текстовый режим: проблема с дисплеем в text mode, решение |
| [amd-debug-tools.md](amd-debug-tools.md) | amd-debug-tools: amd-ttm, amd-bios, amd-pstate, amd-s2idle -- установка и использование |

## Рынок hardware

| Документ | Содержание |
|----------|-----------|
| [enterprise-inference.md](enterprise-inference.md) | Datacenter GPU: NVIDIA B200/H200/H100, AMD MI300X/MI325X/MI355X, cloud pricing $/hr |
| [hardware-alternatives.md](hardware-alternatives.md) | Consumer-альтернативы для локального inference: RTX 5090, Mac M4/M5, DGX Spark, M3 Ultra |

## Inference-стек

Руководства по настройке inference: [docs/inference/](../inference/README.md)
