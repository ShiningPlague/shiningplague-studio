---
name: retrospective
description: "Use at sprint end, after completing a major milestone, or when designer says 'retro', 'retrospective', 'sprint review', 'what worked / what didn't'. ShiningPlague-adopted: full implementation that routes retrospective output to docs/devlog.md (single change-log + retro record), updates sprint-status.yaml to closed, sprint-type aware."
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Output routes to docs/devlog.md (not separate retrospective/ folder)
    - sprint-status.yaml status:closed update
    - Carry-over tracking
    - Sprint-type aware (Foundation/Adoption vs Production vs Polish)
    - Auto-fire opportunity as part of /session-close if sprint closed
---

# Retrospective

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; the studio version is the full implementation that routes retrospective output INTO `docs/devlog.md` rather than creating separate files.

## Devlog routing (studio rule)

Retrospective output gets appended to `docs/devlog.md` under a dated section, NOT to a separate `production/retrospectives/` folder.

**Why:** hard-won rule — `docs/devlog.md` is the single canonical change log. Retrospectives route INTO devlog so the doc stack stays consolidated: one canonical change-log + retro record per file. Avoids parallel docs.

## Procedure

### Step 1: Read sprint state

- `production/sprint-status.yaml` — current sprint metadata + story states
- `production/sprints/sprint-<N>-*.md` — sprint plan + acceptance criteria
- Git log since sprint start — commits, what shipped
- `docs/open-flags.md` — flags raised during sprint
- `production/qa/bugs/` — bugs found during sprint

### Step 2: Synthesize retro themes

For each prompt, gather observations from the sprint:

- **What worked** — 3-5 things that went smoothly + reasons
- **What didn't work** — 3-5 things that struggled + root causes
- **Surprises** — what came up that wasn't planned
- **Action items** — concrete changes for next sprint
- **Velocity / metrics** — stories closed, blocked, deferred

### Step 3: Append to devlog.md

Add a new section to `docs/devlog.md`:

```markdown
## YYYY-MM-DD — Sprint <N> Retrospective: <Sprint Focus>

**Sprint:** <N> · **Type:** Foundation/Adoption | Production | Polish · **Duration:** YYYY-MM-DD → YYYY-MM-DD

### What worked
- ...
- ...

### What didn't work
- ...
- ...

### Surprises
- ...

### Action items for next sprint
- [ ] <action>
- [ ] <action>

### Velocity
- Stories planned: N · Closed: N · Blocked: N · Deferred: N
- Major commits: <list>
- Bugs found: N · Resolved: N

### Open carry-overs
- Stories that didn't close: <list with reasons>
```

### Step 4: Update sprint-status.yaml

- Mark current sprint as `status: closed`
- Add `retrospective_logged: docs/devlog.md#<anchor>`
- Note any stories carrying to next sprint

### Step 5: Propose next sprint

After retro lands, propose firing `/sprint-plan` for next sprint OR `/gate-check` if a phase transition is the natural next step.

## When to fire

- End of any sprint (story status: all closed or carried)
- After major milestone (phase transition, release)
- Designer says "let's reflect", "what worked", "retro"
- Auto-fire opportunity: as part of `/session-close` if a sprint closed that session

## Cross-skill awareness

- After firing, if sprint closed → propose `/sprint-plan new` for next sprint
- If phase transition opportunity → propose `/gate-check <phase>`
- Chain into `/update` if devlog needs broader project sync

## Failure modes

- ❌ Creating retrospective in separate file when devlog.md exists — violates the consolidation rule
- ❌ Skipping `sprint-status.yaml` update — leaves sprint state stale, /help misreports
- ❌ Vague retros ("things were OK") — concrete items only, or skip
- ❌ Firing too early (mid-sprint) — wait until natural sprint end OR designer explicitly invokes early
