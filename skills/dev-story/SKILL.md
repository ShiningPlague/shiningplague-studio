---
name: dev-story
description: "Read a story file and implement it. Loads the full context (story, GDD requirement, ADR guidelines, control manifest), routes to the right programmer agent for the system and engine, implements the code and test, and confirms each acceptance criterion. The core implementation skill — run after /story-readiness, before /code-review and /story-done. ShiningPlague-adopted (Sons of Gilgamesh): SoG paths (docs/adr/, docs/gdd/), Godot 4.6.1 default routing to godot-gdscript-specialist, control manifest at docs/architecture/control-manifest.md."
argument-hint: "[story-path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Task, AskUserQuestion
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/dev-story/SKILL.md
  enhancements:
    - SoG GDD path (docs/gdd/[system].md or docs/GDD v.2.3.md)
    - SoG ADR path (docs/adr/NNN-*.md)
    - Godot 4.6.1 engine + godot-gdscript-specialist as default routing
    - Coding standards at .claude/docs/godot-gotchas.md
    - Architecture principles cross-link to CLAUDE.md
---

# Dev Story

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos. Sons of Gilgamesh project adopted and enhanced. Upstream procedure preserved + SoG path corrections + Godot routing defaults. Vanilla backup: `docs/vanilla-backups/2026-05-15/dev-story/`.

This skill bridges planning and code. It reads a story file in full, assembles all the context a programmer needs, routes to the correct specialist agent, and drives implementation to completion — including writing the test.

**The loop for every story:**
```
/qa-plan sprint           ← define test requirements before sprint begins
/story-readiness [path]   ← validate before starting
/dev-story [path]         ← implement it  (this skill)
/code-review [files]      ← review it
/story-done [path]        ← verify and close it
```

**After all sprint stories are done:** run `/team-qa sprint` to execute the full QA cycle.

**Output:** Source code + test file in the project's `src/` and `tests/` directories.

## SoG Path Reference

| Donchitos vanilla path | SoG path |
|---|---|
| `design/gdd/[filename].md` | `docs/gdd/[system].md` or `docs/GDD v.2.3.md` |
| ADRs | `docs/adr/NNN-*.md` |
| Control manifest | `docs/architecture/control-manifest.md` |
| Stories | `production/epics/<epic-slug>/story-*.md` |
| Test evidence | `tests/` or `tools/` (headless harnesses) |

## SoG Context

- Engine: Godot 4.6.1, GDScript — routes to `godot-gdscript-specialist` by default
- Technical preferences at `.claude/docs/technical-preferences.md`
- Coding standards/gotchas at `.claude/docs/godot-gotchas.md`
- Architecture principles in CLAUDE.md § Architecture principles

---

## Phase 1: Find the Story

**If a path is provided**: read that file directly.

**If no argument**: check `production/session-state/active.md` for the active story. If found, confirm: "Continuing work on [story title] — is that correct?" If not found, ask: "Which story are we implementing?" Glob `production/epics/**/*.md` and list stories with Status: Ready.

---

## Phase 2: Load Full Context

**Before loading any context, verify required files exist.** Extract ADR path from story's `ADR Governing Implementation` field, then check:

| File | Path | If missing |
|------|------|------------|
| TR registry | `docs/architecture/tr-registry.yaml` | **STOP** — "TR registry not found. Run `/create-epics` to generate it." |
| Governing ADR | path from story's ADR field | **STOP** — "ADR file [path] not found. Run `/architecture-decision` to create it, or correct the filename in the story's ADR field." |
| Control manifest | `docs/architecture/control-manifest.md` | **WARN and continue** — "Control manifest not found — layer rules cannot be checked. Run `/create-control-manifest`." |

If TR registry or governing ADR is missing, set story status to **BLOCKED** in session state and do not spawn any programmer agent.

Read all of the following simultaneously:

### The story file

