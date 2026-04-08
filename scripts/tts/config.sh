#!/bin/bash
# TTS-WebUI: переменные и функции
# Подключение: source "$(dirname "$0")/config.sh"

# PATH для локальных бинарников
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

TTS_DIR="${TTS_DIR:-${HOME}/projects/tts-webui}"
TTS_PORT="${TTS_PORT:-7770}"
TTS_REPO="${TTS_REPO:-https://github.com/rsxdalv/TTS-WebUI.git}"

# Кэш моделей -- в общем models/, чтобы переиспользовать с другими проектами
export HF_HOME="${HF_HOME:-${HOME}/models}"

# ROCm для PyTorch (gfx1151 через override)
export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-11.5.1}"
export MIOPEN_FIND_MODE="${MIOPEN_FIND_MODE:-FAST}"

check_tts() {
    if [[ ! -d "$TTS_DIR" ]]; then
        echo "ОШИБКА: TTS-WebUI не установлен ($TTS_DIR)"
        echo "  Установить: ./scripts/tts/install.sh"
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
