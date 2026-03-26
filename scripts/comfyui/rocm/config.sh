#!/bin/bash
# ROCm backend: PyTorch ROCm (нативные safetensors)
# Статус gfx1151: segfault, не работает
export AI_BACKEND=rocm
source "$(dirname "${BASH_SOURCE[0]}")/../common/config.sh"
