---
name: start
description: "Use when onboarding a new project or starting fresh with the Donchitos framework, when the designer says 'start', 'set up the project', or 'onboard'. Routes to the right path based on project state: fresh (Path A/B/C) or existing (Path D -> /adopt). ShiningPlague-adopted (Sons of Gilgamesh): full implementation with 4-path routing, SoG-specific Path D context (project in Production phase, adopt run 2026-05-09)."
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/start/SKILL.md
  enhancements:
    - 4-path routing (A/B/C/D) based on project state
    - SoG-specific Path D context (always for this project)
    - Review-mode prompt (full/lean/solo)
    - Already-onboarded report (project status + suggested re-entry skills)
---

# Start — Guided Project Onboarding

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation — state detection, 4-path routing, review-mode setup. Vanilla backup: `docs/vanilla-backups/2026-05-15/start/`.

Routes the designer to the right onboarding path based on what exists. For Sons of Gilgamesh, this is always Path D (existing project) which hands off to `/adopt`.

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

## SoG-Specific Notes

- Sons of Gilgamesh is always Path D (existing project, already in Production phase)
- `/adopt` was run 2026-05-09, produced `docs/migration/adoption-plan-2026-05-09.md`
- Engine configured: Godot 4.6.1 in `.claude/docs/technical-preferences.md`
- Review mode set: `full` in `production/review-mode.txt`
- If `/start` is invoked again, report: "Project already onboarded. Current phase: [stage]. Run `/adopt` to re-audit, `/gate-check` to validate readiness, or `/help` for what to do next."
