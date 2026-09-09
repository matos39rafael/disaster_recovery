#!/usr/bin/env bash
set -euo pipefail

: "${DR_INSTANCE_ID:?DR_INSTANCE_ID is required}"


COMMAND_ID=$(aws ssm send-command \
  --instance-ids "${DR_INSTANCE_ID}" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "cd /opt/epauta",
    "docker compose --env-file .env -f docker/compose.yml stop app",
    "sleep 5",
    "docker compose --env-file .env -f docker/compose.yml logs --tail=50 litestream",
    "docker compose --env-file .env -f docker/compose.yml stop litestream"
  ]' \
  --query 'Command.CommandId' \
  --output text)

echo "Stopping app and waiting finshing backup to stop litestream."

aws ssm wait command-executed \
  --command-id "$COMMAND_ID" \
  --instance-id "${DR_INSTANCE_ID}"

aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "${DR_INSTANCE_ID}"




