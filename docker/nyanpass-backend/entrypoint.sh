#!/bin/bash

set -euo pipefail

FIRST_RUN="/root/.firstrun"
WORK_DIR="/opt/backend"
GAI_CONF_FILE="/etc/gai.conf"
BIN="rel_backend"

# first run
if [ ! -f "${FIRST_RUN}" ]; then
    # gai.conf
    if [ -w "${GAI_CONF_FILE}" ]; then
        if [ "${IPV4_PRECEDENCE}" = "1" ]; then
            sed -i 's/^#\s*\(precedence\s\+::ffff:0:0\/96\s\+100\)/\1/' ${GAI_CONF_FILE}
        fi
    else
        echo "[entrypoint] gai.conf is readonly, skipped"
    fi

    # touch
    touch ${FIRST_RUN}
fi

APP="${WORK_DIR}/${BIN}"

exec $APP "$@"
