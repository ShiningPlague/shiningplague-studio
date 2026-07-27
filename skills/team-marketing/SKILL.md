---
name: team-marketing
description: "Use when working on store pages, community management, social media strategy, press kits, trailer planning, or player acquisition. Routes to the correct workflow pattern and executes step-by-step."
metadata:
  origin: ShiningPlague
  adopted_by: ShiningPlague
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as team-orchestrator for marketing workstream
    - community-manager + producer dispatch
    - Director gate (CD-PILLARS — marketing must represent identity accurately)
    - Project marketing-context placeholder block (indie defaults)
---

# Team Marketing

> 🌱 **ShiningPlague-authored.** No upstream version exists. Team-orchestrator skill for the marketing workstream.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/marketing.md`
**Domain code:** MK

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

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

## Project-Specific Context

Fill in for your project (examples):

- Team shape + channels (e.g. solo indie — storefront page, social media, devlogs)
- Market research notes, if the project keeps any (name the location here)
- Launch strategy constraint (e.g. launch a testable slice and iterate on market signal)
- Asset production approach (e.g. designer generates promotional art with AI tools)
