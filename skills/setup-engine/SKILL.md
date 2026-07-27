---
name: setup-engine
description: "Use when setting up the engine for a new project or reconfiguring engine settings. Populates technical-preferences.md, validates project.godot, and ensures engine reference docs exist. ShiningPlague-adopted: full implementation with engine-version validation and autoload registry coverage check."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Engine-version validation for {{ENGINE_VERSION}} (project.godot config/features)
    - technical-preferences.md field completeness check
    - Project structure validation (src/, scenes/, data/, etc.)
    - Autoload registry coverage check (cross-ref with system_registry.json)
    - Creates the project-owned engine reference library the agents read
---

# Setup Engine

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; this version is the full implementation — engine version validation, technical-preferences.md check, project structure check, autoload coverage.

Engine configuration and validation for {{ENGINE_VERSION}}. Run at project setup; this skill formalises the process for reproducibility.

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## Procedure

### 1. Verify Engine Version
- Read `project.godot` → `config/features` for engine version
- Cross-check `.claude/docs/technical-preferences.md` → engine version field
- Cross-check `docs/engine-reference/<engine>/VERSION.md` if the project has one (see step 2 -- the template never ships this library)
- Flag any version mismatches

### 2. Establish the engine reference library

`docs/engine-reference/<engine>/` is the project's pinned-version knowledge base:
what the engine actually does in the version this project ships on, which beats a
model's training data whenever the two disagree. **The template never ships it** --
it is engine- and version-specific, so it can only be written per project.

- If `docs/engine-reference/<engine>/VERSION.md` is absent, offer to create the
  folder and seed `VERSION.md` with: engine name, exact pinned version, the release
  date, and a one-line note on which parts of that version post-date the model's
  training data.
- Offer three companion notes alongside it, created empty and filled in as the
  project hits each issue: `deprecated-apis.md`, `breaking-changes.md`,
  `current-best-practices.md`. A `modules/` subfolder holds per-domain notes
  under `docs/engine-reference/<engine>/modules/`, added the same way.
- If the designer declines, say so plainly and move on. The library is optional:
  every skill and agent that reads it must degrade when it is absent.

### 3. Validate technical-preferences.md
Read `.claude/docs/technical-preferences.md`. All fields must be populated:
- Engine + version
- Language (GDScript)
- Architecture patterns (singleton autoloads, signals, resources)
- Naming conventions
- Testing approach
- Performance targets

Flag any blank fields.

### 4. Validate Project Structure
Check that the expected directory structure exists:
- `src/` (scripts), `scenes/` (tscn), `data/` (JSON content)
- `data/_schemas/` (schemas), `addons/` (editor plugins)
- `docs/` (documentation), `production/` (PM state)

### 5. Validate Autoloads
- Read `project.godot` autoloads section
- Cross-check each against `data/_schemas/system_registry.json`
- Flag any autoload not in registry (registry coverage check)

### 6. Output
Report: engine health status, any mismatches or missing config.

## Re-Run Guidance
After initial setup, re-run only if the engine version changes or project.godot drifts.
