#!/bin/bash
exec "$(dirname "$0")/../stop-servers.sh" "$@"
