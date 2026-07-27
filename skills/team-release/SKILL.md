---
name: team-release
description: "Use when preparing a release, creating changelogs, running release checklists, coordinating patch notes, or managing the deployment pipeline. Routes to the correct workflow pattern and executes step-by-step. ShiningPlague-adopted: full implementation with release-manager + devops-engineer + qa-lead dispatch and a project release-context block."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - team-orchestrator execution protocol cross-link
    - Workstream state at production/workstreams/release.md
    - Domain code RL
    - Agent routing table per execution-chain step
    - All 4 PHASE-GATEs trigger via /gate-check
    - Project release-context placeholder block (solo-dev defaults)
---

# Team Release

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; this version is the full implementation.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/release.md`
**Domain code:** RL

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

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

## Project-Specific Context

Fill in for your project (examples):

- Team shape (e.g. solo dev — release = engine export + storefront upload)
- CI pipeline status (e.g. none yet — manual build process)
- Changelog convention (e.g. git commits as the canonical changelog, no CHANGELOG.md file)
