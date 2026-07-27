#!/bin/bash
# Claude Code PostToolUse hook: Auto-regenerate derived artifacts on source edits.
#
# One-branch sync handler:
#   1. data/_schemas/system_registry.json edited
#      -> regenerate docs/gdd/systems-index.md (the human-readable view)
#
# The registry is the SOURCE; the systems index is a derived VIEW. The hook
# keeps the view in sync so it never diverges from the registry.
#
# Two upstream branches were removed with the layout unification: an entity-
# manifest regenerator (this studio's entity authority IS the system registry,
# so the manifest had no source) and a separate quick-spec indexer (quick specs
# are ordinary specs and live in docs/specs/ with the rest of the spec
# lifecycle). Both called runners that do not exist, so both could only ever
# print a misleading success line.
#
# Exit behavior: exit 0 always (advisory only, never blocks).

INPUT=$(cat)

# Parse file path
if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Normalize path separators
FILE_PATH=$(echo "$FILE_PATH" | sed 's|\\|/|g')

# Find Python
PYTHON_CMD=""
for cmd in python python3 py; do
    if command -v "$cmd" >/dev/null 2>&1; then
        PYTHON_CMD="$cmd"
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "[sync] Warning: Python not found, cannot regenerate derived artifacts" >&2
    exit 0
fi

# Branch 1: system_registry.json -> systems-index.md
if echo "$FILE_PATH" | grep -qE 'system_registry\.json$'; then
    "$PYTHON_CMD" tools/generate_systems_index.py >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "[sync-systems-index] Auto-regenerated docs/gdd/systems-index.md from registry" >&2
    fi
fi

exit 0
