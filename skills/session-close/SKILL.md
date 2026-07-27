---
name: session-close
description: "Use when ending a work session — wraps up with director reflections, consistency gate, /update ritual, session reflection, and session log. Fires on 'wrap up', 'close session', 'we're done', or on mechanical triggers (spec archived, ADR accepted, 5+ commits, phase gate pass)."
metadata:
  origin: ShiningPlague
  adopted_by: ShiningPlague
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as unified session-end protocol
    - 8-step close (gate → director reflections → consistency → /update → git → session reflection → session log)
    - Step 0 gates close on /goal-check + /red-flag-scan verdicts (RED pauses close)
    - 3-director parallel CLOSE-CD/CLOSE-TD/CLOSE-PR dispatch
    - Session reflection step (director reflections + log)
    - Auto-file session log at production/session-logs/YYYY-MM-DD-[workstream]-close.md
---

# Session Close

> 🌱 **ShiningPlague-authored.** No upstream version exists. Unified close protocol — every session ends the same way (gate → directors → consistency → /update → git → session reflection).

Unified close protocol. Every session ends the same way.

## Triggers

### Natural (the assistant initiates)
- Designer says "wrap up" / "we're done" / "good session" / "let's close"
- Last task in a plan completes
- Brainstorm reaches consensus and spec saved
- Designer shifts topic away from current work

### Mechanical (safety net)
- After spec archival (→ docs/z-old/)
- After ADR acceptance
- After 5+ commits without an update
- After phase gate passes
- After team-* orchestrator completes

When mechanical trigger fires, prompt: *"That's a natural checkpoint — want me to run the close ritual, or keep going?"*

## Procedure

### Step 0: Pre-Close Self-Check — GATE

**MUST fire BOTH `/goal-check` AND `/red-flag-scan` BEFORE Step 1.** Together they form the gate.

**0a — `/goal-check`** — validates each primary + minor goal against actual evidence (artifacts shipped, commits made, expected outcomes met). Surfaces unresolved issues from `active-goals.json`.

**0b — `/red-flag-scan`** — broader systemic audit: uncommitted work, doc stack drift, complexity drift (skill count, CLAUDE.md lines, orthogonal state axes), broken hooks/skills, technical debt accumulation, framework inconsistency.

Verdict colors:
- 🟢 **GREEN** (all PASS) → continue to Step 1
- 🟡 **YELLOW** (some PARTIAL / DROPPED with carry-over OK) → continue to Step 1 with explicit carry-over commitments written to active.md + sprint-status.yaml
- 🔴 **RED** (critical fail / unresolved blocker) → **CLOSE PAUSES.** Surface critical fails to designer. Designer chooses:
  - Fix now (in-chat resolution) → re-run /goal-check after fix
  - Formally DROP with rationale (write to active-goals.json + active.md)
  - Commit as PARTIAL with explicit carry-over destination
  - Defer close entirely (return to work, close later)

Hard-won rule: this step exists because without it, closes march on while critical issues linger — directors return CONCERNS verdicts and the close continues to Step 2 without designer resolution. The gate forces the pause.

Output of Step 0 gets written to the session log (Step 7) as the gate verdict + designer disposition table.

### Step 1: Director Bookend Re-dispatch

Fire all 3 Tier 1 directors in parallel via `Agent` tool with CLOSE-REFLECTION prompts from `.claude/docs/director-gates.md`:

- `creative-director` → gate **CLOSE-CD**
- `technical-director` → gate **CLOSE-TD**
- `producer` → gate **CLOSE-PR**

Pass each: workstream name + activity, decisions made, scope shipped.
Collect all 3 reflections before proceeding.

### Step 2: Synthesis — Reflection Record

Compose unified reflection from all 3 director outputs:
- Director key concerns
- Alignment / tensions between departments
- Shipped list
- Carryover items
- Producer's food-for-thought question
- Top risk + top opportunity

### Step 3: Close Gate Sequence

Before update ritual:
1. Run `python tools/consistency_check.py` (12 checks — registry, doc stack, ADRs, specs, links, hooks). Exit 0 = no FAILs; WARNs are advisory and never block.
2. If any design doc changed this session → propose `/review-all-gdds`
3. Check routine outcomes (architecture-review drift, code-review findings)
4. **If the runner exits non-zero → update proceeds but git push blocked until the named FAILs are resolved**

### Step 4: Unified Update Ritual

Fire `/update` (project-local skill). It handles:
- git status + recent commits
- consistency_check.py (auto-bumps last_full_audit on PASS)
- devlog.md append
- dev_diary.json (done_major, done_minor, close_note, close_ref)
- active.md full state handoff
- Workstream state file update
- Registry updates for modified systems
- Flag contradictions

### Step 5: Git Checkpoint

Draft commit message. Prompt designer for approval. Never push without explicit go.

### Step 6: Session Reflection

After git push confirmed, capture a brief close-out reflection:
- Summarise the session — what went well, what was challenging, what to carry forward
- Distil a 2-sentence reflection note for the dev_diary entry
- Fold the director reflections (Step 2) and the reflection note into the session log (Step 7)

### Step 7: Session Log Auto-File

Write `production/session-logs/YYYY-MM-DD-[workstream]-close.md`:
- Full director reflections
- Shipped list + commits
- Consistency check results
- Workstream state snapshot
- Reflection note
- Next session priority

Reference from dev_diary via `close_ref` field.
