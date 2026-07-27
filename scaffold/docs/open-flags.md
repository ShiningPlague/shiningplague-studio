# Open Flags

**What this is.** The ledger of contradictions and unresolved questions that the
automated checks found but cannot decide — every one needs a human ruling. This is
the human-readable twin of
`data/_schemas/system_registry.json → flagged_for_designer_review[]`; the two must
carry the same open items.

**Written by** `/consistency-check`, `/architecture-review`, `/review-all-gdds`,
`/red-flag-scan`, `/design-review` — each appends a flag rather than guessing.
**Read by** `/red-flag-scan` (any open `critical` flag fails the scan),
`/retrospective` (flags raised during the sprint), `/gate-check` (open critical
flags block a phase advance).

**A flag is not a bug.** A bug is a defect in the game and lives at
`production/qa/bugs/BUG-NNN-<slug>.md`. A flag is a decision the project owes
itself: two documents disagreeing, a formula with no owner, a system whose status
nobody can confirm.

**Flag format** — newest first:

```markdown
### FLAG-001 — <one-line summary>

- **Severity:** critical | high | medium | low
- **Raised:** YYYY-MM-DD by /<skill>
- **Where:** `<path>` vs `<path>`
- **The contradiction:** <what the two sources each claim>
- **Needs:** <the specific ruling required, and who owes it>
- **Status:** open | resolved
- **Resolved in:** <commit hash> — <what the ruling was>
```

Resolve a flag by setting `Status: resolved`, filling `Resolved in`, and clearing
the matching entry in the registry. Keep the resolved text in place; the reasoning
is worth more than the tidiness.

---

## Open

- _(none — a fresh install has nothing to contradict yet)_

---

## Resolved

- _(none yet)_
