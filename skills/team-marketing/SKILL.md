---
name: team-marketing
description: "Use when working on store pages, community management, social media strategy, press kits, trailer planning, or player acquisition. Routes to the correct workflow pattern and executes step-by-step."
metadata:
  origin: ShiningPlague (Sons of Gilgamesh)
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as team-orchestrator for marketing workstream
    - community-manager + producer dispatch
    - Director gate (CD-PILLARS — marketing must represent identity accurately)
    - SoG marketing context (solo indie, itch.io, devlogs, launch-and-iterate constraint)
---

# Team Marketing

> 🌱 **ShiningPlague-authored (2026-05-15).** Originally authored for the Sons of Gilgamesh project — no upstream version exists. Team-orchestrator skill for the marketing workstream. Promoted to user-level 2026-05-15 for portability.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/marketing.md`
**Domain code:** MK

## Step 0: Load State + Select Activity

1. Read `production/workstreams/marketing.md` — what's done, in-progress, next
2. Ask or infer: which ACTIVITY? (Design / Build / Content / Playtest / Review / Ship)
3. Follow the matching execution chain from `team-orchestrator.md`

## Agent Routing — WHO to dispatch at each step

| Step in chain | Agent to dispatch | What they do |
|---|---|---|
| Design: strategy | `community-manager` | Social media plan, community engagement strategy |
| Design: launch timeline | `producer` | Launch timeline coordination, milestone alignment |
| Build: store page | `community-manager` | Store page copy, screenshots, descriptions |
| Build: press kit | `community-manager` | Press kit assembly, media assets |
| Content: comms | `community-manager` | Devlogs, social posts, patch notes |
| Review: pillars check | `creative-director` | Gate CD-PILLARS |

## Gates to Fire

| Gate | When | Director |
|---|---|---|
| CD-PILLARS | Marketing must represent the game's identity accurately | creative-director |

## SoG-Specific Context

- Solo indie dev — marketing = itch.io page, social media, devlogs
- Market research at `docs/market-research/solo-indie-dev-2026.md`
- Launch-and-iterate constraint: goal is testable slice, not full game
- Designer handles art generation with AI tools
