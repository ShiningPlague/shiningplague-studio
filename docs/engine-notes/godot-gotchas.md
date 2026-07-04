# Godot 4.6 — Project Gotchas

Technical reference extracted from CLAUDE.md on 2026-04-29 to keep the entry-point file lean. These are **project-specific traps** Claude has hit and learned from.

> 🔧 **Use alongside `anthropic-skills:godot`** (🔒 MUST-USE in CLAUDE.md, fires when editing `.gd` / `.tscn` / `.tres` / `.gdshader` / `.gdextension`). That skill = **general Godot reference** (file formats, architecture patterns, validation tools, CLI workflows, code templates). This file = **what we've specifically broken in this project + how we use Godot in our way**. Fire the Anthropic skill for general patterns; consult this file for SoG-specific traps. They complement, no overlap.

---

## Editor / engine quirks

- **UID in `.tscn` files:** Never manually write UIDs. Let Godot auto-assign them.
- **Layout:** Use `VBoxContainer` / `HBoxContainer` with `anchor_right=1.0` / `anchor_bottom=1.0` for full-screen layouts. `set_anchors_preset()` doesn't work reliably for programmatic Controls.
- **`mouse_filter` swallows clicks before a parent's `_gui_input` (learned 2026-06-29, the click-to-continue bug):** if a panel handles clicks in its own `_gui_input` (e.g. NarrativePanel's click-to-advance/continue), a click lands on the topmost Control under the cursor and propagates DOWN the z-order, NOT up the tree. Intermediate containers default to `MOUSE_FILTER_STOP`, so a child container (e.g. `MarginContainer`) **silently eats the click** and the parent panel's `_gui_input` never fires — symptom: clicking does nothing, no error, and a probe in the handler never prints. **Fix:** set the non-interactive descendant containers to `MOUSE_FILTER_IGNORE` and make the input-owning panel `MOUSE_FILTER_STOP`; keep genuinely-interactive children (Buttons, a `RichTextLabel` with meta links) on their own filter. A `RichTextLabel` with `scroll_active = true` is NOT the culprit on its own — verify with a `print` probe in the handler before blaming scroll.
- **`validate_script` MCP tool:** Reports false positives for scripts with `class_name` dependencies. Run the scene directly to verify.
- **Image generation (in-engine):** Pixel-by-pixel loops are slow. Keep procedural images small (128×80 max) or use pre-made assets.
- **Renderer:** Currently Forward+ for dev. Switch to Compatibility for production build.
- **Headless runs strip autoloads:** Running `godot --headless` against the main `project.godot` can mangle the `[autoload]` section (lost MCP autoloads happened during Step 1). Always `git diff project.godot` after a headless harness run; restore if needed. Using `--script` (instead of opening the project) preserves correctly.

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
- Dropdown values in `data/_schemas/dropdowns.json` — single source of truth
- IDs are snake_case strings matching filename: `cliff_overhang.json` has `"id": "cliff_overhang"`
- Connections use ID references, not file paths

### Signals

- Systems emit signals for events; never call other systems directly
- Signal naming: past_tense_verb — `moved_to_location`, `combat_ended`, `item_gathered`

---

## Travel formula

`distance_m / 100 / speed_modifier = minutes`

Where 100m = 1 minute at base speed 1.0 (~6 km/h adventurer pace). Used by Navigator for travel time calculation.

Note: there are TWO travel-time paths in the codebase as of 2026-04-21:
- `src/ui/map_screen.gd:21` flat `TRAVEL_MINUTES = 30` — **ACTIVE** (current single source of truth for the map → combat loop)
- `src/systems/navigator.gd:60` distance-based — **DORMANT** (the formula above; commented in file header)

Resolution pending — pick one when tuning travel pacing.

---

## Key data references

- **49 locations** in No Man's Land with full connections (biome/rarity wiped 2026-04-21 for re-tagging via Location Graph Editor)
- **Location fields:** `biome_type`, `biome_name`, `encounter_rarity`, `faction`, `region_id`, `map_x`, `map_y`, `illustration`, `connections`, `tags`
- **14 materials** across 5 tiers (standard → impossible)
- **Schemas** in `data/_schemas/`: locations, regions, ambient_text, travel_flavor, materials, dropdowns, rarity_tiers, archetype_recipes, trait_multipliers, delivery_matrix, status_effects, card_schema, tag_reference

For full inventory of populated/empty data dirs: [docs/reviews/2026-04-29-project-inventory.md](../../docs/reviews/2026-04-29-project-inventory.md) § Level 4a, or [data/_schemas/system_registry.json](../../data/_schemas/system_registry.json) `data[]` array.
