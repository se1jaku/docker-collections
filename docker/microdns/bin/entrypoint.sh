#!/bin/bash

set -euo pipefail

# first run
FIRST_RUN="/root/.firstrun"
RESOURCE_DIR="/res"
ENCRYPTION_DIR="/enc"
CRON_ROOT_FILE="/etc/crontabs/root"


echo "[entrypoint] initializing ..."

if [ ! -f /etc/timezone ] || ! grep -qxF "${TZ}" /etc/timezone; then
    echo "[entrypoint] updating timezone to ${TZ}..."
    echo "${TZ}" > /etc/timezone
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
fi

if [ ! -f "${FIRST_RUN}" ]; then
    # when any kind of age secret is set
    if [ -n "${AGE_PASSPHRASE:-}" ] || [ -n "${AGE_SECRET_KEY:-}" ]; then
        echo "[entrypoint] age secret found!"

        # resource manager
        if [ -f "${RESOURCE_DIR}/.meta.json" ]; then
            echo "[entrypoint] rendering resources at ${RESOURCE_DIR} ..."
            resource-manager.py ${RESOURCE_DIR} render
        fi

        if [ -f "${ENCRYPTION_DIR}/.meta.json" ]; then
            echo "[entrypoint] rendering resources at ${ENCRYPTION_DIR} ..."
            resource-manager.py ${ENCRYPTION_DIR} render
        fi

        # cron resource manager self-update at 0 2 * * *
        echo -e "0\t2\t*\t*\t*\tresource-manager.py self-update" >> $CRON_ROOT_FILE
        # cron resource manager sync at 55 3 * * *
        echo -e "55\t3\t*\t*\t*\tresource-manager.py ${RESOURCE_DIR} sync" >> $CRON_ROOT_FILE
        # cron resource manager sync at 0 4 * * *
        echo -e "0\t4\t*\t*\t*\tresource-manager.py ${ENCRYPTION_DIR} sync && supervisorctl restart smartdns" >> $CRON_ROOT_FILE
    fi

    # touch first run file
    touch ${FIRST_RUN}
fi

exec "$@"
