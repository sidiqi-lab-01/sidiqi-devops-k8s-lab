#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"

echo "========================================"
echo " ISSUES ASSIGNED TO MILESTONES"
echo " Repository: $REPO"
echo "========================================"
echo

gh issue list \
  --repo "$REPO" \
  --state all \
  --limit 200 \
  --json number,title,state,milestone \
  --jq '.[] |
    select(.milestone != null) |
    "#\(.number) | \(.state) | \(.milestone.title) | \(.title)"'
