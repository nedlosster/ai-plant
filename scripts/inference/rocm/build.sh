#!/bin/bash
# Сборка llama.cpp с HIP (ROCm) backend
# Использование: ./scripts/inference/rocm/build.sh [--clean]

set -euo pipefail
source "$(dirname "$0")/config.sh"

check_rocm || exit 1

CLEAN=false
[[ "${1:-}" == "--clean" ]] && CLEAN=true

if [[ ! -d "$LLAMA_DIR" ]]; then
    echo "ОШИБКА: llama.cpp не найден ($LLAMA_DIR)"
    echo "  git clone https://github.com/ggerganov/llama.cpp.git $LLAMA_DIR"
    exit 1
fi

cd "$LLAMA_DIR"

if $CLEAN || [[ ! -d "$BUILD_DIR" ]]; then
    echo "Полная сборка (cmake + HIP)..."
    rm -rf "$BUILD_DIR"
    cmake -B "$BUILD_DIR" \
        -DGGML_HIP=ON \
        -DAMDGPU_TARGETS="gfx1151" \
        -DCMAKE_PREFIX_PATH="$ROCM_PATH"
else
    echo "Инкрементальная сборка..."
fi

echo "Компиляция ($(nproc) потоков)..."
cmake --build "$BUILD_DIR" -j"$(nproc)"

echo ""
echo "Сборка завершена:"
"$BUILD_DIR/bin/llama-cli" --version 2>&1 | head -5
echo ""
echo "Бинарники: $BUILD_DIR/bin/"
echo "Запуск: $BUILD_DIR/bin/llama-server -m model.gguf -ngl 99"
