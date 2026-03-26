#!/bin/bash
#
# Тихий ночной режим: минимальное тепловыделение и шум
# CPU powersave + GPU low + остановка серверов
#

set -euo pipefail

echo "Переключение в тихий режим..."

# CPU: powersave
for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo powersave | sudo tee "$g" > /dev/null
done

# GPU: минимальная частота
echo low | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level > /dev/null

# Остановка inference-серверов
if pgrep -f llama-server > /dev/null 2>&1; then
    echo "Остановка llama-server..."
    pkill -f llama-server 2>/dev/null || true
    sleep 1
fi

echo ""
echo "Тихий режим:"
echo "  CPU: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "  GPU: $(cat /sys/class/drm/card1/device/power_dpm_force_performance_level)"
echo "  Temp: $(($(cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input) / 1000))C"
echo "  Power: $(($(cat /sys/class/drm/card1/device/hwmon/hwmon*/power1_average) / 1000000))W"
echo ""
echo "Возврат: ./scripts/power/performance.sh"
