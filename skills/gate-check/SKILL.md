---
name: gate-check
description: "Use when validating readiness to advance to the next project phase, before major milestones, after completing a full sprint or epic, or when the designer asks 'are we ready to move on?' Spawns all 4 director agents in parallel for independent verdicts. ShiningPlague-adopted: project paths (docs/adr/ + {{GDD_PATH}} + data/_schemas/system_registry.json), review-mode (full/lean/solo) integration."
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent
argument-hint: "[target-phase]"
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Parallel dispatch of 4 directors (creative/technical/producer/art)
    - Project path adaptations (docs/adr/, {{GDD_PATH}}, system_registry.json)
    - Review-mode integration (full/lean/solo behaviour)
    - Composite verdict escalation rules
    - production/stage.txt write on PASS
---

# Gate Check — Phase Transition Validation

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; the studio version is the full implementation — parallel director dispatch, artifact completeness check, composite verdict, stage.txt write.

Validates project readiness to advance from one phase to the next by spawning 4 director agents in parallel, each reviewing from their domain. Produces a composite PASS / CONCERNS / FAIL verdict.

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## Phases (from workflow-catalog.yaml)

Concept → Systems Design → Technical Setup → Pre-Production → Production → Polish → Release

## Phase 1: Determine Target Phase

**If argument provided:** use it as the target phase.

**If no argument:** read `production/stage.txt` for current phase, then propose next phase from sequence. Confirm with designer.

`stage.txt` is seeded **`not-started`** — that is not a phase, it means no gate has ever
passed here. Read it as "current phase: none" and propose `concept` as the target. This
skill's PASS is what writes the first real phase word into the file.

---

## Phase 2: Collect Artifacts

Read silently before presenting anything:

1. `production/stage.txt` — current phase
2. `production/review-mode.txt` — resolve review mode (full/lean/solo)
3. `docs/gdd/systems-index.md` — systems status overview
4. `docs/architecture/tr-registry.yaml` — requirement coverage
5. `docs/architecture/control-manifest.md` — programmer rules compliance
6. `data/_schemas/system_registry.json` — authoritative system states
7. Glob `docs/adr/[0-9]*.md` — all ADRs and statuses
8. Glob `docs/gdd/*.md` + `{{GDD_PATH}}` — all GDD artifacts
9. Glob `production/sprints/sprint-*.md` — sprint artifacts (if any)
10. Glob `production/session-logs/playtest-*.md` — playtest notes written by `/qa-plan` (if any)

**Project path adaptations:**
- ADRs at `docs/adr/` (`docs/architecture/` holds the blueprint + manifest, never ADRs)
- Master GDD at `{{GDD_PATH}}` (if not split per-system yet)
- System status from `data/_schemas/system_registry.json` (authoritative)
- Design specs at `docs/specs/`, plans at `docs/plans/`

---

## Phase 3: Resolve Review Mode

Read `production/review-mode.txt`. Apply:
- **full** — spawn all 4 director gates (default)
- **lean** — spawn PHASE-GATEs only (this IS a phase gate, so all 4 run anyway)
- **solo** — skip all gates, just do artifact checks, report directly

If mode is `solo`: skip to Phase 5 (artifact-only check).

---

## Phase 4: Spawn Director Gates (parallel)

Spawn ALL 4 director agents simultaneously via Agent tool. Issue all calls before waiting for any result.

Reference: `.claude/docs/director-gates.md` for full gate prompts.

### Gate 1: CD-PHASE-GATE (creative-director)
Pass: target phase, all artifact paths, game pillars from {{GDD_PATH}} pillars section, core fantasy.
Verdict: READY / CONCERNS / NOT READY

### Gate 2: TD-PHASE-GATE (technical-director)
Pass: target phase, architecture doc path (if exists), engine reference, ADR list.
Verdict: READY / CONCERNS / NOT READY

### Gate 3: PR-PHASE-GATE (producer)
Pass: target phase, sprint/milestone artifacts, team size (solo), blocked story count.
Verdict: READY / CONCERNS / NOT READY

### Gate 4: AD-PHASE-GATE (art-director)
Pass: target phase, all art/visual artifacts, art bible (if exists).
Verdict: READY / CONCERNS / NOT READY

---

## Phase 5: Artifact Completeness Check

Independently of director verdicts, check the target phase's required artifacts from `workflow-catalog.yaml`:

For each step in target phase:
- If `required: true` and artifact exists: PASS
- If `required: true` and artifact missing: FAIL (blocker)
- If `required: false` and artifact missing: NOTE (optional)

---

## Phase 6: Composite Verdict

Apply escalation rules:
- Any NOT READY / REJECT from directors → overall **FAIL**
- Any CONCERNS from directors → overall **CONCERNS**
- All READY + all required artifacts present → eligible for **PASS**
- One FAIL artifact check overrides all READY directors → **FAIL**

Present composite verdict with per-director breakdown:

```
## Gate Check: [Current Phase] → [Target Phase]

**Composite Verdict: [PASS / CONCERNS / FAIL]**

| Director | Verdict | Key Finding |
|----------|---------|-------------|
| Creative Director | READY | [one-line summary] |
| Technical Director | CONCERNS | [one-line summary] |
| Producer | READY | [one-line summary] |
| Art Director | NOT READY | [one-line summary] |

### Artifact Check
- [x] [required artifact] — present
- [ ] [required artifact] — MISSING (blocker)
- [-] [optional artifact] — not present (advisory)

### Director Concerns (if any)
[Full text of each CONCERNS or NOT READY verdict]

### Recommendation
[Specific next actions to address blockers or concerns]
```

---

## Phase 7: Write Stage File (if PASS)

If composite verdict is PASS and designer confirms advancement:
- Write target phase name to `production/stage.txt`
- Note: "Phase advanced to [target phase] on [date]"

If CONCERNS and designer chooses to accept:
- Write target phase name to `production/stage.txt`
- Append: "Advanced with accepted concerns on [date]"

If FAIL: do NOT update stage.txt. Surface blockers for resolution.
