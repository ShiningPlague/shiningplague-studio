---
name: team-art
description: "Use when working on art direction, visual identity, art bible, asset pipeline, illustration style, card art, or character art specifications. Routes to the correct workflow pattern and executes step-by-step."
metadata:
  origin: ShiningPlague (Sons of Gilgamesh)
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as team-orchestrator for art workstream
    - art-director + technical-artist dispatch
    - Director gates (AD-CONCEPT-VISUAL, AD-ART-BIBLE, AD-VISUAL, CD-PILLARS)
    - SoG art context (2D illustrated panels + DM log, AI-generated art, no 3D)
---

# Team Art

> 🌱 **ShiningPlague-authored (2026-05-15).** Originally authored for the Sons of Gilgamesh project — no upstream version exists. Team-orchestrator skill for the art workstream. Promoted to user-level 2026-05-15 for portability.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/art.md`
**Domain code:** AR

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

## SoG-Specific Context

- 2D illustrated panels + DM narration log (no 3D)
- Card art: PNG format (not WebP — Godot 4.6 webp import issues)
- AI-generated art (designer generates with AI tools)
- No art bible exists yet — Concept phase gap
- Style reference: dark fantasy, illustrated storybook aesthetic
