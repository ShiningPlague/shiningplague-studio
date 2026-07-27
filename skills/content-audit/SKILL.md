---
name: content-audit
description: "Audit GDD-specified content counts against implemented content. Identifies what's planned vs built. ShiningPlague-adopted: project data paths ({{DATA_DIR}}/enemies/, {{DATA_DIR}}/items/, etc.), with data/_schemas/system_registry.json as the entity-level source of truth."
argument-hint: "[system-name | --summary | (no arg = full audit)]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write
agent: producer
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Project data paths ({{DATA_DIR}}/<content-type>/ per project convention)
    - Project GDD paths (docs/gdd/ + master at {{GDD_PATH}})
    - Registry as authority (data/_schemas/system_registry.json)
---

# Content Audit

> 🌱 **ShiningPlague-adopted.** Originally Donchitos; battle-tested on a shipped Godot project. Upstream procedure preserved + project data paths + registry-as-authority.

When this skill is invoked, parse the argument:
- No argument → full audit across all systems
- `[system-name]` → audit that single system only
- `--summary` → summary table only, no file write

## Project Paths

| What | Canonical path |
|---|---|
| Systems index | `docs/gdd/systems-index.md` |
| Per-system GDDs | `docs/gdd/*.md` + `{{GDD_PATH}}` (master, e.g. `docs/GDD.md`) |
| Enemy data | `{{DATA_DIR}}/enemies/` |
| Item data | `{{DATA_DIR}}/items/` |
| Loot tables | `{{DATA_DIR}}/loot_tables/` |
| NPC / character data | `{{DATA_DIR}}/npcs/` |
| Entity-level authority | `data/_schemas/system_registry.json` |

## Project Content Inventory

- List each populated `{{DATA_DIR}}/<content-type>/` directory and its JSON file count (e.g. `{{DATA_DIR}}/enemies/`, `{{DATA_DIR}}/quest-log/`, `{{DATA_DIR}}/locations/`).
- Content counts come from GDD + checked against actual JSON file counts.

---

## Phase 1 — Context Gathering

1. **Read `docs/gdd/systems-index.md`** for the full list of systems, categories, MVP/priority tier.

2. **L0 pre-scan**: Before full-reading any GDDs, Grep for `## Summary` + content-count keywords:
   ```
   Grep pattern="(## Summary|N enemies|N levels|N items|N abilities|enemy types|item types|N quests|N locations)" glob="docs/gdd/*.md" output_mode="files_with_matches"
   Grep pattern="(## Summary|N enemies|N levels|N items|N quests|N locations)" path="{{GDD_PATH}}" output_mode="content"
   ```
   Single-system audit: skip and go straight to full-read.
   Full audit: full-read only GDDs that matched content-count keywords.

3. **Full-read in-scope GDD files** (or single system GDD if name given).

4. **For each GDD, extract explicit content counts/lists.** Look for:
   - "N enemies" / "enemy types:" / named enemies list
   - "N levels" / "N areas" / "N maps" / "N stages"
   - "N items" / "N weapons" / "N equipment pieces"
   - "N abilities" / "N skills" / "N spells"
   - Any project-specific content nouns (e.g. "N locations", "N enemy archetypes")
   - "N dialogue scenes" / "N conversations" / "N cutscenes"
   - "N quests" / "N missions" / "N objectives"
   - Any explicit enumerated bullet list of named content pieces

5. **Build a content inventory table**:

   | System | Content Type | Specified Count/List | Source GDD |
   |--------|-------------|---------------------|------------|

   Unspecified counts get "Unspecified" and a flag — design gap.

---

## Phase 2 — Implementation Scan

**Enemies:**
- Glob `{{DATA_DIR}}/enemies/*.json`
- Count unique files

**Locations:**
- Glob `{{DATA_DIR}}/locations/*.json`

**Items / Equipment / Loot:**
- Glob `{{DATA_DIR}}/items/*.json`, `{{DATA_DIR}}/loot_tables/*.json`

