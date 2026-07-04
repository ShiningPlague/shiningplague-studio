---
name: team-ui
description: "Use when working on UI screens, HUD layout, menus, editor docks, Project Dashboard, interaction patterns, or screen flow. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted (Sons of Gilgamesh): full implementation with ux-designer + ui-programmer dispatch, SoG context (Control-node based .tscn, 5 editor docks, paged text UI spec)."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/team-ui/SKILL.md
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/ui-ux.md
    - Domain code UX
    - Agent routing table per execution-chain step
    - Director gates (CD-GDD-ALIGN, TD-CODE-REVIEW)
    - SoG UI context (Control-node based, Project Dashboard dock, 5 editor docks, paged text spec)
---

# Team UI

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation. Vanilla backup: `docs/vanilla-backups/2026-05-15/team-ui/`.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/ui-ux.md`
**Domain code:** UX

## Step 0: Load State + Select Activity

1. Read `production/workstreams/ui-ux.md` — what's done, in-progress, next
2. Ask or infer: which ACTIVITY? (Design / Build / Content / Playtest / Review / Ship)
3. Follow the matching execution chain from `team-orchestrator.md`

## Agent Routing — WHO to dispatch at each step

| Step in chain | Agent to dispatch | What they do |
|---|---|---|
| Design: brainstorm / spec | `ux-designer` | User flows, interaction patterns, information architecture |
| Design: GDD authoring | `ux-designer` | 8-section GDD per `/design-system` |
| Build: implementation | `ui-programmer` | Godot Control nodes, .tscn scenes, theme resources |
| Build: code quality | `godot-gdscript-specialist` | GDScript UI patterns, signal wiring |
| Build: code review | `lead-programmer` | Architecture compliance, ADR adherence |
| Playtest: UX testing | `qa-tester` | Input flow, layout validation, edge cases |
| Review: design review | `creative-director` | Gate CD-GDD-ALIGN |
| Review: code review | `lead-programmer` | Gate TD-CODE-REVIEW |

## Gates to Fire

| Gate | When | Director |
|---|---|---|
| CD-GDD-ALIGN | After UI system GDD authoring | creative-director |
| TD-CODE-REVIEW | After UI code ships | lead-programmer |

## Templates

- `.claude/docs/templates/ux-spec.md`
- `.claude/docs/templates/hud-design.md`
- `.claude/docs/templates/interaction-pattern-library.md`

## SoG-Specific Context

- UI is Control-node based (.tscn scenes editable in Godot, not programmatic)
- Project Dashboard dock: `addons/project_dashboard/`
- Editor docks: Monster Editor, Rarity Tier Editor, Location Graph Editor, Archetype Recipe Editor, Trait Multipliers Editor
- Main scenes: `scenes/ui/main_menu.tscn`, `scenes/map/map_screen.tscn`
- Design spec reference: see memory file `reference_ui_design_spec.md`
- Paged text (not scroll), anchored choices, stats strip
