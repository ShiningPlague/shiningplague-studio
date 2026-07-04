#!/bin/bash
# PostToolUse hook (Write|Edit): headless GDScript parse check.
# On parse failure: prints errors to stderr + exit 2 so Claude sees them
# (exit-0/exit-1 stderr is invisible to the model). Never blocks when the
# Godot binary is absent — engine presence is optional on this machine.

INPUT=$(cat)

# Extract tool_input.file_path — jq preferred, grep fallback.
if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
    FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//')
fi

# Normalize Windows backslashes, only act on .gd files that exist.
FILE_PATH=$(echo "$FILE_PATH" | sed 's|\\|/|g')
case "$FILE_PATH" in
    *.gd) ;;
    *) exit 0 ;;
esac
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Resolve Godot binary: $GODOT_BIN, else PATH lookup, else silent pass.
GODOT="${GODOT_BIN:-}"
if [ -z "$GODOT" ]; then
    GODOT=$(command -v godot 2>/dev/null || true)
fi
if [ -z "$GODOT" ]; then
    exit 0
fi

# Run the parse check with a 20s guard (skip guard if timeout missing).
if command -v timeout >/dev/null 2>&1; then
    OUTPUT=$(timeout 20 "$GODOT" --headless --check-only --script "$FILE_PATH" 2>&1)
else
    OUTPUT=$("$GODOT" --headless --check-only --script "$FILE_PATH" 2>&1)
fi
STATUS=$?

if [ $STATUS -ne 0 ]; then
    echo "GDScript validation FAILED for $FILE_PATH (exit $STATUS):" >&2
    echo "$OUTPUT" >&2
    exit 2
fi

exit 0
