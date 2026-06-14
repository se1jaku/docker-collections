#!/bin/bash

set -euo pipefail

# first run
FIRST_RUN="/root/.firstrun"
RESOURCE_DIR="/res"
CRON_ROOT_FILE="/etc/crontabs/root"
SINGBOX_CONFIG_FILE="${SINGBOX_CONFIG_DIR}/config.json"


echo "[entrypoint] initializing ..."

if [ ! -f /etc/timezone ] || ! grep -qxF "${TZ}" /etc/timezone; then
    echo "[entrypoint] updating timezone to ${TZ}..."
    echo "${TZ}" > /etc/timezone
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
fi

# check env
if [ -z "${SINGBOX_REMOTE_URL:-}" ]; then
    echo "SINGBOX_REMOTE_URL not set, check it manually" 2>&1
    exit 1
fi

if [ ! -f "${FIRST_RUN}" ]; then
    # sync config file
    if [ ! -f "${SINGBOX_CONFIG_FILE}" ]; then
        resource-manager.py ${RESOURCE_DIR} sync
    else

    # cron resource manager self-update at 0 2 * * *
    echo -e "0\t2\t*\t*\t*\tresource-manager.py self-update" >> $CRON_ROOT_FILE
    # cron resource manager sync at 0 4 * * *
    echo -e "0\t4\t*\t*\t*\tresource-manager.py ${RESOURCE_DIR} sync && supervisorctl restart sing-box" >> $CRON_ROOT_FILE

    # touch first run file
    touch ${FIRST_RUN}
fi

# check sing-box configuration file
if ! output=$(sing-box -C "${SINGBOX_CONFIG_DIR}" check 2>&1); then
    echo "[entrypoint] sing-box configuration validation failed:" >&2
    printf '%s\n' "$output" >&2
    exit 1
fi

exec "$@"
