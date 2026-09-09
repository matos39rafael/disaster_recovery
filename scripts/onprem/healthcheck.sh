#!/usr/bin/env bash
set -Eeuo pipefail

: "${ONPREM_HOST:?ONPREM_HOST is required}"
: "${ONPREM_USER:?ONPREM_USER is required}"
: "${ONPREM_SSH_KEY:?ONPREM_SSH_KEY is required}"
: "${ONPREM_PROJECT_DIR:?ONPREM_PROJECT_DIR is required}"
: "${APP_HOSTNAME:?APP_HOSTNAME is required}"


TRAEFIK_NETWORK="proxy"
TRAEFIK_SERVICE="traefik"
APP_SERVICE="epauta-app"
CURL_IMAGE="curlimages/curl:8.12.1"
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



command -v ssh >/dev/null 2>&1 || die "ssh command not found"

[[ -f "${ONPREM_SSH_KEY}" ]] || die "SSH key not found: ${ONPREM_SSH_KEY}"

log "Starting on-premises health validation"

# Execução remota


ssh \
    -i "${ONPREM_SSH_KEY}" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    "${ONPREM_USER}@${ONPREM_HOST}" \
    bash -s -- \
        "${ONPREM_PROJECT_DIR}" \
        "${TRAEFIK_NETWORK}" \
        "${TRAEFIK_SERVICE}" \
        "${APP_SERVICE}" \
        "${APP_HOSTNAME}" \
        "${CURL_IMAGE}" \
        "${HEALTHCHECK_RETRIES}" \
        "${HEALTHCHECK_INTERVAL}" <<'REMOTE_SCRIPT'

set -Eeuo pipefail


PROJECT_DIR="$1"
TRAEFIK_NETWORK="$2"
TRAEFIK_SERVICE="$3"
APP_SERVICE="$4"
APP_HOSTNAME="$5"
CURL_IMAGE="$6"
HEALTHCHECK_RETRIES="$7"
HEALTHCHECK_INTERVAL="$8"


log() {
    printf '[%s] [ONPREM] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$*"
}

die() {
    printf '[%s] [ONPREM] [ERROR] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$*" >&2

    exit 1
}


COMPOSE_FILE="${PROJECT_DIR}/compose.yml"


command -v docker >/dev/null 2>&1 || die "docker command not found"

[[ -f "${COMPOSE_FILE}" ]] || die "Compose file not found: ${COMPOSE_FILE}"

log "Checking Docker services..."

docker compose -f "${COMPOSE_FILE}" ps

APP_CONTAINER_ID="$(
    docker compose \
        -f "${COMPOSE_FILE}" \
        ps \
        -q "${APP_SERVICE}"
)"

[[ -n "${APP_CONTAINER_ID}" ]] || die "Application container not found"

APP_STATE="$(
    docker inspect \
        -f '{{.State.Status}}' \
        "${APP_CONTAINER_ID}"
)"

if [[ "${APP_STATE}" != "running" ]]; then
    die "Application container is not running: ${APP_STATE}"
fi

log "Application container: RUNNING"


log "Testing application through Traefik..."

for ((i=1; i<=HEALTHCHECK_RETRIES; i++)); do

    if docker run --rm \
        --network "${TRAEFIK_NETWORK}" \
        "${CURL_IMAGE}" \
        -fsS \
        --max-time 5 \
        -H "Host: ${APP_HOSTNAME}" \
        "http://${TRAEFIK_SERVICE}/" \
        >/dev/null
    then
        log "Traefik routing check: OK"
        break
    fi

    if (( i == HEALTHCHECK_RETRIES )); then
        die "Traefik routing healthcheck failed"
    fi

    log "Traefik route not ready. Retry ${i}/${HEALTHCHECK_RETRIES}"

    sleep "${HEALTHCHECK_INTERVAL}"

done

log "============================================================"
log "ON-PREMISES HEALTHCHECK SUCCESSFUL"
log ""
log "Container state    : RUNNING"
log "Traefik routing    : OK"
log ""
log "On-premises environment is ready to receive traffic."
log "============================================================"

REMOTE_SCRIPT


log "On-premises health validation completed successfully"
