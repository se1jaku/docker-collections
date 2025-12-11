#!/bin/bash

set -euo pipefail

FIRST_RUN="/root/.firstrun"
WORK_DIR="/opt/backend"
GAI_CONF_FILE="/etc/gai.conf"
BIN="rel_backend"

NYAN_CONF_FILE="${NYAN_CONF_FILE:-/etc/nyanpass/config.yml}"
NYAN_SERVE_DIR="${NYAN_SERVE_DIR:-/srv/public}"
NYAN_SQLITE_DATA_DIR="${NYAN_SQLITE_DATA_DIR:-/var/lib/nyanpass}"
NYAN_SERVE_INDEX_FILE="${NYAN_SERVE_DIR}/index.html"

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

    # nyan configuration file
    if [ ! -d "${NYAN_SQLITE_DATA_DIR}" ]; then
        mkdir -p "${NYAN_SQLITE_DATA_DIR}"
    fi
    if [ ! -f "${NYAN_CONF_FILE}" ]; then
        cat << EOF > "${NYAN_CONF_FILE}"
database-path: sqlite3://${NYAN_SQLITE_DATA_DIR}/data.db
disable-queue: false
listen: 0.0.0.0:18888
html-path: ${NYAN_SERVE_DIR}
disable-gzip: false
EOF
    fi
    # nyan serve directory
    if [ ! -d "${NYAN_SERVE_DIR}" ]; then
        mkdir -p "${NYAN_SERVE_DIR}"
    fi
    if [ ! -f "${NYAN_SERVE_INDEX_FILE}" ]; then
        cp -r "${WORK_DIR}/public/." "${NYAN_SERVE_DIR}/"
    fi

    # touch
    touch ${FIRST_RUN}
fi

APP="${WORK_DIR}/${BIN}"

exec $APP "$@"
