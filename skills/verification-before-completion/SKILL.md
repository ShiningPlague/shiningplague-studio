---
name: verification-before-completion
description: "Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always. ShiningPlague-adopted: adds concrete per-change-kind verification commands ({{VERIFY_CMD}} pattern, e.g. engine headless harness, JSON parse checks, ship checklist) + banned-phrasing list."
metadata:
  origin: obra/superpowers
  origin_url: https://github.com/obra/superpowers
  adopted_by: ShiningPlague
  enhancements:
    - Concrete verification commands per change-kind ({{VERIFY_CMD}} for code/data/doc/commit/step ship)
    - Project headless harness pattern ({{TEST_HARNESS}}, e.g. godot --headless --script tools/<step>_check.gd)
    - Ship checklist — what "shipped" actually means
    - Banned phrasing list (eyeball-only claims)
    - Designer-action verification clause (when claims can only be verified in-engine)
    - Auto-fire 🔒 MUST-USE trigger expansion (commits, pushes, PRs, TODO marks)
---

# Verification Before Completion

> 🌱 **ShiningPlague-adopted.** Originally obra/superpowers; battle-tested on a shipped Godot project. Iron law preserved + concrete per-change-kind verification commands layered on.

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

## Project adaptation — what "verified" means concretely

For each kind of change, verification has a CONCRETE command/action ({{VERIFY_CMD}}) that must run. Fill these per project; Godot examples shown:

### Code change in `src/`

1. **Parse check** — run the project's parse/compile check {{VERIFY_CMD}} (e.g. Godot: `godot --headless --path . scenes/<entry-scene>.tscn 2>&1 | grep -E "(SCRIPT ERROR|FATAL)"` returns no output)
2. **Relevant harness** — if a {{TEST_HARNESS}} exists for the affected system (e.g. `tools/<step>_<feature>_check.gd`), run it (e.g. `godot --headless --path . --script "res://tools/<harness>.gd"`) and confirm the SUMMARY line shows `N/N PASS`
3. **In-engine smoke test** — designer runs the game and confirms the user-facing behaviour. Only the designer can do this — propose it explicitly when the change affects user-facing behaviour.

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
4. `data/_schemas/dev_diary.json` dated entry has done_major + done_minor
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
| Step shipped | All 7 ship-checklist items checked | Code lands + 1-line "done" |
| Fix shipped | Harness PASS + headless no errors | Vibes-check on diff |

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

**Project harness (Godot example):**
```
✅ godot --headless --script tools/step3_inventory_check.gd → "SUMMARY: 8/8 PASS" → "step shipped"
❌ "Headless looked clean" (where's the SUMMARY line?)
```

---

## Procedure (auto-fired before "done" claim)

1. **Identify the claim.** What am I about to declare complete/shipped/fixed/passing?
2. **Match it to a verification kind** above.
3. **Run the verification command(s).** Do NOT skip and do NOT substitute "I checked" for an actual command.
4. **Read the output.** If the verification fails, the work is not done — go back to the implementation phase.
5. **Only then make the claim.** Reference the verification in the claim: *"Step shipped — `tools/step3_inventory_check.gd` reports 8/8 PASS, headless entry scene loads with no SCRIPT ERROR."*

---

## When verification cannot run

Some claims can't be verified by the assistant — only by the designer in-engine. Examples: "the item icon renders correctly in the inventory grid", "the menu button feels responsive", "the slot animation looks good." For these:

1. State explicitly that verification requires designer action
2. Propose the exact run-and-test steps
3. Do NOT claim the work is verified until designer confirms

Hard-won rule: fixes have shipped with headless verification passing (no script errors + harness N/N PASS) while the user-facing behaviour still required the designer's manual run to confirm. Both layers of verification must apply.

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
