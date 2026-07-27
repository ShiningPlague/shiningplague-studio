---
name: team-economy
description: "Use when working on resource economy, loot tables, progression curves, reward balance, core-resource tuning, or in-game market design. Routes to the correct workflow pattern and executes step-by-step."
metadata:
  origin: ShiningPlague
  adopted_by: ShiningPlague
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as team-orchestrator for economy workstream
    - economy-designer + systems-designer + game-designer dispatch
    - Director gates (CD-GDD-ALIGN, CD-PILLARS)
    - Project economy-context placeholder block ({{CURRENCY_DATA}})
---

# Team Economy

> 🌱 **ShiningPlague-authored.** No upstream version exists. Team-orchestrator skill for the economy workstream.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/economy.md`
**Domain code:** EC

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

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
| Content: data authoring | Direct — in-engine data editor dock / JSON authoring |
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

## Project-Specific Context

Fill in for your project (examples):

- Core resources/currencies and the pressure each creates on the player
- Economy data files: {{CURRENCY_DATA}} (e.g. `data/economy/*.json`, dock-editable)
- Existing sinks and faucets (e.g. resource drain + loot only, no shop/market yet)
- Secondary economy pressures (e.g. companions or upkeep consuming resources)
- Economy design principles from the GDD (e.g. every choice should cost something)
