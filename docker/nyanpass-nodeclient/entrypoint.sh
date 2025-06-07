#!/bin/bash

set -eu

# Detect architecture
ARCH=$(uname -m)
echo "[entrypoint] Detected architecture: $ARCH"

# Check for AVX2 support
if [[ "$(awk -F ':' '/flags/{print $2; exit}' /proc/cpuinfo)" =~ avx2 ]]; then
    echo "[entrypoint] AVX2 support detected"
    AVX2_SUPPORTED=true
else
    echo "[entrypoint] AVX2 NOT supported"
    AVX2_SUPPORTED=false
fi

# Choose and run the correct binary
BIN="rel_nodeclient"
WORK_DIR="/opt/nodeclient"
if [[ "$ARCH" == "x86_64" && "$AVX2_SUPPORTED" == true ]]; then
    echo "[entrypoint] Running AVX2-optimized binary"
    WORK_DIR="/opt/nodeclientv3"
fi

APP="${WORK_DIR}/${BIN}"

exec $APP "$@"
