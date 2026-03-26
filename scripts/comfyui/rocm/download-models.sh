#!/bin/bash
export AI_BACKEND=rocm
exec "$(dirname "$0")/../download-models.sh" "$@"
