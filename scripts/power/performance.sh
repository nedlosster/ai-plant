#!/bin/bash
#
# Режим производительности: максимальная скорость для inference
# CPU performance + GPU auto
#

set -euo pipefail

echo "Переключение в режим производительности..."

# CPU: performance
for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance | sudo tee "$g" > /dev/null
done

# GPU: автоматическое управление (высокие частоты при нагрузке)
echo auto | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level > /dev/null

echo ""
echo "Режим производительности:"
echo "  CPU: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "  GPU: $(cat /sys/class/drm/card1/device/power_dpm_force_performance_level)"
echo "  Temp: $(($(cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input) / 1000))C"
echo "  Power: $(($(cat /sys/class/drm/card1/device/hwmon/hwmon*/power1_average) / 1000000))W"
