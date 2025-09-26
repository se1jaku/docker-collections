#!/bin/bash

set -euo pipefail

FIRST_RUN="/root/.firstrun"
WORK_DIR="/opt/nodeclient"
BIN="rel_nodeclient"
ARCH=$(uname -m)

# first run
if [ ! -f "${FIRST_RUN}" ]; then
    # touch
    touch ${FIRST_RUN}
fi

# Check for AVX2 support
echo "[entrypoint] Detected architecture: $ARCH"
if [[ "$(awk -F ':' '/flags/{print $2; exit}' /proc/cpuinfo)" =~ avx2 ]]; then
    echo "[entrypoint] AVX2 support detected"
    AVX2_SUPPORTED=true
else
    echo "[entrypoint] AVX2 NOT supported"
    AVX2_SUPPORTED=false
fi

# Choose and run the binary
if [[ "$ARCH" == "x86_64" && "$AVX2_SUPPORTED" == true ]]; then
    echo "[entrypoint] Running AVX2-optimized binary"
    WORK_DIR="/opt/nodeclientv3"
fi

APP="${WORK_DIR}/${BIN}"

exec $APP "$@"
