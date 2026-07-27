#!/bin/bash
# Claude Code SessionStart hook: Load project context at session start
# Outputs context information that Claude sees when a session begins
#
# Input schema (SessionStart): No stdin input

echo "=== ShiningPlague Game Studio — Session Context (framework adopted from Donchitos Claude Code Game Studios) ==="

# Current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$BRANCH" ]; then
    echo "Branch: $BRANCH"

    # Recent commits
    echo ""
    echo "Recent commits:"
    git log --oneline -5 2>/dev/null | while read -r line; do
        echo "  $line"
    done
fi

# Current sprint (find most recent sprint file)
LATEST_SPRINT=$(ls -t production/sprints/sprint-*.md 2>/dev/null | head -1)
if [ -n "$LATEST_SPRINT" ]; then
    echo ""
    echo "Active sprint: $(basename "$LATEST_SPRINT" .md)"
fi

# Current milestone
LATEST_MILESTONE=$(ls -t production/milestones/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_MILESTONE" ]; then
    echo "Active milestone: $(basename "$LATEST_MILESTONE" .md)"
fi

# Open bug count
BUG_COUNT=0
for dir in tests/playtest production; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -name "BUG-*.md" 2>/dev/null | wc -l)
        BUG_COUNT=$((BUG_COUNT + count))
    fi
done
if [ "$BUG_COUNT" -gt 0 ]; then
    echo "Open bugs: $BUG_COUNT"
fi

# Code health quick check
if [ -d "src" ]; then
    TODO_COUNT=$(grep -r "TODO" src/ 2>/dev/null | wc -l)
    FIXME_COUNT=$(grep -r "FIXME" src/ 2>/dev/null | wc -l)
    if [ "$TODO_COUNT" -gt 0 ] || [ "$FIXME_COUNT" -gt 0 ]; then
        echo ""
        echo "Code health: ${TODO_COUNT} TODOs, ${FIXME_COUNT} FIXMEs in src/"
    fi
fi

# --- Workstream state overview ---
WORKSTREAM_DIR="production/workstreams"
if [ -d "$WORKSTREAM_DIR" ]; then
    WS_COUNT=$(find "$WORKSTREAM_DIR" -name "*.md" ! -name "TEMPLATE.md" 2>/dev/null | wc -l)
    if [ "$WS_COUNT" -gt 0 ]; then
        echo ""
        echo "=== WORKSTREAM STATES ==="
        echo "Active workstreams: $WS_COUNT"
        for ws_file in "$WORKSTREAM_DIR"/*.md; do
            ws_name=$(basename "$ws_file" .md)
            if [ "$ws_name" != "TEMPLATE" ]; then
                # Extract current phase from the file header
                ws_phase=$(grep -m1 "Current Phase:" "$ws_file" 2>/dev/null | sed 's/.*Current Phase:\*\* //' | sed 's/>.*//')
                ws_updated=$(grep -m1 "Last Updated:" "$ws_file" 2>/dev/null | sed 's/.*Last Updated:\*\* //' | sed 's/>.*//')
                echo "  - $ws_name: phase=$ws_phase (updated: $ws_updated)"
            fi
        done
        echo "=== END WORKSTREAM STATES ==="
    fi
fi

# --- Active session state recovery ---
# The installer SEEDS this file, so "-f" alone announced "a previous session left
# state" at a project whose first session had not started yet. The seed carries the
# scaffold-seed marker (see .claude/docs/doc-stack.md); a file still carrying it is
# the untouched skeleton, not a handover.
STATE_FILE="production/session-state/active.md"
if [ -f "$STATE_FILE" ] && grep -q "scaffold-seed: unwritten" "$STATE_FILE" 2>/dev/null; then
    echo ""
    echo "=== NO PRIOR SESSION ==="
    echo "$STATE_FILE is still the seeded skeleton — nothing has been handed over yet."
    echo "This is a fresh install. Say \"start\" for guided onboarding."
