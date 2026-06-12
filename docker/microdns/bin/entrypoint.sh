#!/bin/bash

set -euo pipefail

# first run
FIRST_RUN="/root/.firstrun"
RESOURCE_DIR="/res"
ENCRYPTION_DIR="/enc"
CRON_ROOT_FILE="/etc/crontabs/root"


echo "[entrypoint] initializing ..."

if [ ! -f "${FIRST_RUN}" ]; then
    # when any kind of age secret is set
    if [ -n "${AGE_PASSPHRASE:-}" ] || [ -n "${AGE_SECRET_KEY:-}" ]; then
        echo "[entrypoint] age secret found!"

        # resource manager
        echo "[entrypoint] rendering resources at ${RESOURCE_DIR} ..."
        resource-manager.py ${RESOURCE_DIR} render

        echo "[entrypoint] rendering resources at ${ENCRYPTION_DIR} ..."
        resource-manager.py ${ENCRYPTION_DIR} render

        # cron resource manager sync at 0 4 * * *
        echo -e "0\t4\t*\t*\t*\tresource-manager.py ${RESOURCE_DIR} sync && supervisorctl restart smartdns" >> $CRON_ROOT_FILE
    fi

    # touch first run file
    touch ${FIRST_RUN}
fi

exec "$@"
