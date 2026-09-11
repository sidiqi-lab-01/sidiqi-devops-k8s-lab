#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"

echo "========================================"
echo " GITHUB MILESTONE SUMMARY"
echo " Repository: $REPO"
echo "========================================"
echo

gh issue list \
  --repo "$REPO" \
  --state all \
  --limit 200 \
  --json number,title,state,milestone \
  --jq '
    [.[] | select(.milestone != null)]
    | sort_by(.milestone.title)
    | group_by(.milestone.title)
    | .[]
    | "=== \(.[0].milestone.title) ===",
      (.[] | "#\(.number) | \(.state) | \(.title)"),
      ""
  '
