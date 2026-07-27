---
name: architecture-decision
description: "Use when locking a technical or design decision into an ADR. Fires after /brainstorming or /design-review when decisions need to be formally recorded. Batch 2-3 decisions per ADR. ShiningPlague-adopted: full implementation with studio ADR template (Live Sources table), technical-director dispatch with TD-ADR gate, registry + control-manifest + tr-registry update pipeline."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Studio + Donchitos merged ADR template at docs/adr/TEMPLATE.md with Live Sources table
    - Canonical ADR path (docs/adr/NNN-<slug>.md)
    - technical-director dispatch with TD-ADR gate
    - Batch rule (2-3 related decisions per ADR)
    - Pipeline: ADR Accept → control-manifest update → registry sync → tr-registry mark
    - Chain-propose to writing-plans + create-control-manifest
---

# Architecture Decision

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; the studio version is the full implementation — ADR authoring with Live Sources, batch rule, director gate, downstream updates.

Guided ADR authoring using the studio + Donchitos merged template at `docs/adr/TEMPLATE.md`.

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## When to Fire

- After a brainstorm spec reaches FINAL with decisions that constrain implementation
- After `/design-review` APPROVE when the design locks choices
- When the team says "we need to decide X before building"

## Inputs

- **Decisions to lock** — 2-3 related decisions per ADR (per Step sizing retrospective)
- **Source spec** — the brainstorm spec that generated these decisions
- **Existing ADRs** — `docs/adr/` for cross-reference

## Procedure

### 1. Read Context
- Read `docs/adr/TEMPLATE.md` for the format
- Read existing ADRs at `docs/adr/`
- Read the source spec for decisions being locked
- Read `docs/architecture/control-manifest.md` to check for conflicts

### 2. Assign ADR Number
Next number = highest existing + 1. Naming: `docs/adr/NNN-<slug>.md`.

### 3. Draft ADR Sections
Using the template (Donchitos + studio merged format with Live Sources):
- **Title + Status** (Proposed)
- **Context** — what problem, what constraints
- **Decision** — what we chose and why
- **Consequences** — positive + negative + trade-offs
- **Alternatives Considered** — what was rejected and why
- **Live Sources** — which JSON/data files are authoritative for this decision's values

### 4. Dispatch Technical Director
Spawn `technical-director` with gate **TD-ADR** from `.claude/docs/director-gates.md`.
Pass: draft ADR, related existing ADRs, engine constraints.
Await verdict.

### 5. If APPROVE → Accept
- Set status to Accepted
- Update `docs/architecture/control-manifest.md` with new programmer rules
- Update `data/_schemas/system_registry.json` — add ADR to relevant system entries' `decisions[]` and to `documentation_stack.adr_index.adrs[]`
- Update `docs/architecture/tr-registry.yaml` — mark covered requirements

### 6. Present to Designer
Show the ADR for final approval before committing.

## Chain-Propose
After Accept → propose `/writing-plans` to plan implementation.
After Accept → propose `/create-control-manifest` if many rules changed.
After Accept → propose `/verification-before-completion` before any "ADR shipped" claim.

## Batch rule

One ADR covers 2–3 related decisions from one design phase. Don't write one ADR per decision. Illustrative example — these filenames are not shipped, they show the shape:
- `001-your-system-schema-and-slots.md` would cover the data schema + the capacity model + the stacking policy for one system.
- `002-your-system-pipeline-and-effects.md` (later) would cover table resolution + effect architecture + the autoload extraction.

## Project Paths
- ADRs: `docs/adr/NNN-<slug>.md` (`docs/architecture/` holds the blueprint + manifest, never ADRs)
- Template: `docs/adr/TEMPLATE.md`
- Control manifest: `docs/architecture/control-manifest.md`
- TR registry: `docs/architecture/tr-registry.yaml`
- Director gates: `.claude/docs/director-gates.md`
