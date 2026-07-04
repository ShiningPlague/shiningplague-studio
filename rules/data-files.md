---
paths:
  - "data/**"
---

# Data File Rules (Sons of Gilgamesh — adapted from Donchitos)

- All JSON files must be valid JSON — broken JSON breaks in-engine tooling + Project Dashboard
- File naming: lowercase with underscores only, following `[system]_[name].json` pattern
- Every data file must have a documented schema in `data/_schemas/` OR be tagged in `data/_schemas/system_registry.json`
- Numeric values must include comments/companion docs explaining what they mean (see rarity_tiers.json pattern)
- **Key naming: `snake_case` for keys within JSON files** (project convention — NOT camelCase; diverges from Donchitos default)
- No orphaned data entries — every entry must be referenced by code or another data file
- Version data files when making breaking schema changes
- Include sensible defaults for all optional fields
- Trailing newline on every JSON file (project convention)
- Edit via in-engine dock where one exists (Monster Editor / Rarity Tier Editor / Location Graph Editor / Archetype Recipe Editor) — direct edit fine otherwise

## Examples

**Correct** naming and structure (`combat_enemies.json`):

```json
{
  "goblin": {
    "baseHealth": 50,
    "baseDamage": 8,
    "moveSpeed": 3.5,
    "lootTable": "loot_goblin_common"
  },
  "goblin_chief": {
    "baseHealth": 150,
    "baseDamage": 20,
    "moveSpeed": 2.8,
    "lootTable": "loot_goblin_rare"
  }
}
```

**Incorrect** (`EnemyData.json`):

```json
{
  "Goblin": { "hp": 50 }
}
```

Violations: uppercase filename, uppercase key, no `[system]_[name]` pattern, missing required fields.
