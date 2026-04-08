#!/bin/bash
# ROCm/HIP-обёртка для пресета Gemma 4 26B-A4B
export AI_BACKEND=rocm
exec "$(dirname "$0")/../common/presets/gemma4.sh" "$@"
