---
name: consistency-check
description: "Scan the project's docs / GDDs / registry against each other to detect cross-document inconsistencies — a doc promising a file that is not there, a registry entry pointing at a deleted path, an ADR referenced but never written, a system the registry calls built that implementation-status has never heard of, a spec marked archived that never moved. Runner-first: `python tools/consistency_check.py` runs 12 mechanical checks (exit 0 on PASS, non-zero on FAIL); the skill adds the judgement calls a script cannot make — same entity with different stats, same formula with different variables, stale wording. ShiningPlague-adopted: adapts to the studio doc stack (system_registry.json + active.md + implementation-status.md + ADRs + specs)."
argument-hint: "[full | since-last-review | entity:<name> | item:<name>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Studio doc stack (system_registry.json + active.md + implementation-status.md + devlog.md + ADRs + specs)
    - Cross-doc value/path/date agreement checks
    - Stale wording sweep with classify ⚠️/ℹ️
    - Registry structural coverage (data dirs / autoloads / addons / tools)
    - Reflexion log to docs/consistency-failures.md (append-only, don't auto-create)
    - Runner: tools/consistency_check.py — 12 checks, exit 0 on PASS, non-zero on FAIL
---

# Consistency Check

> 🌱 **ShiningPlague-adopted.** Originally Donchitos; battle-tested on a shipped
> game project. The upstream skill read a standalone entity registry; this
> version reads the studio doc stack instead ({{REGISTRY}} =
> `data/_schemas/system_registry.json`, {{SESSION_STATE}} =
> `production/session-state/active.md`, `docs/implementation-status.md`,
> `docs/devlog.md`, `docs/adr/`, `docs/specs/`). Spirit preserved (cross-doc
> consistency, grep-first); paths and cross-checks adapted.

**Core principle:** scan the doc stack for claims that disagree — file paths
that don't resolve, ADR numbers nothing carries, statuses two docs state
differently, stale wording that contradicts the current state. The registry is
the built-state source of truth; cross-check everything against it.

**This skill is the write-time safety net.** It catches what `/design-system`'s
per-section checks may have missed and what `/review-all-gdds`'s holistic review
catches too late.

---

## When to fire

- User says "run a consistency check" / "verify the docs" / "audit the doc stack" / "check everything for drift" → PROPOSE first, fire on confirm
- Before opening a fresh chat (end-of-session readiness check)
- After a feature ships end-to-end
- Before `/architecture-review` or `/review-all-gdds`
- After writing each new GDD (before moving to the next system)
- Before `/create-architecture` (inconsistencies poison downstream ADRs)
- On demand for one entity: `/consistency-check entity:<name>`

Fired automatically as a gate by `/session-close`, `/update`, `/red-flag-scan`
and `/verification-before-completion`.

---

## Phase 1: Run the runner

**Always start here.** The runner is mechanical, fast, and does not hallucinate.

```bash
python tools/consistency_check.py
```

| Flag | Effect |
|---|---|
| *(none)* | full report; on a run with no FAILs, bumps `last_full_audit` in the registry to today |
| `--quiet` | findings + verdict only — good for a gate inside another skill |
| `--no-bump` | never writes to the registry (read-only spot check, pre-push hook) |
| `--fix-safe` | creates absent **empty directories** the doc stack promises (with a `.gitkeep`). Never edits prose or data. |
| `--stale-days N` | how many days of commits `active.md` may lag before check 11 warns (default 7) |
| `--root DIR` | check a different project directory |

**Exit codes:** `0` = no FAIL findings (WARNs may be present) · `1` = at least
one FAIL, each named in the report · `2` = not run from a project root.

**Severity contract:** **FAIL** fails the run — something a session would trip
over. **WARN** never fails it — drift worth knowing about. **SKIP** means the
project has not grown that artifact yet; a brand-new install is mostly SKIPs and
exits 0, and that is the correct day-one state.

### The 12 checks

| # | Check | Fails on |
|---|---|---|
| 1 | registry parses and carries the keys the skills read | unparseable JSON, a key holding the wrong type |
| 2 | registry entry shape | missing `id`/`name`/`status`, a status outside the vocabulary, a duplicate id, an entry that says nothing about where it lives |
| 3 | registry references resolve | a `files[]`/`path`/`dir`/`gdd` that is not on disk, a `depends_on` id nothing defines |
| 4 | registry coverage | *(WARN only)* a populated `data/<dir>/`, an autoload, an addon or a project tool with no registry entry |
| 5 | doc stack | a path `CLAUDE.md`'s reading map promises that does not exist |
| 6 | doc ledger | an `active_docs` / `spec_index` / `adr_index` path the registry claims and disk denies |
| 7 | spec + plan lifecycle | a spec `state=archived` with no `archive_path`; *(WARN)* a doc marked ARCHIVED still sitting in `docs/specs/`, a spec absent from the index |
| 8 | ADR hygiene | one number used by two files, an ADR with no Status line, an `ADR-NNN` referenced in prose that no file carries; *(WARN)* numbering gaps |
| 9 | cross-doc drift | *(WARN only)* registry says built + `implementation-status.md` never mentions it, or the reverse; `stage.txt` and the registry's `phase` disagreeing |
| 10 | doc links | a relative markdown link pointing at a file that does not exist |
| 11 | session-state freshness | *(WARN only)* `active.md` lagging the newest commit by more than `--stale-days` |
| 12 | hook + skill integrity | a hook wired in `.claude/settings.json` that is not on disk, a `SKILL.md` with no parseable frontmatter (`name` + `description`) |

Two deliberate blind spots, so they are visible rather than silent:
- **Archived trees are not link-scanned.** Any directory whose name is or
  contains `z-old`, `old`, `archive(d)`, `backup(s)`, `snapshot(s)` is history;
  a link that rotted after retirement is expected, not a defect.
- **Illustrative rows are not drift.** A table row naming `your-system`,
  `example-thing`, `sample-*`, `my-*` is template documentation, so check 9
  skips it. Real systems must not be named that way.

**If the runner is missing** (an old install), say so plainly and continue with
Phase 2 by hand — do not silently skip the gate.

---

## Phase 2: The judgement calls the runner cannot make

The runner proves paths, numbers, shapes and statuses. It cannot read meaning.
Do these by hand, grep-first — target only the names in scope, no full reads
unless a conflict needs investigating.

**Modes:**
- No argument / `full` — every registered entry against every doc
- `since-last-review` — only docs modified since the last review report
- `entity:<name>` / `item:<name>` — one thing, across all docs

### 2a. Cross-doc value agreement
- The same number stated in two docs must match
- The same date stated in two docs must match
- The same formula must use the same variables in every doc that states it

### 2b. Entity / item / formula consistency (upstream Donchitos pattern)
For each entity, item, formula or constant in scope:
- Grep every in-scope GDD ({{GDD_PATH}} + `docs/gdd/*.md`) for the name
- Extract attribute values mentioned near the name
- Compare against the registry entry and against the data file that owns the number
- **🔴 CONFLICT** — same name, different values in two docs
- **⚠️ STALE REGISTRY** — the source GDD moved on, the registry is behind
- **ℹ️ UNVERIFIABLE** — the name appears with no comparable attribute

### 2c. Stale wording sweep
Grep the live tree (`docs/*.md`, `data/_schemas/*.json`, `production/*.md`,
source, `tools/`) for terms a prior cleanup was supposed to delete. Classify
each hit: **⚠️ stale claim** (live text contradicting the current state) vs
**ℹ️ historical context** (devlog narration, a RESOLUTION note, anything under
an archive directory) — historical is not a finding.

### 2d. Commit traceability
- Every `resolved_in_commit` hash in `flagged_for_designer_review` resolves in `git log`
- The branch is not silently ahead/behind its remote (`git status -sb`)

---

## Phase 3: Output report

```
=== CONSISTENCY CHECK — {{PROJECT_NAME}} ===
Date: [today]
Runner: [N] checks — [N] PASS, [N] WARN, [N] FAIL, [N] not applicable
Judgement pass: [in-scope docs]

Findings:
  🔴 CONFLICT  [detail]
  ⚠️ STALE     [detail]
  🟡 MISSING   [detail]

VERDICT: PASS | WARN — [N] items to review | FAIL — [N] blocking
```

Classify every finding:
- 🔴 **CONFLICT** — the same claim with different values in two docs; one is wrong
- ⚠️ **STALE** — wording in a live doc contradicts the current state
- 🟡 **MISSING** — a path or commit hash claimed but not resolving
- ℹ️ **HISTORICAL** — intentional narration of a past state; not a finding

For each non-historical finding, propose a fix: which doc is authoritative
(default: the source GDD for design intent, the registry for built state, the
data file for numbers), what changes in the contradicting doc, and whether a
commit is needed.

---

## Phase 4: Optional — fix the drift

Only on confirmation, in this order:
1. Stale wording in live docs
2. Missing files — either restore the file OR fix the claim that names it
3. Conflicting values — update the non-authoritative copy to match the source

`--fix-safe` handles exactly one class on its own: an absent empty directory
that the doc stack promises. Everything else is a human-reviewed edit. Bundle
the fixes into one `docs(consistency)` commit and re-run the runner to confirm.

---

## Phase 5: Registry corrections

If stale registry entries were found, ask:
> "May I update `data/_schemas/system_registry.json` to fix the [N] stale entries?"

For each: update the value, set `last_updated` to today, add a note to the
entry's `history` if it has one.

**Never delete registry entries.** Set `status: deprecated` when a system is
gone — a deleted entry takes its own history with it.

Verdict: **COMPLETE** when the re-run is clean; **BLOCKED** when conflicts need
a human decision.

---

## Phase 6: Reflexion log

If 🔴 CONFLICTS were found AND `docs/consistency-failures.md` already exists,
append a dated entry:

```markdown
### YYYY-MM-DD — /consistency-check — [VERDICT]
**Domain**: [systems involved]
**Documents involved**: [source vs contradicting doc]
**What happened**: [entity, attribute, the two differing values]
**Resolution**: [how it was fixed, or "Unresolved — manual action needed"]
**Pattern**: [the generalised lesson — what kind of drift was missed]
```

If the file does not exist, skip silently — do not create it from this skill.

---

## Next steps (chain-propose)

- **PASS** → `/review-all-gdds` for the design-theory pass, or `/create-architecture` if the MVP GDDs are done.
- **CONFLICTS** → fix the flagged docs, re-run the runner to confirm.
- **STALE REGISTRY** → Phase 5, then re-run.
- Run this after each new GDD, not at architecture time — early is cheap.

---

## What this skill does NOT do

- Re-implement by hand what the runner already proves (path existence, JSON
  shape, ADR numbering) — run it and read the report
- Fix anything without confirmation (Phase 4 is opt-in; `--fix-safe` creates
  empty directories and nothing else)
- Create `docs/consistency-failures.md` if it does not exist
- Delete registry entries — deprecate, never delete
