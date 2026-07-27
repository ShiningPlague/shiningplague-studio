---
name: create-architecture
description: "Guided, section-by-section authoring of the master architecture document for the game. Reads all GDDs, the systems index, existing ADRs, and the engine reference library to produce a complete architecture blueprint before any code is written. Engine-version-aware: flags knowledge gaps and validates decisions against the pinned engine version. ShiningPlague-adopted: canonical project paths throughout (ADRs at docs/adr/, master GDD at {{GDD_PATH}}, editable game data under data/)."
argument-hint: "[focus-area: full | layers | data-flow | api-boundaries | adr-audit] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, AskUserQuestion, Task
agent: technical-director
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Canonical ADR path (docs/adr/NNN-<slug>.md)
    - Master GDD support ({{GDD_PATH}} + per-system docs/gdd/*.md when split)
    - Canonical data root (data/)
    - Project context block (existing ADRs, TR registry, control manifest)
    - Engine reference at docs/engine-reference/<engine>/VERSION.md
---

# Create Architecture

> 🌱 **ShiningPlague-adopted.** Originally Donchitos; battle-tested on a shipped Godot project. Upstream procedure preserved + project path corrections throughout.

This skill produces `docs/architecture/architecture.md` — the master architecture document that translates all approved GDDs into a concrete technical blueprint. It sits between design and implementation, and must exist before sprint planning begins.

**Distinct from `/architecture-decision`**: ADRs record individual point decisions. This skill creates the whole-system blueprint that gives ADRs their context.

Resolve the review mode (once, store for all gate spawns this run):
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

See `.claude/docs/director-gates.md` for the full check pattern.

**Argument modes:**
- **No argument / `full`**: Full guided walkthrough — all sections, start to finish
- **`layers`**: Focus on the system layer diagram only
- **`data-flow`**: Focus on data flow between modules only
- **`api-boundaries`**: Focus on API boundary definitions only
- **`adr-audit`**: Audit existing ADRs for engine compatibility gaps only

## Project Paths

| What | Canonical path |
|---|---|
| Game concept | `docs/gdd/game-concept.md` |
| Systems index | `docs/gdd/systems-index.md` (auto-generated from the registry) |
| Per-system GDDs | `docs/gdd/*.md` (when split) + `{{GDD_PATH}}` (master, e.g. `docs/GDD.md`) |
| ADRs | `docs/adr/NNN-*.md` |
| Editable game data | `data/` |
| Architecture output | `docs/architecture/architecture.md` |
| TR registry | `docs/architecture/tr-registry.md` |
| Control manifest | `docs/architecture/control-manifest.md` |

## Project Context

- Master GDD: `{{GDD_PATH}}` (may be monolithic before any per-system split)
- If no per-system GDDs exist yet, the master GDD is the only design source
- Existing ADRs at `docs/adr/`
- Engine reference: `docs/engine-reference/<engine>/VERSION.md`
- Technical preferences: `.claude/docs/technical-preferences.md`

---

## Phase 0: Load All Context

### 0a. Engine Context (Critical)

Read the engine reference library completely:

1. `docs/engine-reference/godot/VERSION.md` → engine name, version, LLM cutoff, post-cutoff risk levels
2. `docs/engine-reference/godot/breaking-changes.md` → HIGH and MEDIUM risk changes
3. `docs/engine-reference/godot/deprecated-apis.md` → APIs to avoid
4. `docs/engine-reference/godot/current-best-practices.md` → post-cutoff best practices
5. All files in `docs/engine-reference/godot/modules/` → current API patterns per domain

If no engine is configured, stop:
> "No engine is configured. Run `/setup-engine` first."

### 0b. Design Context + Technical Requirements Extraction

Read all approved design documents:

1. `docs/gdd/game-concept.md` — game pillars, genre, core loop
2. `docs/gdd/systems-index.md` — all systems, dependencies, priority tiers
3. `.claude/docs/technical-preferences.md`
4. **Every per-system GDD in `docs/gdd/` (when split)** + master GDD `{{GDD_PATH}}`

For each, extract technical requirements:
- Data structures implied by game rules
- Performance constraints
- Engine capabilities required
- Cross-system communication patterns
- State that must persist (save/load implications)
- Threading or timing requirements

Build a **Technical Requirements Baseline**:

```
## Technical Requirements Baseline
Extracted from [N] GDDs | [X] total requirements

| Req ID | GDD | System | Requirement | Domain |
|--------|-----|--------|-------------|--------|
| TR-combat-001 | combat.md | Combat | Hitbox detection per-frame | Physics |
```

### 0c. Existing Architecture Decisions

Read all files in `docs/adr/` to understand what has been decided. List ADRs found and domains.

### 0d. Generate Knowledge Gap Inventory

```
## Engine Knowledge Gap Inventory
Engine: Godot 4.6.1
LLM Training Covers: up to approximately [version]
Post-Cutoff Versions: [list]

### HIGH RISK Domains (must verify against engine reference)
- [Domain]: [Key changes]

### MEDIUM RISK Domains (verify key APIs)
- [Domain]: [Key changes]

### LOW RISK Domains (in training data, likely reliable)
- [Domain]: [no significant post-cutoff changes]

### Systems from GDD that touch HIGH/MEDIUM risk domains:
- [system name] → [domain] → [risk level]
```

Ask: "This inventory identifies [N] systems in HIGH RISK engine domains. Shall I continue building the architecture with these warnings flagged throughout?"

---

## Phase 1: System Layer Mapping

Map every system from `systems-index.md` into an architecture layer:

```
┌─────────────────────────────────────────────┐
│  PRESENTATION LAYER                         │  ← UI, HUD, menus, VFX, audio
├─────────────────────────────────────────────┤
│  FEATURE LAYER                              │  ← gameplay systems, AI, quests
├─────────────────────────────────────────────┤
│  CORE LAYER                                 │  ← physics, input, combat, movement
├─────────────────────────────────────────────┤
│  FOUNDATION LAYER                           │  ← engine integration, save/load,
│                                             │    scene management, event bus
├─────────────────────────────────────────────┤
│  PLATFORM LAYER                             │  ← OS, hardware, engine API surface
└─────────────────────────────────────────────┘
```

For each GDD system:
- Which layer does it belong to?
- What are its module boundaries?
- What does it own exclusively?

Present the proposed layer assignment, ask for approval, write to skeleton file immediately.

**Engine awareness check**: For each Core/Foundation system, flag if it touches HIGH or MEDIUM risk engine domain. Show relevant engine reference excerpt inline.

---

## Phase 2: Module Ownership Map

For each module defined in Phase 1:
- **Owns**: data and state this module is solely responsible for
- **Exposes**: what other modules may read or call
- **Consumes**: what it reads from other modules
- **Engine APIs used**: specific engine classes/nodes/signals (with version + risk noted)

Format as table per layer + ASCII dependency diagram.

**Engine awareness check**: For every engine API listed, verify against the relevant module reference doc. Flag post-cutoff APIs:

```
⚠️  [ClassName.method()] — Godot 4.6 (post-cutoff, HIGH risk)
    Verified against: docs/engine-reference/godot/modules/[domain].md
    Behaviour confirmed: [yes / NEEDS VERIFICATION]
```

---

## Phase 3: Data Flow

Define how data moves between modules. Cover at minimum:
1. **Frame update path**: Input → Core systems → State → Rendering
2. **Event/signal path**: How systems communicate without tight coupling
3. **Save/load path**: What state is serialised, which module owns serialisation
4. **Initialisation order**: Which modules must boot before others

Use ASCII sequence diagrams. For each data flow:
- Name the data being transferred
- Identify the producer and consumer
- State sync call / signal / shared state
- Flag flows crossing thread boundaries

---

## Phase 4: API Boundaries

For each boundary:
- What interface does a module expose?
- What are the entry points (functions/signals/properties)?
- What invariants must callers respect?
- What must the module guarantee?

Write in GDScript or pseudocode. These become contracts programmers implement against.

**Engine awareness check**: If any interface uses engine-specific types (`Node`, `Resource`, `Signal`), flag the version and verify the type exists/signature unchanged.

---

## Phase 5: ADR Audit + Traceability Check

Review all existing ADRs from Phase 0c against both the architecture built in Phases 1-4 AND the Technical Requirements Baseline from Phase 0b.

### ADR Quality Check

For each ADR:
- [ ] Has Engine Compatibility section?
- [ ] Engine version recorded?
- [ ] Post-cutoff APIs flagged?
- [ ] "GDD Requirements Addressed" section?
- [ ] Conflicts with layer/ownership decisions?
- [ ] Still valid for pinned engine version?

### Traceability Coverage Check

Map every requirement from the baseline to existing ADRs:

| Req ID | Requirement | ADR Coverage | Status |
|--------|-------------|--------------|--------|
| TR-combat-001 | Hitbox detection per-frame | ADR-001 | ✅ |
| TR-combat-002 | Combo state machine | — | ❌ GAP |

### Required New ADRs

List decisions from this session AND uncovered Technical Requirements. Group by layer — Foundation first.

---

## Phase 6: Missing ADR List

Group by priority:

**Must have before coding starts (Foundation & Core):**
- [e.g. "Scene management and scene loading strategy"]

**Should have before the relevant system is built:**
- [e.g. "Inventory serialisation format"]

**Can defer to implementation:**
- [e.g. "Specific shader technique for water"]

---

## Phase 7: Write the Master Architecture Document

Once all sections approved, write to `docs/architecture/architecture.md`:

```markdown
# {{PROJECT_NAME}} — Master Architecture

## Document Status
- Version: [N]
- Last Updated: [date]
- Engine: Godot 4.6.1
- GDDs Covered: [list]
- ADRs Referenced: [list]

## Engine Knowledge Gap Summary
[From Phase 0d]

## System Layer Map
[From Phase 1]

## Module Ownership
[From Phase 2]

## Data Flow
[From Phase 3]

## API Boundaries
[From Phase 4]

## ADR Audit
[From Phase 5]

## Required ADRs
[From Phase 6]

## Architecture Principles
[3-5 key principles derived from game concept + GDDs + technical preferences]

## Open Questions
[Decisions deferred — must be resolved before relevant layer is built]
```

---

## Phase 7b: Technical Director Sign-Off + Lead Programmer Feasibility Review

**Step 1 — TD self-review**: Apply gate **TD-ARCHITECTURE** (`.claude/docs/director-gates.md`) as self-review.

**Review mode check** before LP-FEASIBILITY:
- `solo` → skip. "LP-FEASIBILITY skipped — Solo mode." Proceed to Phase 8.
- `lean` → skip. "LP-FEASIBILITY skipped — Lean mode." Proceed to Phase 8.
- `full` → spawn as normal.

**Step 2 — Spawn `lead-programmer`** via Task using gate **LP-FEASIBILITY**.

Pass: architecture document path, technical requirements baseline summary, ADR list.

**Step 3 — Present both assessments**:

Use `AskUserQuestion`: "Technical Director and Lead Programmer have reviewed the architecture. How would you like to proceed?"
Options: `Accept — proceed to handoff` / `Revise flagged items first` / `Discuss specific concerns`

**Step 4 — Record sign-off**:

```
- Technical Director Sign-Off: [date] — APPROVED / APPROVED WITH CONDITIONS
- Lead Programmer Feasibility: FEASIBLE / CONCERNS ACCEPTED / REVISED
```

---

## Phase 8: Handoff

1. **Run these ADRs next**: top 3 from Phase 6, prioritised
2. **Gate check**: "Run `/gate-check pre-production` when all required ADRs are also written."
3. **Update session state**: Write summary to `production/session-state/active.md`

---

## Collaborative Protocol

1. **Load context silently** — don't narrate file reads
2. **Present findings** — show knowledge gap inventory and layer proposals
3. **Ask before deciding** — present options for each architectural choice
4. **Get approval before writing** — each section written only after user approves
5. **Incremental writing** — write each approved section immediately; survives session crashes

Never make a binding architectural decision without user input. If unsure, present 2-4 options with pros/cons.

---

## Recommended Next Steps

- Run `/architecture-decision [title]` for each required ADR — Foundation first
- Run `/create-control-manifest` once required ADRs are written
- Run `/gate-check pre-production` when all required ADRs written and architecture signed off
