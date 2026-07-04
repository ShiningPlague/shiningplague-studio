---
name: team-narrative
description: "Use when working on story, dialogue, lore, companion writing, DM narration, act structure, scene design, or world-building. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted (Sons of Gilgamesh): full implementation with team-orchestrator protocol, narrative-director + world-builder + writer dispatch, SoG narrative context (Orb, companion trust, DM log narration, Narrative Layer is designer's primary objective)."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/team-narrative/SKILL.md
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/narrative.md
    - Domain code NR
    - Agent routing table per execution-chain step
    - Director gates (CD-NARRATIVE, CD-PILLARS, CD-GDD-ALIGN)
    - SoG narrative context (GDD v2.3 §6, lorebook v3, Act 1 scenes, Orb, companion)
    - Narrative Layer flagged as designer's primary objective per dev_diary
---

# Team Narrative

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation. Vanilla backup: `docs/vanilla-backups/2026-05-15/team-narrative/`.

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
| Design: mechanics | `game-designer` | Narrative mechanics (trust system, choice costs, Orb lore) |
| Design: GDD authoring | `narrative-director` | 8-section GDD per `/design-system` |
| Build: implementation | `gameplay-programmer` | GDScript code, dialogue systems, scene scripting |
| Build: code quality | `godot-gdscript-specialist` | Static typing, signals, performance |
| Content: dialogue / lore | `writer` | Dialogue, lore entries, item descriptions, DM narration text |
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

## SoG-Specific Context

- Master GDD: `docs/GDD v.2.3.md` Section 6 (Narrative + Acts)
- Lorebook: `docs/lorebook_v3.md` (canonical lore)
- Act 1 scenes: `docs/act1_scene_reference.md`
- Companion system: trust-based, consumes supplies, acts autonomously
- The Orb: curse + gift duality, central to narrative progression
- DM narration: timestamped scrolling log, composed from weather + description + surroundings
- Narrative Layer is designer's stated primary objective (dev_diary)
