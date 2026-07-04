---
name: team-audio
description: "Use when working on music direction, sound effects, audio cues, ambient soundscapes, or mix balance. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted (Sons of Gilgamesh): full implementation with team-orchestrator protocol, audio-director + sound-designer dispatch, SoG context (6 target genres via bitwize-music plugin, no audio impl yet)."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/team-audio/SKILL.md
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/audio.md
    - Domain code AU
    - Agent routing table per execution-chain step
    - Director gates (CD-GDD-ALIGN, CD-PILLARS)
    - SoG audio context (GDD v2.3 §7.4, bitwize-music plugin, 6 genres)
---

# Team Audio

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation — orchestration protocol, agent routing table, director gates, audio context. Vanilla backup: `docs/vanilla-backups/2026-05-15/team-audio/`.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/audio.md`
**Domain code:** AU

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

## SoG-Specific Context

- GDD v2.3 Section 7.4: Audio Direction — 6 target genres via bitwize-music plugin
- Genres: dark ambient, dungeon synth, orchestral, dark fantasy, high fantasy, new wave synth hop
- No audio implementation yet — this workstream starts at design phase
