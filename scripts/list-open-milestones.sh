#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"

echo "========================================"
echo " OPEN GITHUB MILESTONES"
echo " Repository: $REPO"
echo "========================================"
echo

gh api \
  --method GET \
  "repos/$REPO/milestones" \
  -f state=open \
  -f per_page=100 \
  --jq '.[] |
    "\(.number) | \(.title) | State: \(.state) | Open issues: \(.open_issues) | Closed issues: \(.closed_issues)"'
