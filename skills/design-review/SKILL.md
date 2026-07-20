---
name: design-review
description: "Use after authoring or updating a spec, GDD, or design document. Validates completeness, pillar alignment, MDA consistency, and flags design theory violations. Fires after /brainstorming or /design-system completes. ShiningPlague-adopted: adapts to the project's pillars ({{GDD_PATH}} pillars/MDA sections), spec paths, creative-director dispatch with CD-GDD-ALIGN gate."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Project pillars + MDA from {{GDD_PATH}} pillars/MDA sections
    - creative-director dispatch with CD-GDD-ALIGN gate from .claude/docs/director-gates.md
    - Expected Outcomes section verification (mandatory per project-local brainstorming)
    - Chain-propose to architecture-decision and writing-plans
    - Project spec/GDD/ADR paths
---

# Design Review

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; the studio version is the full implementation — pillar alignment, MDA validation, creative-director dispatch, Expected Outcomes check.

Validates a design document against project pillars, MDA framework, and design theory. Chain-fires after `/brainstorming` (spec review) or `/design-system` (GDD review).

## Inputs

- **Document path** — the spec or GDD to review
- **Game pillars** — from `{{GDD_PATH}}` (or dedicated pillars doc when it exists)
- **MDA aesthetics** — target aesthetic hierarchy from the GDD's MDA section

## Procedure

### 1. Read Context
- Read the document under review
- Read `{{GDD_PATH}}` pillars section + MDA section
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

## Project Paths

- Specs: `docs/specs/YYYY-MM-DD-<topic>-design.md`
- GDDs: `{{GDD_PATH}}` (master) or `docs/gdd/<system>.md` (per-system when split)
- ADRs: `docs/adr/NNN-<slug>.md`
- Director gates: `.claude/docs/director-gates.md`
