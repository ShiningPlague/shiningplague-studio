---
name: help
description: "Use when designer asks 'where are we', 'what should I do now', 'what's next', 'I'm stuck', 'status', OR at session start to surface canonical state. Analyzes what is done and the user's query and offers advice on what to do next. ShiningPlague-adopted: adds workstream + adoption-TODO awareness + paused-spec surfacing on top of canonical phase logic."
argument-hint: "[optional: what you just finished, e.g. 'finished design-review' or 'stuck on ADRs']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
context: |
  !echo "=== Live Project State ===" && echo "Stage: $(cat production/stage.txt 2>/dev/null | tr -d '[:space:]' || echo 'not set')" && echo "Latest sprint: $(ls -t production/sprints/*.md 2>/dev/null | head -1 || echo 'none')" && echo "Session state: $(head -5 production/session-state/active.md 2>/dev/null || echo 'none')"
model: haiku
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Workstream awareness (reads production/workstreams/*.md state)
    - Adoption-TODO surfacing (active.md + docs/migration/adoption-plan-*.md)
    - Paused-spec surfacing (in_progress specs)
    - Next-action priority (canonical-first, then workstream, then in-progress)
    - Cross-link to /project-stage-detect for deeper gap audit
---

# Studio Help — What Do I Do Next?

> 🌱 **ShiningPlague-adopted.** Originally Donchitos; battle-tested on a shipped Godot project. Upstream canonical phase logic preserved + workstream/adoption awareness layered on.

This skill is read-only — it reports findings but writes no files.

Figures out where you are in the game development pipeline and tells you what comes next. **Lightweight** — not a full audit. For full gap analysis, use `/project-stage-detect`.

## When to fire

- Designer asks: "where are we", "what should I do now", "what's next", "I'm stuck", "I don't know", "status", "help"
- Session-start hook output PHASE ARTIFACT STATUS surfaced an unresolved gap
- After a major skill fires — recommend the next canonical step

---

## Step 1: Read the Catalog

Read `.claude/docs/workflow-catalog.yaml`. Authoritative list of all phases, their steps, required/optional flags, and artifact globs.

## Step 1b: Find Skills Not in the Catalog

Glob `.claude/skills/*/SKILL.md`. For each, extract the `name:` field from frontmatter.

Compare against `command:` values in the catalog. Any skill whose name doesn't appear in the catalog is **uncataloged** — usable but not phase-gated.

Collect for Step 7 footer:

```
### Also installed (not in workflow)
- `/skill-name` — [description from SKILL.md frontmatter]
```

Show only if at least one uncataloged skill exists. Limit to the 10 most relevant for current phase.

---

## Step 2: Determine Current Phase

1. **Read `production/stage.txt`** — authoritative. Map to catalog phase key:
   - "Concept" → `concept`
   - "Systems Design" → `systems-design`
   - "Technical Setup" → `technical-setup`
   - "Pre-Production" → `pre-production`
   - "Production" → `production`
   - "Polish" → `polish`
   - "Release" → `release`

2. **If missing**, infer phase from artifacts (most-advanced match wins):
   - `src/` has 10+ source files → `production`
   - `production/stories/*.md` exists → `pre-production`
   - `docs/adr/*.md` exists → `technical-setup`
   - `design/gdd/systems-index.md` exists → `systems-design`
   - `design/gdd/game-concept.md` exists → `concept`
   - Nothing → `concept` (fresh project)

---

## Step 3: Read Session Context

Read `production/session-state/active.md`. Extract:
- What was most recently worked on
- In-progress tasks or open questions
- Current epic/feature/task from STATUS block

This personalizes the output.

---

## Step 4: Read Per-Workstream State (studio addition)

Glob `production/workstreams/*.md`. For each, extract:
- `Current Phase:` line
- `In Progress` section content
- `Blocked` section content
- `Open Questions` section content

Report per-workstream phase + what's in flight + blockers.

---

## Step 5: Read Open Adoption TODOs (studio addition)

Read `production/session-state/active.md`. Look for `🚨 OPEN ADOPTION PLAN TODOs` section. List unresolved items.

Also check `docs/migration/adoption-plan-*.md` for any unchecked items not yet surfaced.

---

## Step 6: Read Open Specs (studio addition)

Glob `docs/specs/*.md`. For each, extract Status (🚧 IN PROGRESS / ✅ FINAL / 🗄️ ARCHIVED). List in-progress specs — paused work waiting to resume.

---

## Step 7: Check Step Completion for Current Phase

For each step in current phase (from catalog):

### Artifact-based checks

If step has `artifact.glob`:
- Use Glob to check
- If `min_count` specified, verify count
- If `artifact.pattern` specified, use Grep to verify pattern
- **Complete** = artifact condition met
- **Incomplete** = artifact missing or pattern not found

If step has `artifact.note` (no glob):
- Mark **MANUAL** — ask user

If step has no `artifact` field:
- Mark **UNKNOWN** — not trackable

### Special case: production phase — read `sprint-status.yaml`

When current phase is `production`, check `production/sprint-status.yaml` before glob-based story checks. If it exists, read it:

- Stories `status: in-progress` → "currently active"
- `status: ready-for-dev` → "next up"
- `status: done` → count as complete
- `status: blocked` → surface as blocker

Skip glob check for `implement` and `story-done` steps — YAML is authoritative.

### Special case: `repeatable: true` (non-production)

For repeatable steps outside production (e.g. "System GDDs"), artifact check tells whether *any* work has been done. Label differently — show detected, note it may be ongoing.

---

## Step 8: Determine Recommended Next Canonical Action

Priority order:
1. **Project canonical phase gap (foundational)** — if Concept/Systems-Design artifacts missing, recommend canonical skill (e.g., `/design-system game-concept` if pointer-only).
2. **Workstream-specific work** — if foundational gaps closed, check which workstream the designer was last on (active.md priorities[0]) and recommend the next canonical step.
3. **In-progress paused work** — if a spec is 🚧 IN PROGRESS, recommend resuming.
4. **Open adoption TODOs** — surface unresolved items even if recommending phase work.

---

## Step 9: Present Output

Keep it **short and direct**. Quick orientation, not a report.

```
## Where You Are: [Phase Label]

**In progress:** [from active.md, if any]

### ✓ Done
- [completed step name]

### → Next up (recommended)
**[Step name]** — [description]
Command: `[/command]`

### Workstream Status

| Workstream | Phase | In Progress | Blocked |
|---|---|---|---|
| Combat | Production | [item] | — |
| Narrative | Concept | — | [blocker] |

### Open Adoption TODOs
- [item 1]
- [item 2]

### Open Specs (paused)
- 🚧 [spec path] — [topic]

### ~ Also available (optional)
- **[Step name]** — [description] → `/command`

### Coming up after that
- [Next step name] (`/command`)

---
Getting close to the **[next phase]** gate → run `/gate-check` when you're ready.
```

**Formatting rules:**
- `✓` for confirmed complete
- `→` for the recommended next step (only one — the first blocker)
- `~` for optional steps available now
- Show commands inline as backtick code
- For MANUAL steps, ask: "I can't tell if [step] is done — has it been completed?"
- Keep the tone friendly and orienting — this is a helpful signpost, not a compliance report.

---

## Step 10: Gate Warning (if close)

If all required steps in current phase are complete (or nearly), add:
> "You're close to the **[Current] → [Next]** gate. Run `/gate-check` when ready."

If multiple required steps remain, skip the gate warning.

---

## Step 11: Escalation Paths

If user seems stuck or confused, add:

```
---
Need more detail?
- `/project-stage-detect` — full gap analysis with all missing artifacts listed
- `/gate-check` — formal readiness check for your next phase
- `/start` — re-orient from scratch
```

Only show if input suggested confusion ("I don't know", "stuck", "lost", "not sure").

---

## Cross-skill awareness

- After firing this skill, if user picks canonical recommendation, the natural next skill fires per `team-orchestrator.md` activity chain.
- Pair with `/project-stage-detect` (also project-local) — that skill does the deep gap audit; this one does the day-to-day "what's next" framing.

## Reference files (project)

- `.claude/docs/workflow-catalog.yaml` — canonical phase pipeline
- `production/stage.txt` — current canonical phase
- `production/workstreams/*.md` — per-workstream state
- `production/session-state/active.md` — open TODOs + priorities
- `docs/specs/*.md` — paused brainstorm specs
- `docs/migration/adoption-plan-*.md` — historical adoption plans
- `tools/generate_session_context.sh` — outputs PHASE ARTIFACT STATUS at session start

## Failure modes

- ❌ Listing all phase artifacts as plain status — that's `/project-stage-detect`'s job. This skill RECOMMENDS next action.
- ❌ Asking "what do you want to do?" without recommending. Always recommend.
- ❌ Forgetting to read active.md adoption TODOs section.
- ❌ Re-scanning all globs when session-start hook already did it.

---

## Collaborative Protocol

- **Never auto-run the next skill.** Recommend it, let the user invoke it.
- **Ask about MANUAL steps** rather than assuming complete or incomplete.
- **Match the user's tone** — if they sound stressed ("I'm totally lost"), be reassuring and give one action, not a list of six.
- **One primary recommendation** — user should leave knowing exactly one thing to do next.
