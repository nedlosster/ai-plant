# ai-server -- inference-сервер

## Общие сведения

| Параметр | Значение |
|----------|----------|
| Hostname | ai-server |
| IP | <SERVER_IP> (Wi-Fi, wlp98s0) |
| Доступ | `ssh -p <SSH_PORT> <user>@<host>` (тунель через KVM) |
| ОС | Ubuntu 24.04.4 LTS (Noble Numbat) |
| Ядро | 6.19.8-061908-generic (PREEMPT_DYNAMIC) |
| linux-firmware | 20250901.git993ff19b-0ubuntu1 |
| Корпус/платформа | Meigao MS-S1 MAX |
| Материнская плата | Meigao SHWSA v1.0 |
| BIOS | AMI 1.06 (04.01.2026) |

## Процессор

| Параметр | Значение |
|----------|----------|
| Модель | AMD Ryzen AI MAX+ 395 w/ Radeon 8060S |
| Кодовое имя | Strix Halo |
| Архитектура | Zen 5, x86_64, семейство 26, модель 112, степпинг 0 |
| Ядра / потоки | 16 ядер / 32 потока (SMT) |
| Сокеты | 1 |
| NUMA-узлы | 1 |
| Частота (base / max) | 625 MHz -- 5187.5 MHz |
| TDP | до 120W (настраивается через cTDP в BIOS) |
| Turbo Boost | включен (Core Performance Boost) |
| Governor | powersave |
| Microcode | 0xb700034 |
| BogoMIPS | 5989.01 |

### Кэш-иерархия

| Уровень | Объем | Инстансы | Примечание |
|---------|-------|----------|------------|
| L1d | 768 KiB | 16 | 48 KiB на ядро, 12-way set associative |
| L1i | 512 KiB | 16 | 32 KiB на ядро, 8-way set associative |
| L2 | 16 MiB | 16 | 1 MiB на ядро, unified |
| L3 | 64 MiB | 2 | 32 MiB на CCX, shared между ядрами |

L3-кэш разделен на два кластера (CCX) по 32 MiB. При инференсе на CPU критична локальность данных внутри одного CCX для минимизации задержек cross-CCX доступа.

### Набор инструкций

AVX-512 (F, DQ, CD, BW, VL, IFMA, VBMI, VBMI2, VNNI, BITALG, VPOPCNTDQ, VP2INTERSECT, BF16), AVX2, AVX_VNNI, FMA, AES, SHA, SSE4.1/4.2, SSSE3, SMT, AMD-V (SVM).

Для инференса на CPU значимы:
- **AVX-512 BF16** -- аппаратное ускорение bfloat16, ключевой формат для LLM-инференса
- **AVX-512 VNNI** -- ускорение INT8-операций (квантизованные модели)
- **AVX_VNNI** -- 256-bit вариант VNNI для задач, где AVX-512 вызывает throttling

## Встроенный GPU -- Radeon 8060S

| Параметр | Значение |
|----------|----------|
| PCI ID | AMD/ATI Device 1586 (rev c1) |
| PCI адрес | bc:00.0 |
| Тип | Display controller |
| Видеопамять (BAR) | 64 GiB (prefetchable) |
| Драйвер ядра | amdgpu (модуль загружен) |
| ROCm / OpenCL | не установлен |

Radeon 8060S -- интегрированный GPU на архитектуре RDNA 3.5 с 40 CU. Использует единый пул памяти (unified memory) с CPU. BAR 64 GiB отражает доступное адресное пространство shared memory.

## NPU -- AMD XDNA

| Параметр | Значение |
|----------|----------|
| PCI ID | 1022:17F0 |
| PCI адрес | bd:00.1 |
| Драйвер | amdxdna (модуль загружен) |
| Устройство | /dev/accel0 |

NPU на архитектуре XDNA 2 (Strix Halo). 50 TOPS INT8. Поддерживается через ONNX Runtime + Vitis AI EP.

## Память

### Физическая конфигурация

| Параметр | Значение |
|----------|----------|
| Полный объем | 128 GiB |
| Тип | LPDDR5 |
| Скорость | 8000 MT/s |
| Напряжение | 0.5V |
| Шина | 256 bit |
| Каналы | 8 (A--H) |
| Модулей на канал | 1 |
| Модуль | Micron MT62F4G32D8DV-023 WT, 16 GiB |
| ECC | нет |
| Производитель | Micron Technology |

