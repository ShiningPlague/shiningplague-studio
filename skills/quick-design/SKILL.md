---
name: quick-design
description: "Lightweight design spec for small changes — tuning adjustments, minor mechanics, balance tweaks. Skips full GDD authoring when a system GDD already exists or the change is too small to warrant one. Produces a Quick Design Spec that embeds directly into story files. ShiningPlague-adopted: project paths (data/ not assets/data/, docs/gdd/+master GDD, output to docs/specs/)."
argument-hint: "[brief description of the change]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Project data path (data/ not assets/data/)
    - Project GDD path (docs/gdd/*.md + {{GDD_PATH}} master)
    - Output to docs/quick-specs/YYYY-MM-DD-<topic>-quick-design.md
    - Dock-editable data note (in-engine editor docks)
---

# Quick Design

> 🌱 **ShiningPlague-adopted.** Originally Donchitos; battle-tested on a shipped Godot project. Upstream procedure preserved + project path corrections.

This is the **lightweight design path** for changes that don't need a full GDD. Full GDD authoring via `/design-system` is the heavyweight path. Use this skill for work under approximately 4 hours of implementation — tuning adjustments, minor behavioral tweaks, small additions to existing systems, or standalone features too small to warrant a full document.

**Output:** `docs/quick-specs/YYYY-MM-DD-<topic>-quick-design.md` (project path) — formerly `design/quick-specs/`

**When to run:** Anytime a change is too small for `/design-system` but too meaningful to implement without a written rationale.

## Project Paths

| Donchitos vanilla path | Project path |
|---|---|
| `design/gdd/` | `docs/gdd/*.md` + `{{GDD_PATH}}` (master, e.g. `docs/GDD.md`) |
| `design/gdd/systems-index.md` | `design/gdd/systems-index.md` (correct) |
| `assets/data/` | `data/` |
| `design/quick-specs/` | `docs/quick-specs/YYYY-MM-DD-<topic>-quick-design.md` (auto-indexed via `tools/generate_quick_specs_index.py` hook) |

## Project Context

- Data files at `data/` may be dock-editable via in-engine editor docks (if the project has them)
- Quick designs embed directly into story files when using the large path
- For the small path, they go to `docs/specs/` with the standard naming convention

---

## 1. Classify the Change

Read the argument and determine category:

- **Tuning** — changing numbers or balance values in an existing system with no behavioral change. Example: "increase jump height from 5 to 6 units."
- **Tweak** — small behavioral change to existing system, no new states/branches/systems. Example: "make dash invincible on frame 1."
- **Addition** — adding a small mechanic that may introduce 1-2 new states or interactions. Example: "add a parry window to block."
- **New Small System** — standalone feature small enough to have no GDD and under approximately one week of implementation. Example: "achievement popup system."

If change doesn't fit — introduces new system with significant cross-system dependencies, > one week implementation, or fundamentally alters core rules — stop and redirect to `/design-system`.

Present classification, confirm before proceeding. If no argument, ask user to describe.

---

## 2. Context Scan

Before drafting:

- Search `docs/gdd/` and `{{GDD_PATH}}` for the GDD section relevant to this change. Read affected sections.
- Check `design/gdd/systems-index.md` (if exists) to understand where this system sits in dependency graph.
- Check prior `docs/specs/*-quick-design.md` files for any that touched this system.
- For Tuning changes, check `data/` for the data file holding relevant values.

Report findings: "Found GDD at [path]. Relevant section: [section]. No conflicting quick specs found."

---

## 3. Draft the Quick Design Spec

### For Tuning changes

```markdown
# Quick Design Spec: [Title]

**Type**: Tuning
**System**: [System name]
**GDD Reference**: `docs/gdd/[filename].md` (or `{{GDD_PATH}} §[section]`) — Tuning Knobs section
**Date**: [today]

## Change

| Parameter | Old Value | New Value | Rationale |
|-----------|-----------|-----------|-----------|
| [param]   | [old]     | [new]     | [why]     |

## Tuning Knob Mapping

Maps to GDD Tuning Knob: [knob name and its documented range].
New value is [within / at the edge of / outside] the documented range.

## Acceptance Criteria

- [ ] [Parameter] reads [new value] from `data/[file]`
- [ ] Behavior difference observable in [specific context]
- [ ] No regression in [related behavior]
```

### For Tweak and Addition changes

```markdown
# Quick Design Spec: [Title]

**Type**: [Tweak / Addition]
**System**: [System name]
**GDD Reference**: `docs/gdd/[filename].md` or `{{GDD_PATH}} §[section]`
**Date**: [today]

## Change Summary

[1-2 sentences describing what changes and why.]

## Motivation

[Why is this change needed? What player experience problem does it solve?
Reference the relevant MDA aesthetic or player feedback if applicable.]

## Design Delta

Current GDD says (quoting):

> [exact quote of the relevant rule or description]

This spec changes that to:

[New rule or description, written with the same precision as a GDD Detailed
Rules section. A programmer should be able to implement from this text alone.]

## New Rules / Values

[Full unambiguous statement of the replacement content.]

## Affected Systems

| System | Impact | Action Required |
|--------|--------|-----------------|
| [system] | [how affected] | [update GDD / update data file / no action] |

## Acceptance Criteria

- [ ] [Specific, testable criterion 1]
- [ ] [Specific, testable criterion 2]
- [ ] [Specific, testable criterion 3]
- [ ] No regression: [the original behavior this must not break]

## GDD Update Required?

[Yes / No]
[If yes: which file, which section, and what the update should say.]
```

### For New Small System changes

Use a trimmed GDD structure. Include only sections directly necessary — skip Player Fantasy, full Formulas, and Edge Cases unless system specifically requires them.

```markdown
# Quick Design Spec: [Title]

**Type**: New Small System
**Scope**: [1-2 sentence description]
**Date**: [today]
**Estimated Implementation**: [hours]

## Overview

[One paragraph a new team member could understand.]

## Core Rules

[Unambiguous rules. Numbered lists for sequential behavior, bullet lists for conditions. Precise enough that programmer implements without questions.]

## Tuning Knobs

| Knob | Default | Range | Category | Rationale |
|------|---------|-------|----------|-----------|
| [name] | [value] | [min–max] | [feel/curve/gate] | [why this default] |

All values must live in `data/[appropriate-file].json`, not hardcoded.

## Acceptance Criteria

- [ ] [Functional criterion: does the right thing]
- [ ] [Functional criterion: handles edge case]
- [ ] [Experiential criterion: feels right]
- [ ] [Regression criterion: doesn't break adjacent system]

## Systems Index

This system is not currently in `design/gdd/systems-index.md`.
[If it should be added: suggest layer and priority tier.]
[If too small: state "Below systems-index tracking threshold — quick spec sufficient."]
```

---

## 4. Approval and Filing

Present draft in full. Ask:

"May I write this Quick Design Spec to `docs/specs/[YYYY-MM-DD]-[kebab-case-title]-quick-design.md`?"

Use today's date in filename. Title = kebab-case description.

If yes, write the file.

If a GDD update is required, ask separately after writing the quick spec:

"This spec modifies rules in [System Name]. May I update `docs/gdd/[filename].md` — specifically the [section name] section?"

Show exact text changed (old vs new) before asking. Don't make GDD edits without explicit approval.

---

## 5. Handoff

```
Quick Design Spec written to: docs/specs/[filename].md
Type: [Tuning / Tweak / Addition / New Small System]
System: [system name]
GDD update: [Required — pending approval / Applied / Not required]

Next step: This spec is ready for `/story-readiness` validation before
implementation. Reference this spec in the story's GDD Reference field.
```

### Pipeline Notes

Verdict: **COMPLETE** — quick design spec written and ready for implementation.

Quick Design Specs **bypass** `/design-review` and `/review-all-gdds` by design. For small, low-risk, well-scoped changes where full review pipeline cost > change risk.

Redirect to full pipeline if:
- Change adds new system belonging in systems index
- Change significantly alters cross-system behavior or contracts
- Change introduces new player-facing mechanics affecting MDA balance
- Implementation likely > one week

In those cases: "This change has grown beyond quick-spec scope. I recommend `/design-system` to author a full GDD."

---

## Recommended Next Steps

- Run `/story-readiness [story-path]` to validate the story before implementation — reference this spec in the story's GDD Reference field
- Run `/dev-story [story-path]` to implement once the story passes readiness
- If change is larger than expected, run `/design-system [system-name]` to author a full GDD instead
