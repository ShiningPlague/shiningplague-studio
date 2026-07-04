---
name: team-economy
description: "Use when working on resource economy, loot tables, progression curves, reward balance, supply/resolve/time tuning, or in-game market design. Routes to the correct workflow pattern and executes step-by-step."
metadata:
  origin: ShiningPlague (Sons of Gilgamesh)
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as team-orchestrator for economy workstream
    - economy-designer + systems-designer + game-designer dispatch
    - Director gates (CD-GDD-ALIGN, CD-PILLARS)
    - SoG economy context (3 resources, rarity tiers, companion supply consumption)
---

# Team Economy

> 🌱 **ShiningPlague-authored (2026-05-15).** Originally authored for the Sons of Gilgamesh project — no upstream version exists. Team-orchestrator skill for the economy workstream. Promoted to user-level 2026-05-15 for portability.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/economy.md`
**Domain code:** EC

## Step 0: Load State + Select Activity

1. Read `production/workstreams/economy.md` — what's done, in-progress, next
2. Ask or infer: which ACTIVITY? (Design / Build / Content / Playtest / Review / Ship)
3. Follow the matching execution chain from `team-orchestrator.md`

## Agent Routing — WHO to dispatch at each step

| Step in chain | Agent to dispatch | What they do |
|---|---|---|
| Design: brainstorm / spec | `economy-designer` | Resource flows, sink/faucet analysis, loot tables |
| Design: formulas / curves | `systems-designer` | Progression formulas, scaling curves |
| Design: core loop integration | `game-designer` | Core loop economy integration |
| Design: GDD authoring | `economy-designer` | 8-section GDD per `/design-system` |
| Build: implementation | `gameplay-programmer` | Economy system code, resource managers |
| Build: code quality | `godot-gdscript-specialist` | Static typing, signals, performance |
| Content: data authoring | Direct — Rarity Tier Editor / JSON authoring |
| Playtest: balance testing | `qa-tester` | Resource rate validation, progression curve checks |
| Review: design review | `creative-director` | Gate CD-GDD-ALIGN |
| Review: pillars check | `creative-director` | Gate CD-PILLARS |

## Gates to Fire

| Gate | When | Director |
|---|---|---|
| CD-GDD-ALIGN | After economy GDD sections | creative-director |
| CD-PILLARS | If economy changes affect consequence/investment pillars | creative-director |

## Templates

- `.claude/docs/templates/economy-model.md`
- `.claude/docs/templates/difficulty-curve.md`

## SoG-Specific Context

- 3 core resources: Supplies (body), Resolve (spirit), Time (pursuit clock)
- Rarity tiers: `data/_schemas/rarity_tiers.json` (dock-editable)
- No shop/market system yet — economy is currently resource drain + loot
- Companion consumes supplies (separate economy pressure)
- Every choice should cost something (GDD design principle)
