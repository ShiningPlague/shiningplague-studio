---
name: create-stories
description: "Break a single epic into implementable story files. Reads the epic, its GDD, governing ADRs, and control manifest. Each story embeds its GDD requirement TR-ID, ADR guidance, acceptance criteria, story type, and test evidence path. Run after /create-epics for each epic. ShiningPlague-adopted: project paths (docs/gdd/ + docs/adr/), stories live at production/epics/<slug>/, qa-lead embeds test cases."
argument-hint: "[epic-slug | epic-path] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
agent: lead-programmer
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Project GDD path (docs/gdd/[system].md + {{GDD_PATH}})
    - Project ADR path (docs/adr/NNN-*.md)
    - Control manifest at docs/architecture/control-manifest.md
    - qa-lead embeds test case specs into story `## QA Test Cases` section
---

# Create Stories

> 🌱 **ShiningPlague-adopted.** Originally Donchitos; battle-tested on a shipped Godot project. Upstream procedure preserved + project path corrections.

A story is a single implementable behaviour — small enough to complete in one focused session, self-contained, and fully traceable to a GDD requirement and an ADR decision. Stories are what developers pick up. Epics are what architects define.

**Run this skill per epic**, not per layer. Run for Foundation epics first, then Core, matching dependency order.

**Output:** `production/epics/[epic-slug]/story-NNN-[slug].md` files

**Previous step:** `/create-epics [system]`
**Next step:** `/story-readiness [story-path]` then `/dev-story [story-path]`

## Project Paths

| What | Canonical path |
|---|---|
| System GDD | `docs/gdd/[system].md` or `{{GDD_PATH}}` |
| ADRs | `docs/adr/NNN-*.md` |
| Control manifest | `docs/architecture/control-manifest.md` |
| Story output | `production/epics/[epic-slug]/` |

Note: if no stories exist yet, that's normal — the small path (spec → ADR → plan → execute) covers small work; stories activate when the large path is needed.

---

## 1. Parse Argument

Extract `--review [full|lean|solo]` if present. If not, read `production/review-mode.txt` (default `full` if missing). Apply check pattern from `.claude/docs/director-gates.md` before every gate invocation.

- `/create-stories [epic-slug]` — e.g. `/create-stories combat`
- `/create-stories production/epics/combat/EPIC.md` — full path accepted
- No argument — ask, Glob `production/epics/*/EPIC.md`, list available epics

---

## 2. Load Everything for This Epic

Read in full:

- `production/epics/[epic-slug]/EPIC.md` — overview, governing ADRs, GDD requirements
- The epic's GDD (`docs/gdd/[system].md` or `{{GDD_PATH}}` section)
- All governing ADRs from `docs/adr/` — Decision, Implementation Guidelines, Engine Compatibility, Engine Notes
- `docs/architecture/control-manifest.md` — rules for this epic's layer; note Manifest Version date
- `docs/architecture/tr-registry.yaml` — TR-IDs for this system

**ADR existence validation**: After reading governing ADRs list, confirm each file exists on disk. If any missing:

> "Epic references [ADR-NNNN: title] but `docs/adr/[adr-file].md` not found.
> Check filename in epic's Governing ADRs list, or run `/architecture-decision`.
> Cannot create stories until all referenced ADR files present."

Don't proceed to Step 3 until all ADR files confirmed.

Report: "Loaded epic [name], GDD [filename], [N] governing ADRs (all confirmed present), control manifest v[date]."

---

## 3. Classify Stories by Type

| Story Type | Assign when criteria reference... |
|---|---|
| **Logic** | Formulas, numerical thresholds, state transitions, AI decisions, calculations |
| **Integration** | Two or more systems interacting, signals crossing boundaries, save/load round-trips |
| **Visual/Feel** | Animation behaviour, VFX, "feels responsive", timing, screen shake, audio sync |
| **UI** | Menus, HUD elements, buttons, screens, dialogue boxes, tooltips |
| **Config/Data** | Balance tuning values, data file changes only — no new code logic |

Mixed stories: assign type with highest implementation risk. Type determines what test evidence is required before `/story-done`.

---

## 4. Decompose the GDD into Stories

For each GDD acceptance criterion:
1. Group related criteria requiring same core implementation
2. Each group = one story
3. Order: foundational behaviour first, edge cases last, UI last

**Story sizing**: one story = ~2-4 hours. Split if longer.

For each story, determine:
- **GDD requirement**: which acceptance criteria
- **TR-ID**: from `tr-registry.yaml`. Use stable ID. If no match, use `TR-[system]-???` and warn.
- **Governing ADR**:
  - `Status: Accepted` → embed normally
  - `Status: Proposed` → `Status: Blocked` with note: "BLOCKED: ADR-NNNN is Proposed — run `/architecture-decision`"
- **Story Type**: from Step 3
- **Engine risk**: from ADR's Knowledge Risk field

---

## 4b. QA Lead Story Readiness Gate

**Review mode check** before QL-STORY-READY:
- `solo` → skip. "QL-STORY-READY skipped — Solo mode." Proceed to Step 5.
- `lean` → skip. "QL-STORY-READY skipped — Lean mode." Proceed to Step 5.
- `full` → spawn as normal.

After decomposing all stories but before presenting for write approval, spawn `qa-lead` via Task using gate **QL-STORY-READY**.

Pass: full story list with acceptance criteria, story types, TR-IDs; epic's GDD acceptance criteria.

Present qa-lead's assessment. For each story flagged GAPS or INADEQUATE, revise acceptance criteria. Once all stories ADEQUATE, proceed.

**After ADEQUATE**: for every Logic and Integration story, ask qa-lead to produce concrete test case specs:

