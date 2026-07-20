---
name: team-narrative
description: "Use when working on story, dialogue, lore, companion writing, narration, act structure, scene design, or world-building. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted: full implementation with team-orchestrator protocol, narrative-director + world-builder + writer dispatch, project narrative context block ({{LORE_DOC}}, {{ACT_REFERENCE}})."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/narrative.md
    - Domain code NR
    - Agent routing table per execution-chain step
    - Director gates (CD-NARRATIVE, CD-PILLARS, CD-GDD-ALIGN)
    - Project narrative context block ({{GDD_PATH}} narrative section, {{LORE_DOC}}, {{ACT_REFERENCE}})
---

# Team Narrative

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; the studio version is the full implementation.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/narrative.md`
**Domain code:** NR

## Step 0: Load State + Select Activity

1. Read `production/workstreams/narrative.md` — what's done, in-progress, next
2. Ask or infer: which ACTIVITY? (Design / Build / Content / Playtest / Review / Ship)
3. Follow the matching execution chain from `team-orchestrator.md`

## Agent Routing — WHO to dispatch at each step

| Step in chain | Agent to dispatch | What they do |
|---|---|---|
| Design: brainstorm / spec | `narrative-director` | Story architecture, act structure, narrative systems |
| Design: world rules | `world-builder` | Factions, cultures, history, geography, world rules |
| Design: mechanics | `game-designer` | Narrative mechanics (trust systems, choice costs, faction reputation) |
| Design: GDD authoring | `narrative-director` | 8-section GDD per `/design-system` |
| Build: implementation | `gameplay-programmer` | GDScript code, dialogue systems, scene scripting |
| Build: code quality | `godot-gdscript-specialist` | Static typing, signals, performance |
| Content: dialogue / lore | `writer` | Dialogue, lore entries, item descriptions, narration text |
| Content: world entries | `world-builder` | Faction profiles, location lore, history entries |
| Playtest: narrative flow | `qa-tester` | Story path coverage, choice consequence validation |
| Review: design review | `creative-director` | Gate CD-NARRATIVE, CD-GDD-ALIGN |
| Review: pillars check | `creative-director` | Gate CD-PILLARS |

## Gates to Fire

| Gate | When | Director |
|---|---|---|
| CD-NARRATIVE | After narrative GDDs, lore docs, dialogue specs | creative-director |
| CD-PILLARS | If narrative changes affect core pillars | creative-director |
| CD-GDD-ALIGN | After narrative system GDD authoring | creative-director |

## Templates

- `.claude/docs/templates/narrative-character-sheet.md`
- `.claude/docs/templates/player-journey.md`
- `.claude/docs/templates/level-design-document.md` (for act/scene layouts)

## Project Context (fill for your project)

- Master GDD narrative section: `{{GDD_PATH}}` §[narrative section]
- Lore home: `{{LORE_DOC}}` (e.g. `docs/world-lore.md` — the single canonical lore doc)
- Act/chapter scene reference: `{{ACT_REFERENCE}}` (e.g. `docs/story-outline.md`)
- Companion / NPC systems: [note the project's core narrative-adjacent mechanics here]
- Narration surface: [how the game delivers narration — log, dialogue boxes, cutscenes]
- Note the designer's current narrative priority here so dispatched agents inherit it
