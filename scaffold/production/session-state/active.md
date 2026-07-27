<!-- scaffold-seed: unwritten — delete this line once you write real content -->
# Active Session State

**Last updated:** (never — seeded by the installer)
**Maintained by:** Claude during work · `/update` and `/session-close` rewrite it · the pre-compact and session-start hooks read it

## How this file works

This is the **handover file**. One session ends, the next one opens cold and reads
this first — so whatever is not written here does not survive. Keep it current,
keep it honest, and put the *next action* where a tired reader will see it: at the
top of PRIMARY NEXT-SESSION ACTION.

Sections below are the skeleton the skills fill in. Leave the headings in place
even while they are empty — `/help`, `/goal-check` and `/red-flag-scan` look for
them by name.

---

## Current project state

**Phase:** not-started (`production/stage.txt` — the seeded default; no gate cleared yet)
**Review mode:** lean (`production/review-mode.txt` — the seeded default; `/start` confirms it)
**Engine:** not configured yet — run `/setup-engine`
**Systems:** none registered yet (`data/_schemas/system_registry.json`)
**Workstreams:** none open yet (`production/workstreams/`)

Nothing has been built. This is a fresh install, and that is a legitimate state —
the file exists so the first session has something true to read.

---

## 🎯 PRIMARY NEXT-SESSION ACTION

**Start the project.** Run `/start` — it detects what exists, routes you to the
right onboarding path, and confirms your review mode. If you already know what
you are making, `/brainstorming` goes straight to the design conversation.

Replace this block with the real next action at the end of every session. One
action, stated as an imperative, with the reason it is next.

---

## Phase chain status

| Phase | State | Evidence |
|---|---|---|
| concept | not started | — |
| systems-design | not started | — |
| technical-setup | not started | — |
| pre-production | not started | — |
| production | not started | — |
| polish | not started | — |
| release | not started | — |

Keep this table agreeing with `production/flow-ledger.yaml` and
`data/_schemas/system_registry.json → next_session_priorities[0]`.
`/consistency-check` compares them.

---

## 🚨 OPEN ADOPTION PLAN TODOs

Unresolved items carried in from `/adopt` or from a previous session, highest
priority first. `/help` surfaces this section by name.

1. _(none yet)_

---

## 🚨 NEXT-SESSION MUST-FIRE

Discipline items the next session must run before anything else — a skill that was
skipped, a verification that was deferred, a gate that was waived.

- _(none yet)_

---

## Session Extracts

Skills append their own dated block here (`## Session Extract — /<skill> [date]`).
Newest at the bottom; prune anything older than the last two sessions into
`production/session-logs/`.