Extract and hold:
- **Story title, ID, layer, type** (Logic / Integration / Visual/Feel / UI / Config/Data)
- **TR-ID** — the GDD requirement identifier
- **Governing ADR** reference
- **Manifest Version** embedded in story header
- **Acceptance Criteria** — every checkbox item, verbatim
- **Implementation Notes** — the ADR guidance section
- **Out of Scope** boundaries
- **Test Evidence** — required test file path
- **Dependencies** — what must be DONE before this story

### The TR registry

Read `docs/architecture/tr-registry.yaml`. Look up story's TR-ID. Read current `requirement` text — source of truth.

### The governing ADR

Read `docs/adr/[adr-file].md`. Extract:
- Full Decision section
- Implementation Guidelines section
- Engine Compatibility section (post-cutoff APIs, known risks)
- ADR Dependencies section

### The control manifest

Read `docs/architecture/control-manifest.md`. Extract rules for this layer:
- Required patterns
- Forbidden patterns
- Performance guardrails

Check: does story's embedded Manifest Version match current manifest header date?

If they differ, use `AskUserQuestion`:
- Prompt: "Story written against manifest v[story-date]. Current manifest is v[current-date]. New rules may apply. Proceed?"
- Options:
  - `[A] Update story manifest version and implement with current rules (Recommended)`
  - `[B] Implement with old rules — accept risk of non-compliance`
  - `[C] Stop — review the manifest diff first`

### Dependency validation

After extracting Dependencies, validate each:
1. Glob `production/epics/**/*.md` to find each dependency story file
2. Read its `Status:` field
3. If any dependency Status not `Complete`/`Done`:
   - Use `AskUserQuestion`: "Story depends on [dependency] which is [status], not Complete. How proceed?"
   - Options: `[A] Proceed anyway` / `[B] Stop — complete dependency first` / `[C] Mark dependency Complete and continue`

### Engine reference

Read `.claude/docs/technical-preferences.md`:
- `Engine:` — Godot 4.6.1
- Naming conventions
- Performance budgets
- Forbidden patterns

---

## Phase 3: Route to the Right Programmer

Based on story's **Layer**, **Type**, and **system name**:

**Config/Data stories — skip agent spawning entirely.** Jump directly to Phase 4. The implementation is a data file edit.

### Primary agent routing table

| Story context | Primary agent |
|---|---|
| Foundation layer — any type | `engine-programmer` |
| Any layer — Type: UI | `ui-programmer` |
| Any layer — Type: Visual/Feel | `gameplay-programmer` |
| Core or Feature — gameplay mechanics | `gameplay-programmer` |
| Core or Feature — AI behaviour, pathfinding | `ai-programmer` |
| Core or Feature — networking, replication | `network-programmer` |
| Config/Data — no code | No agent needed |

### Engine specialist — always spawn as secondary for code stories

For SoG (Godot 4.6.1), default secondary = `godot-gdscript-specialist`.

| Engine | Specialist agents |
|--------|-------------------|
| Godot 4 | `godot-specialist`, `godot-gdscript-specialist`, `godot-shader-specialist` |

**When engine risk is HIGH** (from ADR or VERSION.md): always spawn engine specialist, even for non-engine-facing stories.

---

## Phase 4: Implement

Spawn chosen programmer agent(s) via Task with full context package:

