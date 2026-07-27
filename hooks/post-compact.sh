#!/usr/bin/env bash
# post-compact.sh — fires after conversation compaction
# Reminds Claude to restore session state from the file-backed checkpoint.

ACTIVE="production/session-state/active.md"

echo "=== Context Restored After Compaction ==="

# The installer seeds $ACTIVE, so "-f" alone would send Claude to read a blank
# skeleton "to restore your working context". The scaffold-seed marker (see
# .claude/docs/doc-stack.md) is what tells the two apart.
if [ -f "$ACTIVE" ] && grep -q "scaffold-seed: unwritten" "$ACTIVE" 2>/dev/null; then
  echo "$ACTIVE is still the seeded skeleton — no checkpoint was written."
  echo "Rebuild context from the conversation; write the handover before you close."
elif [ -f "$ACTIVE" ]; then
  SIZE=$(wc -l < "$ACTIVE" 2>/dev/null || echo "?")
  echo "Session state file exists: $ACTIVE ($SIZE lines)"
  echo "IMPORTANT: Read this file now to restore your working context."
  echo "It contains: current task, decisions made, files in progress, open questions."
else
  echo "No session state file found at $ACTIVE"
  echo "If you were mid-task, check production/session-logs/ for the last session audit."
fi

echo "========================================="
