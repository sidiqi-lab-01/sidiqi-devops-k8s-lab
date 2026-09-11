#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"

echo "========================================"
echo " ALL GITHUB MILESTONES"
echo " Repository: $REPO"
echo "========================================"

echo
echo "=== OPEN MILESTONES ==="

gh api \
  --method GET \
  "repos/$REPO/milestones" \
  -f state=open \
  -f per_page=100 \
  --jq '.[] |
    "\(.number) | \(.title) | State: \(.state) | Open issues: \(.open_issues) | Closed issues: \(.closed_issues)"'

echo
echo "=== CLOSED MILESTONES ==="

gh api \
  --method GET \
  "repos/$REPO/milestones" \
  -f state=closed \
  -f per_page=100 \
  --jq '.[] |
    "\(.number) | \(.title) | State: \(.state) | Open issues: \(.open_issues) | Closed issues: \(.closed_issues)"'

echo
echo "========================================"
echo " MILESTONE TOTALS"
echo "========================================"

OPEN_COUNT=$(
  gh api \
    --method GET \
    "repos/$REPO/milestones" \
    -f state=open \
    -f per_page=100 \
    --jq 'length'
)

CLOSED_COUNT=$(
  gh api \
    --method GET \
    "repos/$REPO/milestones" \
    -f state=closed \
    -f per_page=100 \
    --jq 'length'
)

TOTAL_COUNT=$((OPEN_COUNT + CLOSED_COUNT))

echo "Open milestones:   $OPEN_COUNT"
echo "Closed milestones: $CLOSED_COUNT"
echo "Total milestones:  $TOTAL_COUNT"

echo
echo "Milestone report completed successfully."
