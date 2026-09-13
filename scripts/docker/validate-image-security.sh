#!/usr/bin/env bash

set -euo pipefail

IMAGE="${1:-}"

if [[ -z "$IMAGE" ]]; then
    echo "Usage: $0 <image:tag>"
    exit 1
fi

echo "========================================"
echo "Container Image Security Validation"
echo "========================================"
echo "Image: $IMAGE"
echo

echo "=== Image Identity ==="
docker image inspect "$IMAGE" \
    --format 'ID={{.Id}}'

echo
echo "=== Configured Runtime User ==="
USER_VALUE="$(docker image inspect "$IMAGE" \
    --format '{{if .Config.User}}{{.Config.User}}{{else}}root-default{{end}}')"

echo "User=$USER_VALUE"

if [[ "$USER_VALUE" == "root-default" || "$USER_VALUE" == "root" || "$USER_VALUE" == "0" ]]; then
    echo "FAIL: Image is configured to run as root."
    exit 2
else
    echo "PASS: Explicit non-root user configured."
fi

echo
echo "=== Working Directory ==="
docker image inspect "$IMAGE" \
    --format 'WorkingDir={{.Config.WorkingDir}}'

echo
echo "=== Exposed Ports ==="
docker image inspect "$IMAGE" \
    --format 'Ports={{json .Config.ExposedPorts}}'

echo
echo "=== Image History ==="
docker history --no-trunc "$IMAGE"

echo
echo "=== HIGH / CRITICAL Vulnerability Scan ==="

if command -v trivy >/dev/null 2>&1; then
    trivy image \
        --severity HIGH,CRITICAL \
        --ignore-unfixed \
        "$IMAGE"
else
    echo "WARNING: Trivy is not installed; vulnerability scan skipped."
fi

echo
echo "========================================"
echo "Validation completed: $IMAGE"
echo "========================================"
