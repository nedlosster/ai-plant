#!/bin/bash
# Статус: backend, llama.cpp, GPU, серверы, модели
# Backend: AI_BACKEND=vulkan|rocm (или автодетект)

set -euo pipefail
source "$(dirname "$0")/common/config.sh"

echo "=== Backend: $BACKEND ($BUILD_SUFFIX) ==="

echo ""
echo "=== llama.cpp ==="
if [[ -x "$LLAMA_CLI" ]]; then
    "$LLAMA_CLI" --version 2>&1 | grep -E 'version:|built with' | head -2
else
    echo "Не собран (./scripts/${BACKEND}/build.sh)"
fi

echo ""
echo "=== GPU ==="
# ROCm: rocm-smi
if [[ "$BACKEND" == "rocm" ]] && command -v rocm-smi &>/dev/null; then
    echo "ROCm $(cat "$ROCM_PATH/.info/version" 2>/dev/null)"
    echo "HSA_OVERRIDE_GFX_VERSION: $HSA_OVERRIDE_GFX_VERSION"
    echo ""
    rocm-smi 2>/dev/null | grep -E 'Device|===|0 ' || echo "rocm-smi: нет данных"
    echo ""
fi
# sysfs (общее для обоих backend'ов)
if [[ -f "$GPU_BUSY" ]]; then
    printf "Загрузка:    %s%%\n" "$(cat "$GPU_BUSY")"
    printf "VRAM:        %s / %s (carved-out)\n" \
        "$(human_size "$(cat "$VRAM_USED")")" \
        "$(human_size "$(cat "$VRAM_TOTAL")")"
    # GTT
    _gtt_used=$(cat /sys/class/drm/${GPU_CARD}/device/mem_info_gtt_used 2>/dev/null || echo 0)
    _gtt_total=$(cat /sys/class/drm/${GPU_CARD}/device/mem_info_gtt_total 2>/dev/null || echo 0)
    if (( _gtt_total > 0 )); then
        printf "GTT:         %s / %s\n" \
            "$(human_size "$_gtt_used")" \
            "$(human_size "$_gtt_total")"
    fi
    # TTM pages_limit
    _ttm_limit=$(cat /sys/module/ttm/parameters/pages_limit 2>/dev/null || echo 0)
    if (( _ttm_limit > 0 )); then
        printf "TTM limit:   %s\n" "$(human_size "$(( _ttm_limit * 4096 ))")"
    fi
    # KFD GPU heap (нода с simd_count > 0 -- GPU)
    _heap_bytes=""
    for _node in /sys/class/kfd/kfd/topology/nodes/*/; do
        _simd=$(grep 'simd_count' "${_node}properties" 2>/dev/null | awk '{print $2}')
        if [[ "${_simd:-0}" -gt 0 ]]; then
            _heap_bytes=$(grep 'size_in_bytes' "${_node}mem_banks/0/properties" 2>/dev/null | awk '{print $2}')
            break
        fi
    done
    if [[ -n "${_heap_bytes:-}" ]]; then
        printf "KFD heap:    %s\n" "$(human_size "$_heap_bytes")"
    fi
    # Физическая RAM
    _mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    printf "RAM:         %s\n" "$(human_size "$(( _mem_total_kb * 1024 ))")"
    printf "Температура: %dC\n" "$(( $(cat $GPU_TEMP) / 1000 ))"
    printf "Мощность:    %dW\n" "$(( $(cat $GPU_POWER) / 1000000 ))"
    printf "Частота:     %d MHz\n" "$(( $(cat $GPU_FREQ) / 1000000 ))"
else
    echo "GPU sysfs не доступен"
fi

echo ""
echo "=== Серверы ==="
if pgrep -f llama-server > /dev/null 2>&1; then
    pgrep -af llama-server
    echo ""
    for port in $DEFAULT_PORT_CHAT $DEFAULT_PORT_FIM; do
        health=$(curl -s --connect-timeout 1 "http://localhost:${port}/health" 2>/dev/null || echo "")
        [[ -n "$health" ]] && echo "  :${port} $health"
    done
else
    echo "Нет запущенных серверов"
fi

echo ""
echo "=== Модели ==="
if [[ -d "$MODELS_DIR" ]]; then
    list_models
else
    echo "  $MODELS_DIR не существует"
fi
