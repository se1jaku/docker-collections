#!/bin/bash

set -euo pipefail

log() {
  echo "[entrypoint] $*"
}

# Helpers

get_ip() {
  ip -o -4 addr show dev "$1" | awk '{print $4}' | cut -d/ -f1
}

get_subnet() {
  ip route show dev "$1" proto kernel scope link \
    | awk '{print $1}' \
    | head -n1
}

get_nics() {
  ip -o -4 addr show up \
    | awk '{print $2}' \
    | grep -Ev 'lo|docker|veth' \
    | sort -u
}

check_mptcp_support() {
    ss -M &>/dev/null || {
    log "mptcp not supported in this kernel, exiting"
    }
}

# NOTE: gateway assumption: the gateway should be the .1 of the NIC's subnet
get_gateway() {
  local ip="$1"
  echo "${ip%.*}.1"
}

setup_outbound() {
    mapfile -t NICS < <(get_nics)

    NIC_COUNT=${#NICS[@]}
    log "Detected NICs: ${NICS[*]}"
    log "NIC count: ${NIC_COUNT}"

    if [[ "$NIC_COUNT" -le 1 ]]; then
        log "Not enough NICs for mptcp setup, exiting"
        exit 1
    fi

    # configure policy routing
    ip rule show | awk '/lookup 10[0-9]/ {print $0}' | while read -r rule; do
        ip rule del ${rule#*: } || true
    done
    for ((i=1; i<NIC_COUNT; i++)); do
        NIC="${NICS[$i]}"
        TABLE_ID=$((i + 100))

        IP_ADDR=$(get_ip "$NIC")
        SUBNET=$(get_subnet "$NIC")
        GATEWAY=$(get_gateway "$IP_ADDR")

        log "Configuring NIC=$NIC IP=$IP_ADDR SUBNET=$SUBNET TABLE=$TABLE_ID"

        # ip route
        ip route replace "$SUBNET" dev "$NIC" scope link table "$TABLE_ID"
        ip route replace default via "$GATEWAY" dev "$NIC" table "$TABLE_ID"

        # ip rule
        ip rule add from "$IP_ADDR" table "$TABLE_ID"
    done

    # configure endpoints
    ip mptcp endpoint flush
    for ((i=0; i<NIC_COUNT; i++)); do
        NIC="${NICS[$i]}"
        ID=$((i + 1))
        IP_ADDR=$(get_ip "$NIC")

        log "Adding mptcp endpoint: $IP_ADDR dev $NIC id $ID"
        ip mptcp endpoint add "$IP_ADDR" dev "$NIC" id "$ID" subflow
    done

    # set add_addr_accepted
    ip mptcp limits set add_addr_accepted "$NIC_COUNT"
    log "outbound setup complete"
}

# Main

check_mptcp_support

# setup mptcp direction
if [ "${MPTCP_DIRECTION:-}" = "out" ]; then
    setup_outbound
fi

exec realm "$@"
