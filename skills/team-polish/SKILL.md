---
name: team-polish
description: "Use when working on performance optimization, visual polish, feel improvements, juice effects, or pre-release refinement. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted (Sons of Gilgamesh): full implementation with performance-analyst + technical-artist + qa-tester dispatch, SoG context (6 TODOs in src/, no test suite, UI-based)."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/team-polish/SKILL.md
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/polish.md
    - Domain code PL
    - Agent routing table per execution-chain step
    - Director gates (CD-PLAYTEST, TD-CODE-REVIEW, QL-TEST-COVERAGE)
    - SoG polish context (6 TODOs baseline, manual validation, UI-based)
---

# Team Polish

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation. Vanilla backup: `docs/vanilla-backups/2026-05-15/team-polish/`.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/polish.md`
**Domain code:** PL

## Step 0: Load State + Select Activity

1. Read `production/workstreams/polish.md` — what's done, in-progress, next
2. Ask or infer: which ACTIVITY? (Design / Build / Content / Playtest / Review / Ship)
3. Follow the matching execution chain from `team-orchestrator.md`

## Agent Routing — WHO to dispatch at each step

| Step in chain | Agent to dispatch | What they do |
|---|---|---|
| Design: performance targets | `performance-analyst` | Frame time budgets, memory targets, profiling plan |
| Design: visual targets | `technical-artist` | Shader specs, VFX targets, visual optimization goals |
| Build: optimization | `gameplay-programmer` | GDScript optimization, scene tree cleanup |
| Build: visual polish | `technical-artist` | Shaders, VFX, visual optimization |
| Build: code quality | `godot-gdscript-specialist` | GDScript optimization patterns |
| Playtest: regression | `qa-tester` | Regression after polish passes |
| Review: playtest feel | `creative-director` | Gate CD-PLAYTEST |
| Review: code review | `lead-programmer` | Gate TD-CODE-REVIEW |
| Review: test coverage | `qa-tester` | Gate QL-TEST-COVERAGE |

## Gates to Fire

| Gate | When | Director |
|---|---|---|
| CD-PLAYTEST | Player experience validation after polish | creative-director |
| TD-CODE-REVIEW | After optimization code ships | lead-programmer |
| QL-TEST-COVERAGE | Regression coverage after polish changes | qa-tester |

## SoG-Specific Context

- 6 TODOs in src/ (code health baseline)
- No test suite or linter — validation = run scene + watch DM log + console output
- Performance-sensitive: UI/Control-node based, no 3D rendering
