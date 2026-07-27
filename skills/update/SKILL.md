---
name: update
description: Project-local /update — project state sync procedure. Sync docs, run consistency check, write {{CHANGELOG_DOC}} + dev_diary entries, prompt to push. Fires when designer types /update OR says "update", "update docs", "log what we did", "let's update", or similar end-of-session sync intent. NOT to be confused with productivity:update (external task tracker sync — N/A when no external tracker is used).
metadata:
  origin: ShiningPlague
  adopted_by: ShiningPlague
  enhancements:
    - Authored in-studio as project state sync procedure
    - 11-step procedure (git scan → docs read → detect changes → consistency check gate → changelog → dev_diary → workstream → CLAUDE.md → memory → flag contradictions → push prompt)
    - Auto-fires on major ships (spec archived / 5+ commits / infra adoption)
    - Distinct from productivity:update (which syncs external trackers)
    - Date-accuracy check (ask designer if unsure)
    - No CHANGELOG.md — git commits are canonical changelog
---

# /update — project state sync

> 🌱 **ShiningPlague-authored.** Authored in-studio — no upstream version exists; battle-tested on a shipped Godot project. Distinct from `productivity:update` (which is an external-tracker sync skill).

**Purpose:** end-of-session (or major-milestone) doc + state sync. Docs-only — never touches code. Captures the day's work in `{{CHANGELOG_DOC}}` (e.g. `docs/devlog.md`) + `data/_schemas/dev_diary.json`, gates registry coverage, ensures the doc stack is consistent, prompts to push.

**This is the project-local skill. The user-level `productivity:update` skill is for external task-tracker sync (Asana/Linear/Jira/GitHub Issues) — mute it via `enabledPlugins` if the project uses no external tracker.**

---

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## When to fire

- Designer says: "update", "update docs", "/update", "log what we did", "let's update the project state", "log this session"
- 🔒 **Auto-fire** when: 5+ commits in current session AND end-of-session signals (designer says "we're done for today", "ok pushing now", or chat is closing)
- Also auto-fire (proactive) when major milestone shipped — step archived, ADR Accepted, framework adoption, significant bug-chain resolved (per CLAUDE.md "Auto-update dev_diary after major ship events" rule)

---

## Procedure

### 1. Gather recent activity

```bash
git status
git log --oneline -20
```

Note uncommitted work and recent commits. Capture commit hashes for traceability in devlog/dev_diary entries.

### 2. Read current docs

- `docs/implementation-status.md` — per-architecture sections
- `{{CHANGELOG_DOC}}` (e.g. `docs/devlog.md`) — top entry for context
- Memory at `~/.claude/projects/<project>/memory/` is auto-loaded

### 3. Detect changes per recent commit / uncommitted change

For each:
- **System status moved?** Update the relevant per-system section in `implementation-status.md` — "What's built / what's missing" rows + status pills.
- **New gap / data-code mismatch?** Add to that section's **TBD** subsection. Mirror to the doc's Open Questions / TBD section if cross-cutting.
- **New live source (new JSON, new dock)?** Update the live-source table at the top (if the doc has one).
- **Design decision worth preserving?** Add to `{{CHANGELOG_DOC}}`.
- **NEVER** write into `## 📓 Designer Notes (Dev Diary Log)` — that is auto-written by the Project Dashboard Save button.

### 4. Run the consistency check (gate)

```bash
python tools/consistency_check.py
```

12 checks — registry shape + references, registry coverage, the doc stack `CLAUDE.md` promises, the registry's doc ledger, spec/plan lifecycle, ADR hygiene, cross-doc drift, broken links, session-state freshness, hook + skill integrity. On a run with no FAILs it bumps `last_full_audit` to today (pass `--no-bump` for a read-only spot check).

**On FAIL (exit 1):** fix what it names before continuing. Every FAIL is a path, id or claim a session would trip over.

**On WARN (exit 0):** advisory, but read them — registry coverage lives here, and this is the gate that catches shipping without a registry update, a proven failure mode. If this session added a data category / autoload / addon / tool, add the matching `systems[] / tools[] / data[]` entry now rather than letting the warning age.

### 5. Append changelog entry

Top of `{{CHANGELOG_DOC}}` (e.g. `docs/devlog.md`). Format:

