---
name: team-ui
description: "Use when working on UI screens, HUD layout, menus, editor docks, dashboards, interaction patterns, or screen flow. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted: full implementation with ux-designer + ui-programmer dispatch and a project UI-context block."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/ui-ux.md
    - Domain code UX
    - Agent routing table per execution-chain step
    - Director gates (CD-GDD-ALIGN, TD-CODE-REVIEW)
    - Project UI-context placeholder block
---

# Team UI

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; this version is the full implementation.

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

## Project-Specific Context

Fill in for your project (examples):

- UI approach (e.g. Control-node based `.tscn` scenes editable in Godot, not programmatic)
- In-engine dashboard/editor docks, if any (e.g. `addons/project_dashboard/`, data-editor docks)
- Main UI scenes (e.g. `scenes/ui/main_menu.tscn`)
- UI design spec reference, if one exists
- Interaction conventions (e.g. paged text vs scroll, anchored choices, stats strip)