**Characters / NPCs:**
- Glob `{{DATA_DIR}}/npcs/*.json`

**Dialogue / Conversations / Cutscenes:**
- Glob `{{DATA_DIR}}/dialogue/*.json`, `{{DATA_DIR}}/scenes/*.json`

**Quests / Missions:**
- Glob `{{DATA_DIR}}/quests/*.json`, `{{DATA_DIR}}/missions/*.json`

**Any other populated `{{DATA_DIR}}/<content-type>/` directory:**
- Glob and count per directory

**Scenes (Godot):**
- Glob `scenes/**/*.tscn`
- Distinguish gameplay scenes from UI/system scenes via subdirectory naming

**Engine-specific notes (acknowledge in report):**
- Counts are approximations
- Scene files include both gameplay and system/UI scenes; scan counts all, notes caveat

---

## Phase 3 — Gap Report

```
| System | Content Type | Specified | Found | Gap | Status |
|--------|-------------|-----------|-------|-----|--------|
```

**Status categories:**
- `COMPLETE` — Found ≥ Specified (100%+)
- `IN PROGRESS` — Found is 50–99% of Specified
- `EARLY` — Found is 1–49% of Specified
- `NOT STARTED` — Found is 0

**Priority flags:**
Flag `HIGH PRIORITY` if:
- Status is `NOT STARTED` or `EARLY`, AND
- System is tagged MVP or Vertical Slice, OR
- Systems index shows system is blocking downstream systems

**Summary line:**
- Total content items specified (sum of Specified)
- Total content items found (sum of Found)
- Overall gap percentage: `(Specified - Found) / Specified * 100`

---

## Phase 4 — Output

### Full audit and single-system modes

Present gap table and summary. Ask: "May I write the full report to `docs/content-audit-[YYYY-MM-DD].md`?"

If yes, write:

```markdown
# Content Audit — [Date]

## Summary
- **Total specified**: [N] content items across [M] systems
- **Total found**: [N]
- **Gap**: [N] items ([X%] unimplemented)
- **Scope**: [Full audit | System: name]

> Note: Counts are approximations based on file scanning.
> The audit cannot distinguish shipped content from editor/test assets.
> Manual verification is recommended for any HIGH PRIORITY gaps.

## Gap Table

| System | Content Type | Specified | Found | Gap | Status |
|--------|-------------|-----------|-------|-----|--------|

## HIGH PRIORITY Gaps

[List systems flagged HIGH PRIORITY with rationale]

## Per-System Breakdown

### [System Name]
- **GDD**: `docs/gdd/[file].md` or `{{GDD_PATH}} §[section]`
- **Content types audited**: [list]
- **Notes**: [caveats]

## Recommendation

Focus implementation effort on:
1. [Highest-gap HIGH PRIORITY system]
2. [Second system]
3. [Third system]

## Unspecified Content Counts

The following GDDs describe content without giving explicit counts:
[List of GDDs and content types with "Unspecified"]
```

After writing the report:
> "Would you like to create backlog stories for any of the content gaps?"

If yes: for each system, suggest a story title + point to `/create-stories [epic-slug]` or `/quick-design` depending on size.

### --summary mode

Print Gap Table and Summary directly to conversation. Don't write a file.
End with: "Run `/content-audit` without `--summary` to write the full report."

---

## Phase 5 — Next Steps

- If any system is `NOT STARTED` and MVP-tagged → "Run `/design-system [name]` to add missing content counts to GDD before implementation begins."
- If total gap is >50% → "Run `/sprint-plan` to allocate content work across upcoming sprints."
- If backlog stories needed → "Run `/create-stories [epic-slug]` for each HIGH PRIORITY gap."
- If `--summary` was used → "Run `/content-audit` (no flag) to write full report to `docs/`."

Verdict: **COMPLETE** — content audit finished.
