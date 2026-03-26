#!/bin/bash
# Проверка ROCm: установка, GPU, версия, HIP

set -uo pipefail
source "$(dirname "$0")/config.sh"

ERRORS=0

echo "=== Проверка ROCm ==="
echo ""

# 1. ROCm установлен
echo -n "[1/5] ROCm: "
if [[ -f "$ROCM_PATH/.info/version" ]]; then
    echo "OK ($(cat "$ROCM_PATH/.info/version"))"
else
    echo "НЕ УСТАНОВЛЕН"
    ((ERRORS++)) || true
fi

# 2. HSA_OVERRIDE
echo -n "[2/5] HSA_OVERRIDE_GFX_VERSION: "
echo "$HSA_OVERRIDE_GFX_VERSION"

# 3. GPU через rocminfo
echo -n "[3/5] GPU: "
rocm_out=$(rocminfo 2>/dev/null || true)
gpu_name=$(echo "$rocm_out" | grep -m1 'Name:.*gfx' | sed 's/.*Name:\s*//' | tr -d ' ')
if [[ -n "$gpu_name" ]]; then
    marketing=$(echo "$rocm_out" | grep -A1 "Name:.*gfx" | grep 'Marketing' | sed 's/.*Name:\s*//' | head -1)
    echo "OK ($gpu_name -- $marketing)"
else
    echo "НЕ ОПРЕДЕЛЯЕТСЯ"
    ((ERRORS++)) || true
fi

# 4. HIP
echo -n "[4/5] HIP: "
if command -v hipcc &>/dev/null; then
    hip_ver=$(hipcc --version 2>&1 | grep 'HIP version' | head -1)
    echo "OK ($hip_ver)"
else
    echo "НЕ УСТАНОВЛЕН"
    ((ERRORS++)) || true
fi

# 5. rocm-smi
echo -n "[5/5] rocm-smi: "
if command -v rocm-smi &>/dev/null; then
    temp=$(rocm-smi --showtemp 2>/dev/null | grep -oP '\d+\.\d+°C' | head -1)
    power=$(rocm-smi --showpower 2>/dev/null | grep -oP '[\d.]+W' | head -1)
    echo "OK (temp: ${temp:-?}, power: ${power:-?})"
else
    echo "НЕ УСТАНОВЛЕН"
    ((ERRORS++)) || true
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "Все проверки пройдены"
else
    echo "Ошибок: $ERRORS"
fi
exit $ERRORS
