#!/usr/bin/env bash
set -Eeuo pipefail

: "${ONPREM_HOST:?ONPREM_HOST is required}" 
: "${ONPREM_USER:?ONPREM_USER is required}" 
: "${ONPREM_SSH_KEY:?ONPREM_SSH_KEY is required}" 
: "${ONPREM_PROJECT_DIR:?ONPREM_PROJECT_DIR is required}" 
: "${ONPREM_ENV_FILE:?ONPREM_ENV_FILE is required}" 

log() { 
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

die() {
   printf '[%s] [ERROR] %s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" \
    "$*" >&2 
  
  exit 1 
}

command -v ssh >/dev/null 2>&1 || die "ssh command not found" 
[[ -f "${ONPREM_SSH_KEY}" ]] || die "SSH private key not found: ${ONPREM_SSH_KEY}"


log "Starting on-premises stack" 
log "Host : ${ONPREM_HOST}" 
log "User : ${ONPREM_USER}" 


ssh \
    -i "${ONPREM_SSH_KEY}" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    "${ONPREM_USER}@${ONPREM_HOST}" \
    bash -s -- \
        "${ONPREM_PROJECT_DIR}" \
        "${ONPREM_ENV_FILE}" <<'REMOTE_SCRIPT'

set -Eeuo pipefail

# Argumentos recebidos através do SSH

PROJECT_DIR="$1"
ENV_FILE="$2"

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


command -v docker >/dev/null 2>&1 || die "docker command not found"

[[ -d "${PROJECT_DIR}" ]] || die "Project directory not found: ${PROJECT_DIR}"

[[ -f "${ENV_FILE}" ]] || die "Environment file not found: ${ENV_FILE}"

COMPOSE_FILE="${PROJECT_DIR}/compose.yml"

[[ -f "${COMPOSE_FILE}" ]] || die "Compose file not found: ${COMPOSE_FILE}"


log "Starting application and Litestream..."

docker compose \
    --env-file "${ENV_FILE}" \
    -f "${COMPOSE_FILE}" \
    up -d

log "Application stack started"

REMOTE_SCRIPT

log "On-premises stack started successfully"