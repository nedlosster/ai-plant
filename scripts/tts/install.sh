#!/bin/bash
# Установка TTS-WebUI: клонирование, зависимости, PyTorch ROCm
# Использование: ./scripts/tts/install.sh

set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "=== Установка TTS-WebUI ==="

# 1. Клонирование
if [[ -d "$TTS_DIR" ]]; then
    echo "[1/3] TTS-WebUI уже клонирован: $TTS_DIR"
    cd "$TTS_DIR"
    git pull 2>/dev/null || true
else
    echo "[1/3] Клонирование TTS-WebUI..."
    git clone "$TTS_REPO" "$TTS_DIR"
    cd "$TTS_DIR"
fi

# 2. Установка через официальный скрипт (использует Conda + venv внутри)
echo "[2/3] Запуск штатного installer'а TTS-WebUI..."
echo "  Это интерактивная установка -- выбери движки (F5-TTS, XTTS, Fish Speech)"
if [[ -f "./install.sh" ]]; then
    bash ./install.sh
elif [[ -f "./tts_webui_installer.sh" ]]; then
    bash ./tts_webui_installer.sh
else
    echo "ОШИБКА: installer-скрипт TTS-WebUI не найден в $TTS_DIR"
    echo "  Проверь репозиторий: $TTS_REPO"
    exit 1
fi

# 3. Замена PyTorch на ROCm-вариант (gfx1151)
echo "[3/3] Установка PyTorch ROCm для gfx1151..."
if [[ -d "$TTS_DIR/installer_files/env" ]]; then
    # Conda env (стандарт TTS-WebUI)
    source "$TTS_DIR/installer_files/env/bin/activate" 2>/dev/null || \
        source "$TTS_DIR/installer_files/env/etc/profile.d/conda.sh" && conda activate "$TTS_DIR/installer_files/env"
    pip install --no-deps torch torchaudio --index-url https://download.pytorch.org/whl/rocm6.2 --upgrade
    python -c "import torch; print('CUDA available:', torch.cuda.is_available()); print('Device:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU')"
else
    echo "ПРЕДУПРЕЖДЕНИЕ: conda env TTS-WebUI не найден -- PyTorch ROCm установить вручную"
fi

echo ""
echo "Установка завершена"
echo "  Директория: $TTS_DIR"
echo "  Кэш моделей: $HF_HOME"
echo "  ROCm:        HSA_OVERRIDE=$HSA_OVERRIDE_GFX_VERSION"
echo ""
echo "Запуск: ./scripts/tts/start.sh"
