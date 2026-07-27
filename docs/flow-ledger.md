# Flow Ledger — mechanical workflow-state detection

The flow-ledger system answers one question at every session start, **without an LLM**:
*"Given everything on disk, what is the honest next step in the pipeline?"*

It replaces "ask Claude to guess where we are" (which drifts, forgets, and flatters)
with a small deterministic checker that reads a human-authored ledger, cross-checks
every claim against files that actually exist, and derives the recommended next step.

## The three pieces

| Piece | Path | Role |
|---|---|---|
| **Catalog** | `.claude/docs/workflow-catalog.yaml` | The *ideal* pipeline — every phase, its steps, `required` flags, and the artifact glob that proves a step is done. Ships with the framework; the same for every project. |
| **Ledger** | `production/flow-ledger.yaml` | The *actual* state of THIS repo — per step: `done` / `in-progress` / `skipped` / `leapfrogged` / `not-started` / `n-a`, plus evidence paths and (for skips) a reason. Human-authored, project-specific. |
| **Checker** | `tools/workflow_state_check.py` | Reads both, cross-checks ledger claims against evidence on disk, and prints posture + a per-step verdict table + rule-pending blockers + the recommended next step. Pure stdlib (PyYAML if present, a built-in mini-parser if not). No network, no LLM. |

The catalog says *what the ideal is*. The ledger says *what really happened* — including
the deliberate leapfrogs and skips a real project always accumulates. The checker keeps
the ledger honest by refusing to believe a `done` it can't find evidence for.

## What the checker detects (per-step verdicts)

| Verdict | Meaning | Gates? |
|---|---|---|
| `OK` | Ledger status matches evidence on disk | no |
| `CONFLICT` | Ledger says `done` but the evidence paths are missing/empty | **yes — exit 1** |
| `ILLEGITIMATE` | Status is `skipped`/`leapfrogged` with no `reason` | **yes — exit 1** |
| `UNRECORDED` | Evidence exists on disk but the ledger never logged it | no (warning) |
| `-` / `n-a` | No ledger entry and no evidence, or explicitly not-applicable | no |

`CONFLICT` and `ILLEGITIMATE` set exit code **1**, so a hook or CI job can gate on them.
`UNRECORDED` is a nudge to log your work, not a broken state.

## Rule-pending blockers (designer decisions)

Some work is blocked not by a missing artifact but by a **decision the designer hasn't
made yet** (e.g. "lock the art style before any asset work"). Those live in the ledger's
`rule_pending` list, each naming the steps it `blocks`. The checker prints every open
blocker **before** the recommended next step and skips blocked steps when choosing what
to recommend — so the recommendation always lands on the first *unblocked* work. Resolve
a blocker by moving it to `rule_resolved` with a resolution note and date.

## Recommended-next derivation

The checker walks the catalog in phase order and returns the first step that is:

1. not already `done` / `leapfrogged` / `skipped` / `n-a`,
2. not gated by an open `rule_pending` blocker,
3. `required` (optional steps are enhancements, never forward gates), and
4. has its `depends_on` steps satisfied.

If nothing qualifies, it falls back to any in-progress step, then reports "catalog
complete — drive from sprints." Custom (`custom: true`) ledger steps are anchors for
the record, never gates.

## Bootstrap story (a fresh repo)

You do **not** hand-write the ledger from scratch. On a repo with no
`production/flow-ledger.yaml`, run the checker once:

```bash
python tools/workflow_state_check.py
```

It enters **BOOTSTRAP MODE**: it infers a draft from artifact existence alone (marking a
step `done` where its catalog glob matched a non-empty file, else `not-started`), writes
`production/flow-ledger.draft.yaml`, and tells you to review it. The tool cannot know your
leapfrogs, skips, or custom steps — so you:

1. Open the draft.
2. Correct every status + add a real `reason` for each skip/leapfrog + add any custom steps.
3. Rename it to `production/flow-ledger.yaml`.
4. Re-run the checker to get the real state report.

Prefer to start from a worked example instead of the auto-draft? Copy
[`.claude/docs/templates/flow-ledger.TEMPLATE.yaml`](templates/flow-ledger.TEMPLATE.yaml) — it carries
the full schema header plus a done-with-evidence, a leapfrogged-with-reason, and a custom
example step to edit down.

## How it powers the session hook

`.claude/hooks/session-start.sh` calls `tools/workflow_state_check.py --brief` and prints the result
under **CANONICAL-RECOMMENDED NEXT ACTION**. That gives every session a mechanical,
drift-proof answer to "what's next" — posture, any rule-pending blockers, the recommended
next step, and a conflict count — before any agent reasoning happens. If Python or the tool
is unavailable, the hook falls back to a static pointer at the ledger and catalog, so a
session is never left blind. Change what the session recommends by editing the **ledger**,
not the hook.

## Usage

```bash
python tools/workflow_state_check.py            # full report (posture + table + next step)
python tools/workflow_state_check.py --brief    # compact (what the session-start hook uses)
python tools/workflow_state_check.py --json      # machine-readable
```

Exit code is `0` when clean, `1` when any `CONFLICT` or `ILLEGITIMATE` verdict is present —
so you can wire it into a pre-commit or CI gate if you want the ledger kept honest automatically.
