---
name: sprint-plan
description: "Use when planning a new sprint, reviewing sprint progress, or when the designer says 'plan the next sprint', 'what should we work on next', or 'sprint status'. Creates or updates sprint plans in production/sprints/. ShiningPlague-adopted: full implementation with modes (new/status/update), capacity check (40h/sprint solo dev), producer PR-SPRINT gate, sprint-status.yaml integration."
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent
argument-hint: "[new | status | update]"
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Modes: new / status / update / no-arg auto-detect
    - Project candidate sources (specs + plans + next_session_priorities + bugs)
    - Solo dev capacity (40h, 8-12 items, 20% buffer)
    - Producer PR-SPRINT gate dispatch
    - sprint-status.yaml lifecycle integration
    - Chain-propose to /retrospective + /sprint-plan new
---

# Sprint Plan — Sprint Creation and Tracking

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; this version is the full implementation — sprint creation, status report, update mode, producer gate, capacity check.

Creates new sprint plans from the story/spec backlog, tracks progress, and manages sprint lifecycle. Dispatches producer agent for feasibility review.

## Modes

**`new`**: Create a new sprint plan.
**`status`**: Quick 30-line snapshot of current sprint progress.
**`update`**: Update existing sprint with new status, create `production/sprint-status.yaml`.
**No argument**: detect current sprint state and offer appropriate action.

---

## Phase 1: Assess Current State

Read silently:
1. `production/stage.txt` — project phase
2. Glob `production/sprints/sprint-*.md` — existing sprint plans
3. `data/_schemas/system_registry.json` → `next_session_priorities` — designer's priorities
4. `data/_schemas/dev_diary.json` → latest entry → `next` — immediate next actions
5. Glob `production/epics/**/*.md` — stories (if epic/story workflow adopted)
6. Glob `docs/specs/*.md` — active specs (specs/plans workflow)
7. Glob `docs/plans/*.md` — active plans

**Workflow note:** if the project uses the specs/plans workflow rather than epics/stories, sprint plans can reference either. When the epic/story workflow is adopted, this skill reads from both.

---

## Phase 2: Create Sprint Plan (mode: new)

### 2a. Gather Candidate Work

From sources above, build a candidate list:
- Stories with Status: Ready (from `production/epics/`)
- Active specs not yet implemented (from `docs/specs/`)
- `next_session_priorities` from registry
- Bugs from `production/qa/bugs/` (if any)

### 2b. Prioritize

Order by:
1. Blocking dependencies (must-do-first)
2. Designer priority (`next_session_priorities[0]` is highest)
3. MVP vs Alpha vs Full Vision
4. Estimated effort (smallest first for momentum)

### 2c. Capacity Check

Solo dev capacity per sprint (1-2 weeks):
- ~40 hours of Claude-assisted work
- ~8-12 implementable items (depending on complexity)
- Reserve 20% for bugs and polish

### 2d. Draft Sprint Plan

```markdown
# Sprint [N] — [Theme/Focus]

> **Start**: [date]
> **End**: [target date]
> **Goal**: [one sentence — what can we demo at the end?]

## Stories / Tasks

| # | Task | Source | Estimate | Status |
|---|------|--------|----------|--------|
| 1 | [task name] | [spec/story/priority ref] | [S/M/L] | Not Started |
| 2 | ... | | | |

## Sprint Risks
- [risk 1]
- [risk 2]

## Definition of Done
- All tasks complete or explicitly deferred with reason
- Consistency check passes
- Designer smoke test passes
```

Write to `production/sprints/sprint-[N].md`.

---

## Phase 3: Producer Review (if review-mode = full)

Spawn `producer` via Agent with gate **PR-SPRINT** from `.claude/docs/director-gates.md`:
- Pass: proposed story list, capacity, milestone constraints
- Verdict: REALISTIC / CONCERNS / UNREALISTIC

If UNREALISTIC: descope — remove lowest-priority items until producer approves.

---

## Phase 4: Sprint Status (mode: status)

Read the latest sprint file. Count tasks by status. Report:

```
Sprint [N] — [Theme]
Progress: [X]/[Y] tasks complete
- [completed task names]
- [in-progress task names]
- [blocked tasks + reason]
Days remaining: [N]
```

---

## Phase 5: Sprint Update (mode: update)

Update task statuses in the sprint file. If all tasks complete, close the sprint:
1. Mark sprint as Complete in the sprint file
2. Create/update `production/sprint-status.yaml`
3. Propose: "Sprint [N] complete. Run `/retrospective` or plan next sprint with `/sprint-plan new`?"
