---
name: goal-check
description: "Use BEFORE /session-close OR when designer asks 'did we hit goals', 'goal status', 'verify outcomes'. Reads active-goals.json, validates each primary + minor goal against actual artifact/outcome state, reports PASS/PARTIAL/DROPPED/CARRY per goal. Gates close if critical fails."
user-invocable: true
allowed-tools: Read, Edit, Glob, Grep, Bash
metadata:
  origin: ShiningPlague
  adopted_by: ShiningPlague
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally for the session-goal tracking system
    - Gates /session-close (Step 0 — mandatory pre-close)
    - Verdicts: PASS / PARTIAL / DROPPED / CARRY per goal
    - Aggregate: GREEN / YELLOW / RED session-level verdict
    - Updates active-goals.json with outcome classification
---

# Goal Check — Pre-Close Goal Verification

> 🌱 **ShiningPlague-authored.** No upstream version exists. Part of the session-goal tracking system (`/goal-set` + `/goal-add-minor` + `/goal-check`).

Verify session goals (primary + minors) against actual outcomes. **Gates `/session-close`** — if critical fails, close pauses for designer remediation. Closes the "shipped but didn't actually achieve goal" failure mode.

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## When to fire

- Auto-fire as Step 0 of `/session-close` (mandatory pre-close gate)
- Designer asks: "did we hit goals", "verify outcomes", "goal status", "are we done"
- Before any git push of session work

## Procedure

### Step 1: Read active-goals.json

If missing or empty: report "no goals set this session — close can proceed without goal-check, but next time use /goal-set at session start."

### Step 2: For each goal (primary + minors), verify each expected outcome

For each expected outcome bullet:
- **Find evidence:** glob for expected artifact, grep for content marker, git log for commit reference, hook output for state confirmation.
- **Classify:**
  - **PASS** ✅ — evidence found, outcome shipped as specified
  - **PARTIAL** ⚠️ — some evidence but incomplete
  - **DROPPED** ❌ — no evidence, abandoned
  - **CARRY** 🔄 — moved to next session intentionally (designer flagged earlier)

### Step 3: Aggregate verdicts

Compute:
- Goal-level verdict: ALL PASS → goal PASS. Any DROPPED → goal needs review.
- Session-level verdict:
  - All goals PASS → **GREEN** (close can proceed)
  - 1+ PARTIAL, 0 DROPPED → **YELLOW** (close OK with carry-over)
  - 1+ DROPPED, no critical → **YELLOW** (close OK with carry-over)
  - Critical DROPPED (designer-flagged as must-have) → **RED** (close PAUSES)

### Step 4: Surface unresolved issues from active-goals.json

Read `unresolved_issues[]`. For each:
- Status OPEN → flag for designer
- Status RESOLVING → confirm with designer if shipped
- Status DEFERRED → confirm carry-over destination (active.md priorities or sprint-status.yaml)
- Status ACCEPTED → no action

### Step 5: Output verification report

```
## Goal Check — YYYY-MM-DD

### Primary goal: <text>
- Outcome 1 — ✅ PASS (evidence: <file/commit/state>)
- Outcome 2 — ⚠️ PARTIAL (evidence: <partial state>, gap: <what's missing>)
- Outcome 3 — ❌ DROPPED (reason: <why>)
- ...

**Goal verdict:** PASS / PARTIAL / NEEDS-REVIEW

### Minor goals (N)
- MG-1: <text> — DELIVERED ✅
- MG-2: <text> — DELIVERED ✅
- MG-3: <text> — IN PROGRESS ⚠️
- ...

### Unresolved issues (N)
- ISS-XX: <text> — <status> — designer decision: <decision>
- ...

### Session verdict: 🟢 GREEN / 🟡 YELLOW / 🔴 RED

### Recommendation
- GREEN: Proceed with /session-close
- YELLOW: Proceed with explicit carry-over to active.md priorities + sprint-status.yaml
- RED: PAUSE close. Address [critical fails] first. Designer choices: fix now / formally drop with rationale / commit as partial.
```

### Step 6: Update active-goals.json

- Update each `minor_goals_added[].outcome` field with PASS/PARTIAL/DROPPED/CARRY classification
- Update each `unresolved_issues[].status` per designer decision
- Append audit_log: `{ts, event: "goal_check_run", verdict: "<color>"}`

### Step 7: Carry-over write

If carry-overs exist, designer chooses destination per type (note: "next-session-priorities" is not a literal active.md section name; see options below):
- **Workstream-relevant carry-over**: add to `active.md` → 🚨 OPEN ADOPTION PLAN TODOs → Priorities (numbered list) with `[Goal-Defer]` prefix per Item 15b
- **Session-discipline carry-over** (next-session must-fire item): add to `active.md` → 🚨 NEXT-SESSION MUST-FIRE section
- **Sprint-relevant carry-over** (fits next sprint): add to `production/sprint-status.yaml`
- **Registry-level priority shift**: update `data/_schemas/system_registry.json` → `next_session_priorities[]` (top-level array)
- Designer confirms each carry-over destination

## Cross-skill awareness

- Step 0 of `/session-close` MUST call this skill first
- Pairs with built-in `/goal` (CC native per-turn evaluator) — this skill is the explicit final check
- Chain: `/goal-check` → (YELLOW or GREEN) → `/session-close` continues. (RED) → close pauses.

## Failure modes

- ❌ Marking PASS without evidence — verification = command/file output, not assertion
- ❌ Skipping unresolved issues review — they accumulate silently
- ❌ Auto-marking everything CARRY to avoid hard decisions — push designer for honest disposition
- ❌ Letting RED close proceed — close is gated, respect the gate
