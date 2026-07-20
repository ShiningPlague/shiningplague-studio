---
name: godot-engine
description: Use when editing .gd/.tscn/.tres/.gdshader files, creating autoloads/docks/scenes, or authoring specs that will produce them — Godot-specific patterns, pitfalls, and headless validation
---

# Godot Engine Reference

> The anthropic-skills plugin's godot skill is a richer optional upgrade; this bundled skill keeps the studio self-contained.

## Overview

Godot-specific knowledge for safe editing of engine files: what the text formats actually contain, the architecture rules that keep systems decoupled, the 4.x pitfalls that produce silent failures, and how to validate work headlessly without opening the editor.

Fire this skill BEFORE touching any `.gd`, `.tscn`, `.tres`, `.gdshader`, or `.gdextension` file, before creating an autoload/dock/scene, and when authoring a spec or plan that will produce such files.

## Quick reference

### Scene / resource file anatomy

`.tscn` and `.tres` are text formats — editable, diffable, but structured. Know the parts before hand-editing:

```
[gd_scene load_steps=3 format=3 uid="uid://..."]     ; header — format=3 is Godot 4.x
[ext_resource type="Script" path="res://..." id="1"] ; external refs (scripts, textures, scenes)
[sub_resource type="StyleBoxFlat" id="SBF_1"]        ; inline resources local to this file
[node name="Root" type="Control"]                    ; node tree, parent="." paths
[connection signal="pressed" from="Btn" to="." method="_on_pressed"]
```

- **Never hand-write UIDs.** Leave `uid=` alone or omit it — Godot auto-assigns and maintains them. A fabricated UID corrupts the cache.
- `load_steps` must equal 1 + number of ext/sub resources; safest to let the editor rewrite the file rather than hand-count.
- References between files use `res://` paths or `uid://` — keep them consistent; a renamed file without editor involvement breaks both.
- `.tres` is the same grammar with a `[resource]` block instead of a node tree.

### Autoload + signal architecture

- One system = one autoload singleton. Register in `project.godot` under `[autoload]`; scripts live in a dedicated systems directory.
- Systems communicate via **signals, never direct method calls** into other systems. Signal naming: past-tense verb — `moved_to_location`, `combat_ended`, `item_gathered`.
- No system assumes another exists — check for the dependency and degrade gracefully when absent.
- Autoload order matters: an autoload's `_ready()` can only rely on autoloads listed above it.
- `class_name` any Resource type referenced across files, so typed loading works.

### GDScript essentials

- Static typing everywhere: `var name: String = ""`, typed function signatures, typed arrays where practical.
- Dictionary access returns Variant — always cast: `var hp: int = int(data["hp"])`.
- Use `@warning_ignore` for known-acceptable warnings instead of restructuring working code.
- Connect signals in code with typed callables: `some_system.combat_ended.connect(_on_combat_ended)` — not string-based `connect("combat_ended", ...)` (4.x supports it but the callable form fails loudly at parse time instead of silently at runtime).
- `@onready var label: Label = %UniqueName` — prefer scene-unique names (`%`) over brittle absolute node paths for in-scene references.
- Emitting: declare `signal combat_ended(result: Dictionary)` and emit with `combat_ended.emit(result)` — the 3.x `emit_signal("...")` string form is a typo trap.

### Docks and editor plugins

- An editor dock = an `EditorPlugin` script (`@tool`, `extends EditorPlugin`) plus a Control scene, registered via `add_control_to_dock()` in `_enter_tree()` and removed in `_exit_tree()` — always pair them or reloads leak duplicate docks.
- Plugins live at `addons/<name>/` with a `plugin.cfg`; the plugin must be enabled in Project Settings before it loads.
- `@tool` scripts run inside the editor — guard side effects with `Engine.is_editor_hint()` so game logic doesn't execute at edit time.

### Shaders

- `.gdshader` files start with `shader_type spatial;` / `canvas_item` / `particles` / `sky` / `fog` — wrong type = every builtin undefined.
- Uniforms are the data boundary: expose tunables as `uniform`, set from code via `material.set_shader_parameter("name", value)` — don't hardcode constants you'll want to tune.

### Common 4.x pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| `mouse_filter` swallows clicks | Parent's `_gui_input` never fires; clicking does nothing, no error | Clicks land on the topmost Control and propagate DOWN the z-order, not up the tree. Intermediate containers default to `MOUSE_FILTER_STOP` and silently eat the click. Set non-interactive descendant containers to `MOUSE_FILTER_IGNORE`; keep the input-owning panel on `STOP`. Verify with a `print` probe in the handler before blaming anything else. |
| Programmatic anchors | `set_anchors_preset()` unreliable on programmatic Controls | Use `VBoxContainer`/`HBoxContainer` with `anchor_right = 1.0` / `anchor_bottom = 1.0` for full-screen layouts. |
| Headless run mangles `[autoload]` | Autoload entries vanish from `project.godot` after a headless run | Opening the project headlessly can rewrite the file. Prefer `--script` invocations (they preserve it). Always `git diff project.godot` after any headless run; restore if touched. |
| Script validation false positives | Checker reports errors on scripts using `class_name` dependencies | `--check-only` on a single file can't resolve project-wide class names. Confirm by running the scene before treating it as a real error. |
| Slow procedural images | Editor/game stalls generating textures | Pixel-by-pixel `Image` loops are slow. Keep procedural images small (~128×80 max) or use pre-made assets. |
| Renderer mismatch | Works in dev, fails on low-end targets | Note which renderer the project uses (Forward+ vs Compatibility) and re-test before shipping if it changes. |

## Validation commands

Convention: if `godot` is not on PATH, set `GODOT_BIN` to the binary's full path and use `"$GODOT_BIN"` in commands/hooks below.

```bash
# 1. Parse-check a single script (fast, no project load)
godot --headless --check-only --script path/to/file.gd

# 2. Run a headless check-harness script (preferred for data/system validation;
#    --script invocation preserves [autoload] in project.godot)
godot --headless --script tools/<step>_check.gd

# 3. Parse-run a scene to catch load-time errors (missing resources, bad node paths)
godot --headless --path . res://path/to/scene.tscn --quit-after 2
```

A minimal check-harness skeleton (pattern 2):

```gdscript
# tools/example_check.gd — run with: godot --headless --script tools/example_check.gd
extends SceneTree

func _init() -> void:
    var failures: int = 0
    # ... load data / instantiate scenes / assert invariants, print each failure ...
    print("FAIL count: %d" % failures)
    quit(1 if failures > 0 else 0)
```

Exit non-zero on failure so hooks and CI can gate on it.

Rules of thumb:

- Every edited `.gd` gets at least a `--check-only` pass (a PostToolUse hook may already do this — check hook output before re-running manually).
- Data-only changes still get a headless harness run, not just a read-back.
- After ANY headless invocation, `git diff project.godot` — restore the `[autoload]` block if it was rewritten.
- A green `--check-only` is a parse check, not a behavior check. Claims of "working" require running the scene — see the verification-before-completion skill (bundled).

## When NOT to use

- **Non-Godot projects** — this skill is Godot-specific. Unity/Unreal/other-engine projects use the matching engine pack's skill instead; if none is installed, activate one from the optional engine packs before editing engine files.
- **Pure data-file edits with no engine semantics** (e.g. editing a JSON the game reads) — the data-file rules apply, but you still owe a headless harness check if the data feeds engine systems.
- **Design-only discussion** with no engine files in the output — no need to prime this skill until a spec/plan will actually produce `.gd`/`.tscn`/`.tres` files.