1. The complete story file content
2. The current GDD requirement text (from TR registry)
3. The ADR Decision + Implementation Guidelines (verbatim — don't summarise)
4. The control manifest rules for this layer
5. The engine naming conventions and performance budgets
6. Any engine-specific notes from ADR Engine Compatibility
7. The test file path that must be created
8. Explicit instruction: **implement this story and write the test**

Agent should:
- Create or modify files in `src/` following ADR guidelines
- Respect all Required and Forbidden patterns from control manifest
- Stay within story's Out of Scope boundaries
- Write clean, doc-commented public APIs

### Config/Data stories (no agent needed)

For Type: Config/Data, implementation is editing a data file. Read story's acceptance criteria and make specified changes directly. Note values changed.

### Visual/Feel stories

Spawn `gameplay-programmer` to implement code/animation calls. Visual/Feel acceptance criteria cannot be auto-verified — "does it feel right?" check happens in `/story-done` via manual confirmation.

---

## Phase 5: Write the Test

For **Logic** and **Integration** stories, test must be written as part of this implementation — not deferred.

Remind the programmer agent:
> "Test file for this story is required at: `[path from Test Evidence section]`. Story cannot be closed via `/story-done` without it. Write the test alongside implementation."

Test requirements (from coding-standards.md):
- File name: `[system]_[feature]_test.gd`
- Function names: `test_[scenario]_[expected_outcome]`
- Each acceptance criterion must have at least one test function
- No random seeds, no time-dependent assertions, no external I/O
- Test the formula bounds from GDD Formulas section

For **Visual/Feel** and **UI** stories: no automated test. Remind agent to note: "Evidence doc required at `production/qa/evidence/[slug]-evidence.md`."

For **Config/Data** stories: no test file. A smoke check serves as evidence.

---

## Phase 6: Collect and Summarise

After programmer agent(s) complete, collect:
- Files created/modified (with paths)
- Test file created (path + number of test functions)
- Any deviations from story's Out of Scope boundary
- Any questions or blockers
- Any engine-specific risks the specialist flagged

Present concise summary:

```
## Implementation Complete: [Story Title]

**Files changed**:
- `src/[path]` — created / modified ([brief description])
- `tests/[path]` — test file ([N] test functions)

**Acceptance criteria covered**:
- [x] [criterion] — implemented in [file:function]
- [x] [criterion] — covered by test [test_name]
- [ ] [criterion] — DEFERRED: requires playtest (Visual/Feel)

**Deviations from scope**: [None] or [list files touched outside boundary]
**Engine risks flagged**: [None] or [specialist finding]
**Blockers**: [None] or [describe]

Ready for: `/code-review [file1] [file2]` then `/story-done [story-path]`
```

---

## Phase 7: Update Session State

Silently append to `production/session-state/active.md`:

```
## Session Extract — /dev-story [date]
- Story: [story-path] — [story title]
- Files changed: [comma-separated list]
- Test written: [path, or "None — Visual/Feel/Config story"]
- Blockers: [None, or description]
- Next: /code-review [files] then /story-done [story-path]
```

---

## Error Recovery Protocol

If any spawned agent returns BLOCKED, errors, or cannot complete:

1. **Surface immediately**: "[AgentName]: BLOCKED — [reason]"
2. **Assess dependencies**: If output required by subsequent phases, don't proceed
3. **Offer options** via AskUserQuestion: skip / retry narrower scope / stop and resolve
4. **Always produce partial report** — never discard work

Common blockers:
- Input file missing → redirect to skill that creates it
- ADR status is Proposed → run `/architecture-decision` first
- Scope too large → split via `/create-stories`
- Conflicting ADR/story instructions → surface, don't guess
- Manifest version mismatch → show diff, ask

## Collaborative Protocol

- **File writes are delegated** — all source code, test files, evidence docs written by sub-agents spawned via Task. Each sub-agent enforces "May I write to [path]?" individually.
- **Load before implementing** — don't start coding until all context loaded
- **The ADR is the law** — implementation must follow ADR Implementation Guidelines. If guidelines conflict with what seems "better," flag in summary
- **Stay in scope** — Out of Scope is a contract. If implementing requires touching out-of-scope file, stop and surface
- **Test is not optional for Logic/Integration** — don't mark complete without test file
- **Visual/Feel criteria are deferred, not skipped**
- **Ask before large structural decisions** — if story requires pattern not covered by ADR, surface

---

## Recommended Next Steps

- Run `/code-review [file1] [file2]` to review before closing
- Run `/story-done [story-path]` to verify acceptance criteria and mark complete
- After all sprint stories done: run `/team-qa sprint` for full QA cycle
