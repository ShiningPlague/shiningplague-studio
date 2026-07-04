---
name: team-combat
description: "Use when working on combat mechanics, card system, damage pipeline, status effects, timeline resolution, battle flow, or enemy behaviour. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted (Sons of Gilgamesh): full implementation with team-orchestrator protocol, game-designer + systems-designer + gameplay-programmer dispatch, SoG combat context (3 ADRs, card schema, DamageCalculator, StatusEffectManager)."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/team-combat/SKILL.md
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/combat.md
    - Domain code CB
    - Agent routing table per execution-chain step
    - Director gates (CD-GDD-ALIGN, TD-ADR, TD-CODE-REVIEW, CD-PILLARS)
    - SoG combat context (GDD v2.3 §4, roguelite timeline deck-builder)
---

# Team Combat

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation — orchestration protocol, agent routing, director gates, combat context with 3 ADRs and shipped code. Vanilla backup: `docs/vanilla-backups/2026-05-15/team-combat/`.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/combat.md`
**Domain code:** CB

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
| Content: data authoring | Direct — Monster Editor / Archetype Recipe Editor / Trait Multipliers Editor |
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

## SoG Combat Context

- Roguelite timeline deck-builder (GDD v2.3 §4)
- Card schema: `data/_schemas/card_schema.json`
- Archetype recipes: `data/cards/archetype_recipes.json`
- Damage pipeline: `src/systems/damage_calculator.gd` (DamageCalculator autoload)
- Trait multipliers: `data/_schemas/trait_multipliers.json` (dock-editable)
- Status effects: `src/systems/status_effect_system.gd` (StatusEffectManager)
- 3 ADRs: `docs/adr/001-*`, `002-*`, `003-*` (all combat)
- Step 3b (control effects) paused since 2026-04-28
