#!/bin/bash

set -euo pipefail

FIRST_RUN="/root/.firstrun"
WORK_DIR="/opt/backend"
BIN="rel_backend"

# first run
if [ ! -f "${FIRST_RUN}" ]; then
    # touch
    touch ${FIRST_RUN}
fi

APP="${WORK_DIR}/${BIN}"

exec $APP "$@"
