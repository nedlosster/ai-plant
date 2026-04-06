# AMD Ryzen AI MAX+ 395 (Strix Halo)

APU, объединяющий CPU (Zen 5), GPU (RDNA 3.5) и NPU (XDNA 2) на одном кристалле. Техпроцесс TSMC 4nm FinFET.

## Общие характеристики

| Параметр | Значение |
|----------|---------|
| Кодовое имя | Strix Halo |
| Техпроцесс | TSMC N4 (4nm FinFET) |
| TDP | 55W (cTDP: 45--120W) |
| Сокет | FP11 (BGA, не сменный) |
| Память | 8-channel LPDDR5x-8000 (256-bit), макс. 128 GiB |
| Bandwidth | 256 GB/s (теор.), ~212 GB/s (измеренный пик) |
| PCIe | Gen4 x16 |

## CPU -- Zen 5

| Параметр | Значение |
|----------|---------|
| Ядра / потоки | 16 / 32 (SMT) |
| Base clock | 3.0 GHz |
| Boost clock | 5.1 GHz |
| IPC uplift vs Zen 4 | +16% |
| L1d / L1i | 48 KiB / 32 KiB на ядро (16 инстансов) |
| L2 | 1 MiB на ядро, 16-way (16 MiB total) |
| L3 | 64 MiB (2 CCX по 32 MiB) |
| ALU pipelines | 6 |
| Dispatch width | 8-wide |
| FP datapath | 256-bit (два микроопа на 512-bit AVX-512) |
| FADD latency | 2 цикла (vs 3 в Zen 4) |

### Архитектура Zen 5 vs Zen 4

Zen 5 -- значительная переработка микроархитектуры по сравнению с Zen 4:

**Front-end:**
- 8-wide dispatch (vs 6-wide в Zen 4) -- ~39% от общего IPC-прироста
- Dual-pipe fetch/decode
- Улучшенный branch predictor (TAGE-алгоритм): больше предсказаний за цикл

**Кэш:**
- L1 data: 48 KiB на ядро (vs 32 KiB в Zen 4), удвоенная пропускная способность (64B/clk)
- L2: 2x bandwidth на интерфейсе L2/core

**Execution:**
- 6 ALU pipelines
- FADD latency: 2 цикла (vs 3 в Zen 4)
- Нативный AVX-512 datapath (в Strix Halo -- 256-bit с двойной выдачей)

### Набор инструкций

| Категория | Инструкции |
|-----------|-----------|
| SIMD | AVX-512 (F, DQ, CD, BW, VL, IFMA, VBMI, VBMI2, VNNI, BITALG, VPOPCNTDQ, VP2INTERSECT, BF16), AVX2, FMA3 |
| Криптография | AES-NI, SHA |
| Виртуализация | AMD-V (SVM) |
| Совместимость | SSE 4.2/4.1/4a/3/2, MMX+ |

Для AI-инференса на CPU:
- **AVX-512 BF16** -- аппаратное ускорение bfloat16
- **AVX-512 VNNI** -- ускорение INT8 (квантизованные модели)

### Организация CCX

```
CCX 0 (32 MiB L3)           CCX 1 (32 MiB L3)
+------------------------+   +------------------------+
| Core 0  | Core 1  |...|   | Core 8  | Core 9  |...|
| Core 4  | Core 5  |...|   | Core 12 | Core 13 |...|
| 48K L1d | 48K L1d |   |   | 48K L1d | 48K L1d |   |
| 1M  L2  | 1M  L2  |   |   | 1M  L2  | 1M  L2  |   |
+------------------------+   +------------------------+
```

8 ядер на CCX, общий L3 32 MiB. Доступ к L3 своего CCX быстрее, чем к L3 соседнего.

## GPU -- Radeon 8060S (RDNA 3.5)

| Параметр | Значение |
|----------|---------|
| Архитектура | RDNA 3.5 |
| GPU ID | gfx1151 |
| Compute Units (CU) | 40 |
| Shader Processors | 2560 |
| TMUs | 160 |
| ROPs | 64 |
| Ray Tracing Units | 40 (1 на CU) |
| Boost clock | 2900 MHz |
| FP32 (теор.) | ~29.7 TFLOPS |
| FP16/BF16 WMMA (пик) | ~59.4 TFLOPS |
| Shader Engine | 2 (SE), 2 Shader Array на SE, 10 CU на SA |
| VGPR | 192 KiB на SIMD |

### RDNA 3.5 vs RDNA 3

- Scalar unit: добавлены FP-операции (в RDNA 3 -- только integer)
- VGPR: 192 KiB/SIMD (vs 128 KiB в базовых RDNA 3)
- Register cache hints (`s_singleuse_vdst`)
- Предварительные ISA-фичи RDNA 4 для ray tracing
- Тот же набор инструкций GFX11, совместимый с gfx1100 (Navi 31)

### Compute-конфигурация (из dmesg)

```
SE 2, SH per SE 2, CU per SH 10, active_cu_number 40
8 compute rings (comp_1.0.0 -- comp_1.3.1)
1 gfx ring, 1 sdma ring, 2 vcn rings, 2 jpeg rings
```

