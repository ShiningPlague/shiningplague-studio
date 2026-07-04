---
name: team-release
description: "Use when preparing a release, creating changelogs, running release checklists, coordinating patch notes, or managing the deployment pipeline. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted (Sons of Gilgamesh): full implementation with release-manager + devops-engineer + qa-lead dispatch, SoG context (solo dev, manual build, no CI)."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/team-release/SKILL.md
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/release.md
    - Domain code RL
    - Agent routing table per execution-chain step
    - All 4 PHASE-GATEs trigger via /gate-check
    - SoG release context (solo dev, Godot export to itch.io, git as changelog)
---

# Team Release

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation. Vanilla backup: `docs/vanilla-backups/2026-05-15/team-release/`.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/release.md`
**Domain code:** RL

## Step 0: Load State + Select Activity

1. Read `production/workstreams/release.md` — what's done, in-progress, next
2. Ask or infer: which ACTIVITY? (Design / Build / Content / Playtest / Review / Ship)
3. Follow the matching execution chain from `team-orchestrator.md`

## Agent Routing — WHO to dispatch at each step

| Step in chain | Agent to dispatch | What they do |
|---|---|---|
| Design: release plan | `release-manager` | Release branch, versioning, deployment strategy |
| Build: pipeline | `devops-engineer` | Build pipeline, artifacts, CI |
| Build: checklist | `release-manager` | Release checklist execution |
| Playtest: full regression | `qa-lead` | Full regression, quality sign-off |
| Review: all gates | All 4 directors via `/gate-check` | CD, TD, PR, QL phase gates |
| Review: test coverage | `qa-lead` | Gate QL-TEST-COVERAGE |
| Ship: comms | `community-manager` | Patch notes, player comms |

## Gates to Fire

| Gate | When | Director |
|---|---|---|
| All PHASE-GATEs | Before release | CD, TD, PR, QL via `/gate-check` |
| QL-TEST-COVERAGE | Regression sign-off | qa-lead |

## Templates

- `.claude/docs/templates/release-checklist-template.md`
- `.claude/docs/templates/release-notes.md`
- `.claude/docs/templates/changelog-template.md`

## SoG-Specific Context

- Solo dev — release = Godot export + itch.io or similar
- No CI pipeline yet — manual build process
- Git commits are the canonical changelog (no CHANGELOG.md file)
