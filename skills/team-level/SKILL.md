---
name: team-level
description: "Use when working on world map design, location layout, encounter placement, travel systems, or spatial pacing. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted: full implementation with team-orchestrator protocol, level-designer + world-builder + game-designer dispatch, and a project level-context block."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/level-world.md
    - Domain code LW
    - Agent routing table per execution-chain step
    - Director gates (CD-GDD-ALIGN, CD-NARRATIVE, CD-PILLARS)
    - Project level-context placeholder block
---

# Team Level

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; this version is the full implementation.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/level-world.md`
**Domain code:** LW

## Step 0: Load State + Select Activity

1. Read `production/workstreams/level-world.md` — what's done, in-progress, next
2. Ask or infer: which ACTIVITY? (Design / Build / Content / Playtest / Review / Ship)
3. Follow the matching execution chain from `team-orchestrator.md`

## Agent Routing — WHO to dispatch at each step

| Step in chain | Agent to dispatch | What they do |
|---|---|---|
| Design: brainstorm / spec | `level-designer` | Spatial layouts, encounter pacing, difficulty curves |
| Design: world rules | `world-builder` | Lore integration, environmental storytelling |
| Design: mechanics | `game-designer` | Encounter mechanics, travel formulas, gathering actions |
| Design: GDD authoring | `level-designer` | 8-section GDD per `/design-system` |
| Build: implementation | `gameplay-programmer` | Map system code, travel logic, spawn systems |
| Build: code quality | `godot-gdscript-specialist` | Static typing, signals, performance |
| Content: location data | Direct — in-engine location editor dock / JSON authoring |
| Content: encounter data | Direct — in-engine enemy editor dock / JSON authoring |
| Playtest: pacing | `qa-tester` | Travel timing, encounter frequency, difficulty flow |
| Review: design review | `creative-director` | Gate CD-GDD-ALIGN |
| Review: narrative fit | `creative-director` | Gate CD-NARRATIVE |
| Review: pillars check | `creative-director` | Gate CD-PILLARS |

## Gates to Fire

| Gate | When | Director |
|---|---|---|
| CD-GDD-ALIGN | After level/world GDD sections | creative-director |
| CD-NARRATIVE | Narrative purpose of locations | creative-director |
| CD-PILLARS | If world changes affect exploration/discovery pillars | creative-director |

## Templates

- `.claude/docs/templates/level-design-document.md`
- `.claude/docs/templates/faction-design.md`

## Project-Specific Context

Fill in for your project (examples):

- World map scene + location data paths (e.g. `scenes/map/`, `data/locations/`)
- Spatial data schemas (e.g. a location graph JSON, dock-editable)
- Spawn/encounter systems (e.g. tag-based matching — never per-location hardcoded lists)
- Travel/pacing formulas and where they're documented
- Current world content counts (locations, regions, encounter tables)
