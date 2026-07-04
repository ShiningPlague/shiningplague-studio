---
name: verification-before-completion
description: "Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always. ShiningPlague-adopted (Sons of Gilgamesh): adds concrete project verification commands (godot headless harness, JSON parse checks, T10 ship checklist) + banned-phrasing list."
metadata:
  origin: obra/superpowers
  origin_url: https://github.com/obra/superpowers
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/verification-before-completion/SKILL.md
  superpowers_namespace_fallback: /superpowers:verification-before-completion (auto-preserved via plugin)
  enhancements:
    - Concrete SoG verification commands per change-kind (code/data/doc/commit/step ship)
    - Project-specific headless harness pattern (godot --headless --script tools/<step>_check.gd)
    - T10 ship checklist (7 items) — what "shipped" actually means
    - Banned phrasing list (eyeball-only claims)
    - Designer-action verification clause (when claims can only be verified in-engine)
    - Auto-fire 🔒 MUST-USE trigger expansion (commits, pushes, PRs, TODO marks)
---

# Verification Before Completion

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally obra/superpowers. Sons of Gilgamesh project adopted and enhanced. Iron law preserved + SoG verification commands layered on. Vanilla backup: `docs/vanilla-backups/2026-05-15/verification-before-completion/`. Plugin-namespace fallback `/superpowers:verification-before-completion` fires upstream version untouched.

**🔒 MUST-USE — auto-fire on trigger match, no announce-and-wait.**

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## Triggers (auto-fire)

- About to claim any work is "shipped", "complete", "fixed", "verified", "passing", "working", "done"
- About to create a commit
- About to push
- About to open a PR
- About to mark a step / task / TODO as resolved
- User asks "is it done?" / "did that work?" / "verified?"

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

---

## Sons of Gilgamesh — what "verified" means concretely

For each kind of change in this project, verification has a CONCRETE command/action that must run:

### Code change in `src/`

1. **Parse check** — `godot --headless --path . scenes/<entry-scene>.tscn 2>&1 | grep -E "(SCRIPT ERROR|FATAL)"` returns no output
2. **Relevant harness** — if a `tools/<step>_<feature>_check.gd` exists for the affected system, run it via `godot --headless --path . --script "res://tools/<harness>.gd"` and confirm the SUMMARY line shows `N/N PASS`
3. **In-engine smoke test** — designer presses F5 and confirms the user-facing behaviour. Only the designer can do this — propose it explicitly when the change affects user-facing behaviour.

### Data change in `data/*.json`

1. **JSON parse** — `python -c "import json; json.load(open('<path>', encoding='utf-8'))"` exits 0
2. **Trailing newline** — `tail -c 1 <path>` shows `\n` (project rule per data-files.md)
3. **Schema sanity** — values match the schema in `data/_schemas/`

### Doc change

1. **Cross-doc consistency** — fire `/consistency-check` (project-local) so the change doesn't break alignment with registry / active.md / dev_diary / devlog
2. **No broken links** — file paths referenced in the doc resolve

### Commit

1. **Recent files match the message** — `git diff --stat HEAD~1` shows what the message claims
2. **No accidental staging** — `git status` after commit shows expected state
3. **Push succeeds** — `git push 2>&1 | tail -3` shows the upstream-update line, no rejection

### Step ship (T10-equivalent — 7 items)

1. Spec moved to `docs/z-old/specs/`
2. `system_registry.json → spec_index` updated with state=archived, shipped, archive_path, ship_evidence
3. `next_session_priorities[0]` rotated to next step
4. `data/_schemas/dev_diary.json` 2026-MM-DD entry has done_major + done_minor
5. `docs/devlog.md` top entry written
6. `production/session-state/active.md` header + handoff updated
7. `tools/consistency_check.py` exits 0

If ANY of the above is incomplete, the step is NOT shipped. Do not claim it.

---

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |
| SoG step shipped | All 7 T10 items checked | Code lands + 1-line "done" |
| SoG fix shipped | Harness PASS + headless no SCRIPT ERROR | Vibes-check on diff |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Banned phrasings without verification

- "Verified clean."
- "Tests pass."
- "Working as expected."
- "Should be fine."
- "Looks good."
- "Ship it."

Any of those without a concrete command-output reference = failure.

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |
| "I read the file again" | Reading ≠ running. Run the command. |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

**SoG harness:**
```
✅ godot --headless --script tools/step3a_status_effect_check.gd → "SUMMARY: 8/8 PASS" → "M1 shipped"
❌ "Headless looked clean" (where's the SUMMARY line?)
```

---

## Procedure (auto-fired before "done" claim)

1. **Identify the claim.** What am I about to declare complete/shipped/fixed/passing?
2. **Match it to a verification kind** above.
3. **Run the verification command(s).** Do NOT skip and do NOT substitute "I checked" for an actual command.
4. **Read the output.** If the verification fails, the work is not done — go back to the implementation phase.
5. **Only then make the claim.** Reference the verification in the claim: *"M1 shipped — `tools/step3a_status_effect_check.gd` reports 8/8 PASS, headless `combat_screen.tscn` loads with no SCRIPT ERROR."*

---

## When verification cannot run

Some claims can't be verified by the assistant — only by the designer in-engine. Examples: "the green pill renders correctly under the wolf", "the menu button feels responsive", "the slot animation looks good." For these:

1. State explicitly that verification requires designer action
2. Propose the exact F5-and-test steps
3. Do NOT claim the work is verified until designer confirms

The session's M1/M2 fixes hit this — shipped headless verification (no SCRIPT ERROR + harness 8/8 PASS) but the user-facing behaviour required the designer's manual run (F5). Correct — both layers of verification applied.

---

## What this skill does NOT do

- Replace `systematic-debugging` (which is for diagnosing problems, not certifying solutions)
- Replace `code-review` or `simplify` (which are quality lenses on top, not the verification gate)
- Authorise commits without verification — verification BLOCKS the commit until satisfied

---

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" — trust broken
- Undefined functions shipped — would crash
- Missing requirements shipped — incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
