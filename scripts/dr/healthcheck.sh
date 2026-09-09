#!/usr/bin/env bash

set -euo pipefail

URL="${1:-http://localhost:5000}"

echo "[INFO] Checking application: ${URL}"

if curl \
    --silent \
    --show-error \
    --fail \
    --max-time 10 \
    "${URL}" \
    > /dev/null; then

    echo "[OK] ePauta is responding."
    exit 0

else

    echo "[ERROR] ePauta is not responding."
    exit 1

fi
