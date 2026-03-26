# Настройка VRAM: выделение 120 GiB для GPU

Strix Halo (Ryzen AI MAX+ 395) использует unified memory -- CPU и GPU делят одну LPDDR5. По умолчанию Linux/ROCm видит только ~15.5 GiB GPU VRAM из 96 GiB. Эта статья описывает как выделить 120 GiB для GPU.

## Архитектура памяти Strix Halo

```
LPDDR5 (128 GiB физически, 96 GiB доступно)
    |
    +-- Carved-out VRAM (BIOS UMA) -- 512 MiB - 96 GiB
    |   Фиксированная область, зарезервированная в BIOS.
    |   Всегда доступна GPU. Не используется CPU.
    |
    +-- GTT (Graphics Translation Table) -- динамическая
    |   Системная RAM, доступная GPU через page tables.
    |   Размер задаётся параметром ядра amdgpu.gttsize.
    |
    +-- System RAM (MemTotal) -- остаток
        Доступна CPU. Размер = физическая RAM - carved-out.
```

На Strix Halo carved-out и GTT -- **физически одна и та же LPDDR5**. Разницы в скорости нет. Разница в том, как memory manager (TTM) ими управляет.

## Статус (2026-03-27)

Проблема с ограничением 15.5 GiB решена через `ttm.pages_limit=31457280` в параметрах ядра.

| Уровень | VRAM видимый | Статус |
|---------|-------------|--------|
| BIOS (UMA) | 96 GiB | ok |
| amdgpu driver (sysfs) | 96 GiB | ok |
| Vulkan (Mesa RADV) | 96 GiB | ok |
| KFD topology (ROCm) | **120 GiB** | ok (было 15.5 GiB) |
| TTM pages_limit | **120 GiB** | ok (было 15.5 GiB) |
| GTT | 128 GiB | ok |

### Предыдущая проблема (решена)

KFD (Kernel Fusion Driver) брал размер GPU heap из IP Discovery firmware-таблицы, которая для APU указывала только carved-out сегмент (~15.5 GiB). Параметр `ttm.pages_limit=31457280` (120 GiB в 4K-страницах) снимает это ограничение.

## Решение: BIOS + ядро + TTM

### Шаг 1: BIOS -- минимальный carved-out

UMA Frame Buffer Size в BIOS определяет carved-out VRAM. Для Strix Halo рекомендуется **минимальное значение** (512 MiB или Auto):

```
BIOS → Advanced → Integrated Graphics:
  UMA Frame Buffer Size: 512 MB (или Auto)
  Resizable BAR: Enabled
```

Почему минимум: carved-out память недоступна для CPU. На unified memory нет разницы в скорости -- GPU может использовать GTT с той же пропускной способностью. Большой carved-out просто уменьшает RAM для системы.

Текущая настройка (96 GiB carved-out): оставляет только ~32 GiB для CPU. При 512 MiB carved-out -- ~95.5 GiB доступно для распределения между CPU и GPU.

### Шаг 2: Kernel параметры

Основные параметры для увеличения GPU-доступной памяти:

| Параметр | Описание | Рекомендация |
|----------|----------|-------------|
| `amdgpu.gttsize=N` | GTT размер в MiB | 131072 (128 GiB) |
| `ttm.pages_limit=N` | TTM лимит в 4K-страницах | 31457280 (120 GiB) |
| `iommu=pt` | IOMMU pass-through | Улучшает доступ к памяти |
| `amdgpu.vm_update_mode=3` | Page table updates через CPU+SDMA | Стабильность |
| `amdgpu.dc=1` | Display Core | Требуется для вывода |

Расчёт `ttm.pages_limit`:
```
pages = GiB * 1024 * 1024 * 1024 / 4096
120 GiB = 120 * 1073741824 / 4096 = 31457280 страниц
```

### Шаг 3: Применение

```bash
# Редактирование GRUB
sudo nano /etc/default/grub

# Заменить строку GRUB_CMDLINE_LINUX_DEFAULT:
GRUB_CMDLINE_LINUX_DEFAULT="amdgpu.gttsize=131072 amdgpu.vm_update_mode=3 amdgpu.dc=1 consoleblank=0 amdgpu.runpm=0 ttm.pages_limit=31457280"
```

```bash
# Применение
sudo update-grub
sudo reboot
```

### Шаг 4: Верификация

После перезагрузки:

