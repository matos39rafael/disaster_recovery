#!/usr/bin/env bash

set -euo pipefail

CURL_IMAGE="curlimages/curl:8.12.1"
DR_NETWORK="dr"
APP_SERVICE="app"
URL="${1:-http://localhost:5000}"
HEALTHCHECK_RETRIES="10"
HEALTHCHECK_INTERVAL="3"


log() {
    printf '[%s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$*"
}

die() {
    printf '[%s] [ERROR] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$*" >&2

    exit 1
}

log "[INFO] Checking application: ${URL}"


for ((i=1; i<=HEALTHCHECK_RETRIES; i++)); do

    if docker run --rm \
        --network "${DR_NETWORK}" \
        "${CURL_IMAGE}" \
        -fsS \
        --max-time 5 \
        "http://${APP_SERVICE}:5000" \
        >/dev/null
    then
        log "[OK] ePauta is responding."
        break
    fi

    if (( i == HEALTHCHECK_RETRIES )); then
        die "[ERROR] ePauta is not responding."
    fi

    log "[ERROR] ePauta is not responding.. Retry ${i}/${HEALTHCHECK_RETRIES}"

    sleep "${HEALTHCHECK_INTERVAL}"

done