```markdown
## YYYY-MM-DD — Short Title

3-6 bullets covering: what shipped, key decisions, flags raised, what's next.

---
```

### 6. Write today's `dev_diary.json` entry

Key: `data/_schemas/dev_diary.json → entries.[today]`.

Fill `done_major` (2-4 items, one sentence each — the big milestones).
Fill `done_minor` (5-12 bullets — smaller tweaks).

**Leave `next` and `thoughts` alone — those are designer-editable in Project Dashboard → Dev Diary toggle.** Create the entry if missing; overwrite `done_major`/`done_minor` if re-running the command same day.

### 6b. Update workstream state file

If work this session touched a specific workstream, update its state file at `production/workstreams/<name>.md`:
- Move completed items from "In Progress" to "Done" (with date)
- Update "Next" with follow-up work identified
- Log director feedback in "Director Feedback History" table (if close protocol ran)
- Update "Current Phase" if a phase gate passed
- Update "Last Updated" date in header

### 6c. Write close_note to dev_diary

Add `close_note` field to today's dev_diary entry — 2 sentences max. A brief reflection on what shipped this session (from the session-close reflection step if session-close ran).

### 6d. Write close_ref to dev_diary

Add `close_ref` field to today's dev_diary entry — path to the session close log at `production/session-logs/YYYY-MM-DD-[workstream]-close.md`. Only if session-close protocol ran (otherwise omit).

### 7. Update CLAUDE.md `Current State` (only if major shift)

Only when: milestone complete, system retired, pivot. Small changes stay in `implementation-status.md`.

### 8. Update memory

Per auto-memory rules — only cross-conversation facts (project-level decisions, designer feedback patterns, references). Use the four memory types appropriately.

### 9. Flag contradictions

If you find a `FLAG: ...` candidate (e.g., implementation-status says X built but registry says wip), surface it. Don't paper over.

### 10. Report back concisely

```
Update complete:
- Files updated: [list]
- Flags raised: [list]
- Anything needing designer confirmation: [list]
```

### 11. Prompt to push

```
Ready to commit + push? Stage: [list of changed files]. Suggested message: `<draft>`.
```

**Never push without explicit go.**

---

## Auto-fire on major ship (proactive)

CLAUDE.md "Auto-update dev_diary after major ship events" rule: do NOT wait for designer to say "update" before writing to `dev_diary.json`. At end of session where:

- Spec flipped to 🗄️ ARCHIVED
- Commit message starts with `fix(...)` resolving a reported bug
- 5+ commits in one session closing a planned step
- Infrastructure adoption (hooks, framework, tooling) that changes the workflow
- Any retrospective/postmortem learnings worth preserving

→ proactively backfill `done_major` + `done_minor` for today. Leave `next` + `thoughts` alone.

---

## Conventions

- **No CHANGELOG.md** — git commits are the canonical changelog. `{{CHANGELOG_DOC}}` is higher-level context.
- **Date accuracy** — if unsure of today's date (no recent system-reminder, nothing fresh in context), ask designer before writing dated entries.
- **T10 docs-sync ritual** is the SHIP-time variant of this command (last task of every plan): archive shipped spec to `docs/z-old/specs/`, write changelog entry, backfill `dev_diary`, rotate `next_session_priorities[0]`, add registry entries for new autoloads/addons/data categories.

---

## What this skill does NOT do

- Touch source code (docs-only — by design)
- Write into `## 📓 Designer Notes (Dev Diary Log)` (Dashboard auto-writes that)
- Edit `dev_diary.next` or `dev_diary.thoughts` (designer-only)
- Push to remote (always asks first)
- Sync from external task trackers (we don't use them — that's `productivity:update`'s job, and it's N/A here)
- Replace the consistency-check skill (this skill INVOKES it as step 4; consistency-check is its own skill at `.claude/skills/consistency-check/SKILL.md`)

---

## Pointer

For full context on the doc stack, see CLAUDE.md § Doc stack boundary rule + § System registry. For consistency-check specifics, see `.claude/skills/consistency-check/SKILL.md`. For the chain-propose rule that fires after this completes, see `.claude/docs/skills-protocol-extended.md § Chain-propose`.
