#!/bin/bash
export AI_BACKEND=vulkan
exec "$(dirname "$0")/../stop.sh" "$@"
