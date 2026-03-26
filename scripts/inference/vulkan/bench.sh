#!/bin/bash
export AI_BACKEND=vulkan
exec "$(dirname "$0")/../bench.sh" "$@"
