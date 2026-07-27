#!/bin/bash
# Claude Code PreToolUse hook: Validates git commit commands
# Receives JSON on stdin with tool_input.command
# Exit 0 = allow, Exit 2 = block (stderr shown to Claude)
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "git commit -m ..." } }

INPUT=$(cat)

# Parse command -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    COMMAND=$(echo "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Only process git commit commands. Match 'git commit' anywhere in the
# command (covers 'cd x && git commit' and 'git -C path commit' forms).
if ! echo "$COMMAND" | grep -qE 'git([[:space:]]+-C[[:space:]]+[^[:space:]]+)*[[:space:]]+commit'; then
    exit 0
fi

# Get staged files
STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
    exit 0
fi

WARNINGS=""

# Check design documents for required sections
DESIGN_FILES=$(echo "$STAGED" | grep -E '^docs/gdd/')
if [ -n "$DESIGN_FILES" ]; then
    while IFS= read -r file; do
        # Skip auto-generated / different-format files
        case "$file" in
            docs/gdd/systems-index.md|docs/gdd/game-concept.md) continue ;;
        esac
        if [[ "$file" == *.md ]] && [ -f "$file" ]; then
            for section in "Overview" "Player Fantasy" "Detailed" "Formulas" "Edge Cases" "Dependencies" "Tuning Knobs" "Acceptance Criteria"; do
                if ! grep -qi "$section" "$file"; then
                    WARNINGS="$WARNINGS\nDESIGN: $file missing required section: $section"
                fi
            done
        fi
    done <<< "$DESIGN_FILES"
fi

# Validate JSON data files -- block invalid JSON
DATA_FILES=$(echo "$STAGED" | grep -E '^data/.*\.json$')
if [ -n "$DATA_FILES" ]; then
    # Find a working Python command
    PYTHON_CMD=""
    for cmd in python python3 py; do
        if command -v "$cmd" >/dev/null 2>&1; then
            PYTHON_CMD="$cmd"
            break
        fi
    done

    while IFS= read -r file; do
        if [ -f "$file" ]; then
            if [ -n "$PYTHON_CMD" ]; then
                if ! "$PYTHON_CMD" -m json.tool "$file" > /dev/null 2>&1; then
                    echo "BLOCKED: $file is not valid JSON" >&2
                    exit 2
                fi
            else
                echo "WARNING: Cannot validate JSON (python not found): $file" >&2
            fi
        fi
    done <<< "$DATA_FILES"
fi

# Check for hardcoded gameplay values in gameplay code
# Uses grep -E (POSIX extended) instead of grep -P (Perl) for cross-platform compatibility
CODE_FILES=$(echo "$STAGED" | grep -E '^src/gameplay/')
if [ -n "$CODE_FILES" ]; then
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            if grep -qE '(damage|health|speed|rate|chance|cost|duration)[[:space:]]*[:=][[:space:]]*[0-9]+' "$file" 2>/dev/null; then
                WARNINGS="$WARNINGS\nCODE: $file may contain hardcoded gameplay values. Use data files."
            fi
        fi
    done <<< "$CODE_FILES"
fi

# Check for TODO/FIXME without assignee -- uses grep -E instead of grep -P
SRC_FILES=$(echo "$STAGED" | grep -E '^src/')
if [ -n "$SRC_FILES" ]; then
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            if grep -qE '(TODO|FIXME|HACK)[^(]' "$file" 2>/dev/null; then
                WARNINGS="$WARNINGS\nSTYLE: $file has TODO/FIXME without owner tag. Use TODO(name) format."
            fi
        fi
    done <<< "$SRC_FILES"
fi

# Check if registry/memory should have been updated (auto-update nag)
# If we're committing docs/, .claude/skills/, data/ or production/ files
# but NOT system_registry.json, remind to check if registry needs updating.
INFRA_FILES=$(echo "$STAGED" | grep -E '^(docs/|\.claude/skills/|data/|production/|tools/)')
REGISTRY_INCLUDED=$(echo "$STAGED" | grep -c 'system_registry.json')
if [ -n "$INFRA_FILES" ] && [ "$REGISTRY_INCLUDED" -eq 0 ]; then
    WARNINGS="$WARNINGS\nREGISTRY: Committing infrastructure files but NOT system_registry.json. Check: does documentation_stack need updating? New docs/skills/tools created?"
fi

# Emit warnings (non-blocking) as PreToolUse additionalContext JSON on stdout.
# exit-0 stderr is INVISIBLE to Claude — only hookSpecificOutput reaches it.
if [ -n "$WARNINGS" ]; then
    CONTEXT="$(printf "%b" "=== Commit Validation Warnings ===$WARNINGS\n================================")"
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$CONTEXT" | jq -Rsa '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: .}}'
    else
        ESCAPED="$(printf '%s' "$CONTEXT" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n' '\f' | sed 's/\f/\\n/g')"
        printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$ESCAPED"
    fi
fi

exit 0
