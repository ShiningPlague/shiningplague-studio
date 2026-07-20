---
name: architecture-review
description: "Use when validating architecture completeness against GDDs, checking ADR coverage gaps, detecting cross-ADR conflicts, verifying engine compatibility, or when the designer says 'review architecture', 'check ADR coverage', or 'are our ADRs complete?' Produces PASS/CONCERNS/FAIL verdict. ShiningPlague-adopted: uses docs/adr/*.md not docs/architecture/adr-*, integrates with system_registry.json + tr-registry.yaml, adds engine-specialist consult."
argument-hint: "[focus: full | coverage | consistency | engine | single-gdd path/to/gdd.md | rtm]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion, Agent
model: opus
agent: technical-director
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Project ADR path (docs/adr/*.md not docs/architecture/adr-*)
    - Master GDD support ({{GDD_PATH}} + design/gdd/<system>.md mix)
    - system_registry.json cross-reference (system status + dependencies)
    - tr-registry.yaml preservation (never renumber TR-IDs across runs)
    - godot-specialist consultation via Agent dispatch
    - Reflexion log to docs/consistency-failures.md
    - Session state update to production/session-state/active.md
---

# Architecture Review

> 🌱 **ShiningPlague-adopted.** Originally Donchitos; battle-tested on a shipped Godot project. Upstream hardcoded `docs/architecture/adr-*.md`; studio ADRs live at `docs/adr/*.md`. Path conventions corrected throughout + project sources added (`data/_schemas/system_registry.json`, `tr-registry.yaml`, engine-specialist Agent dispatch).

Validates that the complete body of architectural decisions covers all game design requirements, is internally consistent, and correctly targets the project's pinned engine version. Quality gate between Technical Setup and Pre-Production.

## Argument Modes

- **No argument / `full`**: Full review — all phases
- **`coverage`**: Traceability only — which GDD requirements have no ADR
- **`consistency`**: Cross-ADR conflict detection only
- **`engine`**: Engine compatibility audit only
- **`single-gdd [path]`**: Review for one specific GDD
- **`rtm`**: Full Requirements Traceability Matrix (GDD → ADR → Story → Test)

---

## Phase 1: Load Everything

### Phase 1a — Summary Scan (fast, low tokens)

Before reading any full document, use Grep to extract `## Summary` sections:

```
Grep pattern="## Summary" glob="design/gdd/*.md" output_mode="content" -A 4
Grep pattern="## Summary" glob="docs/adr/*.md" output_mode="content" -A 3
```

Also scan master GDD for system sections:
```
Grep pattern="^## [0-9]" path="{{GDD_PATH}}" output_mode="content"
```

For `single-gdd [path]` mode: use the target GDD's summary to identify which ADRs reference the same system, then full-read only those ADRs. Skip full-reading unrelated GDDs.

For `engine` mode: only full-read ADRs — GDDs not needed.

For `coverage` or `full` mode: proceed to full-read everything below.

### Phase 1b — Full Document Load

**Design Documents:**
- `{{GDD_PATH}}` — master GDD (all system designs until per-system split)
- Any per-system GDDs at `design/gdd/<system>.md`
- `design/gdd/systems-index.md` — auto-generated from registry (authoritative system list)

**Architecture Documents:**
- All ADRs at `docs/adr/*.md` (NOT `docs/architecture/` — that's a pointer only)
- `docs/architecture/architecture.md` (if exists)
- `docs/architecture/control-manifest.md`

**Engine Reference:**
- `docs/engine-reference/godot/VERSION.md`
- `docs/engine-reference/godot/breaking-changes.md` (if exists)
- `docs/engine-reference/godot/deprecated-apis.md` (if exists)
- All files in `docs/engine-reference/godot/modules/` (if exists)

**Project Standards:**
- `.claude/docs/technical-preferences.md`

**Project Additional Sources:**
- `data/_schemas/system_registry.json` — authoritative system status + dependencies
- `docs/architecture/tr-registry.yaml` — existing requirement IDs (preserve across runs)

Report: "Loaded [N] GDDs, [M] ADRs, [P] systems in registry, engine: Godot 4.6.1."

Also read `docs/consistency-failures.md` if it exists; surface recurring patterns as a "Known conflict-prone areas" note at the top of Phase 4 output.

---

## Phase 2: Extract Technical Requirements from Every GDD

### Pre-load the TR Registry

Read `docs/architecture/tr-registry.yaml` if it exists. Index existing entries by `id` and normalised `requirement` text. **This prevents ID renumbering across review runs.**

For each requirement extracted:
1. **Exact/near match** → reuse existing TR-ID. Update `requirement` text only if wording changed; add `revised: [date]`.
2. **No match** → assign new ID: `TR-[system]-NNN`, sequence + 1.
3. **Ambiguous** → ask user: "Same as TR-[system]-NNN, or new?"

Skip entries with `status: deprecated`.

For each GDD, extract technical requirements — things architecture must provide:

| Category | Example |
|----------|---------|
| Data structures | "Each entity has health, max health, status effects" |
| Performance constraints | "Collision detection must run at 60fps with 200 entities" |
| Engine capability | "Inverse kinematics for character animation" |
| Cross-system communication | "Damage system notifies UI and audio simultaneously" |
| State persistence | "Player progress persists between sessions" |
| Threading/timing | "AI decisions happen off the main thread" |
| Platform requirements | "Supports keyboard, gamepad, touch" |

Cross-reference `system_registry.json` system status (active/wip/partial/phasing_out) to mark requirement status.

---

## Phase 3: Build the Traceability Matrix

For each TR, search all ADRs:
1. Read `## GDD Requirements Addressed` section
2. Check if decision text implicitly covers the requirement
3. Mark coverage status:

| Status | Meaning |
|--------|---------|
| ✅ **Covered** | An ADR explicitly addresses this requirement |
| ⚠️ **Partial** | An ADR partially covers this, or coverage is ambiguous |
| ❌ **Gap** | No ADR addresses this requirement |

Build the full matrix:

```
| TR-ID | GDD | System | Requirement | ADR Coverage | Status |
|-------|-----|--------|-------------|--------------|--------|
| TR-combat-001 | combat.md | Combat | Hitbox detection < 1 frame | ADR-0003 | ✅ |
| TR-combat-002 | combat.md | Combat | Combo window timing | — | ❌ GAP |
```

Count totals: X covered, Y partial, Z gaps.

### Phase 3b: Story + Test Linkage (rtm mode only)

Glob `production/epics/**/*.md` (excluding EPIC.md index). For each story: extract `TR-ID`, file path, title, Status, `## Test Evidence` test file path.

Glob `tests/**/*` and `tools/**_check.gd`. Build index: system → [test file paths].

For each test path from stories, confirm via Glob whether file exists. Note MISSING if stated but not found.

Extended matrix adds Story + Test File + Test Status (COVERED / MISSING / NONE / NO STORY) columns.

---

## Phase 4: Cross-ADR Conflict Detection

Compare every ADR against every other for:
- **Data ownership conflict** — two ADRs claim same data
- **Integration contract conflict** — incompatible interface assumptions
- **Performance budget conflict** — combined exceeds frame budget
- **Dependency cycle** — A requires B requires A
- **Architecture pattern conflict** — signals vs direct calls to same system
- **State management conflict** — dual authority over same game state

For each conflict, output:
```
## Conflict: [ADR-NNNN] vs [ADR-MMMM]
Type: [Data ownership / Integration / Performance / Dependency / Pattern / State]
ADR-NNNN claims: [...]
ADR-MMMM claims: [...]
Impact: [what breaks if both implemented as written]
Resolution options:
  1. [Option A]
  2. [Option B]
```

### ADR Dependency Ordering

1. Collect `Depends On` fields from every ADR's "ADR Dependencies" section
2. Topological sort → implementation order
3. Flag unresolved dependencies (depends on Proposed ADR)
4. Detect cycles → 🔴 DEPENDENCY CYCLE
5. Output recommended implementation order (Foundation → Core → Feature)

---

## Phase 5: Engine Compatibility Cross-Check

### Version Consistency
- Do all ADRs that mention an engine version agree on the same version?
- Flag any ADR written for an older engine version as potentially stale.

### Post-Cutoff API Consistency
- Collect "Post-Cutoff APIs Used" fields from all ADRs
- Verify against module reference docs
- Check for contradictory assumptions

### Deprecated API Check
- Grep all ADRs for API names listed in `deprecated-apis.md`
- Flag any ADR referencing a deprecated API

### Missing Engine Compatibility Sections
- List ADRs missing the section entirely (blind spots)

### Engine Specialist Consultation

Spawn `godot-specialist` (or primary specialist from `.claude/docs/technical-preferences.md`) via Agent for:
1. Confirm or challenge each audit finding — specialists know engine nuances not in reference docs
2. Identify engine-specific anti-patterns the audit may have missed (wrong Godot node type, etc.)
3. Flag ADRs assuming engine behaviour different from pinned version

Incorporate findings under `### Engine Specialist Findings` in Phase 5 output.

---

## Phase 5b: Design Revision Flags (Architecture → GDD Feedback)

For each **HIGH RISK engine finding** from Phase 5, check whether any GDD makes an assumption that the verified engine reality contradicts.

Cases to check:
1. Post-cutoff API behaviour differs from training-data assumptions → check GDDs referencing the system
2. Known engine limitations in ADRs → check GDDs designing mechanics around affected features
3. Deprecated API conflicts → check GDDs assuming deprecated API behaviour

```
### GDD Revision Flags (Architecture → Design Feedback)
| GDD | Assumption | Reality (from ADR/engine-reference) | Action |
|-----|-----------|--------------------------------------|--------|
```

If none: "No GDD revision flags — all GDD assumptions consistent with verified engine behaviour."

Ask: "Should I flag these GDDs for revision in the systems index?" If yes, update Status to exact string "Needs Revision" (no parentheticals — other skills match the exact string).

---

## Phase 6: Architecture Document Coverage

If `docs/architecture/architecture.md` exists, validate:
- Every system from `systems-index.md` appears in architecture layers
- Data flow covers all cross-system communication from GDDs
- API boundaries support all integration requirements
- No orphaned architecture (systems in arch doc with no GDD)

---

## Phase 7: Output the Review Report

```
## Architecture Review Report — {{PROJECT_NAME}}
Date: [date]
Engine: Godot 4.6.1
GDDs Reviewed: [N]
ADRs Reviewed: [M]

### Traceability Summary
Total requirements: [N] — ✅ Covered: [X] — ⚠️ Partial: [Y] — ❌ Gaps: [Z]

### Coverage Gaps (no ADR exists)
[Per gap: TR-ID, GDD, system, requirement, suggested ADR title, engine risk]

### Cross-ADR Conflicts
[All conflicts from Phase 4]

### ADR Dependency Order
[Topologically sorted, with unresolved deps and cycles]

### GDD Revision Flags
[From Phase 5b, or "None"]

### Engine Compatibility Issues
[From Phase 5]

### Architecture Document Coverage
[From Phase 6]

### Verdict: [PASS / CONCERNS / FAIL]
PASS: All requirements covered, no conflicts, engine consistent
CONCERNS: Some gaps/partial, no blocking conflicts
FAIL: Foundation/Core gaps, or blocking conflicts

### Blocking Issues (FAIL only)

### Required ADRs (prioritised, Foundation first)
```

---

## Phase 8: Write and Update

Ask via AskUserQuestion: "Review complete. What would you like to write?"
- [A] Write all three files (review report + traceability index + TR registry)
- [B] Write review report only at `docs/architecture/architecture-review-[date].md`
- [C] Don't write — review findings first

### RTM Output (rtm mode only)

Additionally ask: "May I write full RTM to `docs/architecture/requirements-traceability.md`?"

### TR Registry Update

Ask: "May I update `docs/architecture/tr-registry.yaml` with new requirement IDs?"

If yes:
- **Append** new TR-IDs not in registry
- **Update** `requirement` text + `revised` date for entries whose GDD wording changed (ID stays same)
- **Mark** `status: deprecated` for entries whose GDD requirement no longer exists (confirm before)
- **Never** renumber or delete
- Update `last_updated` and `version` at top

### Reflexion Log Update

Append any 🔴 CONFLICT entries from Phase 4 to `docs/consistency-failures.md` (if file exists, append only):

```markdown
### [YYYY-MM-DD] — /architecture-review — 🔴 CONFLICT
**Domain**: Architecture / [domain]
**Documents involved**: [ADR-NNNN] vs [ADR-MMMM]
**What happened**: [conflict]
**Resolution**: [how resolved]
**Pattern**: [generalised lesson]
```

Only append CONFLICT entries (not GAP). Don't create file if missing.

### Session State Update

After writing approved files, silently append to `production/session-state/active.md`:

```
## Session Extract — /architecture-review [date]
- Verdict: [PASS / CONCERNS / FAIL]
- Requirements: [N] total — [X] covered, [Y] partial, [Z] gaps
- New TR-IDs registered: [N, or "None"]
- GDD revision flags: [comma-separated GDD names, or "None"]
- Top ADR gaps: [top 3 gap titles, or "None"]
- Report: docs/architecture/architecture-review-[date].md
```

Update registry at `data/_schemas/system_registry.json`:
- For each new ADR referenced, ensure `documentation_stack.adr_index.adrs[]` has the entry

---

## Phase 9: Handoff

1. **Immediate actions**: Top 3 ADRs to create (highest-impact gaps first, Foundation before Feature)
2. **Gate guidance**: "Run `/gate-check pre-production` when blocking issues resolved"
3. **Rerun trigger**: "Re-run `/architecture-review` after each new ADR"

Close with AskUserQuestion: "Architecture review complete. What would you like to do next?"
- [A] Write a missing ADR — open fresh session, run `/architecture-decision [system]`
- [B] Run `/gate-check pre-production` — if all blocking gaps resolved
- [C] Stop here for this session

---

## Error Recovery Protocol

If any spawned agent returns BLOCKED, errors, or fails:
1. **Surface immediately**: Report "[AgentName]: BLOCKED — [reason]"
2. **Assess dependencies**: If output required by later phase, don't proceed without user input
3. **Offer options** via AskUserQuestion: skip / retry narrower scope / stop
4. **Always produce partial report** — output whatever completed

---

## Collaborative Protocol

1. **Read silently** — don't narrate every file read
2. **Show the matrix** — present full traceability matrix before asking
3. **Don't guess** — if requirement is ambiguous, ask
4. **Ask before writing** — always confirm
5. **Non-blocking** — verdict is advisory; user decides whether to continue despite CONCERNS or FAIL

---

## Project Path Reference (why this override exists)

| What | Donchitos vanilla path | Project path |
|------|------------------------|----------|
| ADRs | `docs/architecture/adr-*.md` | `docs/adr/*.md` |
| Master GDD | `design/gdd/<system>.md` only | `{{GDD_PATH}}` + `design/gdd/<system>.md` |
| Systems registry | `design/gdd/systems-index.md` only | `data/_schemas/system_registry.json` (source) + `design/gdd/systems-index.md` (generated view) |
| Engine reference | `docs/engine-reference/[engine]/` | `docs/engine-reference/<engine>/VERSION.md` |
