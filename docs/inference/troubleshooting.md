# Диагностика и решение проблем inference-стека

Платформа: Radeon 8060S (gfx1151), Vulkan 1.4.318 (RADV, driver 25.2.8), Ubuntu 24.04.4.

## Общие проверки

```bash
# GPU определяется системой
lspci | grep -i 'display\|vga'
# bc:00.0 Display controller: AMD/ATI Device 1586

# Драйвер amdgpu загружен
lsmod | grep amdgpu

# VRAM доступна
cat /sys/class/drm/card1/device/mem_info_vram_total
# 103079215104 (96 GiB)

# Устройства DRM
ls -la /dev/dri/
# card1, renderD128

# Vulkan
vulkaninfo --summary 2>&1 | grep deviceName
```

## Vulkan

### "No Vulkan devices found" / "Failed to create Vulkan instance"

Причина: Mesa Vulkan-драйвер не установлен или не видит GPU.

```bash
# Установка драйвера
sudo apt install mesa-vulkan-drivers

# Проверка
vulkaninfo --summary
```

### "Could NOT find Vulkan (missing: glslc)" при сборке

Причина: не установлен Vulkan shader compiler.

```bash
sudo apt install glslc
```

### "Permission denied" на /dev/dri/renderD128

Причина: пользователь не в группах `video` и `render`.

```bash
sudo usermod -aG video,render $USER
# Перелогиниться или использовать sg:
sg render -c 'vulkaninfo --summary'

# Проверка
groups | grep render
```

### Vulkan видит устройство, но llama.cpp не использует GPU

```bash
# Отладка
GGML_VK_DEBUG=1 ./build/bin/llama-cli -m model.gguf -ngl 99 -p "test" -n 10

# Проверить что -ngl > 0
# Проверить что сборка с -DGGML_VULKAN=ON
```

### Низкая производительность Vulkan

- `-ngl` слишком мало: не все слои на GPU
- Контекст слишком большой: `-c` потребляет VRAM, GPU swap на CPU
- Governor не `performance`: `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`
- Thermal throttling: `cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input`

## ROCm

### "GPU not supported" в rocminfo

Причина: HSA_OVERRIDE_GFX_VERSION не установлена.

```bash
export HSA_OVERRIDE_GFX_VERSION=11.5.1
rocminfo | grep gfx
```

### "hipErrorNoBinaryForGpu"

Причина: AMDGPU_TARGETS при сборке не совпадает с GPU target.

```bash
# ROCm 7.2.1 -- нативный gfx1151:
cmake -B build -DGGML_HIP=ON -DAMDGPU_TARGETS="gfx1151"
```

### Segfault при генерации (ROCm)

Причина: устаревшая версия ROCm (6.x) с ISA-несовместимостью.

- Обновить ROCm до 7.2.1+ (segfault устранён в ROCm 7.x, [ROCm#5853](https://github.com/ROCm/ROCm/issues/5853))
- Проверить HSA_OVERRIDE_GFX_VERSION=11.5.1
- Пересобрать llama.cpp с `-DAMDGPU_TARGETS="gfx1151"`

### "Could not load ROCm library"

```bash
export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH
export PATH=/opt/rocm/bin:$PATH
```

## Память

### OOM (Out of Memory)

Модель + KV-cache превышает доступный VRAM.

```bash
# Расчет
# model_size + KV_cache + overhead < 120 GiB (GPU-доступная память)

# Пример: 70B Q4_K_M (40 GiB) + ctx 32768 (20 GiB) + overhead (1 GiB) = 61 GiB -- помещается
# 70B Q8_0 (70 GiB) + ctx 32768 (20 GiB) = 90 GiB -- на пределе
```

Решения:
- Уменьшить контекст (`-c 4096` вместо `-c 32768`)
- Использовать меньшую квантизацию (Q4_K_M вместо Q8_0)
- Partial offload: уменьшить `-ngl` (часть слоев на CPU)

### "KV cache allocation failed"

Контекст слишком большой для оставшегося VRAM.

```bash
# Уменьшить -c
./build/bin/llama-cli -m model.gguf -ngl 99 -c 4096  # вместо -c 32768
```

### Мониторинг VRAM

```bash
# Текущее использование
cat /sys/class/drm/card1/device/mem_info_vram_used
# Перевод в GiB: $((value / 1073741824))

# Непрерывный мониторинг
watch -n 1 'echo "$(($(cat /sys/class/drm/card1/device/mem_info_vram_used) / 1048576)) MiB"'
```

## Производительность

### tok/s ниже ожидаемого

Контрольный список:
1. GPU используется? `cat /sys/class/drm/card1/device/gpu_busy_percent` (должен быть > 0 при генерации)
2. Все слои на GPU? `-ngl 99`
3. Governor = performance? `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`
4. C-states отключены? `cat /sys/devices/system/cpu/cpuidle/current_driver` (должен быть `none`)
5. Температура в норме? `cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input` (< 90000 = 90C)
6. VRAM не переполнена? Если используется swap -- резкое падение скорости

### Теоретический максимум не достигается

Потеря 10-30% от теоретического tok/s -- нормально. Накладные расходы:
- KV-cache обращения
- Attention computation
- Overhead фреймворка и API
- Квантизация/деквантизация

## Логирование

```bash
# Vulkan отладка
GGML_VK_DEBUG=1 ./build/bin/llama-cli ...

# ROCm/HIP отладка
AMD_LOG_LEVEL=1 ./build/bin/llama-cli ...

# Ядро (amdgpu)
journalctl -b 0 -k | grep -iE 'amdgpu.*error|fault|timeout'

# dmesg (OOM killer, GPU reset)
dmesg | grep -iE 'oom\|killed\|gpu.*reset\|fence.*timeout'
```

## Связанные статьи

- [llama.cpp + Vulkan](vulkan-llama-cpp.md)
- [llama.cpp + ROCm](rocm-llama-cpp.md)
- [Установка ROCm](rocm-setup.md)
- [Драйвер amdgpu](../platform/amdgpu-driver.md)
