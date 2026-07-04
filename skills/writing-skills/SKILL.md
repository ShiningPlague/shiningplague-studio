---
name: writing-skills
description: "Use when creating new skills, editing existing skills, or verifying skills work before deployment. ShiningPlague-adopted (Sons of Gilgamesh): adds SoG-specific paths (.claude/skills/<name>/SKILL.md), the actual rationalisations observed in the 2026-04-30 discipline-drift session, and a red-flag self-check before any SKILL.md tool call."
metadata:
  origin: obra/superpowers
  origin_url: https://github.com/obra/superpowers
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/writing-skills/SKILL.md
  superpowers_namespace_fallback: /superpowers:writing-skills (auto-preserved via plugin)
  enhancements:
    - SoG path conventions (.claude/skills/<name>/SKILL.md per project)
    - User-level SoG skill catalogue (see docs/skills-index.md for the live list)
    - Verbatim rationalisations from observed 2026-04-30 drift session
    - Pre-tool self-check (3 questions) before any SKILL.md Write/Edit
    - Red-flag list with project-specific triggers
    - Cross-link to .claude/hooks/pretool-skill-gate.sh (mechanical reminder hook)
    - Three-layer enforcement model (UserPromptSubmit hook + PreToolUse hook + this skill)
---

# Writing Skills

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally obra/superpowers. Sons of Gilgamesh project adopted and enhanced. Upstream TDD-for-process-docs philosophy preserved + SoG-specific pre-tool self-check + drift-rationalisation table layered on. Vanilla backup: `docs/vanilla-backups/2026-05-15/writing-skills/`. Plugin-namespace fallback `/superpowers:writing-skills` fires upstream version untouched.

## Overview

**Writing skills IS Test-Driven Development applied to process documentation.**

**In Sons of Gilgamesh, studio skills live PROJECT-LOCAL at `.claude/skills/<name>/SKILL.md`** — repo-canonical since the 2026-07-04 two-home separation ruling. User level (`~/.claude/skills/`) holds ONLY personal skills. **NEVER create a user-level twin of a project skill:** Anthropic precedence is user > project, so a user-level twin silently shadows the project version (the 2026-05-15 shadow bug — the two-home model keeps the sets disjoint so it cannot recur). See project CLAUDE.md for adoption history.

You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill. That skill defines the fundamental RED-GREEN-REFACTOR cycle. This skill adapts TDD to documentation.

**Official guidance:** For Anthropic's official skill authoring best practices, see anthropic-best-practices.md. This document provides additional patterns and guidelines that complement the TDD-focused approach in this skill.

---

## Sons of Gilgamesh — Pre-Write/Edit self-check (MANDATORY before tool call)

Before ANY `Write` or `Edit` tool call where `file_path` matches `.claude/skills/<name>/SKILL.md`:

1. **Did `/writing-skills` fire this turn?** If no → fire it FIRST, then proceed.
2. **What's the failing test?** What real-world behaviour are you scripting against?
3. **Does the change need a project-local override or upstream fix?** Project-local wins for SoG paths/conventions; upstream fix is for general patterns.

If any answer is unclear, STOP and resolve before tool call.

### SoG-specific paths

SoG-customised studio SKILLs live PROJECT-LOCAL at `.claude/skills/<name>/SKILL.md` (repo-canonical since 2026-07-04) — see `docs/skills-index.md` for the live catalogue (bulk adopted from Donchitos + obra/superpowers; see `docs/vanilla-backups/2026-05-15/` for originals). Personal skills stay user-level (`~/.claude/skills/`).

Selection of high-traffic overrides:

| Skill | Override reason |
|---|---|
| `brainstorming` | SoG spec paths (`docs/specs/`) + outcome-first framing + per-Q appendix + 5-mode framework |
| `consistency-check` | Reads `system_registry.json` not Donchitos's `entities.yaml` |
| `verification-before-completion` | Concrete SoG verification commands (`tools/<step>_check.gd`) |
| `regression-suite` | SoG headless harness pattern + capture-as-test |
| `update` | SoG `/update` procedure (devlog + dev_diary + registry + push prompt) |
| `writing-skills` | THIS FILE — SoG-specific self-check + drift rationalisations |

**Each override declares what it changes from upstream** via the `metadata` block + adoption banner.

### Rationalisations observed in 2026-04-30 discipline drift

Three slips happened in one session. Each had a verbatim internal rationalisation:

