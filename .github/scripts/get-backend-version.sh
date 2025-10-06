#!/bin/bash

DOWNLOAD_HOST="https://dl.nyafw.com"
DOWNLOAD_PREFIX="/download/"
PRODUCT="rel_backend_linux_amd64"

info=$(curl -s "${DOWNLOAD_HOST}${DOWNLOAD_PREFIX}${PRODUCT}.txt")
date=$(echo "$info" | grep "$PRODUCT" | sed -n 's/.*zf-\([0-9]\{8\}\).*/\1/p')

echo -n $date
