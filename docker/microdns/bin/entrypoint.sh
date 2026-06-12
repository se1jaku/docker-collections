#!/bin/bash

set -euo pipefail

# first run
FIRST_RUN="/root/.firstrun"
RESOURCE_DIR="/res"
ENCRYPTION_DIR="/enc"
CRON_ROOT_FILE="/etc/crontabs/root"


echo "[entrypoint] initializing ..."

if [ ! -f "${FIRST_RUN}" ]; then
    # when RAGE_PASSPHRASE is set
    if [ -n "${RAGE_PASSPHRASE:-}" ]; then
        echo "[entrypoint] RAGE_PASSPHRASE found!"

        echo "[entrypoint] rendering resources at ${RESOURCE_DIR} ..."
        resource-manager.py ${RESOURCE_DIR} render

        echo "[entrypoint] rendering resources at ${ENCRYPTION_DIR} ..."
        resource-manager.py ${ENCRYPTION_DIR} render
    fi

    # touch first run file
    touch ${FIRST_RUN}
fi

exec "$@"
