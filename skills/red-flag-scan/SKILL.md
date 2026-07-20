---
name: red-flag-scan
description: "Use BEFORE /session-close (Step 0 — co-fires with /goal-check) OR on demand when designer asks 'any red flags', 'self-check', 'sanity check', 'what's wrong'. Scans for uncommitted work, doc drift, complexity buildup, broken hooks, technical debt accumulation, framework inconsistencies. Surfaces with severity verdicts."
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
metadata:
  origin: ShiningPlague
  adopted_by: ShiningPlague
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as session-close orchestrator
    - Dispatches canonical audit skills (code-review, review-all-gdds, architecture-review, consistency-check) — does not duplicate
    - Framework-specific drift scans (complexity, hooks, technical-debt, framework inconsistency)
    - Severity verdicts (GREEN/YELLOW/ORANGE/RED) with gate behavior on RED
    - Pairs with /goal-check at Step 0 of /session-close
---

# Red Flag Scan — Self-Check Audit Orchestrator

> 🌱 **ShiningPlague-authored.** No upstream version exists. Session-close orchestrator that dispatches canonical audit skills based on session change kind.

**This is an ORCHESTRATOR.** It does NOT duplicate logic from existing canonical skills — it dispatches them based on what changed in the session, then aggregates results. Existing canonical skills do the deep work; this skill is the conductor.

## Orchestration logic

Based on what changed in the session (detected via `git diff`), dispatch the right canonical skill:

| Session change | Fire this canonical skill | Output goes to |
|---|---|---|
| Any source-code change (`src/**/*.gd`) | `/code-review` | Code review report |
| GDD modified (`docs/GDD*.md`, `design/gdd/*.md`) | `/review-all-gdds` | Cross-GDD review report |
| ADR added or arch changed (`docs/adr/*.md`, `docs/architecture/*.md`) | `/architecture-review` | Architecture review report |
| Any doc stack change (>3 docs touched) | `/consistency-check` | 49-check audit report |
| Any work-completion claim mid-session | `/verification-before-completion` (likely already fired) | Verification evidence |
| Always: framework-specific drift (complexity, hooks, broken skills) | THIS skill's own scan (Steps 3-6 below) | Drift report |

**Do not duplicate** the canonical skills' procedures. Just call them, collect outputs.

---

# Red Flag Scan — Self-Check Audit (procedure)

Broad audit for issues NOT necessarily tied to specific goals. Complements `/goal-check` (which is goal-evidence verification). This skill catches **systemic / architectural / drift** concerns by orchestrating canonical audit skills + adding framework-specific drift checks they don't cover.

## When to fire

- **Mandatory** as part of `/session-close` Step 0 (alongside `/goal-check`)
- Designer asks: "red flags", "self-check", "sanity check", "what's wrong", "anything concerning"
- After major framework changes (5+ commits in session) before commit chain

## Procedure

### Step 1: Uncommitted-work scan

```bash
git status --short
```

- Modified files not committed: flag if >5 OR if any look critical (CLAUDE.md, settings.json, autoloads)
- Untracked files: flag if any look like work-in-progress (specs, plans, GDDs)
- (Cross-session dirty-file tracking is intentionally out of scope — it would require session state that doesn't persist. Add it only if the project ships session-state persistence.)

### Step 2: Doc stack drift scan

- Run `python tools/consistency_check.py` (if not already this session)
- 49+ cross-doc checks
- Flag: any WARN/FAIL not from prior known-acceptable list
- Flag: registry coverage failures (autoloads/addons/data dirs without entries)
- Flag: stale `last_full_audit` date (>7 days)

### Step 3: Complexity drift scan

- Count: total project-local skills at `.claude/skills/` — flag if >50 (current threshold)
- Count: top-level docs at `docs/` — flag if >25 (current threshold)
- Count: orthogonal state axes (project phase + workstream phase + workstream category + sprint type + META phase) — flag if >5
- Count: CLAUDE.md line count — flag if >450
- **Conceptual cognitive load:** any framework dimension that requires reading >2 docs to understand = flag

### Step 4: Broken hooks / skills scan

- For each hook in `.claude/settings.json` hooks section: check the script file exists at `.claude/hooks/`
- For each project-local skill at `.claude/skills/<name>/SKILL.md`: verify frontmatter is valid YAML
- Flag any missing hook scripts or malformed skill frontmatter

### Step 5: Technical debt accumulation

- Grep for TODO/FIXME in `src/` — flag if total count >10 (absolute threshold — delta-based thresholds like "increased since last session" would require cross-session state that doesn't exist)
- Open bugs in `production/qa/bugs/` — flag if count >5 or any older than 14 days
- Open flags in `docs/open-flags.md` — flag if critical >0
- Unresolved issues in `active-goals.json → unresolved_issues[]` with status: OPEN — flag count

### Step 6: Framework inconsistency scan

- adoption-plan TODOs open vs claimed-phase mismatch
- stage.txt vs actual artifact completeness (use /project-stage-detect output)
- workstream phase vs project canonical phase orthogonality intact?
- Sprint backlog vs adoption TODOs vs paused brainstorm items: any duplication, contradiction, or orphaned items?

### Step 7: Severity verdict per flag

For each flag raised:
- 🟢 **OK** — within thresholds, no action
- 🟡 **WATCH** — approaching threshold, monitor, no immediate action
- 🟠 **CONCERN** — needs attention this week
- 🔴 **CRITICAL** — needs attention before close

### Step 8: Output report

```
## Red Flag Scan — YYYY-MM-DD

### 1. Uncommitted work
[severity]: [count/details]

### 2. Doc stack drift
[severity]: [count/details]

### 3. Complexity drift
[severity]: [specific metrics]
  - Skills count: N (threshold 50)
  - CLAUDE.md lines: N (threshold 450)
  - Orthogonal state axes: N (threshold 5)
  - ...

### 4. Broken hooks/skills
[severity]: [count/details]

### 5. Technical debt
[severity]: [bugs/TODOs/flags]

### 6. Framework inconsistency
[severity]: [count/details]

### Aggregate verdict
🟢 GREEN / 🟡 YELLOW (N watch items) / 🟠 ORANGE (N concerns) / 🔴 RED (N critical)

### If RED: PAUSE close. Critical items to address:
1. [item] — [why]
2. ...

### If ORANGE: continue close but log all CONCERN items to active.md for next-session resolution

### If YELLOW: continue close, monitor watch items
```

### Step 9: Update active.md

Append any ORANGE/RED items to active.md `🚨 OPEN ADOPTION PLAN TODOs` section (or create new `🚨 RED FLAGS` section) with structured handoff format.

## Cross-skill awareness

- /session-close Step 0: fires this skill AFTER /goal-check. Both must return GREEN/YELLOW for close to continue.
- /goal-check focuses on goal evidence; this skill focuses on systemic health.
- Could chain to /consistency-check for detailed cross-doc audit if Step 2 flags WARN.

## Failure modes

- ❌ Marking everything OK without actually checking — verification = command/file output, not assertion
- ❌ Skipping Step 3 (complexity drift) because "the project is fine" — complexity buildup is invisible to anyone inside it
- ❌ Letting RED close proceed — gate exists for a reason

## Thresholds

Tunable. If thresholds feel wrong, designer adjusts in this SKILL.md:
- Skills: >50 = complexity warn
- CLAUDE.md: >450 lines = bloat warn
- Top-level docs: >25 = sprawl warn
- Orthogonal state axes: >5 = cognitive overload warn
- Uncommitted file count: >5 modified = checkpoint warn
- Bug age: >14 days = stale warn
- Last full audit: >7 days = drift warn
