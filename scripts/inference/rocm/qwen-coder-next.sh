#!/bin/bash
# ROCm/HIP-обёртка для пресета Qwen3-Coder-Next 80B-A3B
#
# ВНИМАНИЕ: HIP-аллокация ограничена ~30 GiB GPU-памяти, тогда как модель
# занимает ~45 GiB. Возможен OOM на загрузке. Для этой модели предпочтителен
# Vulkan-бекенд (см. ../vulkan/qwen-coder-next.sh).
export AI_BACKEND=rocm
exec "$(dirname "$0")/../common/presets/qwen-coder-next.sh" "$@"