```
Test: [criterion text]
  Given: [precondition]
  When: [action]
  Then: [expected result / assertion]
  Edge cases: [boundary values or failure states]
```

For Visual/Feel and UI stories, manual verification steps:
```
Manual check: [criterion text]
  Setup: [how to reach the state]
  Verify: [what to look for]
  Pass condition: [unambiguous pass description]
```

These embed directly into each story's `## QA Test Cases` section. Developer implements against these — programmer doesn't write tests from scratch.

---

## 5. Present Stories for Review

Present full story list before writing:

```
## Stories for Epic: [name]

Story 001: [title] — Logic — ADR-NNNN
  Covers: TR-[system]-001 ([1-line summary])
  Test required: tests/unit/[system]/[slug]_test.gd

Story 002: [title] — Integration — ADR-MMMM
  Covers: TR-[system]-002, TR-[system]-003
  Test required: tests/integration/[system]/[slug]_test.gd

Story 003: [title] — Visual/Feel — ADR-NNNN
  Covers: TR-[system]-004
  Evidence required: production/qa/evidence/[slug]-evidence.md

[N stories total: N Logic, N Integration, N Visual/Feel, N UI, N Config/Data]
```

Use `AskUserQuestion`:
- Prompt: "May I write these [N] stories to `production/epics/[epic-slug]/`?"
- Options: `[A] Yes — write all [N] stories` / `[B] Not yet — review or adjust first`

---

## 6. Write Story Files

For each story, write `production/epics/[epic-slug]/story-[NNN]-[slug].md`:

```markdown
# Story [NNN]: [title]

> **Epic**: [epic name]
> **Status**: Ready
> **Layer**: [Foundation / Core / Feature / Presentation]
> **Type**: [Logic | Integration | Visual/Feel | UI | Config/Data]
> **Manifest Version**: [date from control-manifest.md header]

## Context

**GDD**: `docs/gdd/[system].md` (or `{{GDD_PATH}}` §[section])
**Requirement**: `TR-[system]-NNN`
*(Requirement text in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: [ADR-NNNN: title]
**ADR Decision Summary**: [1-2 sentence summary]

**Engine**: Godot 4.6.1 | **Risk**: [LOW / MEDIUM / HIGH]
**Engine Notes**: [from ADR Engine Compatibility — post-cutoff APIs, verification required]

**Control Manifest Rules (this layer)**:
- Required: [relevant required pattern]
- Forbidden: [relevant forbidden pattern]
- Guardrail: [relevant performance guardrail]

---

## Acceptance Criteria

*From GDD, scoped to this story:*

- [ ] [criterion 1 — directly from GDD]
- [ ] [criterion 2]
- [ ] [performance criterion if applicable]

---

## Implementation Notes

*Derived from ADR-NNNN Implementation Guidelines:*

[Specific, actionable guidance. Don't paraphrase in ways that change meaning. This is what the programmer reads instead of the ADR.]

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story NNN+1]: [what it handles]

---

## QA Test Cases

*Written by qa-lead at story creation. Developer implements against these — don't invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: [criterion text]
  - Given: [precondition]
  - When: [action]
  - Then: [assertion]
  - Edge cases: [boundary values / failure states]

**[For Visual/Feel / UI stories — manual verification]:**

- **AC-1**: [criterion text]
  - Setup: [how to reach the state]
  - Verify: [what to look for]
  - Pass condition: [unambiguous pass description]

---

## Test Evidence

**Story Type**: [type]
**Required evidence**:
- Logic: `tests/unit/[system]/[story-slug]_test.gd` — must exist and pass
- Integration: `tests/integration/[system]/[story-slug]_test.gd` OR playtest doc
- Visual/Feel: `production/qa/evidence/[story-slug]-evidence.md` + sign-off
- UI: `production/qa/evidence/[story-slug]-evidence.md` or interaction test
- Config/Data: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: [Story NNN-1 must be DONE, or "None"]
- Unlocks: [Story NNN+1, or "None"]
```

### Update `production/epics/[epic-slug]/EPIC.md`

Replace "Stories: Not yet created" with populated table:

```markdown
## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [title] | Logic | Ready | ADR-NNNN |
| 002 | [title] | Integration | Ready | ADR-MMMM |
```

---

## 7. After Writing

Use `AskUserQuestion` to close:

Check:
- Are there other epics in `production/epics/` without stories yet?
- Is this the last epic? Include `/sprint-plan` as option if so.

Widget:
- Prompt: "[N] stories written to `production/epics/[epic-slug]/`. What next?"
- Options:
  - `[A] Start implementing — run /story-readiness [first-story-path]` (Recommended)
  - `[B] Create stories for [next-epic-slug] — run /create-stories [slug]` (only if other epics need stories)
  - `[C] Plan the sprint — run /sprint-plan` (only if all epics have stories)
  - `[D] Stop here for this session`

Note: "Work through stories in order — each story's `Depends on:` field tells you what must be DONE before you can start it."

---

## Collaborative Protocol

1. **Read before presenting** — load all inputs silently before showing story list
2. **Ask once** — present all stories for the epic in one summary, not one at a time
3. **Warn on blocked stories** — flag any story with Proposed ADR before writing
4. **Ask before writing** — get approval for full story set before writing files
5. **No invention** — acceptance criteria from GDDs, implementation notes from ADRs, rules from manifest
6. **Never start implementation** — this skill stops at the story file level

After writing:

- **Verdict: COMPLETE** — [N] stories written. Run `/story-readiness` → `/dev-story` to begin.
- **Verdict: BLOCKED** — user declined. No story files written.
