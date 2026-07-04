---
name: team-infra
description: "Use when working on framework maintenance, hook extensions, skill authoring, editor tools, Python automation, CI pipeline, or Donchitos customization. Routes to the correct workflow pattern and executes step-by-step."
metadata:
  origin: ShiningPlague (Sons of Gilgamesh)
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as team-orchestrator for infrastructure workstream
    - tools-programmer + devops-engineer + godot-gdscript-specialist dispatch
    - Director gate (TD-CODE-REVIEW)
    - SoG infra context (16 hooks, 11 rules, project-local skill registry, MCP server, addons)
---

# Team Infra

> 🌱 **ShiningPlague-authored (2026-05-15).** Originally authored for the Sons of Gilgamesh project — no upstream version exists. Team-orchestrator skill for the infrastructure workstream (Donchitos customization + tooling). Promoted to user-level 2026-05-15 for portability.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/infrastructure.md`
**Domain code:** IF

## Step 0: Load State + Select Activity

1. Read `production/workstreams/infrastructure.md` — what's done, in-progress, next
2. Ask or infer: which ACTIVITY? (Design / Build / Content / Playtest / Review / Ship)
3. Follow the matching execution chain from `team-orchestrator.md`

## Agent Routing — WHO to dispatch at each step

| Step in chain | Agent to dispatch | What they do |
|---|---|---|
| Design: tool spec | `tools-programmer` | Tool requirements, automation design |
| Design: CI/CD plan | `devops-engineer` | Build pipeline, deployment strategy |
| Build: Python automation | `tools-programmer` | Python scripts, pipeline tools, editor extensions |
| Build: Godot plugins | `godot-gdscript-specialist` | Godot addon/dock development |
| Build: CI/CD | `devops-engineer` | Build scripts, deployment automation |
| Build: code review | `lead-programmer` | Architecture compliance, ADR adherence |
| Playtest: tool testing | `qa-tester` | Hook/script/dock validation |
| Review: code review | `lead-programmer` | Gate TD-CODE-REVIEW |

## Gates to Fire

| Gate | When | Director |
|---|---|---|
| TD-CODE-REVIEW | After infrastructure code ships | lead-programmer |

## Templates

- `.claude/docs/templates/technical-design-document.md`

## SoG-Specific Context

- `.claude/hooks/` — 16 hooks (session-start, skill-trigger-detect, pre/post-compact, validate-commit, etc.)
- `.claude/rules/` — 11 path-scoped rules
- `.claude/skills/` — 13+ project-local overrides (this number grows)
- `tools/` — Python automation (consistency_check.py, check_registry_coverage.py, generate_systems_index.py, show_flags.py)
- `addons/` — Godot editor docks (project_dashboard, monster_editor, rarity_tier_editor, etc.)
- `server/` — MCP server (npm build when `server/src/` changes)
- Donchitos framework lives at `.claude/docs/`, `.claude/agents/`, `.claude/skills/` (all project-local, repo-canonical; studio skills moved into `.claude/skills/` per the 2026-07-04 two-home ruling — user level holds only personal skills)
