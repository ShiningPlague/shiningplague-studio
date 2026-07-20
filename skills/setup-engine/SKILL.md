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
---

# Setup Engine

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; this version is the full implementation — engine version validation, technical-preferences.md check, project structure check, autoload coverage.

Engine configuration and validation for {{ENGINE_VERSION}}. Run at project setup; this skill formalises the process for reproducibility.

## Procedure

### 1. Verify Engine Version
- Read `project.godot` → `config/features` for engine version
- Cross-check `.claude/docs/technical-preferences.md` → engine version field
- Cross-check `docs/engine-reference/godot/VERSION.md`
- Flag any version mismatches

### 2. Validate technical-preferences.md
Read `.claude/docs/technical-preferences.md`. All fields must be populated:
- Engine + version
- Language (GDScript)
- Architecture patterns (singleton autoloads, signals, resources)
- Naming conventions
- Testing approach
- Performance targets

Flag any blank fields.

### 3. Validate Project Structure
Check that the expected directory structure exists:
- `src/` (scripts), `scenes/` (tscn), `data/` (JSON content)
- `data/_schemas/` (schemas), `addons/` (editor plugins)
- `docs/` (documentation), `production/` (PM state)

### 4. Validate Autoloads
- Read `project.godot` autoloads section
- Cross-check each against `data/_schemas/system_registry.json`
- Flag any autoload not in registry (registry coverage check)

### 5. Output
Report: engine health status, any mismatches or missing config.

## Re-Run Guidance
After initial setup, re-run only if the engine version changes or project.godot drifts.
