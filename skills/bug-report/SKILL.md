---
name: bug-report
description: Use when filing a bug found mid-session ('file a bug', 'log this bug', 'that's broken — track it'), when a routine finding needs manual promotion, or when verifying/closing an existing BUG-NNN after a fix ('/bug-report verify BUG-003', '/bug-report close BUG-003'). Not for triage/prioritisation — that's /bug-triage.
metadata:
  origin: ShiningPlague-authored
  replaces: Donchitos pointer stub
  format_source: tools/promote_findings_to_bugs.py output shape (must stay compatible)
---

# Bug Report

> 🌱 **ShiningPlague-authored.** Replaces the original Donchitos pointer stub — this is the real implementation, format-compatible with the auto-promotion pipeline (`tools/promote_findings_to_bugs.py`).

## Overview

Files, verifies, and closes formal bugs at `production/qa/bugs/BUG-NNN-<slug>.md`. One file per bug. Same format whether filed manually (this skill) or auto-promoted from routine findings (`tools/promote_findings_to_bugs.py`) — downstream tooling (`/bug-triage`, `/sprint-plan`) must not care which path created it.

## Mode 1 — File (default)

1. **Next ID:** `ls production/qa/bugs/BUG-*.md` → max NNN + 1, zero-padded to 3.
2. **Severity (impact, not urgency):** S1 crash/data-loss/blocks-all-testing · S2 feature broken, no workaround · S3 feature impaired, workaround exists · S4 cosmetic/polish.
3. **Write the file** — `production/qa/bugs/BUG-NNN-<kebab-slug>.md`:

```markdown
---
id: BUG-NNN
status: TRIAGE-PENDING
severity: S1|S2|S3|S4
priority: TRIAGE-PENDING
source: <designer-report | assistant-observed | skill/routine name>
flagged: YYYY-MM-DD
flagged_at: YYYY-MM-DD HH:MM
auto_promoted: false
---

# BUG-NNN — <One-line title>

## Finding

What is broken, where observed (scene/system/file), repro steps if known,
expected vs actual. Cite evidence (console output, screenshot path, registry
live_test_notes entry) — no evidence, say so explicitly.

## Report

Pointer to fuller context (spec, review doc, devlog date) or "inline — no separate report".

## Triage notes

_Empty — pending /bug-triage run._
```

4. **Close the loop:** mention the new BUG-NNN in the session's devlog/dev_diary entry at /update time. If S1/S2, ALSO surface it to the designer immediately — don't let it sit silent until triage.

## Mode 2 — Verify (`/bug-report verify BUG-NNN`)

After a fix lands. Per `verification-before-completion`: run the actual repro / relevant headless check, cite output in the bug file under a new `## Verification YYYY-MM-DD` section. Evidence before assertions. If verification fails, say so in the file and leave status untouched.

## Mode 3 — Close (`/bug-report close BUG-NNN`)

Only after a passing verify. Set `status: CLOSED`, add `closed: YYYY-MM-DD` to frontmatter, one-line resolution under `## Resolution`. Never close without a Verification section — that's the failure mode this mode exists to block.

## Common mistakes

- Filing bugs in `next_session_priorities` or chat context instead of a BUG file — they evaporate. If it's a real defect, it gets a file.
- Setting priority at filing time — priority is /bug-triage's job (severity is yours).
- Closing on "should be fixed now" — verify mode first, always.
