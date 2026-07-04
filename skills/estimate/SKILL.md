---
name: estimate
description: "Use when estimating effort for a feature, sprint item, or workstream task. Breaks work into sub-tasks, estimates each, identifies risks, and produces a total with confidence range. Fires during sprint planning or when the designer asks 'how long will this take?' ShiningPlague-adopted (Sons of Gilgamesh): full implementation with SoG context (solo dev, no test suite, data-driven architecture), 1-2 week step sizing per Card System pattern."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/estimate/SKILL.md
  enhancements:
    - Complexity-based estimate ranges (Low/Medium/High)
    - Risk multipliers (1.2x/1.5x/2x)
    - Optimistic/Expected/Pessimistic output
    - SoG context (solo dev, no parallelism, data-driven fast paths)
    - 1-2 week step sizing (Card System pattern)
---

# Estimate

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation — sub-task breakdown, complexity-based estimates, risk multipliers, SoG context. Vanilla backup: `docs/vanilla-backups/2026-05-15/estimate/`.

Effort breakdown and estimation for planning.

## Procedure

### 1. Understand the Work
Read the governing document (spec, story, or verbal description).
Identify: what systems are touched, what's new vs modified, dependencies.

### 2. Break Into Sub-Tasks
Decompose into implementable chunks (each 1-3 days max per CLAUDE.md sprint rules).
For each sub-task:
- Description
- Systems/files touched
- Dependencies on other sub-tasks
- Complexity: Low (routine) / Medium (some unknowns) / High (significant unknowns)

### 3. Estimate Each Sub-Task

| Complexity | Estimate range |
|---|---|
| Low | 0.5-1 day |
| Medium | 1-2 days |
| High | 2-3 days + spike risk |

### 4. Identify Risks
- **Technical unknowns** — never done this in Godot before?
- **Dependencies** — blocked on another system or decision?
- **Scope ambiguity** — design not fully locked?
- **Integration risk** — touches multiple autoloads/systems?

Each risk adds a multiplier (1.2x for low, 1.5x for medium, 2x for high).

### 5. Output

```
## Estimate: [feature/task name]

### Sub-Tasks
| # | Task | Complexity | Estimate | Dependencies |
|---|---|---|---|---|
| 1 | [task] | Medium | 1-2 days | None |
| 2 | [task] | High | 2-3 days | Task 1 |

### Risks
- [risk 1] — impact: [multiplier]

### Total
- Optimistic: [X] days
- Expected: [Y] days
- Pessimistic: [Z] days (if risks materialise)

### Recommendation
[Whether this fits in a sprint, needs slicing, or needs a spike first]
```

## Context for SoG
- Solo dev — no parallelism across people, but agent parallelism available
- No test suite — verification time is manual (factor into estimates)
- Data-driven architecture — data changes are fast, code changes are slower
- Each "step" (per Card System pattern) should be 1-2 weeks max
