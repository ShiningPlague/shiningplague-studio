---
name: story-readiness
description: "Validate that a story file is implementation-ready before a developer picks it up. Checks the story's required sections, that its governing ADR is Accepted, that its embedded control-manifest version is current, and that every acceptance criterion is testable. Runs between /create-stories and /dev-story, and during /sprint-plan story selection. Returns READY / READY WITH GAPS / NOT READY."
metadata:
  origin: ShiningPlague
  enhancements:
    - QL-STORY-READY director gate dispatch (qa-lead)
    - ADR Status check — the gate /adopt calls BLOCKING when an ADR has no `## Status`
    - Control-manifest version drift detection (story's embedded version vs. current)
    - Testability pass over every acceptance criterion, by story type
---

# Story Readiness

The gate between *a story exists* and *a developer starts work*. It is cheap to
run and it is the only thing standing between a vague acceptance criterion and a
week of rework.

> 🌱 **ShiningPlague Studio skill.** The pipeline step `/create-stories` →
> **`/story-readiness`** → `/dev-story` → `/code-review` → `/story-done`.

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## Usage

```
/story-readiness [story-path]     validate one story
/story-readiness                  validate every story in the current sprint
```

With no argument, read the newest `production/sprints/sprint-*.md`, take its
story list, and validate each one.

## Inputs

| Input | Path |
|---|---|
| Story file | `production/epics/<epic-slug>/<story>.md` |
| Governing ADR | `docs/adr/NNN-<slug>.md` (named in the story) |
| Control manifest | `docs/architecture/control-manifest.md` |
| System GDD | `docs/gdd/[system].md` or the master `docs/GDD.md` |
| Sprint plan | newest `production/sprints/sprint-*.md` (no-argument mode only) |

## Procedure

### 1. Read the story

Confirm the story carries every section `/create-stories` writes: **Story Type**,
**GDD Reference** (TR-ID), **Governing ADR**, **Acceptance Criteria**,
**Test Evidence**, **Out of Scope**, **Manifest Version**.

A missing section is a finding, not a crash — record it and keep going.

### 2. Check the governing ADR

Read the ADR the story names and find its `## Status` heading.

| ADR state | Verdict |
|---|---|
| `Accepted` | pass |
| `Proposed` / `Draft` | **NOT READY** — run `/architecture-decision` to land it first |
| `Superseded` / `Deprecated` | **NOT READY** — the story is written against retired rules |
| No `## Status` section at all | **NOT READY** — say so explicitly; this check cannot pass silently |
| Story names no ADR | finding only — fine for Config/Data and Visual/Feel stories, a gap for Logic and Integration |

The "no `## Status` section" row exists because a status check that silently
passes everything is worse than no check. `/adopt` classifies that same gap as
BLOCKING for exactly this reason.

### 3. Check control-manifest drift

Compare the story's embedded **Manifest Version** with the `Manifest Version`
field in `docs/architecture/control-manifest.md`.

- Same date → pass.
- Story older → **READY WITH GAPS**: "This story was written against the
  [date] manifest; the current manifest is [date]. Re-read the layer rules
  before implementing, or regenerate the story."
- Manifest absent → one line saying so, skip this check.

### 4. Testability pass over the acceptance criteria

Every criterion must be specific enough that a developer knows unambiguously when
it is done. Judge by story type:

| Story Type | A criterion is ready when… |
|---|---|
| Logic | it can be verified by an automated test — named inputs, named expected output |
| Integration | it is observable in a running build, with the observation stated |
| Visual/Feel | it names what evidence proves it (screenshot, capture) and who signs off |
| UI | it names the screen, the interaction, and the expected end state |
| Config/Data | it names the data file and the value range, not just "tune it" |

Flag any criterion containing an unmeasurable word — *feels good*, *fast*,
*polished*, *intuitive* — unless the story also states how it will be judged.

### 5. Dispatch the QA lead

Spawn `qa-lead` with gate **QL-STORY-READY** from `.claude/docs/director-gates.md`.
Pass: story path, story type, acceptance criteria verbatim, the GDD requirement.
Await the verdict and fold it into the report.

Skip this step in lean or solo review mode (`production/review-mode.txt`) — say
one line that you skipped it and why.

### 6. Report

```
## Story Readiness: [story title]

**Verdict:** READY | READY WITH GAPS | NOT READY

| Check | Result |
|---|---|
| Required sections | [pass / missing: ...] |
| Governing ADR status | [Accepted / ...] |
| Manifest version | [current / stale ([story date] vs [manifest date]) / manifest absent] |
| Acceptance criteria testable | [N/N / N of M — see below] |
| QL-STORY-READY | [verdict / skipped — lean mode] |

**Blockers** (NOT READY only)
- [what must change before implementation starts]

**Gaps** (proceed, but knowingly)
- [what is imperfect and what it will cost]
```

## Verdict meanings

- **READY** — hand it to `/dev-story`.
- **READY WITH GAPS** — implementable, but state the gaps out loud first and let
  the user decide whether to fix the story or accept the risk.
- **NOT READY** — name the one thing that must change. Do not start implementing.

## Recommended next steps

- READY → `/dev-story [story-path]`
- NOT READY on an ADR → `/architecture-decision`
- NOT READY on criteria → `/create-stories [epic-slug]` to rewrite, or edit the
  story in place with the user
