#!/bin/bash
# Установка ROCm 6.4 на Ubuntu 24.04 (Strix Halo)
# Запуск: sudo ./scripts/inference/rocm/install.sh

set -euo pipefail

ROCM_VERSION="6.4"
ROCM_DEB="amdgpu-install_6.4.60400-1_all.deb"
ROCM_URL="https://repo.radeon.com/amdgpu-install/${ROCM_VERSION}/ubuntu/noble/${ROCM_DEB}"

if [[ $EUID -ne 0 ]]; then
    echo "ОШИБКА: запустить с sudo"
    exit 1
fi

echo "=== Установка ROCm ${ROCM_VERSION} ==="
echo ""

# 1. Очистка
echo "[1/4] Очистка старых версий..."
apt purge -y amdgpu-install 2>/dev/null || true
rm -rf /opt/rocm*

# 2. Загрузка
echo "[2/4] Загрузка amdgpu-install..."
wget -q "$ROCM_URL" -O /tmp/amdgpu-install.deb
dpkg -i /tmp/amdgpu-install.deb
apt update -qq

# 3. Установка
echo "[3/4] Установка ROCm (без DKMS)..."
amdgpu-install --usecase=rocm --no-dkms -y

# 4. Окружение
echo "[4/4] Настройка окружения..."
tee /etc/profile.d/rocm.sh > /dev/null << 'EOF'
export ROCM_PATH=/opt/rocm
export PATH=$ROCM_PATH/bin:$PATH
export LD_LIBRARY_PATH=$ROCM_PATH/lib:$LD_LIBRARY_PATH
export HSA_OVERRIDE_GFX_VERSION=11.5.0
EOF

echo ""
echo "ROCm $(cat /opt/rocm/.info/version 2>/dev/null) установлен"
echo ""
echo "Перелогиниться или: source /etc/profile.d/rocm.sh"
echo "Проверка: ./scripts/inference/rocm/check.sh"
