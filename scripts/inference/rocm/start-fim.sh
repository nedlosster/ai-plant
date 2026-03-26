#!/bin/bash
export AI_BACKEND=rocm
exec "$(dirname "$0")/../start-fim.sh" "$@"
