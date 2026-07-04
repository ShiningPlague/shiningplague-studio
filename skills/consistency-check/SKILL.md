---
name: consistency-check
description: "Scan project docs / GDDs / registries against each other to detect cross-document inconsistencies — same entity with different stats, same item with different values, same formula with different variables, stale wording, broken paths, untraceable commits. Grep-first approach. ShiningPlague-adopted (Sons of Gilgamesh): adapts to system_registry.json + active.md + dev_diary.json doc stack instead of Donchitos's design/registry/entities.yaml. Runner at tools/consistency_check.py."
argument-hint: "[full | since-last-review | entity:<name> | item:<name>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/consistency-check/SKILL.md
  enhancements:
    - SoG doc stack (system_registry.json + active.md + dev_diary.json + devlog.md + ADRs + specs)
    - Cross-doc value/path/date agreement checks
    - Commit traceability (resolved_in_commit hashes must resolve)
    - Stale wording sweep with classify ⚠️/ℹ️
    - Registry structural coverage (autoloads / addons / data dirs)
    - Reflexion log to docs/consistency-failures.md (append-only, don't auto-create)
    - Runner cross-link: tools/consistency_check.py (44 checks, exits 0 on PASS)
    - Scheduled task consistency-check (every 2 days at 6am)
---

# Consistency Check

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos. Sons of Gilgamesh project adopted and enhanced. Upstream skill expected `design/registry/entities.yaml` + `design/gdd/*.md`; SoG version adapts to our actual doc stack (`data/_schemas/system_registry.json` + `production/session-state/active.md` + `data/_schemas/dev_diary.json` + `docs/devlog.md`). Spirit preserved (cross-doc consistency, grep-first); paths + cross-checks adapted. Vanilla backup: `docs/vanilla-backups/2026-05-15/consistency-check/`.

**Core principle:** scan our doc stack for cross-document inconsistencies — claims that disagree, file paths that don't resolve, commit hashes that don't exist, stale wording that contradicts current state. The registry is the entity-level source of truth; cross-check everything against it.

**This skill is the write-time safety net.** It catches what `/design-system`'s per-section checks may have missed and what `/review-all-gdds`'s holistic review catches too late.

---

## When to fire

- User says "run a consistency check" / "verify the docs" / "audit the doc stack" / "check everything for drift" → PROPOSE first, fire on confirm
- Before opening a fresh chat (end-of-session readiness check)
- After a step ships end-to-end (post-T10-equivalent verification)
- Before `/architecture-review` or `/review-all-gdds`
- After writing each new GDD (before moving to the next system)
- Before `/create-architecture` (inconsistencies poison downstream ADRs)
- On demand for a specific entity: `/consistency-check entity:<name>`

The scheduled task `consistency-check` (every 2 days at 6am, cron `0 6 */2 * *`) runs an automated version. Schedule catches background drift; manual fire catches end-of-session readiness.

---

## Phase 1: Parse Arguments and Load Doc Stack

**Modes:**
- No argument / `full` — check all registered entries against all docs
- `since-last-review` — check only docs modified since the last review report
- `entity:<name>` — check one specific entity across all docs
- `item:<name>` — check one specific item across all docs

**Load `data/_schemas/system_registry.json`** and extract canonical claims:
- `documentation_stack.spec_index.specs[]` — every spec's state, file path, archive_path, ADR link
- `documentation_stack.adr_index.adrs[]` — every ADR's number, status, date, file
- `documentation_stack.active_docs[]` — every live doc's path + role
- `next_session_priorities[]` — current and next steps
- `flagged_for_designer_review[]` — open issues with severity + resolved_in_commit
- `live_test_notes` — current_focus and recent change log
- `systems[]` — system status per registry status lifecycle

**Locate doc-stack files for cross-check:**
- `production/session-state/active.md` — compaction-anchor, must match registry header claims
- `data/_schemas/dev_diary.json` — entries[YYYY-MM-DD] done_major / done_minor / next / thoughts
- `docs/devlog.md` — top entry must match dev_diary done_major + registry current_focus
- `docs/implementation-status.md` — per-architecture sections must match registry system status
- `docs/adr/<NNN>-*.md` files referenced by adr_index
- `docs/specs/*.md` and `docs/z-old/specs/*.md` files referenced by spec_index
- `docs/plans/*.md` files referenced by spec_index `plan` fields

For GDD review modes, also load:
- `docs/GDD v.2.3.md` (master) and `docs/gdd/*.md` (per-system, when split)

If the registry is empty:
> "Registry has no systems. Run `/design-system` or build systems first; the registry populates as systems land. Nothing to check yet."

---

## Phase 2: Cross-Check (skill-spirit, project-paths)

Run these checks (the runner at `tools/consistency_check.py` is the canonical implementation — refer to it for the exact logic):

### 2a. File existence
- Every `spec_index.file` and `archive_path` exists at the claimed path (state=archived → archive_path; otherwise → file)
- Every `adr_index.file` exists
- Every `active_docs.path` exists (file or directory as appropriate)
- Every `plan` field in spec_index resolves to an actual file in `docs/plans/`
- Every `report` field in flagged items resolves

### 2b. State agreement
- `priorities[0].title` matches the next planned step
- `active.md` header matches `priorities[0]`'s framing
- `active.md` "Phase chain status" section matches `priorities[0]`'s implied phase
- `dev_diary.json[latest_date].done_major` mentions the same shipped milestones as `devlog.md`'s top entry
- `implementation-status.md` per-architecture sections reflect the same status as `registry.systems[].status`

### 2c. Commit traceability
- Every `flagged_item.resolved_in_commit` hash resolves in `git log --oneline -50`
- Every `commits` reference in scope_notes / kickoff_for_new_chat resolves
- Recent commit chain is on master and pushed (no `ahead`/`behind` in `git status -sb`)

### 2d. Stale wording sweep
- Search live tree (`docs/*.md`, `data/_schemas/*.json`, `production/*.md`, `src/`, `tools/`) for terms that should have been deleted on prior cleanup commits.
- For each match, classify: ⚠️ stale claim (live, contradicts current state) vs ℹ️ historical context (devlog narration, RESOLUTION note, z-old archive)

### 2e. Cross-doc value agreement
- Same numbers stated in two docs must match
- Same paths referenced in two docs must agree
- Same dates referenced in two docs must agree

### 2f. Registry structural coverage
- Verify every autoload in `project.godot`, every `addons/<name>/plugin.cfg`, and every populated `data/<dir>/` has a matching entry in `system_registry.json`
- Verify all `files[]` paths resolve on disk
- Verify all `depends_on` / `consumed_by` / `produced_by` ids resolve to real entries
- Implemented as `tools/check_registry_coverage.py`; called as check [17] inside `tools/consistency_check.py`

### 2g. Cross-GDD entity/item/formula consistency (if GDDs in scope)
Adopted from Donchitos pattern. For each registered entity, item, formula, constant:
- Grep every in-scope GDD for the name
- Extract attribute values mentioned near the name
- Compare against registry entry
- **🔴 CONFLICT**: same name, different values across two docs
- **⚠️ STALE REGISTRY**: source GDD updated, registry behind
- **ℹ️ UNVERIFIABLE**: name mentioned but no comparable attribute

This phase is the upstream Donchitos consistency-check spirit — grep-first, target only entity-name matches, no full reads unless conflict needs investigation.

---

## Phase 3: Output Report

```
=== CONSISTENCY CHECK — Sons of Gilgamesh ===
Date: [today]
Registry: [N systems, N specs, N ADRs, N flagged, N priorities]
In-scope docs: [list]

[N] checks passed
[N] conflicts/warnings:
  - [kind]: [detail]

VERDICT: PASS | WARN — [N] items to review
```

Classify each finding:
- 🔴 **CONFLICT** — same claim with different values across two docs; one is wrong
- ⚠️ **STALE** — wording in a live doc contradicts the current state
- 🟡 **MISSING** — file path / commit hash claimed but doesn't resolve
- ℹ️ **HISTORICAL** — match found but it's intentional historical narration — not a finding

For each non-historical finding, propose a fix:
- Which doc is authoritative (default: the source GDD / registry source)
- What to change in the contradicting doc
- Whether a commit is needed

---

## Phase 4: Optional — Fix Authoritative Drift

If the user confirms, fix in this order:
1. Stale wording in live docs (cleanup edits)
2. Missing files (either restore the file OR fix the registry claim)
3. Conflicting values (update the non-authoritative copy to match the source)

Each fix is a discrete edit. Bundle into one `docs(consistency)` commit.

---

## Phase 5: Registry Corrections (Donchitos pattern, adapted)

If stale registry entries found, ask:
> "May I update `data/_schemas/system_registry.json` to fix the [N] stale entries?"

For each stale entry:
- Update the `value` / attribute field
- Set `revised:` or `last_updated:` to today's date
- Add a note in registry-entry `history` array

**Never delete registry entries.** Set `status: deprecated` if the entry no longer exists.

After writing: Verdict: **COMPLETE** — consistency check finished.
If conflicts remain unresolved: Verdict: **BLOCKED** — [N] conflicts need manual resolution.

---

## Phase 6: Reflexion Log

If 🔴 CONFLICTS found AND `docs/consistency-failures.md` exists, append a dated entry:

```markdown
### YYYY-MM-DD — /consistency-check — [VERDICT]
**Domain**: [systems involved]
**Documents involved**: [source vs conflicting doc]
**What happened**: [specific conflict — entity name, attribute, differing values]
**Resolution**: [how fixed, or "Unresolved — manual action needed"]
**Pattern**: [generalised lesson — what kind of drift was missed]
```

If the file doesn't exist, skip silently — do not create from this skill.

---

## Implementation runner

The canonical Python runner is `tools/consistency_check.py`. It does Phases 1-3 automatically. Run with:

```
python tools/consistency_check.py
```

Exits 0 on PASS, non-zero on warnings. Could be wired into a git pre-push hook. Findings printed to stdout.

The runner is project-aware (knows our paths, claims, expected commit hashes). Update it when project conventions shift (new doc added to active_docs, new flagged-item field, etc.).

---

## Next Steps (chain-propose)

- **If PASS**: Run `/review-all-gdds` for holistic design-theory review, or `/create-architecture` if all MVP GDDs are complete.
- **If CONFLICTS FOUND**: Fix the flagged docs, then re-run `/consistency-check` to confirm resolution.
- **If STALE REGISTRY**: Update the registry (Phase 5), then re-run to verify.
- Run `/consistency-check` after writing each new GDD to catch issues early, not at architecture time.

---

## What this skill does NOT do

- Re-implement what the runner already does (re-running JSON parse, file existence) — defer to the runner
- Fix conflicts without designer confirmation (Phase 4 is opt-in)
- Append to `docs/consistency-failures.md` if it doesn't exist (don't auto-create)
- Delete registry entries (deprecate, never delete)
