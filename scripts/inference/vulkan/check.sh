#!/bin/bash
# Проверка Vulkan, GPU, групп, зависимостей
# Запуск на AI-сервере: ./scripts/inference/vulkan/check.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

ERRORS=0

echo "=== Проверка окружения для llama.cpp + Vulkan ==="
echo ""

# 1. Группы
echo -n "[1/7] Группы video/render: "
if groups | grep -q render && groups | grep -q video; then
    echo "OK ($(groups | tr ' ' ', '))"
else
    echo "ОШИБКА -- добавить: sudo usermod -aG video,render \$USER"
    ((ERRORS++)) || true
fi

# 2. Устройства DRI
echo -n "[2/7] Устройства /dev/dri/: "
if [[ -e /dev/dri/renderD128 ]] && [[ -e /dev/dri/card1 ]]; then
    echo "OK (card1, renderD128)"
else
    echo "ОШИБКА -- GPU не определяется"
    ((ERRORS++)) || true
fi

# 3. Vulkan
echo -n "[3/7] Vulkan: "
vk_device=$(vulkaninfo --summary 2>&1 | grep 'deviceName.*AMD' | head -1 | sed 's/.*= //')
if [[ -n "$vk_device" ]]; then
    vk_api=$(vulkaninfo --summary 2>&1 | grep 'apiVersion' | head -1 | sed 's/.*= //')
    echo "OK ($vk_device, API $vk_api)"
else
    echo "ОШИБКА -- vulkaninfo не видит AMD GPU"
    echo "  Проверить: sudo apt install vulkan-tools mesa-vulkan-drivers"
    echo "  Проверить: группа render"
    ((ERRORS++)) || true
fi

# 4. Зависимости сборки
echo -n "[4/7] Зависимости (cmake, g++, glslc): "
missing=""
command -v cmake &>/dev/null || missing+="cmake "
command -v g++ &>/dev/null || missing+="build-essential "
command -v glslc &>/dev/null || missing+="glslc "
if [[ -z "$missing" ]]; then
    echo "OK"
else
    echo "ОШИБКА -- не установлены: $missing"
    echo "  sudo apt install cmake build-essential git libvulkan-dev glslc"
    ((ERRORS++)) || true
fi

# 5. llama.cpp собран
echo -n "[5/7] llama.cpp: "
if [[ -x "$LLAMA_SERVER" ]]; then
    version=$("$LLAMA_CLI" --version 2>&1 | grep 'version:' | head -1 || echo "unknown")
    echo "OK ($version)"
else
    echo "НЕ СОБРАН -- запустить: ./scripts/inference/vulkan/build.sh"
    ((ERRORS++)) || true
fi

# 6. Модели
echo -n "[6/7] Модели: "
model_count=$(find "$MODELS_DIR" -name "*.gguf" ! -name "*-of-*" -type f 2>/dev/null | wc -l)
split_count=$(find "$MODELS_DIR" -name "*-00001-of-*.gguf" -type f 2>/dev/null | wc -l)
total=$((model_count + split_count))
if [[ $total -gt 0 ]]; then
    echo "OK ($total моделей)"
    list_models
else
    echo "НЕТ МОДЕЛЕЙ -- загрузить: ./scripts/inference/download-model.sh"
fi

# 7. GPU состояние
echo -n "[7/7] GPU: "
if [[ -f "$GPU_BUSY" ]]; then
    busy=$(cat "$GPU_BUSY")
    vram_used=$(($(cat "$VRAM_USED") / 1048576))
    vram_total=$(($(cat "$VRAM_TOTAL") / 1048576))
    temp=$(($(cat $GPU_TEMP) / 1000))
    echo "OK (загрузка ${busy}%, VRAM ${vram_used}/${vram_total} MiB, ${temp}C)"
else
    echo "ОШИБКА -- sysfs GPU не доступен"
    ((ERRORS++)) || true
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "Все проверки пройдены"
else
    echo "Ошибок: ${ERRORS}"
fi
exit $ERRORS
