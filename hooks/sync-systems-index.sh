#!/bin/bash
# Claude Code PostToolUse hook: Auto-regenerate derived artifacts on source edits.
#
# Three-branch sync handler:
#   1. data/_schemas/system_registry.json edited
#      -> regenerate design/gdd/systems-index.md (Donchitos systems-index format)
#   2. docs/quick-specs/*.md edited
#      -> regenerate docs/quick-specs/INDEX.md + update registry.quick_spec_index[]
#   3. data/<type>/*.json edited (except _schemas/)
#      -> regenerate design/registry/entities.yaml (Donchitos entities manifest)
#
# All registries / manifests stay derived artifacts. The hook keeps them in
# sync automatically so they never diverge from the source JSONs.
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
        echo "[sync-systems-index] Auto-regenerated design/gdd/systems-index.md from registry" >&2
    fi
fi

# Branch 2: docs/quick-specs/*.md (excluding INDEX.md + README.md) -> regenerate INDEX
if echo "$FILE_PATH" | grep -qE 'docs/quick-specs/.+\.md$' \
   && ! echo "$FILE_PATH" | grep -qE 'docs/quick-specs/(INDEX|README)\.md$'; then
    "$PYTHON_CMD" tools/generate_quick_specs_index.py >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "[sync-quick-specs] Auto-regenerated docs/quick-specs/INDEX.md + registry" >&2
    fi
fi

# Branch 3: data/<type>/*.json (excluding _schemas/) -> regenerate entities.yaml
if echo "$FILE_PATH" | grep -qE 'data/[^/]+/[^/]+\.json$' \
   && ! echo "$FILE_PATH" | grep -qE 'data/_schemas/'; then
    "$PYTHON_CMD" tools/generate_entities_yaml.py >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "[sync-entities] Auto-regenerated design/registry/entities.yaml" >&2
    fi
fi

exit 0
