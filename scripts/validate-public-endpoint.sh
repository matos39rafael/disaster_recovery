#!/usr/bin/env bash
set -Eeuo pipefail

: "${APP_HOSTNAME:?APP_HOSTNAME is required}"

HEALTHCHECK_RETRIES="${HEALTHCHECK_RETRIES:-10}"
HEALTHCHECK_INTERVAL="${HEALTHCHECK_INTERVAL:-3}"

for ((i=1; i<=HEALTHCHECK_RETRIES; i++)); do

    if curl -fsS --max-time 5 \
        "https://${APP_HOSTNAME}/" \
        >/dev/null
    then
        echo "Public endpoint route: OK"
        break
    fi

    if (( i == HEALTHCHECK_RETRIES )); then
        echo "Public endpoint route failed"
        exit 1
    fi

    echo "Public endpoint route. Retry ${i}/${HEALTHCHECK_RETRIES}"

    sleep "${HEALTHCHECK_INTERVAL}"

done
