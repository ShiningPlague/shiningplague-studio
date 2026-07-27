---
name: team-combat
description: "Use when working on combat mechanics, damage pipeline, status effects, battle flow, or enemy behaviour. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted: full implementation with team-orchestrator protocol, game-designer + systems-designer + gameplay-programmer dispatch, project combat-context block."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/combat.md
    - Domain code CB
    - Agent routing table per execution-chain step
    - Director gates (CD-GDD-ALIGN, TD-ADR, TD-CODE-REVIEW, CD-PILLARS)
    - Project combat-context block ({{GDD_PATH}} combat section, combat ADRs, autoloads)
---

# Team Combat

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; the studio version is the full implementation — orchestration protocol, agent routing, director gates, project combat-context block.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/combat.md`
**Domain code:** CB

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## Step 0: Load State + Select Activity

1. Read `production/workstreams/combat.md` — what's done, in-progress, next
2. Ask or infer: which ACTIVITY? (Design / Build / Content / Playtest / Review / Ship)
3. Follow the matching execution chain from `team-orchestrator.md`

## Agent Routing — WHO to dispatch at each step

When the execution chain says "dispatch specialist," use these agents:

| Step in chain | Agent to dispatch | What they do |
|---|---|---|
| Design: brainstorm / spec | `game-designer` | Combat mechanic design, balance targets |
| Design: formulas / curves | `systems-designer` | Damage formulas, interaction matrices |
| Design: GDD authoring | `game-designer` | 8-section GDD per `/design-system` |
| Build: implementation | `gameplay-programmer` | GDScript code, autoloads, scenes |
| Build: code quality | `godot-gdscript-specialist` | Static typing, signals, performance |
| Build: code review | `lead-programmer` | Architecture compliance, ADR adherence |
| Content: data authoring | Direct — via the project's in-engine editor docks (if any) or data JSON edits |
| Playtest: debugging | `gameplay-programmer` | Root cause via `/systematic-debugging` |
| Playtest: test cases | `qa-tester` | Headless harnesses, regression entries |
| Review: design review | `creative-director` | Gate CD-GDD-ALIGN |
| Review: architecture | `technical-director` | Gate TD-ADR, TD-CODE-REVIEW |

## Gates to Fire

| Gate | When | Director |
|---|---|---|
| CD-GDD-ALIGN | After combat GDD or spec | creative-director |
| TD-ADR | After combat ADR | technical-director |
| TD-CODE-REVIEW / LP-CODE-REVIEW | After combat code ships | lead-programmer |
| CD-PILLARS | If combat changes affect core pillars | creative-director |

## Project Combat Context (fill for your project)

- Combat model: [one-line summary, e.g. turn-based / real-time / hybrid] (`{{GDD_PATH}}` combat section)
- Core combat schemas: `data/_schemas/[combat-schema].json`
- Damage pipeline: `src/systems/[damage-system].gd` ([autoload name])
- Tunable multipliers / curves: `data/_schemas/[tuning-file].json` (dock-editable if the project has docks)
- Status/effect system: `src/systems/[effect-system].gd` ([autoload name])
- Combat ADRs: list the `docs/adr/NNN-*` entries that govern combat
- Note any paused combat work here so dispatched agents inherit it
