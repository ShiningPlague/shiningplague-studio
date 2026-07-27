---
name: team-audio
description: "Use when working on music direction, sound effects, audio cues, ambient soundscapes, or mix balance. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted: full implementation with team-orchestrator protocol, audio-director + sound-designer dispatch, project audio-context block."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/audio.md
    - Domain code AU
    - Agent routing table per execution-chain step
    - Director gates (CD-GDD-ALIGN, CD-PILLARS)
    - Project audio-context block ({{GDD_PATH}} audio section, target genres, tooling)
---

# Team Audio

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; the studio version is the full implementation — orchestration protocol, agent routing table, director gates, project audio-context block.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/audio.md`
**Domain code:** AU

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## Step 0: Load State + Select Activity

1. Read `production/workstreams/audio.md` — what's done, in-progress, next
2. Ask or infer: which ACTIVITY? (Design / Build / Content / Playtest / Review / Ship)
3. Follow the matching execution chain from `team-orchestrator.md`

## Agent Routing — WHO to dispatch at each step

When the execution chain says "dispatch specialist," use these agents:

| Step in chain | Agent to dispatch | What they do |
|---|---|---|
| Design: brainstorm / spec | `audio-director` | Music direction, sonic identity, mix strategy |
| Design: SFX specs | `sound-designer` | SFX specs, audio event lists, mixing parameters |
| Design: GDD authoring | `audio-director` | 8-section GDD per `/design-system` |
| Build: implementation | `gameplay-programmer` | Audio bus setup, event triggers, adaptive music code |
| Build: code quality | `godot-gdscript-specialist` | AudioStreamPlayer patterns, bus routing |
| Content: asset lists | `sound-designer` | Sound asset specs, cue sheets, mix targets |
| Playtest: audio feel | `qa-tester` | Volume balance, timing, spatial feel |
| Review: design review | `creative-director` | Gate CD-GDD-ALIGN |
| Review: pillars check | `creative-director` | Gate CD-PILLARS |

## Gates to Fire

| Gate | When | Director |
|---|---|---|
| CD-GDD-ALIGN | After audio GDD sections | creative-director |
| CD-PILLARS | If audio changes affect tone/atmosphere pillars | creative-director |

## Templates

- `.claude/docs/templates/sound-bible.md`

## Project Audio Context (fill for your project)

- Audio direction source: `{{GDD_PATH}}` audio section — target genres, sonic identity
- Genres: [list the project's target genres here]
- Music tooling: [note any music-generation plugin or asset pipeline the project uses]
- Note the workstream's current phase here (e.g. "no audio implementation yet — starts at design phase")
