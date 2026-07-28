<!-- scaffold-seed: unwritten — delete this line once you write real content -->
# Control Manifest

> **Engine**: [engine + version]
> **Last Updated**: [YYYY-MM-DD]
> **Manifest Version**: [YYYY-MM-DD]
> **ADRs Covered**: [ADR-NNNN, ADR-MMMM, …]
> **Status**: Unwritten — run `/create-control-manifest`

**What this is.** The flat rules sheet a programmer reads before touching code:
what you must do, what you must never do, per architectural layer. Where an ADR
explains *why*, this file tells you *what* — and it is the faster read of the two.

**Written by** `/create-control-manifest`, which extracts every rule from the
Accepted ADRs, `.claude/docs/technical-preferences.md` and the engine reference
docs. Re-run it whenever an ADR is accepted or revised; it never invents a rule
that has no source.
**Read by** `/dev-story` (before writing code), `/code-review` (as the checklist),
`/story-readiness` (via the Manifest Version below).

`Manifest Version` is the date this manifest was generated. Story files embed it
when they are created, and `/story-readiness` compares a story's embedded version
to this field to catch stories written against stale rules. It always matches
`Last Updated` — same date, two consumers.

**How to fill it:** run `/create-control-manifest`. Every rule it writes carries
its source in the line — a rule with no `source:` is a rule nobody agreed to.

---

## Foundation Layer Rules

*Applies to: scene management, event architecture, save/load, engine initialisation.*

### Required Patterns
*Every "must / always / required to" from an Accepted ADR's Implementation Guidelines.*
- **[rule]** — source: [ADR-NNNN]

### Forbidden Approaches
*Every alternative an ADR explicitly rejected. The rejection reason becomes the rule.*
- **Never [anti-pattern]** — [why, in one clause] — source: [ADR-NNNN]

### Performance Guardrails
*Budgets from an ADR's Performance Implications section. Numbers, not adjectives.*
- **[system]**: max [N] ms/frame — source: [ADR-NNNN]

---

## Core Layer Rules

*Applies to: the core gameplay loop, main player systems, physics, collision.*

### Required Patterns
- **[rule]** — source: [ADR-NNNN]

### Forbidden Approaches
- **Never [anti-pattern]** — [why] — source: [ADR-NNNN]

### Performance Guardrails
- **[system]**: max [N] ms/frame — source: [ADR-NNNN]

---

## Feature Layer Rules

*Applies to: secondary mechanics, AI systems, secondary features.*

### Required Patterns
- **[rule]** — source: [ADR-NNNN]

### Forbidden Approaches
- **Never [anti-pattern]** — [why] — source: [ADR-NNNN]

---

## Presentation Layer Rules

*Applies to: rendering, audio, UI, VFX, shaders, animations.*

### Required Patterns
- **[rule]** — source: [ADR-NNNN]

### Forbidden Approaches
- **Never [anti-pattern]** — [why] — source: [ADR-NNNN]

---

## Global Rules (All Layers)

### Naming Conventions

*Copied from `.claude/docs/technical-preferences.md`. If it is blank there, decide
it there first — this file is a mirror, not the decision.*

| Element | Convention | Example |
|---|---|---|
| Classes | [convention] | [example] |
| Variables | [convention] | [example] |
| Signals / events | [convention] | [example] |
| Files | [convention] | [example] |
| Constants | [convention] | [example] |

### Performance Budgets

| Target | Value |
|---|---|
| Framerate | [e.g. 60 fps on the minimum spec] |
| Frame budget | [ms] |
| Draw calls | [max per frame] |
| Memory ceiling | [MB] |

### Approved Libraries / Addons

*Anything not on this list needs a decision before it enters the build.*

- [library] — approved for [purpose] — source: [ADR-NNNN or technical-preferences]

### Forbidden APIs ([engine version])

*Deprecated, removed, or unverified against the pinned engine version.*

- `[api name]` — deprecated since [version] / unverified post-cutoff
- Source: `docs/engine-reference/<engine>/deprecated-apis.md`

### Cross-Cutting Constraints

*Rules that hold regardless of layer.*

- [constraint] — source: [ADR-NNNN]
