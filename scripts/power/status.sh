#!/bin/bash
#
# Текущий режим энергосбережения
#

set -euo pipefail

governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
gpu_level=$(cat /sys/class/drm/card1/device/power_dpm_force_performance_level)
temp=$(($(cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input) / 1000))
power=$(($(cat /sys/class/drm/card1/device/hwmon/hwmon*/power1_average) / 1000000))
freq=$(($(cat /sys/class/drm/card1/device/hwmon/hwmon*/freq1_input) / 1000000))
cpu_mhz=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
cpu_mhz=$((cpu_mhz / 1000))

# Определение режима
if [[ "$governor" == "performance" ]]; then
    mode="ПРОИЗВОДИТЕЛЬНОСТЬ"
elif [[ "$gpu_level" == "low" ]]; then
    mode="ТИХИЙ"
else
    mode="СБАЛАНСИРОВАННЫЙ"
fi

echo "=== Режим: $mode ==="
echo ""
echo "CPU:"
echo "  Governor: $governor"
echo "  Частота:  ${cpu_mhz} MHz"
echo ""
echo "GPU:"
echo "  DPM level: $gpu_level"
echo "  Частота:   ${freq} MHz"
echo "  Temp:      ${temp}C"
echo "  Power:     ${power}W"
echo ""

servers=$(pgrep -af llama-server 2>/dev/null || true)
if [[ -n "$servers" ]]; then
    echo "Серверы: запущены"
else
    echo "Серверы: нет"
fi

echo ""
echo "Переключение:"
echo "  ./scripts/power/quiet.sh       -- тихий (ночной)"
echo "  ./scripts/power/balanced.sh    -- сбалансированный"
echo "  ./scripts/power/performance.sh -- производительность"
