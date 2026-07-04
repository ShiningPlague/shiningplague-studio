---
name: team-level
description: "Use when working on world map design, location graph, biome layout, encounter placement, travel system, or spatial pacing. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted (Sons of Gilgamesh): full implementation with team-orchestrator protocol, level-designer + world-builder + game-designer dispatch, SoG context (52 locations, biome matrix, location graph)."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/team-level/SKILL.md
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/level-world.md
    - Domain code LW
    - Agent routing table per execution-chain step
    - Director gates (CD-GDD-ALIGN, CD-NARRATIVE, CD-PILLARS)
    - SoG world context (52 locations, biome matrix, location graph, travel formula)
---

# Team Level

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation. Vanilla backup: `docs/vanilla-backups/2026-05-15/team-level/`.

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
| Content: location data | Direct — Location Graph Editor dock |
| Content: encounter data | Direct — Monster Editor / JSON authoring |
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

## SoG-Specific Context

- World map: `scenes/map/map_screen.tscn`, data at `data/locations/`
- Location graph: `data/_schemas/location_graph.json` (dock-editable)
- Biome matrix: 3-axis spawn system (biome x condition x altitude)
- Travel formula: see `.claude/docs/godot-gotchas.md`
- Tag-based systems: spawns/gathering/illustrations use tag matching
- 52 existing locations across biomes
