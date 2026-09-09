#!/usr/bin/env bash
set -Eeuo pipefail

: "${TERRAFORM_DIR:?TERRAFORM_DIR is required}"

PLAN_FILE="${TERRAFORM_DIR}/transition.tfplan"

log() {
    printf '[%s] [TERRAFORM] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$*"
}

die() {
    printf '[%s] [TERRAFORM] [ERROR] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$*" >&2
    exit 1
}


command -v terraform >/dev/null 2>&1 \
    || die "terraform command not found"

[[ -d "${TERRAFORM_DIR}" ]] \
    || die "Terraform directory not found: ${TERRAFORM_DIR}"


log "Initializing Terraform..."

terraform \
    -chdir="${TERRAFORM_DIR}" \
    init \
    -input=false


log "Validating Terraform configuration..."

terraform \
    -chdir="${TERRAFORM_DIR}" \
    validate


log "Creating cutover plan..."

terraform \
    -chdir="${TERRAFORM_DIR}" \
    plan -var-file=environments/failback.tfvars \
    -var-file=terraform.tfvars \
    -out=${PLAN_FILE}


log "Applying cutover to failback..."

terraform \
    -chdir="${TERRAFORM_DIR}" \
    apply -auto-approve \
    "${PLAN_FILE}"


log "Traffic transition completed successfully."