| Excuse used 2026-04-30 | Reality |
|---|---|
| "I already know SKILL.md conventions from earlier in this session" | Conventions != current task. Fire the skill anyway. The fire takes <1 second. |
| "It's just a small edit" | A "small edit" can produce 100+ inserted lines. Fire the skill. |
| "The hook's 🟢 propose is advisory" | CLAUDE.md says auto-fires when editing SKILL.md. The hook's 🟢 is the *trigger announcement*; the rule itself is 🔒. Fire. |
| "I fired it once this turn already" | Each new SKILL.md authoring is a new commitment to TDD-for-skills. Fire each time. |
| "Inline-rewriting a skill while we're discussing it doesn't count as authoring" | If `Write` or `Edit` targets a SKILL.md path, it counts. Fire. |

If you find yourself thinking ANY of the above before a SKILL.md edit: STOP. Fire `/writing-skills`. Then proceed.

### Red flags — STOP and fire skill

Before any `Write` or `Edit` tool call:

- File path contains `.claude/skills/` AND ends in `SKILL.md`
- About to author a "small section" addition to an existing SKILL.md
- About to rewrite a SKILL.md that was already authored this session
- About to create a new project-local override
- The hook fired `[skill-trigger 🔒 MANDATORY]` for writing-skills authoring this turn

**All of these mean: fire `/writing-skills` first, then edit.**

### Mechanical enforcement (added 2026-04-30)

This SKILL is one layer of three:

1. **UserPromptSubmit hook** (`.claude/hooks/skill-trigger-detect.sh`) fires keyword detection on user prose. When designer mentions skill authoring, injects a 🔒 MANDATORY reminder.
2. **PreToolUse hook** (`.claude/hooks/pretool-skill-gate.sh`) fires on every `Write` / `Edit` tool call. When file_path matches SKILL.md, injects a loud reminder via `additionalContext`. Cannot block (stateless), but cannot be missed either.
3. **THIS SKILL** (project-local override) — provides the rationalisation-resistant content when the skill fires.

If today taught anything: softer reminders get walked past. Three layers means three independent points of failure required for drift. Less likely.

### When NOT to fire writing-skills

- Reading a SKILL.md (Read tool, no Write/Edit) — no fire needed
- Discussing skills in chat without authoring — no fire needed
- Reorganising files that aren't SKILL.md (e.g. moving templates) — no fire needed
- Editing CLAUDE.md sections that mention skills — no fire needed (CLAUDE.md is project instructions, not a SKILL.md)

The trigger is specifically: about to `Write` or `Edit` with `file_path` ending in `.claude/skills/<name>/SKILL.md`.

---

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future Claude instances find and apply effective approaches.

**Skills are:** Reusable techniques, patterns, tools, reference guides

**Skills are NOT:** Narratives about how you solved a problem once

## TDD Mapping for Skills

| TDD Concept | Skill Creation |
|-------------|----------------|
| **Test case** | Pressure scenario with subagent |
| **Production code** | Skill document (SKILL.md) |
| **Test fails (RED)** | Agent violates rule without skill (baseline) |
| **Test passes (GREEN)** | Agent complies with skill present |
| **Refactor** | Close loopholes while maintaining compliance |
| **Write test first** | Run baseline scenario BEFORE writing skill |
| **Watch it fail** | Document exact rationalizations agent uses |
| **Minimal code** | Write skill addressing those specific violations |
| **Watch it pass** | Verify agent now complies |
| **Refactor cycle** | Find new rationalizations → plug → re-verify |

The entire skill creation process follows RED-GREEN-REFACTOR.

## When to Create a Skill

**Create when:**
- Technique wasn't intuitively obvious to you
- You'd reference this again across projects
- Pattern applies broadly (not project-specific)
- Others would benefit

