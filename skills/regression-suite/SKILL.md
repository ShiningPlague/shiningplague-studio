---
name: regression-suite
description: "Map test coverage to GDD critical paths, identify fixed bugs without regression tests, flag coverage drift from new features, and maintain tests/regression-suite.md. Run after implementing a bug fix or before a release gate. ShiningPlague-adopted (Sons of Gilgamesh): adapts to SoG headless harness pattern (tools/<step>_<feature>_check.gd) + scene parse-checks + GUT-deferred decision."
argument-hint: "[update | audit | report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/regression-suite/SKILL.md
  enhancements:
    - SoG test-type taxonomy (headless GDScript harness / Python validators / scene parse / smoke)
    - Capture-as-test procedure after every bug fix
    - Coverage-gap procedure after every step ships
    - On-demand audit procedure
    - Known regression test gaps log (with commit hashes)
    - GUT framework adoption deferred per CLAUDE.md
---

# Regression Suite

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos. Sons of Gilgamesh project adopted and enhanced. Upstream pattern preserved (capture-as-test + coverage drift detection + manifest at `tests/regression-suite.md`); SoG-specific test types added (GDScript headless harness, Python validators, scene parse-checks). Vanilla backup: `docs/vanilla-backups/2026-05-15/regression-suite/`.

**Core principle:** every fixed bug should have a regression test that would have caught it. A regression suite is not a new test category — it is a **curated list of tests already in `tools/` and `tests/`** that collectively cover critical paths and known failure points. This skill maintains that list.

**Output:** `tests/regression-suite.md`

---

## When to fire

- 🟢 **After every bug fix lands** — capture-as-test pattern. The bug becomes a test that would have caught it pre-fix.
- 🟢 **After each step ships end-to-end** — coverage gap pass. Identify which step features lack coverage.
- 🟢 **On-demand** — designer asks *"are we covered for X?"* / *"do we have a regression test for the slot drift bug?"*
- 🟢 **Before a major refactor** — confirm the existing test coverage will catch breakage.
- 🟢 **Before a release gate** — `/gate-check polish` requires regression suite exists.
- 🟢 **As part of sprint close** — detect coverage drift.

---

## Arguments

- `/regression-suite update` — scan new bug fixes this sprint, check for regression test presence, add new tests to manifest
- `/regression-suite audit` — full audit of GDD critical paths vs existing coverage; flag paths with no test
- `/regression-suite report` — read-only status report (no writes), suitable for sprint reviews
- No argument — run `update` if sprint active, else `audit`

---

## In-scope test types for SoG

| Type | Where it lives | Example |
|---|---|---|
| Headless GDScript harness | `tools/<step>_<feature>_check.gd` | `tools/step3a_status_effect_check.gd` (8 tests) |
| Headless data validation | Python script in `tools/` | `tools/consistency_check.py` (44 checks across doc stack) |
| Scene parse-check | `godot --headless scene.tscn` parse output | combat_screen.tscn no SCRIPT ERROR |
| Cross-step regression runner | `tools/regression_check.gd` (planned, not yet built per registry) | runs all step harnesses in sequence |
| Manual smoke test | F5 in editor + designer eyeball | T9 in-engine smoke test |

GUT framework adoption is a deferred decision per CLAUDE.md — for now, scene-based + headless-script verification.

---

## Procedure: capture-as-test mode (fires after a bug fix)

1. **Identify the bug.** What was the symptom? What was the root cause? What commit fixed it?
2. **Identify the test layer.** Where would the test live?
   - Pure data layer (JSON validity) → Python script
   - Engine logic (apply/tick/expire) → headless GDScript harness
   - Scene loading → headless scene parse check
   - User-facing render → manual smoke test (no automation possible without engine running)
3. **Write the failing test.** Reproduce the bug as a test case that would have failed PRE-fix. Verify it passes POST-fix.
4. **Add to the relevant harness file** (or create a new harness if none exists for that domain).
5. **Append entry to `tests/regression-suite.md`** with:
   - Bug description + commit hash
   - Test location (file:line)
   - Critical path coverage tag (combat / map / data / etc.)
6. **Verify the harness runs cleanly:** `godot --headless --path . --script "res://tools/<harness>.gd"` shows N+1/N+1 PASS (the +1 is the new test).
7. **Commit + push:** `test(<step>): add regression for <bug short> (closes commit <hash>)`.

## Procedure: coverage-gap mode (fires after a step ships)

1. **List every system/feature shipped in the step.** From `system_registry.json → recently_changed_*` + the step's spec.
2. **For each, ask: is there a test that would catch a regression?**
3. **Classify gaps:**
   - 🔴 No test exists for a critical path (blocks player from playing)
   - 🟠 No test exists for a feature explicitly marked in spec
   - 🟡 No test for an edge case or polish detail
4. **Write tests for the 🔴 cases inline.** Propose `/writing-plans` for 🟠+ batch if 3+ items.
5. **Update `tests/regression-suite.md`** with new coverage rows + flag critical gaps in `system_registry.json → flagged_for_designer_review`.

## Procedure: on-demand audit (designer asks "are we covered for X?")

1. **Find the relevant tests.** Grep `tools/` for keywords related to X.
2. **Read each test's assertions.** Are they actually covering the behaviour, or just sanity-checking?
3. **Report coverage assessment:** strong / partial / none, with file:line references.
4. **Propose new tests if gaps exist.**

## Procedure: full audit mode (Donchitos pattern, adapted)

For `audit` mode:

