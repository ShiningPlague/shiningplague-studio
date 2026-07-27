<!-- scaffold-seed: unwritten — delete this line once you write real content -->
# Implementation Status

**What this is.** The per-system view of what is built, and the map from each
system to the data files that tune it. The CLAUDE.md reading map sends
*"data / pipeline reference — formulas, tables, tuning"* here.

**The one rule this file obeys: numbers live in data, not here.** A row points at
the data file and names the tool that edits it. Changing a value means editing
the data file, never editing this prose. If you find a stat table written out
below, that is a bug — move it into `data/` and leave a pointer.

**Written by** `/update` (T10 docs-sync), `/dev-story` and `/story-done` as
systems land, `/content-audit` when planned-vs-built drifts.
**Read by** `/consistency-check` — every row's status must match
`data/_schemas/system_registry.json → systems[].status`, which is authoritative.

**Status vocabulary** (same words as the registry): `planned`, `stub`, `wip`,
`partial`, `active`, `phasing_out`, `deprecated`, `dormant`, `for_review`.

---

## Systems

| System | Status | GDD | Data | Tuned with | Notes |
|---|---|---|---|---|---|
| _(none yet — `/map-systems` fills this in)_ | — | — | — | — | — |

Example row, once you have a system:

| `your-system` | partial | `docs/gdd/your-system.md` | `data/your-system/` | `tools/your_system_editor.py` | Main path works; edge cases open |

---

## Data categories

| Category | Directory | Schema | Count | Edited with |
|---|---|---|---|---|
| _(none yet)_ | — | — | — | — |

Every populated `data/<category>/` needs a row here **and** an entry in the
registry's `data[]` array. `/consistency-check` checks both directions.

---

## Known gaps

Things a system needs and does not have yet — missing tests, missing tooling,
missing content. One line each; promote anything that blocks work into
`docs/open-flags.md`.

- _(none yet)_
