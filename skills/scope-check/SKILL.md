---
name: scope-check
description: "Use during implementation to detect scope creep — when work drifts beyond the current spec/plan/story. Fires during sprints, after plan tasks, or when the designer suspects deviation. Compares current work against the stated scope. ShiningPlague-adopted (Sons of Gilgamesh): full implementation with priority-ordered scope document lookup (plan / spec / story / workstream) and 20% drift heuristic."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/scope-check/SKILL.md
  enhancements:
    - Priority-ordered scope document lookup
    - 20% drift heuristic for flagging
    - SoG paths (docs/specs/, docs/plans/, production/workstreams/)
    - Park-in-live_test_notes proposal for parked work
---

# Scope Check

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation — priority-ordered scope doc lookup, 20% drift heuristic, park-or-expand proposal. Vanilla backup: `docs/vanilla-backups/2026-05-15/scope-check/`.

Detect scope deviation by comparing current work against the governing spec, plan, or story.

## Procedure

### 1. Identify Governing Scope Document
Find the active scope document (in priority order):
- Active plan: `docs/plans/YYYY-MM-DD-*-plan.md` with status 🚧 ACTIVE
- Active spec: `docs/specs/YYYY-MM-DD-*-design.md` with status 🚧 IN PROGRESS
- Active story: `production/stories/*.md` with status in-progress
- Active workstream state: `production/workstreams/<name>.md` → "In Progress" section

### 2. Extract Stated Scope
From the governing document, extract:
- What was planned to be built/changed
- What was explicitly out of scope (if stated)
- Expected outcomes at ship

### 3. Compare Against Current Work
`git diff --stat` + read changed files. For each change:
- **In scope** — directly serves the stated plan
- **Adjacent** — related but not stated (potential creep)
- **Out of scope** — unrelated to current work

### 4. Assess Creep Risk
- Count adjacent + out-of-scope changes
- Estimate effort consumed on non-scope work
- Flag if the ratio exceeds 20% (heuristic — adjust per context)

### 5. Output

```
## Scope Check: [governing document name]

### In Scope
- [change 1] ✓
- [change 2] ✓

### Adjacent (potential creep)
- [change 3] ⚠ — related but not in plan

### Out of Scope
- [change 4] ✗ — not related to current work

### Verdict
CLEAN — all work is in scope
or
DRIFT — [N] changes outside scope, [estimate] effort diverted
```

### 6. If Drift Detected
Propose to designer:
- Park out-of-scope work in `live_test_notes.top_of_mind_YYYY-MM-DD`
- Or expand scope (with explicit acknowledgment)
- Or revert and refocus

## SoG Paths
- Specs: `docs/specs/`
- Plans: `docs/plans/`
- Workstreams: `production/workstreams/`
