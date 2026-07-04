---
paths:
  - "src/systems/**"
  - "src/combat/**"
---

# Gameplay Code Rules (Sons of Gilgamesh — adapted from Donchitos)

- ALL gameplay values MUST come from external config/data files (live JSONs in `data/`), NEVER hardcoded in code
- Use delta time for ALL time-dependent calculations (frame-rate independence)
- Cross-system communication via Godot SIGNALS, never direct method calls between systems
- Every autoload exposes a clear public API (`# --- PUBLIC API ---` comment block convention)
- State machines: use the `Easy State Machine` addon or `behaviour_toolkit` addon, with explicit transition tables
- Document which GDD section / ADR each feature implements in code comments (e.g. `# ADR 001 Decision 3 — deck policy`)
- **Autoload singleton pattern is the project convention** (TimeSystem, CombatSystem, CardDB, etc.) — this diverges from Donchitos's DI-first default, and is correct for Godot 4 project patterns. No need for dependency injection.
- Static typing everywhere: `var name: String = ""` not `var name = ""`. Dictionary accesses always cast explicitly (`int(data["hp"])`).
- Tests: scene-based verification for Step 1+. GUT framework adoption is a future infra decision.

## Examples

**Correct** (data-driven):

```gdscript
var damage: float = config.get_value("combat", "base_damage", 10.0)
var speed: float = stats_resource.movement_speed * delta
```

**Incorrect** (hardcoded):

```gdscript
var damage: float = 25.0   # VIOLATION: hardcoded gameplay value
var speed: float = 5.0      # VIOLATION: not from config, not using delta
```
