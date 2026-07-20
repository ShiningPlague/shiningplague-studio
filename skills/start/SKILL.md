---
name: start
description: "Use when onboarding a new project or starting fresh with the Donchitos framework, when the designer says 'start', 'set up the project', or 'onboard'. Routes to the right path based on project state: fresh (Path A/B/C) or existing (Path D -> /adopt). ShiningPlague-adopted: full implementation with 4-path routing and review-mode setup."
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - 4-path routing (A/B/C/D) based on project state
    - Review-mode prompt (full/lean/solo)
    - Already-onboarded report (project status + suggested re-entry skills)
---

# Start — Guided Project Onboarding

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; the studio version is the full implementation — state detection, 4-path routing, review-mode setup.

Routes the designer to the right onboarding path based on what exists — fresh projects take Path A/B/C; existing projects take Path D, which hands off to `/adopt`.

## Phase 1: Detect Project State

Read silently:
1. `production/stage.txt` — if exists, project already onboarded
2. `design/gdd/game-concept.md` — concept exists?
3. `.claude/docs/technical-preferences.md` — engine configured?
4. Glob `src/**/*.gd` — source code exists?
5. Glob `docs/adr/*.md` — ADRs exist?
6. `docs/migration/adoption-plan-*.md` — prior adoption plan?

---

## Phase 2: Route to Path

Based on findings, present the appropriate path:

### Path A: "I have no idea what to build" (nothing exists)
1. `/brainstorming` — guided creative exploration
2. `/setup-engine` — configure engine + version
3. `/design-review` — validate concept
4. `/map-systems` — decompose into systems
5. `/design-system [system]` — author per-system GDDs
6. prototyper agent dispatch — test core mechanic
7. `/sprint-plan new` — plan first sprint

### Path B: "I know what I want to build" (concept clear, no artifacts)
1. `/setup-engine [engine] [version]`
2. Delegate to `creative-director` for game pillars
3. `/map-systems`
4. `/design-system [system]` per system
5. `/architecture-decision`
6. `/sprint-plan new`

### Path C: "I know the game but not the engine" (concept clear, engine undecided)
1. `/setup-engine` (no args — asks about needs, recommends engine)
2. Follow Path B from step 2

### Path D: "I have an existing project" (artifacts detected)
1. `/project-stage-detect` — analyze what exists
2. `/adopt` — audit format compliance, build migration plan
3. `/setup-engine` if not configured
4. `/gate-check` — validate phase readiness
5. `/sprint-plan new` — plan next sprint

---

## Phase 3: Set Review Mode (if not already set)

Check `production/review-mode.txt`. If it doesn't exist, ask:

"How much design review would you like as you work?"
- **Full** — Director specialists review at each workflow step. Recommended for solo devs who want the full agent team experience.
- **Lean** — Directors only at phase gates. Balanced.
- **Solo** — No director reviews. Maximum speed.

Write choice to `production/review-mode.txt`.

---

## Re-invocation Note

- If `/start` is invoked on an already-onboarded project (stage.txt exists), report: "Project already onboarded. Current phase: [stage]. Run `/adopt` to re-audit, `/gate-check` to validate readiness, or `/help` for what to do next."
