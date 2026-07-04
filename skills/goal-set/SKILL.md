---
name: goal-set
description: "Use at session start (or whenever designer wants to declare session intent) to write the primary session goal to active-goals.json. Designer says 'set goal X', 'goal for today is Y', 'what we're trying to achieve is Z'. Goal persists across chat for /goal-check verification at close."
user-invocable: true
allowed-tools: Read, Write, Edit, Bash
metadata:
  origin: ShiningPlague (Sons of Gilgamesh)
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally for SoG session-goal tracking system
    - Designer-invoked declaration (NOT auto-fired by the assistant)
    - Concrete expected-outcomes mandatory (per project-local brainstorming convention)
    - Frozen-state lifecycle (locks when first work-skill fires)
    - audit_log trail
---

# Goal Set — Declare Session Primary Goal

> 🌱 **ShiningPlague-authored (2026-05-15).** Originally authored for the Sons of Gilgamesh project — no upstream version exists. Part of the session-goal tracking system (`/goal-set` + `/goal-add-minor` + `/goal-check`). Promoted to user-level 2026-05-15 for portability.

Write the session's primary goal to `production/session-state/active-goals.json`. This is the goal that `/goal-check` validates at session close. **Designer-invoked only** — the assistant doesn't pick this; designer declares it.

## When to fire

- Session start, after designer states clear intent ("today we're authoring game-concept.md", "this session is META framework hardening", "we're shipping the Combat GDD")
- Whenever designer wants to formalize what THIS chat is trying to accomplish
- Auto-propose at session start if designer's first prompt is a workstream × activity declaration

## When NOT to fire

- Mid-chat exploratory talk without commitment yet
- Designer hasn't picked a workstream + activity
- Goal would be vague ("do stuff", "work on it") — push back, ask designer to make it concrete

## Procedure

### Step 1: Read current active-goals.json

```bash
cat production/session-state/active-goals.json
```

If primary_goal is already set + `frozen: false`, ask designer: "Existing goal is X. Replace, keep, or amend?"

If `frozen: true`, refuse to overwrite — primary goal is locked until session closes. Offer `/goal-add-minor` instead.

### Step 2: Capture goal + expected outcomes

Ask designer for:
- **Goal text** (1 sentence — what does shipping this session look like?)
- **Expected outcomes** (3-7 concrete bullets — what artifacts/decisions/behaviors will exist when goal is met?)

Per project-local `/brainstorming` SKILL: expected outcomes must be concrete (not "improved X" — say what clicks-into-what-result).

### Step 3: Write to active-goals.json

Update fields:
- `session_id`: `YYYY-MM-DD-<workstream>-<topic-slug>`
- `session_started`: today's date
- `session_focus`: `<Workstream> × <Activity>` per session-focus model
- `frozen`: false (becomes true when designer fires first work-skill like /writing-plans)
- `primary_goal.text`: the goal sentence
- `primary_goal.set_at`: today
- `primary_goal.expected_outcomes`: the concrete bullets
- `audit_log`: append `{ts, event: "goal_set", note: <goal text>}`

### Step 4: Update session-start hook awareness

The hook (`tools/generate_session_context.sh`) already reads phase artifacts. It SHOULD also surface active primary goal at session start. If not yet wired, propose hook extension (small follow-on).

### Step 5: Confirm + chain-propose

Report to designer:
- "Primary goal locked: <text>"
- "Expected outcomes: <list>"
- "Goal becomes FROZEN when first work-skill fires (per session-focus discipline)"
- "I'll surface it at session close for /goal-check verification"

Propose firing first work-skill if designer has chosen activity (chain-propose).

## Cross-skill awareness

- After this fires, `/goal-add-minor` can append mid-session minor goals
- `/goal-check` at session close validates all goals
- `/session-close` Step 0 reads this file for pre-close verification
- Pairs with built-in CC `/goal` command if available (this skill = persistent SoG wrapper; /goal = per-turn Haiku evaluator). Both can coexist.

## Failure modes

- ❌ Setting vague goals ("do stuff") — push back for concreteness
- ❌ Overwriting frozen primary goal — refuse, offer /goal-add-minor
- ❌ Skipping expected outcomes — refuse, they're the verification criteria
- ❌ Auto-firing without designer declaration — this is designer-invoked
