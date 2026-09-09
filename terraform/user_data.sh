#!/bin/bash

set -euo pipefail

exec > >(tee /var/log/epauta-user-data.log | logger -t epauta-user-data -s 2>/dev/console) 2>&1

echo "========================================"
echo " ePauta DR - User Data"
echo "========================================"

# shellcheck disable=SC2034
PROJECT_DIR="/opt/epauta"

echo "[INFO] Creating project directories"

mkdir -p "$${PROJECT_DIR}/docker"
mkdir -p "$${PROJECT_DIR}/scripts"

echo "[INFO] Installing compose.yml"

cat > "$${PROJECT_DIR}/docker/compose.yml" <<'COMPOSE_EOF'
${compose}
COMPOSE_EOF

echo "[INFO] Installing litestream.yml"

cat > "$${PROJECT_DIR}/docker/litestream.yml" <<'LITESTREAM_EOF'
${litestream}
LITESTREAM_EOF

echo "[INFO] Installing bootstrap.sh"

cat > "$${PROJECT_DIR}/scripts/bootstrap.sh" <<'BOOTSTRAP_EOF'
${bootstrap}
BOOTSTRAP_EOF


echo "[INFO] Installing healthcheck.sh"

cat > "$${PROJECT_DIR}/scripts/healthcheck.sh" <<'HEALTHCHECK_EOF'
${healthcheck}
HEALTHCHECK_EOF

echo "[INFO] Installing restore.sh"

cat > "$${PROJECT_DIR}/scripts/restore.sh" <<'RESTORE_EOF'
${restore}
RESTORE_EOF

echo "[INFO] Starting bootstrap"
chmod 750 "$${PROJECT_DIR}/scripts/"*.sh

# shellcheck disable=SC2154
export AWS_REGION="${aws_region}"

# shellcheck disable=SC2154
export LITESTREAM_BUCKET="${litestream_bucket}"

# shellcheck disable=SC2154
export EPAUTA_HOST="${epauta_host}"

# shellcheck disable=SC2154
export APP_IMAGE="${app_image}"

# shellcheck disable=SC2154
export TUNNEL_TOKEN="${tunnel_token}"

"$${PROJECT_DIR}/scripts/bootstrap.sh"

echo "========================================"
echo " ePauta DR - Bootstrap completed"
echo "========================================"
