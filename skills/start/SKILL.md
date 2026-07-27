---
name: start
description: "Use when onboarding a new project or starting fresh with the studio framework, when the designer says 'start', 'set up the project', or 'onboard'. Routes to the right path based on project state: fresh (Path A/B/C) or existing (Path D -> /adopt). ShiningPlague-adopted: full implementation with 4-path routing and review-mode setup."
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

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## Phase 1: Detect Project State

> **Existence is not evidence.** The installer seeds the whole document stack, so
> on a brand-new project `stage.txt`, `game-concept.md`, `review-mode.txt`, the
> registry and `docs/adr/TEMPLATE.md` all *exist* and are all still empty. Judge
> every signal below on **content**, never on the file being present — otherwise a
> stranger's first `/start` reports "already onboarded" at an untouched install.

Read silently:
1. `production/stage.txt` — read the value. Anything past `concept` means real
   work has happened. `concept` is the seeded day-one value and proves nothing.
2. `data/_schemas/system_registry.json` — the built-state authority. A non-empty
   `systems[]` is the strongest "this project is already in flight" signal there is.
3. `docs/gdd/game-concept.md` — concept **written**? The seeded copy is the blank
   template; if the elevator pitch is still the bracketed `[…]` prompt text, treat
   it as absent.
4. `.claude/docs/technical-preferences.md` — engine configured? (Not scaffolded —
   presence here is a real signal.)
5. Glob `src/**/*` for engine source files — source code exists?
6. Glob `docs/adr/[0-9]*.md` — real ADRs exist? (`NNN-<slug>.md` only; the leading
   digit excludes the seeded `docs/adr/TEMPLATE.md`, which is a skeleton, not a
   decision.)
7. `docs/adoption-plan-*.md` — prior adoption plan?

**Fresh project** = none of 1–3, 5 or 6 carry content. Route to Path A/B/C.
**Existing project** = any of them does. Route to Path D.

---

## Phase 2: Route to Path

Based on findings, present the appropriate path. Frame it as a friendly roadmap, not a checklist to be enforced — the designer can describe their game in plain words at any point, and steps can be skipped or reordered if they ask:

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

## Phase 3: Confirm Review Mode

`production/review-mode.txt` is seeded by the installer as `lean`, so it always
exists — its presence is not a sign the designer ever chose. On a fresh project
(Phase 1 found no content), confirm the default rather than assuming it:

"You're set to **lean** review — director specialists weigh in at phase gates
only. Want to change that?"
- **Full** — Director specialists review at each workflow step. Recommended for solo devs who want the full agent team experience.
- **Lean** — Directors only at phase gates. Balanced. *(the seeded default)*
- **Solo** — No director reviews. Maximum speed.

Write the choice to `production/review-mode.txt` only if they pick something other
than what is already there. If the file is absent (a `--no-scaffold` install), ask
the open question instead and write the answer.

---

## Re-invocation Note

- If `/start` is invoked on an already-onboarded project — Phase 1 found **content**, not merely files: `stage.txt` past `concept`, a non-empty `systems[]`, a written concept, or a real `docs/adr/[0-9]*.md` — report: "Project already onboarded. Current phase: [stage]. Run `/adopt` to re-audit, `/gate-check` to validate readiness, or `/help` for what to do next."
- Never report "already onboarded" because the seeded document stack exists. A fresh install has every one of those files and an empty project; that is the day-one state, not prior work.
