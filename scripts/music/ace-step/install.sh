#!/bin/bash
# Установка ACE-Step 1.5: клонирование, зависимости, PyTorch ROCm, загрузка моделей
# Использование: ./scripts/music/ace-step/install.sh

set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "=== Установка ACE-Step 1.5 ==="

# 1. uv
if ! command -v uv &>/dev/null; then
    echo "[1/5] Установка uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "[1/5] uv: $(uv --version)"
fi

# 2. Клонирование
if [[ -d "$ACESTEP_DIR" ]]; then
    echo "[2/5] ACE-Step уже клонирован: $ACESTEP_DIR"
    cd "$ACESTEP_DIR"
    git pull 2>/dev/null || true
else
    echo "[2/5] Клонирование ACE-Step..."
    git clone https://github.com/ACE-Step/ACE-Step-1.5.git "$ACESTEP_DIR"
    cd "$ACESTEP_DIR"
fi

echo "Установка зависимостей (uv sync)..."
uv sync

# 3. PyTorch ROCm (замена CPU-версии для GPU)
echo "[3/5] Установка PyTorch ROCm 6.2.4 (GPU)..."
uv pip install --no-deps torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2.4 --reinstall

# Проверка GPU
echo -n "  GPU: "
if .venv/bin/python -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
    .venv/bin/python -c "import torch; print(torch.cuda.get_device_name(0))"
else
    echo "не обнаружен (CPU fallback)"
fi

# 4. Загрузка основных моделей
mkdir -p "$ACESTEP_MODELS_DIR"
echo "[4/5] Загрузка основных моделей (~10 GiB)..."
.venv/bin/python -m acestep.model_downloader

# 5. Загрузка LM 4B (максимальное качество)
echo "[5/5] Загрузка LM 4B (~8 GiB)..."
.venv/bin/python -m acestep.model_downloader --model acestep-5Hz-lm-4B

echo ""
echo "Установка завершена"
echo "  Директория: $ACESTEP_DIR"
echo "  Модели:     checkpoints/"
echo "  LM:         $ACESTEP_LM_MODEL_PATH"
echo "  DiT:        $ACESTEP_CONFIG_PATH (turbo, 8 шагов)"
echo "  Backend:    PyTorch ROCm (HSA_OVERRIDE=$HSA_OVERRIDE_GFX_VERSION)"
echo ""
echo "Запуск: ./scripts/music/ace-step/start.sh"
