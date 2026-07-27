---
name: team-art
description: "Use when working on art direction, visual identity, art bible, asset pipeline, illustration style, card art, or character art specifications. Routes to the correct workflow pattern and executes step-by-step."
metadata:
  origin: ShiningPlague
  adopted_by: ShiningPlague
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as team-orchestrator for art workstream
    - art-director + technical-artist dispatch
    - Director gates (AD-CONCEPT-VISUAL, AD-ART-BIBLE, AD-VISUAL, CD-PILLARS)
    - Project art-context placeholder block
---

# Team Art

> 🌱 **ShiningPlague-authored.** No upstream version exists. Team-orchestrator skill for the art workstream.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/art.md`
**Domain code:** AR

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## Step 0: Load State + Select Activity

1. Read `production/workstreams/art.md` — what's done, in-progress, next
2. Ask or infer: which ACTIVITY? (Design / Build / Content / Playtest / Review / Ship)
3. Follow the matching execution chain from `team-orchestrator.md`

## Agent Routing — WHO to dispatch at each step

When the execution chain says "dispatch specialist," use these agents:

| Step in chain | Agent to dispatch | What they do |
|---|---|---|
| Design: brainstorm / spec | `art-director` | Visual identity, style guide, asset standards |
| Design: GDD authoring | `art-director` | 8-section GDD per `/design-system` |
| Build: asset pipeline | `technical-artist` | Asset pipeline, shaders, rendering optimization |
| Build: implementation | `gameplay-programmer` | Illustration system code, asset loading |
| Content: art specs | `art-director` | Per-asset visual direction, reference sheets |
| Playtest: visual review | `art-director` | In-context visual validation |
| Review: concept visual | `art-director` | Gate AD-CONCEPT-VISUAL |
| Review: art bible | `art-director` | Gate AD-ART-BIBLE |
| Review: per-asset visual | `art-director` | Gate AD-VISUAL |
| Review: pillars check | `creative-director` | Gate CD-PILLARS |

## Gates to Fire

| Gate | When | Director |
|---|---|---|
| AD-CONCEPT-VISUAL | Concept phase visual direction | art-director |
| AD-ART-BIBLE | Art bible validation | art-director |
| AD-VISUAL | Per-asset or per-system visual review | art-director |
| CD-PILLARS | If art changes affect aesthetic pillars | creative-director |

## Templates

- `.claude/docs/templates/art-bible.md`

## Project-Specific Context

Fill in for your project (examples):

- Rendering approach (e.g. 2D illustrated panels, no 3D)
- Asset format constraints (e.g. preferred image formats; engine importer quirks such as Godot's WebP issues)
- Art production approach (e.g. AI-generated art directed by the designer)
- Art bible status (exists / Concept-phase gap)
- Style reference (genre + aesthetic keywords)
