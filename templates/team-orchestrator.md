# Team Orchestrator — Execution Protocol

> All `/team-*` skills follow this protocol. This is NOT a reference doc — it is
> an IMPERATIVE execution guide. Follow each step in order. Do NOT skip steps.
> Do NOT improvise a different sequence.

## Phase 0: Route to Activity

Ask the designer (or infer from context): what ACTIVITY are we doing?
Present these options:

| Activity | What happens | Entry skill |
|---|---|---|
| **Design** | Brainstorm → spec → GDD → review | `/brainstorming` |
| **Build** | Plan → implement → test → review | `/writing-plans` |
| **Content** | Author data/text in docks/JSON | No skill — direct dock work |
| **Playtest** | Run game, find bugs, verify | `/systematic-debugging` |
| **Review** | Code/design/architecture review | `/code-review` or `/design-review` |
| **Ship** | Update, gate check, push | `/session-close` |

Once activity is selected, execute the matching chain below.

---

## DESIGN Activity — Execution Chain

Execute these steps IN ORDER. Do NOT skip. WAIT for each to complete.

### Step 1: FIRE `/brainstorming`
```
Skill(skill="brainstorming")
```
Follow the project-local brainstorming SKILL.md procedure. Output: spec at
`docs/specs/YYYY-MM-DD-<topic>-design.md` with `## Expected outcomes at ship`.
WAIT for spec to reach status: ✅ FINAL.

### Step 2: FIRE `/design-review`
```
Skill(skill="design-review")
```
Dispatches `creative-director` with gate **CD-GDD-ALIGN**. Validates pillar
alignment, MDA consistency, design theory. WAIT for verdict.
- APPROVE → proceed to Step 3
- CONCERNS → revise spec, re-run Step 2
- REJECT → return to Step 1

### Step 3: FIRE `/architecture-decision`
```
Skill(skill="architecture-decision")
```
Lock decisions into ADR at `docs/adr/NNN-<slug>.md`. Dispatches
`technical-director` with gate **TD-ADR**. WAIT for verdict.
- APPROVE → ADR status = Accepted. Proceed to Step 4.

### Step 4: DECIDE path
- If work is SMALL (fits in 1 ADR, 1-2 weeks) → go to BUILD Activity
- If work is LARGE (multi-system, multi-week) → continue to Step 5

### Step 5 (large path only): FIRE `/design-system`
```
Skill(skill="design-system")
```
Author per-system GDD (8 sections). Dispatches `game-designer` using
design-agent-protocol (Question-First Workflow). WAIT for GDD to complete.

### Step 6 (large path only): FIRE `/map-systems`
```
Skill(skill="map-systems")
```
Decompose into systems with dependencies. Updates `docs/gdd/systems-index.md`.

### Step 7 (large path only): FIRE `/create-architecture`
```
Skill(skill="create-architecture")
```
Master architecture doc from all GDDs + ADRs.

### Step 8 (large path only): FIRE `/create-epics` then `/create-stories`
```
Skill(skill="create-epics")
Skill(skill="create-stories", args="<epic-slug>")
```
Break into implementable stories. This is where SPRINTS start.

---

## BUILD Activity — Execution Chain

### Step 1: FIRE `/writing-plans`
```
Skill(skill="writing-plans")
```
Break the spec/ADR/story into implementation tasks. Output: plan at
`docs/plans/YYYY-MM-DD-<topic>-plan.md`.

### Step 2: FIRE `/executing-plans` or `/dev-story`
```
Skill(skill="executing-plans")  # for plan-based work
Skill(skill="dev-story")        # for story-based work
```
Dispatches the workstream's specialist programmer (from team roster) using
implementation-agent-protocol. Example: routes to `gameplay-programmer` +
`godot-gdscript-specialist`.

Each task follows: read spec → ask architecture → propose → implement → test.
WAIT for each task to complete before proceeding.

### Step 3: FIRE `/test-driven-development` (per task)
```
Skill(skill="test-driven-development")
```
Write test BEFORE implementation code. 🔒 MUST-USE.

### Step 4: FIRE `/verification-before-completion`
```
Skill(skill="verification-before-completion")
```
Run actual verification commands. Cite output. 🔒 MUST-USE.

### Step 5: FIRE `/code-review`
```
Skill(skill="code-review")
```
Dispatches `lead-programmer` with gate **LP-CODE-REVIEW**. Cross-checks
ADRs + control manifest + Godot patterns. WAIT for verdict.

### Step 6: FIRE `/finishing-a-development-branch`
```
Skill(skill="finishing-a-development-branch")
```
Merge, commit, update.

---

## CONTENT Activity — Execution Chain

### Step 1: Identify data type
Read the workstream state file → what content needs authoring?
(Enemies, cards, locations, dialogue, loot tables, etc.)

### Step 2: Open the relevant dock or JSON
- Monsters → Monster Editor dock
- Rarity tiers → Rarity Tier Editor dock
- Locations → Location Graph Editor dock
- Cards → data/cards/*.json (Card Editor dock = Step 4 future)
- Trait multipliers → Trait Multipliers Editor dock
- Other → direct JSON editing at data/<type>/

### Step 3: Validate
Run `tools/consistency_check.py` to verify data integrity after changes.

---

## PLAYTEST Activity — Execution Chain

### Step 1: FIRE `/systematic-debugging` if bugs found
```
Skill(skill="systematic-debugging")
```
Phase 1 evidence-gathering FIRST. 🔒 MUST-USE before any fix.

### Step 2: After fix → FIRE `/regression-suite`
```
Skill(skill="regression-suite")
```
Map the fixed bug to a regression test entry.

### Step 3: FIRE `/verification-before-completion`
Verify the fix works. 🔒 MUST-USE.

---

## REVIEW Activity — Execution Chain

### Step 1: Determine review type
- Code changed → `/code-review`
- Design doc changed → `/design-review`
- ADRs need coverage check → `/architecture-review`
- Cross-doc consistency → `/consistency-check`
- Security audit → `/security-audit`
- GDD cross-check → `/review-all-gdds`

### Step 2: Fire the relevant skill
Each dispatches the appropriate specialist agent per its SKILL.md procedure.

---

## SHIP Activity — Execution Chain

### Step 1: FIRE `/gate-check`
```
Skill(skill="gate-check")
```
Spawns all 4 directors in parallel for phase gate verdicts.

### Step 2: FIRE `/session-close`
```
Skill(skill="session-close")
```
7-step close protocol: director reflections → consistency gate → /update → git push → session reflection → session log.

---

## After ANY Activity Completes

1. Update `production/workstreams/<name>.md` — move items Done → In Progress → Next
2. Propose the NEXT natural activity (chain-propose rule)
3. Return structured report to the studio lead

---

## Cross-references — Template + Agent per Activity

This file defines the **skill chain** for each activity. For the **template + agent** that backs each skill in each phase, see **[.claude/docs/agents-index.md § Phase → Template → Skill → Agent Map](../agents-index.md)**.

Example lookup: in DESIGN Activity Step 1 (`/brainstorming`), agents-index.md tells you:
- Concept-phase target → template `game-concept.md`, primary agent `creative-director`
- Systems-Design-phase combat target → template `design-doc-from-implementation.md`, primary agent `game-designer` + `systems-designer`
- And so on.

The skill chain here is generic; the per-phase binding is in agents-index.md.
