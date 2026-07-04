#!/bin/bash
# SessionEnd hook: append ONE snapshot block to the session log.
# (Replaces the old session-stop.sh which fired on Stop — every turn —
# and produced a 12.5MB log. SessionEnd fires once per session.)
# Always exits 0 — logging must never block session teardown.

LOG_DIR="production/session-logs"
LOG_FILE="$LOG_DIR/session-log.md"

mkdir -p "$LOG_DIR" 2>/dev/null

TIMESTAMP=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
MODIFIED_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d '[:space:]')

{
    echo ""
    echo "## Session end — $TIMESTAMP"
    echo ""
    echo "- Branch: $BRANCH"
    echo "- Modified files (git status --porcelain): ${MODIFIED_COUNT:-0}"
    echo "- Last 5 commits:"
    git log --oneline -5 2>/dev/null | sed 's/^/    /'
} >> "$LOG_FILE" 2>/dev/null

exit 0
