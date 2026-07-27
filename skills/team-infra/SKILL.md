---
name: team-infra
description: "Use when working on framework maintenance, hook extensions, skill authoring, editor tools, Python automation, CI pipeline, or Donchitos customization. Routes to the correct workflow pattern and executes step-by-step."
metadata:
  origin: ShiningPlague
  adopted_by: ShiningPlague
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as team-orchestrator for infrastructure workstream
    - tools-programmer + devops-engineer + godot-gdscript-specialist dispatch
    - Director gate (TD-CODE-REVIEW)
    - Template infrastructure inventory (hooks, rules, skills, tools, addons)
---

# Team Infra

> 🌱 **ShiningPlague-authored.** No upstream version exists. Team-orchestrator skill for the infrastructure workstream (framework customization + tooling).

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/infrastructure.md`
**Domain code:** IF

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

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

## Template Infrastructure Inventory

- `.claude/hooks/` — session lifecycle hooks (session-start, skill-trigger-detect, pre/post-compact, validate-commit, etc.)
- `.claude/rules/` — path-scoped rules
- `.claude/skills/` — the studio skill set (repo-canonical)
- `tools/` — Python automation shipped with the studio (consistency_check.py — the doc-stack gate; doc_stack_check.py — the path-promise guard; workflow_state_check.py — the flow-ledger check) plus whatever runners this project adds
- `addons/` — engine editor docks/plugins, if the project uses them (e.g. a project dashboard, data-editor docks)
- `server/` — MCP server, if the project has one (rebuild when `server/src/` changes)
- The framework lives at `.claude/docs/`, `.claude/agents/`, `.claude/skills/` (all project-local, repo-canonical). Two-home rule: studio skills live in the repo's `.claude/skills/`; user level holds only personal skills — never create a user-level twin of a project skill (precedence would silently shadow it).