### Step A — Load existing manifest
Read `tests/regression-suite.md` if it exists. Extract total registered tests, last updated date, any flagged as STALE/QUARANTINED. If missing: note "No regression suite found — will create one."

### Step B — Load test inventory
Glob all test files (`tools/*_check.gd`, `tools/*.py`, `tests/`). For each file, note system + filename.

### Step C — Load GDD critical paths
Read `docs/GDD v.2.3.md` or per-system GDDs. For each MVP-tier system, extract Acceptance Criteria, Formulas, Edge Cases. These define critical paths.

### Step D — Load closed bugs
From `system_registry.json → flagged_for_designer_review[]` with `resolved_in_commit`. For each, check if a test references the bug or its scenario.

### Step E — Map coverage
For each critical path/bug, assign:

| Status | Meaning |
|--------|---------|
| **COVERED** | Test file exists targeting this criterion's logic |
| **PARTIAL** | Test exists but doesn't cover all cases (happy path only) |
| **MISSING** | No test found for this critical path |
| **EXEMPT** | Visual/Feel/UI criterion — not automatable by design |

Elevate MISSING items that correspond to formulas/state machines to **HIGH PRIORITY**.

### Step F — Detect coverage drift
- Stories completed this sprint with no test files
- New systems in registry since last regression-suite update
- GDD sections added/revised since manifest last updated
- Manifest `Last Updated` date — if gap > 2 sprints, flag stale

---

## Output Report Format

```
## Regression Suite Status

**Mode**: [update | audit | report]
**Existing registered tests**: [N]
**Test files scanned**: [N]

### Critical Path Coverage (audit mode only)
| System | Total ACs | Covered | Partial | Missing | Exempt |
|--------|-----------|---------|---------|---------|--------|
| [name] | [N] | [N] | [N] | [N] | [N] |

**Coverage rate (non-exempt)**: [N]%

### Bug Regression Coverage
| Bug ID | System | Severity | Has Regression Test? |
|--------|--------|----------|----------------------|
| BUG-NNN | [system] | S[N] | YES / NO ⚠ |

**Bugs without regression tests**: [N]

### Coverage Drift Indicators
[List new systems or stories with no test coverage, or "None detected."]

### Recommended New Regression Tests
| Priority | System | Suggested Test File | Covers |
|----------|--------|---------------------|--------|
| HIGH | [system] | `tools/<step>_<bug>_check.gd` | BUG-NNN / AC-[N] |
| MEDIUM | [system] | `tools/<step>_<feature>_check.gd` | [criterion] |
```

---

## `tests/regression-suite.md` schema

```markdown
# Regression Suite Manifest

> Last Updated: [date]
> Total registered tests: [N]
> Coverage: [N]% of GDD critical paths

## How to run

godot --headless --path . --script "res://tools/<harness>.gd"
python tools/consistency_check.py

## Registered Regression Tests

### [System Name]

| Test File | Test Function | Covers | Added |
|-----------|---------------|--------|-------|
| `tools/<harness>.gd:line` | `test_<scenario>` | AC-N / BUG-NNN | [date] |

## Known Gaps

| Priority | System | Suggested Path | Covers | Reason Not Yet Written |
|----------|--------|----------------|--------|------------------------|
| HIGH | [system] | `tools/<path>` | BUG-NNN | Bug fixed without test |

## Quarantined Tests

| Test File | Function | Reason | Quarantined Since |
|-----------|----------|--------|-------------------|
```

---

## Known regression test gaps (seed entries)

These are bugs that shipped without regression tests — every one is a future-firing of this skill:

_None currently logged._ The 3 seed entries (front_image_null `746cb06`, pill expiry `629534c`, slot drift `fd52283`) were confirmed fixed and resolved (designer 2026-05-15). Append new gap entries here as bugs ship without regression tests.

**Template for new entries:**

- **<bug name>** (commit `<hash>`). <where the test should live + what it should assert>.

---

## Write Output

Ask: "May I write/update `tests/regression-suite.md` with the current regression suite manifest?"

For `update` mode: append new entries; never remove existing entries (use `Edit` with targeted insertions).
For `audit` mode: rewrite the full manifest with updated coverage data.
For `report` mode: do not write anything.

After writing (if approved):

- For each HIGH priority gap: "Consider creating the missing regression test before the next sprint."
- If bug regression gaps > 0: "These bugs can silently return without regression tests. The next sprint should include a story to write the missing tests."
- If coverage drift detected: "Regression suite may be drifting. Consider running `/regression-suite audit` at the next sprint boundary."

Verdict: **COMPLETE** — regression suite updated. (If user declined write: Verdict: **BLOCKED**.)

---

## Collaborative Protocol

- **Never remove existing regression tests from the manifest** without explicit user approval
- **Gaps are advisory, not blocking** — surface them clearly but don't prevent other work (except at release gate)
- **Quarantine is not deletion** — flaky tests should be quarantined (noted in manifest), not removed; they should be fixed by `/test-flakiness`
- **Ask before writing** — always confirm before creating or updating the manifest

---

## What this skill does NOT do

- Replace `verification-before-completion` (which verifies CURRENT change, not builds regression suite for FUTURE changes)
- Auto-write tests without designer review on test approach (especially 🟠+ cases)
- Touch the GUT framework adoption decision — that's a future technical-director call

---

## Cross-link

Regression Harness routine is parked in `system_registry.json → next_session_priorities` as a deferred item. When that lands (~150 LOC, 2 hours per registry estimate), it'll provide the cross-step runner that this skill writes tests for.
