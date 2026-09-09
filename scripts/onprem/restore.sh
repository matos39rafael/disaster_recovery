#!/usr/bin/env bash
set -Eeuo pipefail

: "${ONPREM_HOST:?ONPREM_HOST is required}"
: "${ONPREM_USER:?ONPREM_USER is required}"
: "${ONPREM_SSH_KEY:?ONPREM_SSH_KEY is required}"
: "${BUCKET:?BUCKET is required}"
: "${REGION:?REGION is required}"
: "${ONPREM_PROJECT_DIR:?ONPREM_PROJECT_DIR is required}"
: "${ONPREM_ENV_FILE:?ONPREM_ENV_FILE is required}"


VOLUME="${ONPREM_VOLUME:-epauta_v2_data}"
DB_FILE="${DB_FILE:-igreja.db}"
LITESTREAM_IMAGE="${LITESTREAM_IMAGE:-litestream/litestream:0.5.17}"
SQLITE_IMAGE="${SQLITE_IMAGE:-keinos/sqlite3:latest}"
ALPINE_IMAGE="${ALPINE_IMAGE:-alpine:3.22}"

APP_UID="${APP_UID:-1000}"
APP_GID="${APP_GID:-1000}"

FAILBACK_MARKER="${FAILBACK_MARKER:-TESTE_DR_FAILBACK}"


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


log "Starting on-premises failback restore"
log "Host : ${ONPREM_HOST}"
log "User : ${ONPREM_USER}"
log "S3 bucket : ${BUCKET}"
log "AWS region: ${REGION}"


#Execução Remota

ssh \
    -i "${ONPREM_SSH_KEY}" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    "${ONPREM_USER}@${ONPREM_HOST}" \
    bash -s -- \
        "${ONPREM_PROJECT_DIR}" \
        "${ONPREM_ENV_FILE}" \
        "${VOLUME}" \
        "${DB_FILE}" \
        "${BUCKET}" \
        "${REGION}" \
        "${LITESTREAM_IMAGE}" \
        "${SQLITE_IMAGE}" \
        "${ALPINE_IMAGE}" \
        "${APP_UID}" \
        "${APP_GID}" \
        "${FAILBACK_MARKER}" <<'REMOTE_SCRIPT'

set -Eeuo pipefail

# Argumentos recebidos através do SSH

PROJECT_DIR="$1"
ENV_FILE="$2"
VOLUME="$3"
DB_FILE="$4"
BUCKET="$5"
REGION="$6"
LITESTREAM_IMAGE="$7"
SQLITE_IMAGE="$8"
ALPINE_IMAGE="$9"

shift 9

APP_UID="$1"
APP_GID="$2"
FAILBACK_MARKER="$3"

DB_PATH="/data/${DB_FILE}"


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


log "Loading AWS credentials from local .env"

set -a
source "${ENV_FILE}"
set +a


: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID is required}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY is required}"

log "Stopping application and Litestream..."

docker compose \
    --env-file "${ENV_FILE}" \
    -f "${COMPOSE_FILE}" \
    down

log "Application stack stopped"

log "Creating safety backup of current on-premises database"

docker run --rm \
    --user 0:0 \
    -v "${VOLUME}:/data" \
    "${ALPINE_IMAGE}" \
    sh -eu -c '
        DB_FILE="$1"

        TIMESTAMP="$(date +%Y%m%d%H%M%S)"

        if [ -f "/data/${DB_FILE}" ]; then

            BACKUP="/data/${DB_FILE}.pre-failback.${TIMESTAMP}"

            cp "/data/${DB_FILE}" "${BACKUP}"

            echo "[INFO] Safety backup created: ${BACKUP}"

        else

            echo "[WARN] Existing database not found"

        fi

        rm -f \
            "/data/${DB_FILE}" \
            "/data/${DB_FILE}-wal" \
            "/data/${DB_FILE}-shm"

    ' sh "${DB_FILE}"

log "Restoring latest Litestream replica from S3"

docker run --rm \
    --user 0:0 \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_REGION="${REGION}" \
    -e AWS_DEFAULT_REGION="${REGION}" \
    -v "${VOLUME}:/data" \
    "${LITESTREAM_IMAGE}" \
    restore \
        -o "${DB_PATH}" \
        "s3://${BUCKET}/sqlite/epauta/"

log "Checking restored database file"

docker run --rm \
    -v "${VOLUME}:/data:ro" \
    "${ALPINE_IMAGE}" \
    test -f "${DB_PATH}" \
    || die "Restored database not found"


log "Fixing database ownership and permissions"

docker run --rm \
    --user 0:0 \
    -v "${VOLUME}:/data" \
    "${ALPINE_IMAGE}" \
    sh -eu -c '
        DB_PATH="$1"
        APP_UID="$2"
        APP_GID="$3"

        chown "${APP_UID}:${APP_GID}" "${DB_PATH}"
        chmod 660 "${DB_PATH}"
    ' sh \
        "${DB_PATH}" \
        "${APP_UID}" \
        "${APP_GID}"


log "Running SQLite integrity_check"

INTEGRITY_RESULT="$(
    docker run --rm \
        -v "${VOLUME}:/data:ro" \
        "${SQLITE_IMAGE}" \
        "${DB_PATH}" \
        "PRAGMA integrity_check;"
)"

if [[ "${INTEGRITY_RESULT}" != "ok" ]]; then

    die "SQLite integrity_check failed: ${INTEGRITY_RESULT}"

fi

log "SQLite integrity_check: OK"


log "Searching for DR marker: ${FAILBACK_MARKER}"

MARKER_COUNT="$(
    docker run --rm \
        -v "${VOLUME}:/data:ro" \
        "${SQLITE_IMAGE}" \
        "${DB_PATH}" \
        "
        SELECT COUNT(*)
        FROM item
        WHERE titulo = '${FAILBACK_MARKER}';
        "
)"


if ! [[ "${MARKER_COUNT}" =~ ^[0-9]+$ ]]; then

    die "Unexpected SQLite result: ${MARKER_COUNT}"

fi

if (( MARKER_COUNT < 1 )); then

    die "Marker '${FAILBACK_MARKER}' not found in restored database"

fi

log "Marker '${FAILBACK_MARKER}' found (${MARKER_COUNT} record(s))"


log "============================================================"
log "ON-PREMISES DATABASE RESTORE SUCCESSFUL"
log ""
log "SQLite integrity : OK"
log "DR marker        : FOUND"
log "Database         : ${DB_FILE}"
log ""
log "Application remains STOPPED"
log "============================================================"

REMOTE_SCRIPT


log "On-premises restore completed successfully"
