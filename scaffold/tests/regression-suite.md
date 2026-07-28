<!-- scaffold-seed: unwritten — delete this line once you write real content -->
# Regression Suite Manifest

> Last updated: [YYYY-MM-DD]
> Total registered tests: 0
> Coverage: [N]% of critical paths

**What this is.** A curated list of tests that already exist, chosen because
together they cover the critical paths and the places this project has broken
before. It is not a new test category and it does not hold test code — it is the
index that says which of your existing checks must stay green.

**Written by** `/regression-suite` — it globs your test files, maps them to the
critical paths in the GDDs, and appends a row per fixed bug that earned a test.
**Read by** `/regression-suite` itself on the next run (never renumber, never drop
a row), the release gate, and anyone asking "what breaks if I touch this?".

**The rule this file enforces:** every fixed bug should have a test that would have
caught it. A bug closed without one belongs in § Known gaps below, with the commit
hash, until it does.

**How to fill it:** run `/regression-suite` after a bug fix or before a release
gate. This project's tests live wherever you put them — the skill discovers them
rather than assuming a framework.

---

## How to run

*The exact commands, so a new contributor can run the suite without asking. One
line per runner.*

```bash
# [your headless harness invocation]
python tools/consistency_check.py
```

---

## Registered regression tests

*One `###` block per system. `Covers` cites the acceptance criterion or bug id the
test exists for — a test that covers nothing nameable is a test nobody will
maintain.*

_(none yet — `/regression-suite` registers the first entries)_

Shape of one block:

### [System name]

| Test file | Test function | Covers | Added |
|---|---|---|---|
| `[path to test]` | `test_[scenario]` | AC-N / BUG-NNN | [YYYY-MM-DD] |

---

## Known gaps

*Bugs that shipped without a regression test, and critical paths with no coverage.
Every row is a future firing of `/regression-suite`.*

| Priority | System | Suggested path | Covers | Why not written yet |
|---|---|---|---|---|
| _(none yet)_ | — | — | — | — |

---

## Quarantined tests

*Tests that are failing for a known reason and are excluded on purpose. A test
quarantined without a date and a reason is a deleted test with extra steps.*

| Test file | Function | Reason | Quarantined since |
|---|---|---|---|
| _(none yet)_ | — | — | — |
