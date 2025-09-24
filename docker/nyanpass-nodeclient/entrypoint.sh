#!/bin/bash

set -euo pipefail

FIRST_RUN="/root/.firstrun"
ARCH=$(uname -m)

# first run
if [ ! -f "${FIRST_RUN}" ]; then
    # ipv4 precedence
    if [ "${IPV4_PRECEDENCE}" = "1" ]; then
        echo "[entrypoint] Setting IPv4 precedence"
        echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
    fi

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

# Choose and run the correct binary
BIN="rel_nodeclient"
WORK_DIR="/opt/nodeclient"
if [[ "$ARCH" == "x86_64" && "$AVX2_SUPPORTED" == true ]]; then
    echo "[entrypoint] Running AVX2-optimized binary"
    WORK_DIR="/opt/nodeclientv3"
fi

APP="${WORK_DIR}/${BIN}"

exec $APP "$@"
