#!/bin/bash
# ACE-Step 1.5: переменные и функции
# Подключение: source "$(dirname "$0")/config.sh"

# PATH для uv и других локальных бинарников
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

ACESTEP_DIR="${ACESTEP_DIR:-${HOME}/projects/ACE-Step-1.5}"
ACESTEP_PORT="${ACESTEP_PORT:-7860}"
ACESTEP_MODELS_DIR="${ACESTEP_MODELS_DIR:-${HOME}/models/ace-step}"

# Конфигурация моделей (максимальное качество для 96 GiB VRAM)
export ACESTEP_CONFIG_PATH="${ACESTEP_CONFIG_PATH:-acestep-v15-turbo}"
export ACESTEP_LM_MODEL_PATH="${ACESTEP_LM_MODEL_PATH:-acestep-5Hz-lm-4B}"
export ACESTEP_LM_BACKEND="${ACESTEP_LM_BACKEND:-pt}"
export ACESTEP_INIT_LLM="${ACESTEP_INIT_LLM:-true}"

# ROCm (PyTorch HIP backend)
export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-11.5.0}"
export MIOPEN_FIND_MODE="${MIOPEN_FIND_MODE:-FAST}"

# Кэш моделей HuggingFace -> ~/models/ace-step/
export HF_HOME="${ACESTEP_MODELS_DIR}"

check_acestep() {
    if [[ ! -d "$ACESTEP_DIR" ]]; then
        echo "ОШИБКА: ACE-Step не установлен ($ACESTEP_DIR)"
        echo "  Установить: ./scripts/music/ace-step/install.sh"
        return 1
    fi
}

check_uv() {
    if ! command -v uv &>/dev/null; then
        echo "ОШИБКА: uv не установлен"
        echo "  Установить: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi
}

check_port_free() {
    local port="$1"
    if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
        echo "ОШИБКА: порт $port занят"
        ss -tlnp 2>/dev/null | grep ":${port} " | head -3
        return 1
    fi
}
