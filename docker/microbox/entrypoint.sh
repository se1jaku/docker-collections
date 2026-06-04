#!/bin/bash

set -euo pipefail

# first run
FIRST_RUN="/root/.firstrun"
CRON_ROOT_FILE="/etc/crontabs/root"
SINGBOX_CONFIG_FILE="${SINGBOX_CONFIG_DIR}/config.json"

# check env
if [ -z "${BACKUP_DIR:-}" ]; then
    echo "BACKUP_DIR not set, check it manually" 2>&1
    exit 1
fi

if [ -z "${SINGBOX_REMOTE_URL:-}" ]; then
    echo "SINGBOX_REMOTE_URL not set, check it manually" 2>&1
    exit 1
fi

# check sing-box configuration file
if [ ! -f "${SINGBOX_CONFIG_FILE}" ]; then
    microhelper.py update
else
    if ! output=$(sing-box -C "${SINGBOX_CONFIG_DIR}" check 2>&1); then
        echo "sing-box configuration validation failed:" >&2
        printf '%s\n' "$output" >&2
        exit 1
    fi
fi

if [ ! -f "${FIRST_RUN}" ]; then
    mkdir -p ${BACKUP_DIR}

    # cron microhelper self-update at 0 3 * * 1
    echo -e "0\t3\t*\t*\t1\tmicrohelper.py update" >> $CRON_ROOT_FILE
    # cron microhelper update at 0 4 * * 1
    echo -e "0\t4\t*\t*\t1\tmicrohelper.py update" >> $CRON_ROOT_FILE

    # touch first run file
    touch ${FIRST_RUN}
fi

exec "$@"
