#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1
    pwd
)"

LOCAL_PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
TERRAFORM_DIR="${LOCAL_PROJECT_DIR}/terraform"

DR_PROJECT_DIR=/opt/epauta
DATA_DIR=/opt/epauta/data
LITESTREAM_DIR=/opt/epauta/litestream
BUCKET="$(terraform -chdir="$TERRAFORM_DIR" output -raw dr_backup_bucket)"
REGION="$(terraform -chdir="$TERRAFORM_DIR" output -raw aws_region)"
ONPREM_PROJECT_DIR="/home/ubuntu/docker/epauta_v2" 
ONPREM_ENV_FILE="${ONPREM_PROJECT_DIR}/.env"
APP_HOSTNAME="epauta.rafaelmatos.me"




echo "[INFO] Discovering DR instance..."

DR_INSTANCE_ID="$(
    terraform \
        -chdir="${TERRAFORM_DIR}" \
        output -raw dr_instance_id
)"

if [[ -z "$DR_INSTANCE_ID" ]]; then
    echo "[ERROR] Unable to determine DR instance ID."
    exit 1
fi

echo "[OK] DR instance: $DR_INSTANCE_ID"

INSTANCE_STATE=$(
    aws ec2 describe-instances \
        --instance-ids "$DR_INSTANCE_ID" \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text
)

if [[ "$INSTANCE_STATE" != "running" ]]; then
    echo "[ERROR] DR instance is not running: $INSTANCE_STATE"
    exit 1
fi


SSM_STATUS=$(
    aws ssm describe-instance-information \
        --filters "Key=InstanceIds,Values=$DR_INSTANCE_ID" \
        --query 'InstanceInformationList[0].PingStatus' \
        --output text
)

if [[ "$SSM_STATUS" != "Online" ]]; then
    echo "[ERROR] DR instance is not available through SSM."
    exit 1
fi

echo "[OK] DR instance is running and SSM is online."


export DR_PROJECT_DIR
export DATA_DIR
export LITESTREAM_DIR
export TERRAFORM_DIR
export DR_INSTANCE_ID
export BUCKET
export REGION
export ONPREM_HOST="100.84.230.51"
export ONPREM_USER="ubuntu"
export ONPREM_SSH_KEY="${HOME}/.ssh/id_ed25519"
export ONPREM_PROJECT_DIR
export ONPREM_ENV_FILE
export APP_HOSTNAME


step() {
    echo
    echo "=================================================="
    echo "$1"
    echo "=================================================="
}

step "1. Demoting AWS DR"
"${SCRIPT_DIR}/aws/demote-dr.sh"

step "2. Restoring database on-premises"
"${SCRIPT_DIR}/onprem/restore.sh"

step "3. Starting on-premises application"
"${SCRIPT_DIR}/onprem/start-onprem.sh"

step "4. Validating on-premises health"
"${SCRIPT_DIR}/onprem/healthcheck.sh"

step "5. Switching traffic to on-premises"
"${SCRIPT_DIR}/terraform/transition.sh"

step "6. Validating public endpoint"
"${SCRIPT_DIR}/validate-public-endpoint.sh"

step "7. Deprovisioning AWS DR"
"${SCRIPT_DIR}/terraform/destroy-dr.sh"

echo "[OK] Failback completed successfully"

