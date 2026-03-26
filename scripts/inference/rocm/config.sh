#!/bin/bash
# ROCm backend: переменные и функции
# Подключение: source "$(dirname "$0")/config.sh"

export AI_BACKEND=rocm
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/config.sh"

# --- ROCm-специфичные проверки ---

# Проверка установки ROCm
check_rocm() {
    if [[ ! -d "$ROCM_PATH" ]]; then
        echo "ОШИБКА: ROCm не установлен ($ROCM_PATH)"
        echo "  Установить: docs/inference/rocm-setup.md"
        return 1
    fi
    if ! command -v rocminfo &>/dev/null; then
        echo "ОШИБКА: rocminfo не найден"
        return 1
    fi
}

# Проверка GPU через ROCm
check_gpu() {
    if ! rocminfo 2>/dev/null | grep -q 'gfx'; then
        echo "ОШИБКА: GPU не определяется через ROCm"
        echo "  HSA_OVERRIDE_GFX_VERSION=$HSA_OVERRIDE_GFX_VERSION"
        return 1
    fi
}
