---
name: setup-engine
description: "Use when setting up the engine for a new project or reconfiguring engine settings. Populates technical-preferences.md, validates project.godot, and ensures engine reference docs exist. Already done for SoG — useful for future projects. ShiningPlague-adopted (Sons of Gilgamesh): full implementation with Godot 4.6.1 validation, autoload registry coverage check, status note for completed SoG setup."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/setup-engine/SKILL.md
  enhancements:
    - Godot 4.6.1 specific validation (project.godot config/features)
    - technical-preferences.md field completeness check
    - Project structure validation (src/, scenes/, data/, etc.)
    - Autoload registry coverage check (cross-ref with system_registry.json)
    - Status note for completed SoG setup
---

# Setup Engine

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation — engine version validation, technical-preferences.md check, project structure check, autoload coverage. Vanilla backup: `docs/vanilla-backups/2026-05-15/setup-engine/`.

Engine configuration and validation. For SoG, this was completed manually (Godot 4.6.1, technical-preferences.md populated 2026-05-09). This skill formalises the process for reproducibility.

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

## SoG Status
Already complete. Re-run only if engine version changes or project.godot drifts.