```bash
# 1. Параметры ядра применены
cat /proc/cmdline | tr ' ' '\n' | grep -E 'amdgpu|ttm|iommu'

# 2. TTM pages_limit
cat /sys/module/ttm/parameters/pages_limit
# Ожидание: 31457280

# 3. GTT размер из dmesg
sudo dmesg | grep -i 'gtt.*memory'
# Ожидание: amdgpu: 122880M of GTT memory ready

# 4. VRAM через sysfs
cat /sys/class/drm/card1/device/mem_info_vram_total | awk '{printf "VRAM total: %.1f GiB\n", $1/1073741824}'

# 5. Системная RAM
grep MemTotal /proc/meminfo
# При BIOS UMA=512MB: ~95.5 GiB
# При BIOS UMA=96GB: ~32 GiB

# 6. KFD topology (ROCm)
cat /sys/class/kfd/kfd/topology/nodes/1/mem_banks/0/properties
# Проверить size_in_bytes

# 7. PyTorch ROCm
export HSA_OVERRIDE_GFX_VERSION=11.5.0
python3 -c "import torch; free, total = torch.cuda.mem_get_info(0); print(f'GPU: {total/1073741824:.1f} GiB')"
```

## Утилита amd-ttm

AMD предоставляет утилиту `amd-ttm` для автоматической конфигурации:

```bash
# Установка
pip install amd-debug-tools

# Просмотр текущих значений
amd-ttm

# Установка 120 GiB
sudo amd-ttm --set 120

# Сохраняется в /etc/modprobe.d/ttm.conf
# Требует перезагрузки
```

## Баланс памяти

Физическая LPDDR5 делится между CPU (MemTotal) и GPU (carved-out VRAM):

| Конфигурация | CPU (MemTotal) | GPU (carved-out) | GTT (динамический) |
|-------------|---------------|-------------------|---------------------|
| BIOS 96 GiB (текущая) | ~32 GiB | 96 GiB | зависит от gttsize |
| BIOS 512 MiB | ~95.5 GiB | 512 MiB | до 120 GiB |
| BIOS Auto | ~64 GiB (зависит от прошивки) | ~32 GiB | до 120 GiB |

Для inference рекомендуется:
- BIOS UMA: **512 MiB** (минимум для framebuffer)
- GTT: **120 GiB** (через amdgpu.gttsize + ttm.pages_limit)
- CPU RAM: ~95.5 GiB (хватает для системы + CPU offload)

GPU использует GTT для больших моделей. Скорость GTT = скорость carved-out (одна физическая LPDDR5, 256 GB/s).

## Важные замечания

### Ядро 6.18.4+

Для корректной работы VRAM на Strix Halo требуется ядро **6.18.4+** (или 6.19.x). Более ранние версии имеют баги в KFD для gfx1151.

Текущее ядро: 6.19.8 -- подходит.

### KFD и ROCm

Даже после увеличения TTM pages_limit KFD topology может показывать carved-out размер (из firmware). ROCm видит GPU VRAM = carved-out, а GTT -- как отдельный pool. Для приложений (PyTorch, ACE-Step) значение имеет `torch.cuda.mem_get_info()` и реальная возможность аллокации.

Проверка реальной аллокации:
```bash
python3 -c "
import torch
sizes = [10, 20, 40, 60, 80, 100, 120]
for gb in sizes:
    try:
        x = torch.empty(int(gb * 1024**3 / 4), dtype=torch.float32, device='cuda')
        print(f'{gb} GiB: OK')
        del x; torch.cuda.empty_cache()
    except:
        print(f'{gb} GiB: FAIL')
        break
"
```

### uv run сбрасывает ROCm torch

`uv run` пересинхронизирует зависимости и заменяет ROCm torch на CPU-версию. После настройки VRAM -- использовать `.venv/bin/python`, не `uv run`.

## Ссылки

- AMD Strix Halo optimization: https://rocm.docs.amd.com/en/latest/how-to/system-optimization/strixhalo.html
- ROCm VRAM issue: https://github.com/ROCm/ROCm/issues/5444
- Framework Strix Halo LLM setup: https://github.com/Gygeek/Framework-strix-halo-llm-setup
- amd-debug-tools (amd-ttm): https://github.com/superm1/amd-debug-tools
- Strix Halo unified memory setup: https://dev.webonomic.nl/setting-up-unified-memory-for-strix-halo-correctly-on-ubuntu-25-04-or-25-10/

## Связанные статьи

- [Текстовый режим](text-mode.md) -- отключение GUI для освобождения VRAM
- [Настройка ядра](gpu-kernel-setup.md) -- установка mainline ядра
- [BIOS](bios-setup.md) -- настройка UMA
- [ROCm setup](../inference/rocm-setup.md) -- статус gfx1151