### Дисплейные выходы

DCN 3.5.1: до 9 дисплейных коннекторов (DP, HDMI). На данной платформе (MS-S1 MAX): 8x DP + 1x HDMI.

## NPU -- XDNA 2

| Параметр | Значение |
|----------|---------|
| Архитектура | XDNA 2 |
| AI Engine tiles | 32 |
| INT8 TOPS | 50 |
| INT4 TOPS | ~100 |
| PCI ID | 1022:17F0 |
| Драйвер Linux | amdxdna (mainline с ядра 6.14) |
| Устройство | /dev/accel0 |
| MAC на тайл | 2x vs XDNA 1 |
| On-chip memory | 1.6x больше на тайл vs XDNA 1 |

### Поддержка в Linux

Драйвер `amdxdna` включен в mainline ядро с версии 6.14. Программный стек: ONNX Runtime + Vitis AI EP, ROCm.

### Сравнение NPU

| NPU | Платформа | INT8 TOPS |
|-----|-----------|-----------|
| **AMD XDNA 2** | **Strix Halo** | **50** |
| Intel NPU 4 | Lunar Lake | 48 |
| Qualcomm Hexagon | Snapdragon X Elite | 45 |
| Apple Neural Engine | M4 | 38 |

## Unified Memory Architecture

CPU, GPU и NPU разделяют единый пул LPDDR5x-8000. Память распаяна на подложке (BGA, не заменяемая). Максимум контроллера -- 128 GiB (8 каналов x 2 ранка x 16Gbit чипы). Распределение между CPU и GPU задаётся в BIOS (UMA Frame Buffer Size).

| Конфигурация RAM | GPU VRAM (макс.) | RAM для CPU |
|-----------------|-----------------|-------------|
| 32 GiB | 24 GiB | ~8 GiB |
| 64 GiB | 48 GiB | ~16 GiB |
| 128 GiB | 96 GiB | ~32 GiB |

Текущая конфигурация: 128 GiB total, 96 GiB GPU VRAM, ~31 GiB CPU RAM.

### Преимущества unified memory для инференса

- Нет PCIe-трансфера между CPU и GPU: данные доступны обоим без копирования
- До 96 GiB VRAM: загрузка моделей 70B+ без квантизации до Q2/Q3
- Переключение между CPU и GPU inference без перемещения весов

### Ограничения

- Bandwidth 256 GB/s (пик ~212 GB/s) -- делится между CPU и GPU
- Для сравнения: RTX 4090 имеет 1008 GB/s, Apple M4 Max -- 546 GB/s
- Token generation (memory-bound) в 2--4x медленнее при том же объеме модели

## Бенчмарки CPU

### Cinebench R23

| Процессор | Single-core | Multi-core |
|-----------|------------|------------|
| **Ryzen AI MAX+ 395** | **~2034** | **~33,960** |
| Ryzen 9 7945HX (16C, Zen 4) | ~1930 | ~33,000 |
| Core i9-14900HX (24C) | ~2050 | ~29,000 |
| Apple M4 Max (16C) | ~2150 | ~27,000 |
| Ryzen 9 9950X (16C, Zen 5, desktop) | ~2200 | ~39,000 |

### Cinebench 2024

| Процессор | Single-core | Multi-core |
|-----------|------------|------------|
| **Ryzen AI MAX+ 395** | **~116** | **~1,791** |
| Ryzen 9 7945HX | ~113 | ~1,739 |
| Core i9-14900HX | ~110 | ~1,544 |

### Geekbench 6

| Процессор | Single-core | Multi-core |
|-----------|------------|------------|
| **Ryzen AI MAX+ 395** | **~3,040** | **~22,125** |
| Apple M4 Max (16C) | ~3,800 | ~25,000 |
| Ryzen 9 7945HX | ~2,800 | ~20,500 |
| Core i9-14900HX | ~2,900 | ~18,500 |

### Вывод по CPU

- Multi-core: на уровне Ryzen 9 7945HX, +16% IPC vs Zen 4 компенсирует более низкие частоты мобильного TDP
- Single-core: уступает M4 Max (~20%) и desktop Zen 5 (~8%) из-за ограничений TDP 55W
- При увеличении cTDP до 120W -- приближается к desktop-показателям

## Бенчмарки GPU

### 3DMark Time Spy

| GPU | Score |
|-----|-------|
| **Radeon 8060S** | **~10,100--11,250** |
| RTX 4060 Laptop (100W) | ~10,000--11,000 |
| RTX 4070 Laptop (115W) | ~13,000--14,000 |
| RX 7600 (desktop) | ~12,000 |
| Apple M4 Max (40C GPU) | ~13,500 (Metal, не 3DMark) |

### Теоретический compute

