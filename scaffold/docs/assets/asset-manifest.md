<!-- scaffold-seed: unwritten — delete this line once you write real content -->
# Asset Manifest

> Last updated: [YYYY-MM-DD]

**What this is.** The one index of every asset the game needs: what it is, which
context asked for it, what state it is in, and which spec file describes it. It is
the production-phase answer to "how much art is left?".

**Written by** `/asset-spec` — it appends one context block per system, level or
character it specs, and recounts the progress summary. Run bare, `/asset-spec`
reads this file to pick the next unspecced context.
**Read by** `/content-audit` (planned vs built), the production phase gate, and the
art-director when scheduling.

**How to fill it:** run `/asset-spec system:<name>` (or `level:` / `character:`)
once your art bible and the relevant GDD are approved. Do not hand-maintain the
counts — they are recomputed on each run.

**Status vocabulary:** `Needed` · `In progress` · `Done` · `Approved`

---

## Progress summary

*Recounted from the context tables below on every `/asset-spec` run.*

| Total | Needed | In progress | Done | Approved |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 |

---

## Assets by context

*One `###` block per system / level / character that has been specced. Asset ids are
global and sequential — `ASSET-001` onward — so a row can be cited from a story, a
bug or a sprint plan without ambiguity.*

_(none yet — `/asset-spec` writes the first block)_

Shape of one block, once you have a context:

### System: [name]

| Asset ID | Name | Category | Status | Spec file |
|---|---|---|---|---|
| ASSET-001 | [asset name] | [category] | Needed | `docs/assets/specs/[name]-assets.md` |