### Пропускная способность

Теоретический максимум: 8000 MT/s x 256 bit / 8 = **256 GB/s**.

Для сравнения:
- NVIDIA RTX 4090 (GDDR6X): 1008 GB/s
- AMD Instinct MI300X (HBM3): 5300 GB/s
- Apple M2 Ultra (LPDDR5): 800 GB/s

256 GB/s -- ограничение для token/s при инференсе больших моделей, т.к. LLM-инференс упирается в memory bandwidth при генерации (memory-bound фаза).

### Распределение unified memory

Ryzen AI MAX+ 395 использует unified memory -- единый пул LPDDR5 для CPU и GPU. Распределение задается в BIOS (UMA Frame Buffer Size).

Текущая конфигурация:

| Назначение | Объем |
|-----------|-------|
| VRAM (GPU) | 96 GiB (98304 MiB) |
| RAM (CPU) | ~31 GiB |
| Подкачка (swap) | 8 GiB |

```
# Проверка распределения
cat /sys/class/drm/card1/device/mem_info_vram_total   # 103079215104 (96 GiB)
grep MemTotal /proc/meminfo                             # 32485244 kB (~31 GiB)
```

### GTT и TTM

| Параметр | Значение |
|----------|----------|
| GTT | 128 GiB (`amdgpu.gttsize=131072`) |
| TTM pages_limit | 120 GiB (`ttm.pages_limit=31457280`) |
| KFD GPU heap | 120 GiB |

GTT -- область системной памяти, доступная GPU через GART. TTM pages_limit снимает ограничение KFD firmware (по умолчанию 15.5 GiB). Подробности: [vram-allocation.md](vram-allocation.md).

### Рекомендации для инференса

- **120 GiB GPU-доступной памяти** (carved-out 96 GiB + GTT) -- MoE 122B в Q4_K_M (71 GiB) помещается полностью
- **Swap 8 GiB** -- минимум, рекомендуется увеличить при работе с препроцессингом данных на CPU
- Unified memory исключает PCIe-трансфер, bandwidth 256 GB/s (LPDDR5 8000 MT/s)

## Хранилище

| Параметр | Значение |
|----------|----------|
| Диск | Crucial CT2000P310SSD8 (NVMe) |
| Объём | 1.8 TiB |
| Разделы | EFI (1 GiB) + root (1.8 TiB) |

## Сеть

| Интерфейс | Состояние | IP |
|-----------|-----------|-----|
| wlp98s0 (Wi-Fi) | UP | <SERVER_IP>/24 |
| enp97s0 (Ethernet) | DOWN | -- |
| lo | UNKNOWN | 127.0.0.1/8 |

## Доступ

```bash
# Прямой доступ через тунель KVM
ssh -p <SSH_PORT> <user>@<host>

# Альтернативный доступ: KVM -> AI-сервер
ssh -p <KVM_PORT> <kvm_host>
ssh <user>@<SERVER_IP>
```

Тунель настроен в auto-ssh-tunnels на KVM: `-R 127.0.0.1:<SSH_PORT>:<SERVER_IP>:22`.

## Статус ПО для инференса

| Компонент | Версия | Статус |
|-----------|--------|--------|
| amdgpu (драйвер) | ядро 6.19.8 | загружен, gfx1151 |
| amdxdna (NPU) | ядро 6.19.8 | загружен |
| ROCm | 6.4.0-47 | установлен, segfault на gfx1151 при инференсе |
| Vulkan (Mesa RADV) | API 1.4.318, driver 25.2.8 | работает, основной backend |
| llama.cpp | b8541 (Vulkan) | собран, рабочий |

ROCm установлен, но HIP-ядра падают с segfault на gfx1151 ([подробности](../inference/rocm-setup.md#статус-gfx1151-strix-halo)). Vulkan -- рабочий backend для инференса.

## Связанные статьи

- [Процессор](processor.md)
- [Настройка BIOS](bios-setup.md)
- [Настройка ядра](gpu-kernel-setup.md)
