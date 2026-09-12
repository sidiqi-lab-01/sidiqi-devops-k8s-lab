#!/usr/bin/env bash
set -euo pipefail

OWNER="sidiqi-lab-01"
REPO="sidiqi-devops-k8s-lab"
PROJECT_NUMBER="2"

echo "========================================"
echo " ADD ROADMAP ISSUES TO GITHUB PROJECT"
echo " Owner:   $OWNER"
echo " Repo:    $REPO"
echo " Project: $PROJECT_NUMBER"
echo "========================================"

for ISSUE_NUMBER in $(seq 69 116); do

  ISSUE_URL="https://github.com/$OWNER/$REPO/issues/$ISSUE_NUMBER"

  echo
  echo "Processing issue #$ISSUE_NUMBER"

  if gh project item-add "$PROJECT_NUMBER" \
      --owner "$OWNER" \
      --url "$ISSUE_URL" >/dev/null 2>&1; then

    echo "[ADDED] Issue #$ISSUE_NUMBER"

  else
    echo "[INFO] Issue #$ISSUE_NUMBER may already exist in the project or could not be added."
  fi

done

echo
echo "========================================"
echo " PROJECT POPULATION COMPLETE"
echo "========================================"
