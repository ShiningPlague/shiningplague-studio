---
name: design-review
description: "Use after authoring or updating a spec, GDD, or design document. Validates completeness, pillar alignment, MDA consistency, and flags design theory violations. Fires after /brainstorming or /design-system completes. ShiningPlague-adopted (Sons of Gilgamesh): adapts to SoG pillars (GDD v.2.3 §1.3/§1.5), spec paths, creative-director dispatch with CD-GDD-ALIGN gate."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/design-review/SKILL.md
  enhancements:
    - SoG pillars + MDA from GDD v.2.3 §1.3/§1.5
    - creative-director dispatch with CD-GDD-ALIGN gate from .claude/docs/director-gates.md
    - Expected Outcomes section verification (mandatory per project-local brainstorming)
    - Chain-propose to architecture-decision and writing-plans
    - SoG spec/GDD/ADR paths
---

# Design Review

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation — pillar alignment, MDA validation, creative-director dispatch, Expected Outcomes check. Vanilla backup: `docs/vanilla-backups/2026-05-15/design-review/`.

Validates a design document against project pillars, MDA framework, and design theory. Chain-fires after `/brainstorming` (spec review) or `/design-system` (GDD review).

## Inputs

- **Document path** — the spec or GDD to review
- **Game pillars** — from `docs/GDD v.2.3.md` (or dedicated pillars doc when it exists)
- **MDA aesthetics** — target aesthetic hierarchy from GDD §1.5

## Procedure

### 1. Read Context
- Read the document under review
- Read `docs/GDD v.2.3.md` §1.3 (pillars), §1.5 (MDA)
- Read `data/_schemas/system_registry.json` for related systems
- If system GDD: also read `design/gdd/systems-index.md` for dependency context

### 2. Dispatch Creative Director
Spawn `creative-director` with gate **CD-GDD-ALIGN** from `.claude/docs/director-gates.md`.
Pass: document path, pillars, MDA target, system's Player Fantasy section.
Await verdict: APPROVE / CONCERNS / REJECT.

### 3. Validate Design Theory
Check for:
- **Dominant strategies** — is there one option that's always best?
- **Economic imbalance** — do costs and rewards make sense?
- **Cognitive overload** — too many simultaneous mechanics?
- **Pillar drift** — does this move away from what the game IS?
- **Ludonarrative dissonance** — do mechanics contradict narrative themes?

### 4. Check Expected Outcomes
Every spec must have `## Expected outcomes at ship` per project-local `brainstorming` convention. Verify it exists and is concrete (testable by the designer), not vague. Push back on outcomes like "better combat" — outcomes must be concrete enough for a playtester or editor user to verify in a 5-minute session.

### 5. Present Verdict
- APPROVE — proceed to ADR or implementation
- CONCERNS [list] — revise flagged sections, then re-review
- REJECT [blockers] — fundamental redesign needed

## Chain-Propose

After APPROVE → propose `/architecture-decision` if the design needs locked decisions.
After APPROVE → propose `/writing-plans` if the design is ready for implementation.

After CONCERNS/REJECT → revise the spec, then re-run `/design-review`.

## SoG Paths

- Specs: `docs/specs/YYYY-MM-DD-<topic>-design.md`
- GDDs: `docs/GDD v.2.3.md` (master) or `docs/gdd/<system>.md` (per-system when split)
- ADRs: `docs/adr/NNN-<slug>.md`
- Director gates: `.claude/docs/director-gates.md`
