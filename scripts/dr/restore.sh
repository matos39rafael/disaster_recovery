#!/usr/bin/env bash

set -euo pipefail

DATA_DIR="${DATA_DIR:-/data/epauta}"
DB_PATH="${DATA_DIR}/igreja.db"

LITESTREAM_BUCKET="${LITESTREAM_BUCKET:?LITESTREAM_BUCKET is required}"
AWS_REGION="${AWS_REGION:?AWS_REGION is required}"

LITESTREAM_IMAGE="${LITESTREAM_IMAGE:-litestream/litestream:latest}"

mkdir -p "${DATA_DIR}"

echo "[INFO] Starting SQLite restore"
echo "[INFO] Destination: ${DB_PATH}"
echo "[INFO] S3 bucket: ${LITESTREAM_BUCKET}"

if [[ -f "${DB_PATH}" ]]; then
    BACKUP="${DB_PATH}.pre-restore.$(date +%Y%m%d%H%M%S)"

    echo "[WARNING] Existing database found."
    echo "[INFO] Moving existing database to ${BACKUP}"

    mv "${DB_PATH}" "${BACKUP}"
fi

docker run --rm \
    --user 0:0 \
    -e AWS_REGION="${AWS_REGION}" \
    -e LITESTREAM_BUCKET="${LITESTREAM_BUCKET}" \
    -v "${DATA_DIR}:/data" \
    "${LITESTREAM_IMAGE}" \
    restore \
    -o /data/igreja.db \
    "s3://${LITESTREAM_BUCKET}/sqlite/epauta/"

chown "${APP_UID:-1000}:${APP_GID:-1000}" "${DB_PATH}"
chmod 660 "${DB_PATH}"

echo "[INFO] Restore completed."

ls -lh "${DB_PATH}"
