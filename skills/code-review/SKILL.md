---
name: code-review
description: "Use after implementing a feature, fixing a bug, or completing a plan task. Reviews code architecture, adherence to ADRs and control manifest, coding standards, and Godot patterns. Fires after /dev-story or /executing-plans completes. ShiningPlague-adopted (Sons of Gilgamesh): full implementation with lead-programmer dispatch (LP-CODE-REVIEW gate), control-manifest cross-check, godot-gdscript-specialist consult, SoG architecture principles checklist."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/code-review/SKILL.md
  enhancements:
    - lead-programmer dispatch with LP-CODE-REVIEW gate
    - Control manifest cross-check (55 rules at docs/architecture/control-manifest.md)
    - SoG architecture principles checklist (data-driven, tag-based, decomposed, modular, human-editable, action-based)
    - godot-gdscript-specialist dispatch for engine-specific review
    - Chain-propose to verification-before-completion + commit/push
---

# Code Review

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation — director-gate dispatch, control-manifest cross-check, engine-specialist consult. Vanilla backup: `docs/vanilla-backups/2026-05-15/code-review/`.

Architectural code review that validates implementation against design decisions, coding standards, and engine-specific patterns.

## Inputs

- **Changed files** — `git diff` or explicit file list
- **Governing ADR(s)** — from `docs/adr/` (if the feature has one)
- **Control manifest** — `docs/architecture/control-manifest.md` (55 rules)

## Procedure

### 1. Gather Context
- `git diff --stat` to identify scope of changes
- Read the governing ADR (if known) or grep `docs/adr/` for related decisions
- Read `docs/architecture/control-manifest.md` for applicable rules
- Read `.claude/docs/godot-gotchas.md` for Godot-specific patterns

### 2. Dispatch Lead Programmer
Spawn `lead-programmer` with gate **LP-CODE-REVIEW** from `.claude/docs/director-gates.md`.
Pass: diff, ADR references, control manifest rules relevant to changed systems.
Await verdict.

### 3. Check Against Control Manifest
For each changed file, identify which control manifest rules apply (rules are tagged by system/layer). Flag violations.

### 4. Check Architecture Principles
From CLAUDE.md:
- **Data-driven**? (no embedded data in scripts — JSON in `data/`)
- **Tag-based**? (no hardcoded per-location lists — use tag matching)
- **Decomposed**? (signals, not direct method calls — autoload singletons)
- **Modular**? (no assumed dependencies — check + degrade gracefully)
- **Human-editable**? (schema in `data/_schemas/`)
- **Action-based**? (player actions query tags, not hardcoded lists)

### 5. Engine-Specific Review
Spawn `godot-gdscript-specialist` for:
- Static typing enforcement
- Signal vs direct call patterns
- Resource class usage
- Performance patterns (avoid per-frame allocations, use `@export` over `get_node`)

### 6. Present Verdict
- APPROVE — ship it
- CONCERNS [list] — fix flagged items, then re-review
- REJECT [blockers] — architecture violation, needs redesign

## Chain-Propose

After APPROVE → propose `/verification-before-completion` if not yet run.
After APPROVE → propose commit + push (with drafted commit message).
After CONCERNS/REJECT → revise the code, then re-run `/code-review`.

## SoG Paths

- Source: `src/systems/`, `src/ui/`, `src/autoloads/`
- Scenes: `scenes/`
- Addons: `addons/`
- ADRs: `docs/adr/`
- Control manifest: `docs/architecture/control-manifest.md`
- Godot gotchas: `.claude/docs/godot-gotchas.md`
- Director gates: `.claude/docs/director-gates.md`
