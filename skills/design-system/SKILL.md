---
name: design-system
description: "Use when authoring a new system GDD, when the designer says 'design the narrative system' or 'write a GDD for X', or when /map-systems identifies a system that needs a detailed design document. Guided 8-section authoring using the Donchitos game-design-document template. One section at a time, designer approval between sections. ShiningPlague-adopted: adapts to master GDD + per-system split convention, dispatches game-designer + creative-director, adds studio Live Sources / Implementation Notes / Open Questions sections."
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent
argument-hint: "[system-name]"
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - 8-section Donchitos template + studio Live Sources / Implementation Notes / Open Questions
    - Master GDD + per-system GDD split convention
    - game-designer agent dispatch for complex mechanics
    - creative-director gate (CD-GDD-ALIGN) review in full mode
    - Registry sync (system_registry.json status update on GDD completion)
    - Numbers-never-in-GDD rule (JSON + dock pattern)
---

# Design System — Guided GDD Authoring

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; the studio version is the full implementation — 8-section template, agent dispatch, director review, registry sync.

Author a per-system Game Design Document using the 8-section Donchitos template. One section at a time, with designer approval between sections. Dispatches game-designer agent for mechanical design and creative-director for pillar alignment review.

## Phase 1: Identify the System

**If argument provided:** use it as the system name.

**If no argument:** read `design/gdd/systems-index.md` (auto-generated from registry), list systems with Status = "Not Started" or "In Progress", and ask which one to design.

Then check:
1. Does `docs/gdd/<system-name>.md` already exist? If yes: "GDD already exists. Edit it, or start fresh?"
2. Read the master GDD `{{GDD_PATH}}` for any existing design content about this system.
3. Read `data/_schemas/system_registry.json` for the system's status, features, dependencies.
4. Read `docs/architecture/tr-registry.yaml` for related technical requirements.
5. Read any related ADRs from `docs/adr/`.
6. Read the game pillars from the {{GDD_PATH}} pillars section.

Report context found: "Found [N] related TR-IDs, [M] related ADRs, existing design content in master GDD Section [X]."

---

## Phase 2: Load Template

Read the template at `.claude/docs/templates/game-design-document.md`. This defines the 8 required sections plus studio additions.

The 8 Donchitos sections:
1. Overview
2. Player Fantasy
3. Detailed Design (Core Rules + States + Interactions)
4. Formulas
5. Edge Cases
6. Dependencies
7. Tuning Knobs
8. Acceptance Criteria

**Studio additions** (add after Acceptance Criteria):
- Live Sources table (JSON paths + editor docks — mandatory for data-driven systems)
- Implementation Notes (file paths to existing code, if any)
- Open Questions

---

## Phase 3: Author Section by Section

For EACH section, follow this cycle:

1. **Draft the section** using context from Phase 1 (master GDD content, TR-IDs, ADRs, registry)
2. **Present the draft** to the designer with: "Here's the [Section Name] draft. Approve, revise, or skip?"
3. **Wait for approval** before proceeding to the next section
4. **Write the approved section** to `docs/gdd/<system-name>.md` immediately (persist decisions, manage context)

**Section-specific guidance:**

### Overview
One paragraph. What this system is, what the player does, why it exists. No jargon. Cite the master GDD section if content already exists there.

### Player Fantasy
What should the player FEEL? The emotional promise. Tie directly to the game pillars from {{GDD_PATH}} — which ones does this system serve?

### Detailed Design
The meaty section. Core rules as numbered steps (a programmer implements this without asking questions). States and transitions as a table. Interactions with other systems — specify the interface: what data flows in/out, who owns what.

**Dispatch game-designer agent** for this section if the system has complex mechanics. The game-designer can draft the rules while I coordinate.

### Formulas
Every formula with: variable definitions, expected value ranges, example calculations. Link to live data sources in `data/_schemas/` where the actual numbers live.

### Edge Cases
Explicitly state what happens. "Handle gracefully" is not valid. Each edge case = scenario + behavior.

### Dependencies
Bidirectional. If this system depends on combat, combat's GDD must mention this system. Cross-reference `design/gdd/systems-index.md` layer assignments.

### Tuning Knobs
Each knob: safe range, what gameplay aspect it affects, where the value lives (JSON path + editor dock).

### Acceptance Criteria
Testable criteria. A QA tester verifies pass/fail. Each criterion traces to a TR-ID from `docs/architecture/tr-registry.yaml`.

---

## Phase 4: Director Review (if review-mode = full)

Read `production/review-mode.txt`. If `full`:

Spawn `creative-director` via Agent with gate **CD-GDD-ALIGN** from `.claude/docs/director-gates.md`:
- Pass: GDD file path, game pillars, MDA aesthetics, system's Player Fantasy section
- Await verdict: APPROVE / CONCERNS / REJECT

If CONCERNS: surface to designer with options (Revise / Accept / Discuss).
If REJECT: surface blockers, do not mark GDD as Approved.

---

## Phase 5: Finalize

1. Set GDD status to `Approved` (or `In Review` if director had CONCERNS that were accepted)
2. Update `design/gdd/systems-index.md` by running `python tools/generate_systems_index.py` (or the hook handles this if registry updated)
3. Update `data/_schemas/system_registry.json` — set the system's status to reflect GDD completion
4. Propose chain follow-on: "GDD complete. Next: `/design-review` for validation, or `/architecture-decision` if this system needs a new ADR."

---

## Studio Notes

- **Master GDD stays as overview.** Per-system GDDs in `docs/gdd/` hold the deep design. Master GDD section headers get a pointer: "See `docs/gdd/<system>.md` for detailed design."
- **Template-first rule:** Use the Donchitos template as base. Add studio Live Sources / Implementation Notes / Open Questions on top.
- **Data-driven mandate:** Every tuning knob must point to a JSON file, not a hardcoded value. Every formula must reference where the actual numbers live.
- **Numbers never live in the GDD.** The GDD explains the formula; the JSON holds the values; the dock edits them.
