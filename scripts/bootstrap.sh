#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/opt/epauta}"
DATA_DIR="${DATA_DIR:-/data/epauta}"

APP_UID="${APP_UID:-1000}"
APP_GID="${APP_GID:-1000}"

AWS_REGION="${AWS_REGION:?AWS_REGION is required}"
LITESTREAM_BUCKET="${LITESTREAM_BUCKET:?LITESTREAM_BUCKET is required}"
EPAUTA_HOST="${EPAUTA_HOST:?EPAUTA_HOST is required}"
APP_IMAGE="${APP_IMAGE:?APP_IMAGE is required}"
TUNNEL_TOKEN="${TUNNEL_TOKEN:?TUNNEL_TOKEN is required}"

echo "========================================"
echo " ePauta DR Bootstrap"
echo "========================================"

echo "[INFO] Installing system dependencies"

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
    docker.io \
    curl \
    unzip \
    ca-certificates \
    jq

echo "[INFO] Installing Docker Compose"

mkdir -p /usr/local/lib/docker/cli-plugins

curl -SL \
  https://github.com/docker/compose/releases/download/v2.39.3/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose

chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

echo "[INFO] Installing AWS CLI v2"

curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o /tmp/awscliv2.zip

unzip -q /tmp/awscliv2.zip -d /tmp

/tmp/aws/install

rm -rf /tmp/aws /tmp/awscliv2.zip

systemctl enable docker
systemctl start docker

echo "[INFO] Waiting for Docker daemon"

until docker info >/dev/null 2>&1; do
    sleep 2
done

echo "[INFO] Creating directories"

mkdir -p "${PROJECT_DIR}"
mkdir -p "${PROJECT_DIR}/docker"
mkdir -p "${PROJECT_DIR}/scripts"
mkdir -p "${DATA_DIR}"

echo "[INFO] Configuring database directory"

chown -R "${APP_UID}:${APP_GID}" "${DATA_DIR}"
chmod 750 "${DATA_DIR}"

echo "[INFO] Retrieving application secrets"

SECRET_KEY="$(aws ssm get-parameter \
    --name "/epauta/dr/SECRET_KEY" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text \
    --region "${AWS_REGION}")"

ADMIN_USER="$(aws ssm get-parameter \
    --name "/epauta/dr/ADMIN_USER" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text \
    --region "${AWS_REGION}")"

ADMIN_PASSWORD="$(aws ssm get-parameter \
    --name "/epauta/dr/ADMIN_PASSWORD" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text \
    --region "${AWS_REGION}")"

echo "[INFO] Creating application environment"


cat > "${PROJECT_DIR}/.env" <<EOF
DATA_DIR=${DATA_DIR}
LITESTREAM_DIR=${PROJECT_DIR}/docker

APP_IMAGE=${APP_IMAGE}
APP_UID=${APP_UID}
APP_GID=${APP_GID}

AWS_REGION=${AWS_REGION}
LITESTREAM_BUCKET=${LITESTREAM_BUCKET}

TUNNEL_TOKEN=${TUNNEL_TOKEN}

SECRET_KEY=${SECRET_KEY}
ADMIN_USER=${ADMIN_USER}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

FLASK_ENV=production
EOF



chmod 600 "${PROJECT_DIR}/.env"

echo "[INFO] Restoring SQLite database"

export DATA_DIR
export LITESTREAM_BUCKET
export AWS_REGION

"${PROJECT_DIR}/scripts/restore.sh"

echo "[INFO] Pulling application image"

cd "${PROJECT_DIR}"

docker compose \
    --env-file .env \
    -f docker/compose.yml \
    pull

echo "[INFO] Starting ePauta"

docker compose \
    --env-file .env \
    -f docker/compose.yml \
    up -d

echo "[INFO] Current containers"

docker compose \
    --env-file .env \
    -f docker/compose.yml \
    ps


echo "[INFO] Running application healthcheck"

"${PROJECT_DIR}/scripts/healthcheck.sh"

echo "========================================"
echo " ePauta DR Bootstrap completed"
echo "========================================"
