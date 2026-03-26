# Настройка BIOS для Meigao MS-S1 MAX (Strix Halo) под инференс

Платформа: Meigao MS-S1 MAX (плата SHWSA v1.0), AMI BIOS v1.06, AMD Ryzen AI MAX+ 395.

Настройки BIOS меняются только через интерфейс BIOS при загрузке (Del / F2). Часть параметров можно компенсировать из ОС через параметры ядра и systemd.

## Текущее состояние

Снято из ОС 2026-03-26:

| Параметр | Текущее значение | Оптимальное | Статус |
|----------|-----------------|-------------|--------|
| VRAM (UMA) | 96 GiB | 96 GiB | ok |
| LPDDR5 Speed | 8000 MT/s | 8000 MT/s | ok |
| IOMMU | включен | включен | ok |
| Secure Boot | отключен | отключен | ok |
| SMT | включен | включен | ok |
| Core Performance Boost | включен | включен | ok |
| BAR0 (GPU) | 64 GiB | 64 GiB (максимум платформы) | ok |
| C-states | отключены (cpuidle: none) | отключены | ok |
| CPU Governor | performance | performance | ok (systemd unit) |

## Распределение памяти (UMA / VRAM)

Ключевая настройка для инференса. Ryzen AI MAX+ 395 использует unified memory -- единый пул LPDDR5 для CPU и GPU. В BIOS задается, сколько памяти выделяется под GPU (VRAM).

### Расположение в BIOS

```
Advanced -> AMD CBS -> NBIO Common Options -> GFX Configuration
  -> UMA Frame Buffer Size
```

| Значение UMA | VRAM для GPU | RAM для CPU (из 128 GiB) | Назначение |
|--------------|-------------|--------------------------|------------|
| Auto | ~16 GiB | ~112 GiB | по умолчанию, мало для LLM |
| 32G | 32 GiB | 96 GiB | легкие модели |
| 64G | 64 GiB | 64 GiB | баланс |
| **96G** | **96 GiB** | **32 GiB** | **инференс больших моделей (установлено)** |
| 128G | 128 GiB | минимум | максимум VRAM, мало RAM для CPU |

96 GiB -- достаточно для загрузки моделей 70B в Q4_K_M (~40 GiB) или нескольких моделей 7B--13B одновременно. CPU остается ~31 GiB для системы, препроцессинга и KV-cache.

### Проверка из ОС

```bash
# VRAM (в байтах)
cat /sys/class/drm/card1/device/mem_info_vram_total
# 103079215104 = 96 GiB

# Из журнала ядра
journalctl -b 0 -k | grep 'VRAM:'
# amdgpu: VRAM: 98304M (98304M used)

# RAM для CPU
grep MemTotal /proc/meminfo
# MemTotal: 32485244 kB (~31 GiB)
```

## Выполненные настройки BIOS

### C-states -- отключены

```
Advanced -> AMD CBS -> CPU Common Options
  -> Global C-state Control: Disabled
```

Отключение C-states снижает латентность при инференсе -- CPU не уходит в глубокий сон между batch-обработкой. cpuidle driver: `none`.

### BAR0 (GPU) -- 64 GiB

BAR0 = 64 GiB -- максимум для данной платформы. Above 4G Decoding включен. При 96 GiB VRAM часть адресуется через GTT.

### CPU Performance Boost -- включен

```
Advanced -> AMD CBS -> CPU Common Options
  -> Core Performance Boost: Enabled
```

Boost до 5187 MHz.

## Настройки, не требующие изменений

### IOMMU -- включен

```
Advanced -> AMD CBS -> NBIO Common Options
  -> IOMMU: Enabled
```

Нужен для корректной работы ROCm и возможной GPU-виртуализации.

### Secure Boot -- отключен

```
Security -> Secure Boot
  -> Secure Boot: Disabled
```

Отключен для совместимости с mainline-ядрами и DKMS-модулями (ROCm). Mainline-ядра с kernel.ubuntu.com подписаны, но сторонние модули -- нет.

### Память -- 8000 MT/s

```
Advanced -> AMD CBS -> UMC Common Options -> DDR5 Common Options
  -> LPDDR5 Speed: 8000 MT/s
```

Максимальная скорость для установленных модулей Micron MT62F4G32D8DV-023 WT. 8 каналов, 256-bit шина, теоретический bandwidth 256 GB/s.

Дополнительно можно проверить:
- `Power Down Enable: Disabled` -- убирает задержки при выходе памяти из энергосберегающего режима

## Компенсация из ОС

Параметры, которые можно настроить без входа в BIOS.

