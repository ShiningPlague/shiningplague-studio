---
name: map-systems
description: "Use when decomposing a game concept into systems with dependency ordering, when starting design-first work on a new feature area, or when the designer says 'what systems do we need for X?' Reads the master GDD and produces/updates docs/gdd/systems-index.md. ShiningPlague-adopted: full implementation with system_registry.json as source of truth (auto-regenerates systems-index.md), creative-director + technical-director parallel gate review, studio layer/priority taxonomy."
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent
argument-hint: "[scope: full | area-name]"
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - system_registry.json as source of truth, systems-index.md auto-generated
    - Layer taxonomy (Foundation / Core / Feature / Presentation / Polish)
    - Priority taxonomy (MVP / Vertical Slice / Alpha / Full Vision)
    - Circular dependency / God Object / inverted-layer flags
    - Parallel CD-SYSTEMS + TD-SYSTEM-BOUNDARY director gates
    - Hook auto-regenerates systems-index.md on registry update
---

# Map Systems — System Decomposition and Dependency Mapping

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; this version is the full implementation — scope detection, layer/priority taxonomy, dependency mapping with God Object detection, dual-director gate review.

Decomposes a game concept or feature area into systems, assigns layers and priorities, maps dependencies, produces/updates the systems index. The creative-director reviews for vision alignment; the technical-director reviews for architectural soundness.

## Phase 1: Determine Scope

**`full`** (default): Decompose the entire game from the master GDD.
**`<area-name>`**: Decompose a specific feature area (e.g. "narrative", "player-progression").

Read:
1. `{{GDD_PATH}}` (e.g. `docs/GDD.md`) — master GDD (design intent)
2. `data/_schemas/system_registry.json` — what already exists
3. `docs/gdd/systems-index.md` — current systems table (auto-generated from registry)
4. `docs/architecture/tr-registry.yaml` — technical requirements already identified

Report: "Scope: [full/area]. Found [N] existing systems in registry, [M] technical requirements."

---

## Phase 2: Identify Systems

For the scoped area, identify every distinct system needed. A system is a discrete unit of functionality with:
- A single responsibility
- Clear inputs and outputs
- Implementable as one autoload singleton or one scene tree branch

For each system, determine:

| Field | Description |
|-------|-------------|
| **Name** | snake_case identifier |
| **Layer** | Foundation / Core / Feature / Presentation / Polish |
| **Priority** | MVP / Vertical Slice / Alpha / Full Vision |
| **Dependencies** | What systems must exist before this one |
| **What it does** | One sentence |

**Layer assignment rules:**
- **Foundation**: infrastructure with no game logic (save/load, config, state persistence)
- **Core**: primary gameplay loops (combat, movement, resource management)
- **Feature**: game-specific content systems (quests, crafting, NPC schedules)
- **Presentation**: UI, VFX, audio integration, HUD
- **Polish**: optimization, accessibility, feel-tuning

**Priority assignment rules:**
- **MVP**: must ship for the game to be playable
- **Vertical Slice**: needed to prove the core loop works
- **Alpha**: full feature set, rough edges OK
- **Full Vision**: nice-to-have, cut if time runs out

---

## Phase 3: Map Dependencies

Build a dependency graph. For each system, list:
- **Depends on**: systems that must be built FIRST
- **Depended on by**: systems that need THIS system

Check for:
- Circular dependencies (A needs B needs A) — propose resolution
- God Object risks (one system depended on by >5 others) — propose decomposition
- Inverted layer dependencies (Feature depending on Presentation) — flag

Present the dependency graph as an ASCII diagram or table.

---

## Phase 4: Director Review (if review-mode = full)

Read `production/review-mode.txt`. If `full`, spawn two directors in parallel:

**CD-SYSTEMS gate** (creative-director): Does the system set deliver the core fantasy? Missing systems? Scope creep systems?

**TD-SYSTEM-BOUNDARY gate** (technical-director): Are boundaries clean? God Object risks? Dependency ordering problems? Inverted dependencies?

Reference: `.claude/docs/director-gates.md` for full gate prompts.

---

## Phase 5: Update Registry and Index

For NEW systems identified:
1. Add entries to `data/_schemas/system_registry.json` with status `planned`
2. The PostToolUse hook auto-regenerates `docs/gdd/systems-index.md`

For EXISTING systems with new dependency info:
1. Update `depends_on` / `consumed_by` fields in the registry

Propose chain follow-on: "Systems mapped. Next: `/design-system [highest-priority-unmapped]` to author per-system GDDs in dependency order."

---

## Studio Notes

- `system_registry.json` is source of truth. `systems-index.md` is auto-generated.
- Update the registry, not the index directly. Hook handles regeneration.
- The studio registry uses richer status values (active/wip/partial/dormant/planned/etc.) which map to Donchitos statuses in the generated index.
- When decomposing a new area (e.g. a narrative layer), cross-reference existing systems in the registry to avoid duplication.
