# Godot 4.x — Project Gotchas

Technical reference extracted from CLAUDE.md to keep the entry-point file lean. These are **project-specific traps** learned the hard way on a shipped Godot project — add your own as you hit them.

> 🔧 **Use alongside `godot-engine` (bundled; the anthropic-skills plugin's godot skill is an optional upgrade)** — 🔒 MUST-USE in CLAUDE.md, fires when editing `.gd` / `.tscn` / `.tres` / `.gdshader` / `.gdextension`. That skill = **general Godot reference** (file formats, architecture patterns, validation tools, CLI workflows, code templates). This file = **what we've specifically broken + how we use Godot in our way**. Fire the engine skill for general patterns; consult this file for project-specific traps. They complement, no overlap.

---

## Editor / engine quirks

- **UID in `.tscn` files:** Never manually write UIDs. Let Godot auto-assign them.
- **Layout:** Use `VBoxContainer` / `HBoxContainer` with `anchor_right=1.0` / `anchor_bottom=1.0` for full-screen layouts. `set_anchors_preset()` doesn't work reliably for programmatic Controls.
- **`mouse_filter` swallows clicks before a parent's `_gui_input`:** if a panel handles clicks in its own `_gui_input` (e.g. a narrative panel's click-to-advance), a click lands on the topmost Control under the cursor and propagates DOWN the z-order, NOT up the tree. Intermediate containers default to `MOUSE_FILTER_STOP`, so a child container (e.g. `MarginContainer`) **silently eats the click** and the parent panel's `_gui_input` never fires — symptom: clicking does nothing, no error, and a probe in the handler never prints. **Fix:** set the non-interactive descendant containers to `MOUSE_FILTER_IGNORE` and make the input-owning panel `MOUSE_FILTER_STOP`; keep genuinely-interactive children (Buttons, a `RichTextLabel` with meta links) on their own filter. A `RichTextLabel` with `scroll_active = true` is NOT the culprit on its own — verify with a `print` probe in the handler before blaming scroll.
- **`validate_script` MCP tool:** Reports false positives for scripts with `class_name` dependencies. Run the scene directly to verify.
- **Image generation (in-engine):** Pixel-by-pixel loops are slow. Keep procedural images small (128×80 max) or use pre-made assets.
- **Renderer:** Forward+ is fine for dev. Consider Compatibility for production builds targeting wider hardware.
- **Headless runs strip autoloads:** Running `godot --headless` against the main `project.godot` can mangle the `[autoload]` section (we have lost registered autoloads this way). Always `git diff project.godot` after a headless harness run; restore if needed. Using `--script` (instead of opening the project) preserves correctly.

---

## Coding standards quick reference

Enforced by: `.claude/rules/gameplay-code.md` + `.claude/rules/data-files.md` (path-scoped, auto-fire on matching paths). GDD 8-section format enforced by `/design-system` skill. Verification-driven development enforced by `/verification-before-completion` (🔒 MUST-USE).

### GDScript essentials

- Static typing everywhere: `var name: String = ""` not `var name = ""`
- Dictionary access returns Variant — always cast: `var hp: int = int(data["hp"])`
- `class_name` for Resource types referenced across files
- `@warning_ignore` for known warnings, don't restructure working code
- All system autoloads in `src/systems/`, register in `project.godot [autoload]`

### Data files

- One JSON per entity (one location, one enemy, one NPC)
- Schemas in `data/_schemas/` are the templates
- Dropdown values in a single source-of-truth file (e.g. `data/_schemas/dropdowns.json`)
- IDs are snake_case strings matching filename: `cliff_overhang.json` has `"id": "cliff_overhang"`
- Connections use ID references, not file paths

### Signals

- Systems emit signals for events; never call other systems directly
- Signal naming: past_tense_verb — `moved_to_location`, `combat_ended`, `item_gathered`

---

## Project-specific traps (add yours here)

As your project accumulates its own hard-won lessons (duplicate code paths pending resolution, importer quirks with specific asset formats, plugin conflicts), record them in this section — one bullet per trap, with symptom + fix. Keep the lesson, skip the war story.
