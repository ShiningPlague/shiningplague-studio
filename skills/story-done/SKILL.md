---
name: story-done
description: "Close an implemented story. Verifies every acceptance criterion against real evidence, checks the required test or evidence doc exists, records any GDD/ADR deviation, flips the story to Status: Complete, and syncs the registry and implementation status. Runs after /dev-story and /code-review. Never mark a story complete by hand — run this."
metadata:
  origin: ShiningPlague
  enhancements:
    - Evidence gate by story type (test file for Logic/Integration, evidence doc for Visual-Feel/UI)
    - Deviation capture — GDD and ADR drift recorded at close, not discovered later
    - Registry + implementation-status sync, so "is it built?" stays answerable
    - LP-CODE-REVIEW handshake — refuses a silent close on unreviewed code
---

# Story Done

The close gate. A story is complete when its acceptance criteria are verified
against evidence that exists — not when the code was written.

> 🌱 **ShiningPlague Studio skill.** The pipeline step `/create-stories` →
> `/story-readiness` → `/dev-story` → `/code-review` → **`/story-done`**.

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## Usage

```
/story-done [story-path]
```

## Inputs

| Input | Path |
|---|---|
| Story file | `production/epics/<epic-slug>/<story>.md` |
| Test file | the path named in the story's **Test Evidence** section |
| Evidence doc | `production/qa/evidence/<slug>-evidence.md` (template: `.claude/docs/templates/test-evidence.md`) |
| Governing ADR | `docs/adr/NNN-<slug>.md` |
| System GDD | `docs/gdd/[system].md` or the master `docs/GDD.md` |
| Registry | `data/_schemas/system_registry.json` |
| Status doc | `docs/implementation-status.md` |

## Procedure

### 1. Walk the acceptance criteria

Take the criteria one at a time. For each, state the evidence and the verdict:

```
AC1: [criterion verbatim]
  Evidence: [test name that passes / file:line / screenshot path / manual step run]
  Verdict: MET | NOT MET | UNVERIFIABLE
```

`UNVERIFIABLE` is an honest answer — use it rather than guessing. A criterion
with no evidence is not met.

### 2. Evidence gate by story type

| Story Type | Required before close | If missing |
|---|---|---|
| Logic | the named test file exists **and** passes | **BLOCKING** — do not close |
| Integration | the named test file, or a documented playtest | **BLOCKING** — do not close |
| Visual/Feel | evidence doc in `production/qa/evidence/` + sign-off | ADVISORY — close is allowed, record the debt |
| UI | evidence doc or manual walkthrough record | ADVISORY — close is allowed, record the debt |
| Config/Data | a smoke pass over the changed data | ADVISORY |

Run the project's verification command for the test — see
`/verification-before-completion` for the per-change-kind commands. Paste the
real output into the report. A test that was never run is not evidence.

### 3. Confirm the code was reviewed

Check whether `/code-review` has run over the changed files (its report, or the
LP-CODE-REVIEW verdict in the session state).

- Reviewed and APPROVE → continue.
- CONCERNS → continue, and carry the concerns into the report.
- Not reviewed → offer to run `/code-review [files]` now. If the user declines,
  close anyway and record "closed without code review" in the deviations.

### 4. Capture deviations

Compare what was built against what was specified:

- **GDD deviation** — behaviour differs from the system GDD. Record it and ask
  whether the GDD should be updated (a shipped behaviour that contradicts its
  GDD is the drift `/consistency-check` will find later).
- **ADR deviation** — the implementation departs from the governing ADR's
  Implementation Guidelines. Record it. A repeated deviation is a signal the ADR
  needs revisiting via `/architecture-decision`.
- **Scope deviation** — files touched outside the story's **Out of Scope**
  contract. Record it; consider `/scope-check`.

Deviations do not block a close. Silence about them does the damage.

### 5. Close the story

Only after steps 1–4, and only with the user's go-ahead:

- Set the story's `Status:` field to `Complete` and stamp the date.
- Append the evidence paths to the story's **Test Evidence** section.
- Append any deviation notes to the story under `## Deviations at close`.

Ask before writing: *"May I mark [story] Complete and write the close notes?"*

### 6. Sync the state files

- `data/_schemas/system_registry.json` — move the system's `status` forward if
  this story changed it (`planned` → `wip` → `partial` → `active`). The registry
  is the authoritative "is it built?" source; a close that leaves it stale is a
  close that lied.
- `docs/implementation-status.md` — update the system's row.
- `production/session-state/active.md` — append a one-line close extract.

### 7. Report

```
## Story Done: [story title]

**Verdict:** CLOSED | BLOCKED

| Acceptance criterion | Evidence | Verdict |
|---|---|---|
| ... | ... | MET |

**Evidence gate:** [pass / BLOCKING — test file missing at <path>]
**Code review:** [APPROVE / CONCERNS: ... / not run — closed anyway at user's direction]
**Deviations:** [none / GDD: ... / ADR: ... / scope: ...]
**State synced:** [registry row, implementation-status row, session state]

Next: [next story path, or `/sprint-plan status` if this was the last one]
```

## What blocks a close

Exactly two things:

1. A Logic or Integration story with no passing test.
2. An acceptance criterion marked NOT MET.

Everything else is recorded and carried, not blocked. If the user wants to close
over a blocker, say plainly what is being accepted and let them decide —
then record it as a deviation.

## Recommended next steps

- More stories in the sprint → `/story-readiness [next-story]`
- Last story in the sprint → `/qa-plan [sprint]` then `/retrospective`
- Five or more commits since the last sync → `/update`
