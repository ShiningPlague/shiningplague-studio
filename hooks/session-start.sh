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

# --- Workstream state overview (added 2026-05-11) ---
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
STATE_FILE="production/session-state/active.md"
if [ -f "$STATE_FILE" ]; then
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

# --- MANDATORY SESSION PROTOCOL REMINDER (added 2026-05-11, extended 2026-05-11b) ---
echo ""
echo "=== MANDATORY SESSION PROTOCOL — DO NOT SKIP ==="
echo "CLAUDE.md conversation-start protocol (7 steps) MUST fire NOW:"
echo "  1. Fire using-superpowers"
echo "  2. Context load: active.md + dev_diary (especially thoughts) + open-flags + workstream headers"
echo "  3. 🔒 DIRECTOR POV BRIEFS: Dispatch creative-director + technical-director + producer"
echo "     in PARALLEL via Agent tool. Prompts at docs/specs/2026-05-11-workstream-formalization-design.md § Section 3 Step 2."
echo "     They read GDD + registry + workstreams + dev_diary.thoughts + routine results."
echo "     This is NON-NEGOTIABLE. Every session. No matter what the user says first."
echo "  4. Synthesize all 3 POVs + present SESSION MENU (see format above)"
echo "     → MAP the designer's words to Skills + Templates + Agents (table)"
echo "     → PRESENT 3-5 concrete action paths"
echo "     → SHOW full workstream table"
echo "     → END with recommendation, NOT passive listening"
echo "  5. Surface critical flags from docs/open-flags.md"
echo "  6. Surface open bugs from production/qa/bugs/ (if any)"
echo "  7. Match user's message against skills index — 🔒 auto-fire, 🟢 propose"
echo ""
echo "FAILURE MODES (all observed, all enforced):"
echo "  - Ending opening with 'send the doc' / 'I am listening' = PROTOCOL FAIL"
echo "  - Skipping the workstream table = PROTOCOL FAIL"
echo "  - Not mapping user's words to skills/templates = PROTOCOL FAIL"
echo "  - Skipping director briefs = same failure as skipping /verification-before-completion"
echo "=== END MANDATORY PROTOCOL ==="

echo "==================================="
exit 0