**Don't create for:**
- One-off solutions
- Standard practices well-documented elsewhere
- Project-specific conventions (put in CLAUDE.md)
- Mechanical constraints (if it's enforceable with regex/validation, automate it—save documentation for judgment calls)

## Skill Types

### Technique
Concrete method with steps to follow (condition-based-waiting, root-cause-tracing)

### Pattern
Way of thinking about problems (flatten-with-flags, test-invariants)

### Reference
API docs, syntax guides, tool documentation (office docs)

## Directory Structure

```
skills/
  skill-name/
    SKILL.md              # Main reference (required)
    supporting-file.*     # Only if needed
```

**Flat namespace** - all skills in one searchable namespace

**Separate files for:**
1. **Heavy reference** (100+ lines) - API docs, comprehensive syntax
2. **Reusable tools** - Scripts, utilities, templates

**Keep inline:**
- Principles and concepts
- Code patterns (< 50 lines)
- Everything else

## SKILL.md Structure

**Frontmatter (YAML):**
- Two required fields: `name` and `description` (see [agentskills.io/specification](https://agentskills.io/specification) for all supported fields)
- Max 1024 characters total
- `name`: Use letters, numbers, and hyphens only (no parentheses, special chars)
- `description`: Third-person, describes ONLY when to use (NOT what it does)
  - Start with "Use when..." to focus on triggering conditions
  - Include specific symptoms, situations, and contexts
  - **NEVER summarize the skill's process or workflow** (see CSO section for why)
  - Keep under 500 characters if possible

```markdown
---
name: Skill-Name-With-Hyphens
description: Use when [specific triggering conditions and symptoms]
---

# Skill Name

## Overview
What is this? Core principle in 1-2 sentences.

## When to Use
[Small inline flowchart IF decision non-obvious]

Bullet list with SYMPTOMS and use cases
When NOT to use

## Core Pattern (for techniques/patterns)
Before/after code comparison

## Quick Reference
Table or bullets for scanning common operations

## Implementation
Inline code for simple patterns
Link to file for heavy reference or reusable tools

## Common Mistakes
What goes wrong + fixes

## Real-World Impact (optional)
Concrete results
```

## Claude Search Optimization (CSO)

**Critical for discovery:** Future Claude needs to FIND your skill

### 1. Rich Description Field

**Purpose:** Claude reads description to decide which skills to load for a given task. Make it answer: "Should I read this skill right now?"

**Format:** Start with "Use when..." to focus on triggering conditions

**CRITICAL: Description = When to Use, NOT What the Skill Does**

The description should ONLY describe triggering conditions. Do NOT summarize the skill's process or workflow in the description.

**Why this matters:** Testing revealed that when a description summarizes the skill's workflow, Claude may follow the description instead of reading the full skill content. A description saying "code review between tasks" caused Claude to do ONE review, even though the skill's flowchart clearly showed TWO reviews (spec compliance then code quality).

When the description was changed to just "Use when executing implementation plans with independent tasks" (no workflow summary), Claude correctly read the flowchart and followed the two-stage review process.

**The trap:** Descriptions that summarize workflow create a shortcut Claude will take. The skill body becomes documentation Claude skips.

```yaml
# ❌ BAD: Summarizes workflow - Claude may follow this instead of reading skill
description: Use when executing plans - dispatches subagent per task with code review between tasks

# ❌ BAD: Too much process detail
description: Use for TDD - write test first, watch it fail, write minimal code, refactor

# ✅ GOOD: Just triggering conditions, no workflow summary
description: Use when executing implementation plans with independent tasks in the current session

# ✅ GOOD: Triggering conditions only
description: Use when implementing any feature or bugfix, before writing implementation code
```

**Content:**
- Use concrete triggers, symptoms, and situations that signal this skill applies
- Describe the *problem* (race conditions, inconsistent behavior) not *language-specific symptoms* (setTimeout, sleep)
- Keep triggers technology-agnostic unless the skill itself is technology-specific
- If skill is technology-specific, make that explicit in the trigger
- Write in third person (injected into system prompt)
- **NEVER summarize the skill's process or workflow**

### 2. Keyword Coverage

Use words Claude would search for:
- Error messages: "Hook timed out", "ENOTEMPTY", "race condition"
- Symptoms: "flaky", "hanging", "zombie", "pollution"
- Synonyms: "timeout/hang/freeze", "cleanup/teardown/afterEach"
- Tools: Actual commands, library names, file types

### 3. Descriptive Naming

**Use active voice, verb-first:**
- ✅ `creating-skills` not `skill-creation`
- ✅ `condition-based-waiting` not `async-test-helpers`

### 4. Token Efficiency (Critical)

**Problem:** getting-started and frequently-referenced skills load into EVERY conversation. Every token counts.

**Target word counts:**
- getting-started workflows: <150 words each
- Frequently-loaded skills: <200 words total
- Other skills: <500 words (still be concise)

**Techniques:**

**Move details to tool help:**
```bash
# ❌ BAD: Document all flags in SKILL.md
search-conversations supports --text, --both, --after DATE, --before DATE, --limit N

# ✅ GOOD: Reference --help
search-conversations supports multiple modes and filters. Run --help for details.
```

**Use cross-references:**
```markdown
# ❌ BAD: Repeat workflow details
When searching, dispatch subagent with template...
[20 lines of repeated instructions]

# ✅ GOOD: Reference other skill
Always use subagents (50-100x context savings). REQUIRED: Use [other-skill-name] for workflow.
```

**Verification:**
```bash
wc -w skills/path/SKILL.md
# getting-started workflows: aim for <150 each
# Other frequently-loaded: aim for <200 total
```

### Cross-Referencing Other Skills

**When writing documentation that references other skills:**

Use skill name only, with explicit requirement markers:
- ✅ Good: `**REQUIRED SUB-SKILL:** Use superpowers:test-driven-development`
- ✅ Good: `**REQUIRED BACKGROUND:** You MUST understand superpowers:systematic-debugging`
- ❌ Bad: `See skills/testing/test-driven-development` (unclear if required)
- ❌ Bad: `@skills/testing/test-driven-development/SKILL.md` (force-loads, burns context)

**Why no @ links:** `@` syntax force-loads files immediately, consuming 200k+ context before you need them.

## The Iron Law (Same as TDD)

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

This applies to NEW skills AND EDITS to existing skills.

Write skill before testing? Delete it. Start over.
Edit skill without testing? Same violation.

**No exceptions:**
- Not for "simple additions"
- Not for "just adding a section"
- Not for "documentation updates"
- Don't keep untested changes as "reference"
- Don't "adapt" while running tests
- Delete means delete

**REQUIRED BACKGROUND:** The superpowers:test-driven-development skill explains why this matters. Same principles apply to documentation.

## Testing All Skill Types

Different skill types need different test approaches:

### Discipline-Enforcing Skills (rules/requirements)

**Examples:** TDD, verification-before-completion, designing-before-coding

**Test with:**
- Academic questions: Do they understand the rules?
- Pressure scenarios: Do they comply under stress?
- Multiple pressures combined: time + sunk cost + exhaustion
- Identify rationalizations and add explicit counters

**Success criteria:** Agent follows rule under maximum pressure

### Technique Skills (how-to guides)

**Examples:** condition-based-waiting, root-cause-tracing, defensive-programming

**Test with:**
- Application scenarios: Can they apply the technique correctly?
- Variation scenarios: Do they handle edge cases?
- Missing information tests: Do instructions have gaps?

**Success criteria:** Agent successfully applies technique to new scenario

### Pattern Skills (mental models)

**Examples:** reducing-complexity, information-hiding concepts

**Test with:**
- Recognition scenarios: Do they recognize when pattern applies?
- Application scenarios: Can they use the mental model?
- Counter-examples: Do they know when NOT to apply?

**Success criteria:** Agent correctly identifies when/how to apply pattern

### Reference Skills (documentation/APIs)

**Examples:** API documentation, command references, library guides

**Test with:**
- Retrieval scenarios: Can they find the right information?
- Application scenarios: Can they use what they found correctly?
- Gap testing: Are common use cases covered?

**Success criteria:** Agent finds and correctly applies reference information

## Common Rationalizations for Skipping Testing

| Excuse | Reality |
|--------|---------|
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
| "It's just a reference" | References can have gaps, unclear sections. Test retrieval. |
| "Testing is overkill" | Untested skills have issues. Always. 15 min testing saves hours. |
| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying. |
| "Too tedious to test" | Testing is less tedious than debugging bad skill in production. |
| "I'm confident it's good" | Overconfidence guarantees issues. Test anyway. |
| "Academic review is enough" | Reading ≠ using. Test application scenarios. |
| "No time to test" | Deploying untested skill wastes more time fixing it later. |

**All of these mean: Test before deploying. No exceptions.**

## Bulletproofing Skills Against Rationalization

Skills that enforce discipline (like TDD) need to resist rationalization. Agents are smart and will find loopholes when under pressure.

**Psychology note:** Understanding WHY persuasion techniques work helps you apply them systematically. See persuasion-principles.md for research foundation (Cialdini, 2021; Meincke et al., 2025) on authority, commitment, scarcity, social proof, and unity principles.

### Close Every Loophole Explicitly

Don't just state the rule - forbid specific workarounds.

### Address "Spirit vs Letter" Arguments

Add foundational principle early: **Violating the letter of the rules is violating the spirit of the rules.**

This cuts off entire class of "I'm following the spirit" rationalizations.

### Build Rationalization Table

Capture rationalizations from baseline testing. Every excuse agents make goes in the table.

### Create Red Flags List

Make it easy for agents to self-check when rationalizing.

### Update CSO for Violation Symptoms

Add to description: symptoms of when you're ABOUT to violate the rule.

## RED-GREEN-REFACTOR for Skills

Follow the TDD cycle:

### RED: Write Failing Test (Baseline)

Run pressure scenario with subagent WITHOUT the skill. Document exact behavior:
- What choices did they make?
- What rationalizations did they use (verbatim)?
- Which pressures triggered violations?

This is "watch the test fail" - you must see what agents naturally do before writing the skill.

### GREEN: Write Minimal Skill

Write skill that addresses those specific rationalizations. Don't add extra content for hypothetical cases.

Run same scenarios WITH skill. Agent should now comply.

### REFACTOR: Close Loopholes

Agent found new rationalization? Add explicit counter. Re-test until bulletproof.

**Testing methodology:** See @testing-skills-with-subagents.md for the complete testing methodology.

## Anti-Patterns

### ❌ Narrative Example
"In session 2025-10-03, we found empty projectDir caused..."
**Why bad:** Too specific, not reusable

### ❌ Multi-Language Dilution
example-js.js, example-py.py, example-go.go
**Why bad:** Mediocre quality, maintenance burden

### ❌ Code in Flowcharts
**Why bad:** Can't copy-paste, hard to read

### ❌ Generic Labels
helper1, helper2, step3, pattern4
**Why bad:** Labels should have semantic meaning

## STOP: Before Moving to Next Skill

**After writing ANY skill, you MUST STOP and complete the deployment process.**

**Do NOT:**
- Create multiple skills in batch without testing each
- Move to next skill before current one is verified
- Skip testing because "batching is more efficient"

**The deployment checklist below is MANDATORY for EACH skill.**

Deploying untested skills = deploying untested code. It's a violation of quality standards.

## Skill Creation Checklist (TDD Adapted)

**IMPORTANT: Use TodoWrite to create todos for EACH checklist item below.**

**RED Phase - Write Failing Test:**
- [ ] Create pressure scenarios (3+ combined pressures for discipline skills)
- [ ] Run scenarios WITHOUT skill - document baseline behavior verbatim
- [ ] Identify patterns in rationalizations/failures

**GREEN Phase - Write Minimal Skill:**
- [ ] Name uses only letters, numbers, hyphens (no parentheses/special chars)
- [ ] YAML frontmatter with required `name` and `description` fields (max 1024 chars; see [spec](https://agentskills.io/specification))
- [ ] Description starts with "Use when..." and includes specific triggers/symptoms
- [ ] Description written in third person
- [ ] Keywords throughout for search (errors, symptoms, tools)
- [ ] Clear overview with core principle
- [ ] Address specific baseline failures identified in RED
- [ ] Code inline OR link to separate file
- [ ] One excellent example (not multi-language)
- [ ] Run scenarios WITH skill - verify agents now comply

**REFACTOR Phase - Close Loopholes:**
- [ ] Identify NEW rationalizations from testing
- [ ] Add explicit counters (if discipline skill)
- [ ] Build rationalization table from all test iterations
- [ ] Create red flags list
- [ ] Re-test until bulletproof

**Quality Checks:**
- [ ] Small flowchart only if decision non-obvious
- [ ] Quick reference table
- [ ] Common mistakes section
- [ ] No narrative storytelling
- [ ] Supporting files only for tools or heavy reference

**Deployment:**
- [ ] Commit skill to git and push to your fork (if configured)
- [ ] Consider contributing back via PR (if broadly useful)

## Discovery Workflow

How future Claude finds your skill:

1. **Encounters problem** ("tests are flaky")
2. **Finds SKILL** (description matches)
3. **Scans overview** (is this relevant?)
4. **Reads patterns** (quick reference table)
5. **Loads example** (only when implementing)

**Optimize for this flow** - put searchable terms early and often.

## The Bottom Line

**Creating skills IS TDD for process documentation.**

Same Iron Law: No skill without failing test first.
Same cycle: RED (baseline) → GREEN (write skill) → REFACTOR (close loopholes).
Same benefits: Better quality, fewer surprises, bulletproof results.

If you follow TDD for code, follow it for skills. It's the same discipline applied to documentation.
