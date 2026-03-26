#!/bin/bash
export AI_BACKEND=rocm
exec "$(dirname "$0")/../check.sh" "$@"