| GPU | FP32 TFLOPS | Bandwidth |
|-----|-------------|-----------|
| **Radeon 8060S** | **~29.7** | **256 GB/s (shared)** |
| RTX 4060 Laptop | ~15.1 | 256 GB/s (dedicated GDDR6) |
| RTX 4070 Desktop | ~29.1 | 504 GB/s |
| RTX 4090 Desktop | ~82.6 | 1,008 GB/s |
| Apple M4 Max (40C) | ~17.8 | 546 GB/s |

FP32 TFLOPS у 8060S выше RTX 4060 Laptop, но bandwidth делится с CPU. Реальная gaming/compute производительность -- на уровне RTX 4060 Laptop.

## Бенчмарки AI / LLM Inference

### llama.cpp (Vulkan)

| Модель | Квантизация | tok/s (tg) |
|--------|------------|------------|
| Llama 2 7B | Q4_K_M | ~48 |
| Shisa V2 8B | Q4_K_M | ~42 |
| Qwen 3 30B-A3B (MoE) | Q4 | ~72 |
| DeepSeek R1 70B | Q8_0 | ~3 |
| DeepSeek R1 70B | Q4_K_M | ~5 |

### Сравнение по LLM inference (70B модели)

| Платформа | VRAM | Bandwidth | 70B Q4 tok/s | 70B Q8 tok/s |
|-----------|------|-----------|-------------|-------------|
| **Ryzen AI MAX+ 395** | **96 GiB** | **212 GB/s** | **~5** | **~3** |
| Apple M4 Max (128 GB) | 128 GiB | 546 GB/s | ~10 | ~6 |
| RTX 4090 (24 GB) | 24 GiB | 1,008 GB/s | ~18 | не помещается |
| 2x RTX 4090 (48 GB) | 48 GiB | 2,016 GB/s | ~30 | ~18 |

### Ключевые наблюдения

1. **70B помещается целиком** -- основное преимущество. RTX 4090 не может загрузить 70B Q8 (70 GiB > 24 GiB VRAM)
2. **Bandwidth -- узкое место**: tg скорость пропорциональна bandwidth. M4 Max в ~2.5x быстрее из-за 546 vs 212 GB/s
3. **MoE-модели**: высокая скорость (Qwen 3 30B-A3B дает ~72 tok/s), т.к. активны только 3B параметров
4. **7B--13B модели**: практически интерактивная скорость (40+ tok/s)

### Stable Diffusion

По данным AMD:
- SD 3.5: до 3.9x быстрее Apple M4 Pro
- Video diffusion: 3.3--3.5x быстрее M4 Pro
- Сопоставимо с RTX 4090 на video generation за счет объема VRAM

## Позиционирование

### vs Apple M4 Max

| Критерий | Ryzen AI MAX+ 395 | Apple M4 Max |
|----------|-------------------|-------------|
| CPU SC | ~3,040 (GB6) | ~3,800 (GB6) |
| CPU MC | ~22,125 (GB6) | ~25,000 (GB6) |
| GPU (gaming) | ~RTX 4060 Laptop | ~RTX 4070 Laptop |
| Memory BW | 212 GB/s | 546 GB/s |
| Max VRAM | 96 GiB | 128 GiB |
| LLM 70B Q4 | ~5 tok/s | ~10 tok/s |
| NPU | 50 TOPS | 38 TOPS |
| ОС | Linux / Windows | macOS |
| Цена (mini-PC) | ~$1,500--2,500 | ~$3,499+ (MacBook Pro) |
| TDP (SoC) | 55--120W | 40--70W |

M4 Max быстрее в абсолютных числах (bandwidth), но Strix Halo дешевле и работает с Linux/ROCm-экосистемой.

### vs NVIDIA RTX 4090 Desktop

| Критерий | Ryzen AI MAX+ 395 | RTX 4090 Desktop |
|----------|-------------------|-----------------|
| VRAM | 96 GiB (unified) | 24 GiB (dedicated) |
| Bandwidth | 212 GB/s | 1,008 GB/s |
| FP32 | ~29.7 TFLOPS | ~82.6 TFLOPS |
| 70B Q4 | ~5 tok/s | ~18 tok/s |
| 70B Q8 | ~3 tok/s | не помещается |
| TDP (system) | ~100W | ~600W+ (system) |
| Цена | ~$1,500--2,500 | ~$2,600+ (GPU + system) |

RTX 4090 -- в 3--4x быстрее по tok/s, но ограничен 24 GiB VRAM. Для моделей >24 GiB -- Strix Halo единственный вариант в данном ценовом диапазоне.

### Уникальная ниша

1. **96 GiB unified VRAM на x86** -- единственный чип для 70B+ LLM без multi-GPU
2. **$1,500--2,500 за mini-PC** -- дешевле любого решения с сопоставимым объемом VRAM
3. **SoC 55--120W** -- работает в компактном корпусе без внешнего GPU
4. **Полный x86 + Linux** -- совместимость с существующим AI-стеком (PyTorch, llama.cpp, ComfyUI)

## Связанные статьи

- [Спецификация сервера](server-spec.md)
- [Настройка BIOS](bios-setup.md)
- [Настройка ядра](gpu-kernel-setup.md)
- [Драйвер amdgpu](amdgpu-driver.md)
