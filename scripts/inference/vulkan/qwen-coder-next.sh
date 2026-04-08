#!/bin/bash
# Vulkan-обёртка для пресета Qwen3-Coder-Next 80B-A3B
export AI_BACKEND=vulkan
exec "$(dirname "$0")/../common/presets/qwen-coder-next.sh" "$@"
