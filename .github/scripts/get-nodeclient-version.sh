#!/bin/bash

DOWNLOAD_HOST="https://dl.nyafw.com"
DOWNLOAD_PREFIX="/download/"
PRODUCT="rel_nodeclient_linux_amd64v3"

info=$(curl -s "${DOWNLOAD_HOST}${DOWNLOAD_PREFIX}${PRODUCT}.txt")
date=$(echo "$info" | sed -n 's/.*zf-nc\([0-9]\{8\}\).*/\1/p')

echo -n $date
