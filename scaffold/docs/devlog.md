# Devlog

**What this is.** The change log and the retrospective record, in one file, newest
entry at the top. If it shipped, it has an entry here.

**Written by** `/update` (one entry per working session) and `/retrospective`
(sprint retros append here — this project keeps one narrative, not two).
**Read by** the CLAUDE.md reading map row *"what changed recently"*, `/help`, and
`/consistency-check` — which compares the top entry against
`data/_schemas/dev_diary.json` (newest `done_major`) and the registry's
`live_test_notes.current_focus`. Those three must tell the same story.

**Entry format** — copy this shape, newest first:

```markdown
## YYYY-MM-DD — <short title of what shipped>

**Shipped**
- <thing that now works> (`<commit hash>`)

**Changed**
- <behaviour or data that moved, and what it moved from/to>

**Decisions**
- <decision> → `docs/adr/NNN-<slug>.md`

**Next**
- <the single next action, matching registry next_session_priorities[0]>
```

Keep entries factual and short. The reasoning belongs in the ADR, the design
belongs in the spec, the state belongs in the registry. This file is the timeline.

---

## YYYY-MM-DD — Studio framework installed

**Shipped**
- The ShiningPlague Game Studio framework, project-local under `.claude/`.
- The document stack scaffolded: registry, session state, stage, review mode,
  workstream template, ADR template, this devlog.

**Next**
- Run `/start` to onboard the project, or `/brainstorming` to go straight to
  design. Then replace this entry with your own first real one.
