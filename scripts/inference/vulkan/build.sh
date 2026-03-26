#!/bin/bash
# Сборка/пересборка llama.cpp с Vulkan
# Использование: ./scripts/inference/vulkan/build.sh [--clean]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

CLEAN=false
[[ "${1:-}" == "--clean" ]] && CLEAN=true

if [[ ! -d "$LLAMA_DIR" ]]; then
    echo "Клонирование llama.cpp..."
    git clone https://github.com/ggerganov/llama.cpp.git "$LLAMA_DIR"
fi

cd "$LLAMA_DIR"

echo "Обновление репозитория..."
git pull

if $CLEAN || [[ ! -d build ]]; then
    echo "Полная пересборка (cmake)..."
    rm -rf build
    cmake -B build -DGGML_VULKAN=ON
else
    echo "Инкрементальная сборка..."
fi

echo "Компиляция ($(nproc) потоков)..."
cmake --build build -j"$(nproc)"

echo ""
echo "Сборка завершена. Проверка:"
"$LLAMA_CLI" --version 2>&1 | head -5