elif [ -f "$STATE_FILE" ]; then
    echo ""
    echo "=== ACTIVE SESSION STATE DETECTED ==="
    echo "A previous session left state at: $STATE_FILE"
    echo "Read this file to recover context and continue where you left off."
    echo ""
    echo "Quick summary:"
    # head -40 instead of head -20 — the first ~13 lines of active.md are
    # header + how-this-file-works boilerplate; meaningful "Current project
    # state" starts ~L14. 40 lines catches enough state for the snippet.
    head -40 "$STATE_FILE" 2>/dev/null
    TOTAL_LINES=$(wc -l < "$STATE_FILE" 2>/dev/null)
    if [ "$TOTAL_LINES" -gt 40 ]; then
        echo "  ... ($TOTAL_LINES total lines — read the full file to continue)"
    fi
    echo "=== END SESSION STATE PREVIEW ==="
fi

# --- DYNAMIC SESSION CONTEXT (flags, bugs, templates, menu enforcement) ---
# generate_session_context.sh is an OPTIONAL project-specific context script.
# Absent by default in a fresh install — the guard skips it cleanly. Add your own
# if you want richer per-project context (flags, bugs, phase-artifact status).
CONTEXT_SCRIPT="$(dirname "$0")/../../tools/generate_session_context.sh"
if [ -f "$CONTEXT_SCRIPT" ]; then
    bash "$CONTEXT_SCRIPT"
fi

# --- CANONICAL-RECOMMENDED NEXT ACTION (mechanical, zero-LLM) ---
# Derived from production/flow-ledger.yaml cross-checked against artifact evidence
# on disk by tools/workflow_state_check.py. Ships with the framework — no project
# customization required. If no ledger exists yet, the tool prints BOOTSTRAP MODE
# and writes a draft you review + rename (see templates/flow-ledger.TEMPLATE.yaml).
# Edit the LEDGER to change posture / rule-pending / recommended-next — not the hook.
echo ""
echo "=== CANONICAL-RECOMMENDED NEXT ACTION (from flow-ledger) ==="
WSC="$(dirname "$0")/../../tools/workflow_state_check.py"
PYBIN="$(command -v python || command -v python3)"
if [ -n "$PYBIN" ] && [ -f "$WSC" ]; then
    # --brief: posture + rule-pending + recommended-next + conflict count.
    # Indent for readability under the header.
    "$PYBIN" "$WSC" --brief 2>/dev/null | sed 's/^/    /'
    WSC_RC=${PIPESTATUS[0]}
    if [ "${WSC_RC:-0}" -ne 0 ]; then
        echo "    ⚠️ workflow_state_check reported CONFLICTS (exit $WSC_RC) — run: python tools/workflow_state_check.py"
    fi
else
    # Fallback if python/the tool is unavailable — never leave the session blind.
    echo "    (workflow_state_check.py unavailable — falling back to static note)"
    echo "    LEDGER: production/flow-ledger.yaml · CATALOG: .claude/docs/workflow-catalog.yaml"
    echo "    Run for full state: python tools/workflow_state_check.py"
fi
echo "=== END CANONICAL-RECOMMENDED NEXT ACTION ==="

# --- SESSION OPENING GUIDANCE (adaptive) ---
echo ""
echo "=== SESSION OPENING — ADAPTIVE ==="
echo "Sense the mode from the user's first message and project state, then open accordingly:"
echo ""
echo "LIGHT (default — quick question, small fix, new/early project, casual tone):"
echo "  Answer or act directly. One-line orientation if useful. Offer the recommended"
echo "  next step at the end. No ceremony."
echo ""
echo "FULL (multi-system feature, release prep, 'be thorough', returning after a gap,"
echo "      or repeated bugs — escalate when signals warrant):"
echo "  1. Context load: session state + workstream headers + open flags/bugs"
echo "  2. Dispatch director POV briefs (creative + technical + producer) in parallel"
echo "  3. Synthesize; map the user's words to skills/agents (.claude/docs/skills-index.md"
echo "     + .claude/docs/agents-index.md); present 2-3 concrete paths + a recommendation"
echo ""
echo "Always, either mode:"
echo "  - End with a recommendation, not passive listening."
echo "  - Never send the user to read a doc — read it yourself and give them what matters."
echo "=== END SESSION OPENING ==="

echo "==================================="
exit 0