### CPU Governor -> performance (установлено)

Systemd unit `/etc/systemd/system/cpu-performance.service` устанавливает governor `performance` при загрузке:

```ini
[Unit]
Description=Set CPU governor to performance
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > $g; done'

[Install]
WantedBy=multi-user.target
```

C-states отключены в BIOS, дополнительных параметров ядра не требуется.

### Transparent HugePages

Текущее: `madvise` (включены по запросу приложения). Для инференса с большими буферами памяти можно включить глобально:

```bash
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
```

## Энергосбережение / производительность (BIOS)

### Максимальная производительность (inference server)

```
Advanced -> AMD CBS -> SMU Common Options
  -> Determinism Control: Manual
  -> Determinism Slider: Performance
  -> cTDP Control: Manual
  -> cTDP: 120W (или максимум платформы)
```

### Тихий / сбалансированный режим

В BIOS: оставить все в Auto. BIOS динамически управляет частотами и потреблением.

Если в BIOS есть настройки вентиляторов:
```
Advanced -> Hardware Monitor -> Fan Control
  -> CPU Fan Mode: Silent / Low Speed
  -> System Fan Mode: Silent
```

Или через SMU:
```
Advanced -> AMD CBS -> SMU Common Options
  -> Fan Control Policy: Silent
  -> cTDP Control: Manual
  -> cTDP: 45W (минимальный TDP платформы)
```

### Снижение шума из ОС (без BIOS)

Вентиляторы Meigao MS-S1 MAX управляются через EC (Embedded Controller) -- прямого доступа из ОС нет (`pwm*`, `fan*_input` отсутствуют в sysfs). Снижение шума -- только через уменьшение тепловыделения.

```bash
# --- Тихий ночной режим ---

# CPU: powersave (динамическая частота, снижение до 625 MHz в idle)
for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo powersave | sudo tee "$g" > /dev/null
done

# GPU: автоматическое управление (снижение частот в idle)
echo auto | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level > /dev/null

# GPU: принудительно низкая частота (минимум)
echo low | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level > /dev/null

# Остановить inference-серверы (если не нужны)
pkill llama-server 2>/dev/null

# Проверка: потребление должно упасть до ~15-20W, температура до ~30C
echo "CPU: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "GPU: $(cat /sys/class/drm/card1/device/power_dpm_force_performance_level)"
echo "Temp: $(($(cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input) / 1000))C"
echo "Power: $(($(cat /sys/class/drm/card1/device/hwmon/hwmon*/power1_average) / 1000000))W"
```

```bash
# --- Возврат в рабочий режим ---

for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance | sudo tee "$g" > /dev/null
done
echo auto | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level > /dev/null
```

При снижении потребления до 15-20W вентиляторы работают на минимальных оборотах или останавливаются (зависит от кривой EC в BIOS).

Из ОС (без перезагрузки в BIOS):

```bash
# Переключить governor на powersave (динамическое управление частотой)
for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo powersave | sudo tee "$g" > /dev/null
done

# Включить автоматическое управление частотой GPU
echo auto | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level

# Проверка
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/class/drm/card1/device/power_dpm_force_performance_level
```

Для возврата в режим производительности:

```bash
# CPU: performance
for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance | sudo tee "$g" > /dev/null
done

# GPU: высокая частота
echo high | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level
```

## Обновление BIOS

Текущая версия: AMI 1.06 (04.01.2026).

```bash
sudo dmidecode -t bios | grep -E 'Version|Release Date'
```

Проверять обновления на сайте Meigao / Minisforum (OEM MS-S1 MAX). Обновление может исправить:
- Баги ACPI (текущий: `Could not resolve symbol \_SB.PCI0.GPP9.DEV0`)
- Проблемы USB (текущий: `usb 5-4: device descriptor read/64, error -71`)
- Стабильность unified memory
- Ограничение BAR на 64 GiB

## Контрольный список

Настройки BIOS:
- [x] UMA Frame Buffer Size: 96G
- [x] Core Performance Boost: Enabled
- [x] Global C-state Control: Disabled
- [x] LPDDR5 Speed: 8000 MT/s
- [x] Above 4G Decoding: Enabled
- [x] IOMMU: Enabled
- [x] Secure Boot: Disabled

Настройки ОС:
- [x] CPU Governor: performance (systemd unit)
- [ ] Transparent HugePages: always (опционально)

## Связанные статьи

- [Процессор](processor.md)
- [Спецификация сервера](server-spec.md)
- [Настройка ядра](gpu-kernel-setup.md)
