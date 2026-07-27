# The Doc Stack — where every artifact lives

> One page that answers "where does X live?". If a skill, an agent, or a future session
> needs to know who writes a file and who reads it, this table is the contract. When a
> doc and this page disagree, **this page and `CLAUDE.md`'s reading map win** — fix the doc.

The layout below is enforced mechanically: `tools/doc_stack_check.py` reads
`tools/doc_stack.manifest.json` and fails if any shipped doc commands a path that nothing
in the framework creates. Adding a doc means adding one manifest entry with a one-line
reason — never a new matching rule in the checker.

---

## The three lifecycles

Every artifact comes into existence exactly one of three ways. The column **Source** below
uses these words:

| Source | Meaning | Present in a fresh install? |
|---|---|---|
| **shipped** | Copied out of the framework bundle by the installer. | Yes — always. |
| **scaffold** | Created empty (or seeded from a template) by the installer's scaffold step. | Yes — unless you passed `--no-scaffold`. |
| **on use** | Written by a skill or agent the first time it runs. | **No.** Absent is the correct day-one state. |

**Optional** in the tables below means "on use, and a project may legitimately never create
it". A lean project that never runs `/security-audit` has no security report, and nothing
should complain about that.

---

## Seeded is not written — the `scaffold-seed` marker

Scaffolding bought coherence and sold a signal. Before the stack was seeded, "does the file
exist?" was a usable proxy for "did somebody do this work?". Now every `scaffold` row above
exists from minute one, so that proxy is a constant — and a tool that reads it reports work
the user never did. It did: on a virgin install `tools/workflow_state_check.py` announced
three `UNRECORDED` steps (`game-concept`, `art-bible`, `map-systems`) and told a brand-new
user to log them. The "evidence" was the three blank skeletons the installer had written
sixty seconds earlier.

**The fix is one token.** Every seeded document carries a marker line near the top, and
**you delete that line when you write real content**. Nothing else about the file matters.

| The seed is… | The marker line |
|---|---|
| markdown / HTML | `<!-- scaffold-seed: unwritten — delete this line once you write real content -->` |
| YAML / anything `#`-commented | `# scaffold-seed: unwritten — delete this line once you write real content` |

The token is **`scaffold-seed: unwritten`**. It is defined in code exactly once —
`SCAFFOLD_SEED_MARKER` in `tools/workflow_state_check.py` — and this table is its
human-readable contract. Every other reader is prose: a skill that gates on an artifact
says "treat a file carrying the `scaffold-seed` marker as absent", it does not re-declare
the token.

**What the marker buys, mechanically:** `tools/workflow_state_check.py` treats a file
carrying it as **absent evidence** — for a `glob` with or without a `pattern`, for
`min_count` arithmetic, for `BOOTSTRAP MODE` inference, and for a ledger's own `evidence:`
paths (so `status: done` pointing at an untouched skeleton is a `CONFLICT`, which is what it
is). A directory counts as evidence only if it holds a real file: `.gitkeep` and marked
skeletons do not make `docs/adr/` an architecture decision.

**Three seeds cannot carry a comment line, and are handled by value instead:**

| Seed | Why no marker | The seeded-default signal |
|---|---|---|
| `production/stage.txt` | Read with `cat`; a comment line would corrupt every reader. | Seeded **`not-started`** — deliberately not a phase name. `/gate-check` writes a real phase on the first PASS. |
| `data/_schemas/system_registry.json`, `dev_diary.json` | JSON has no comments. | Seeded structurally empty — `"systems": []`, `"entries": {}`. Emptiness is already machine-visible, which is exactly what a marker would have added. |
| `production/review-mode.txt` | Must hold a value the gates can act on. | Seeded `lean`. `/start` confirms it out loud on a fresh project rather than assuming the designer chose it. |

**When you add a new seed**, put the marker in it. A seed without one re-opens this defect
for whichever tool reads it next.

---

## Design layer — `docs/`

| Path | What it is | Written by | Read by | Source |
|---|---|---|---|---|
| `docs/GDD.md` | Master game design document. | `/design-system`, you | `/design-review`, `/gate-check`, `/create-architecture`, `/content-audit` | scaffold |
| `docs/gdd/<system>.md` | One design doc per system. | `/design-system` | `/create-architecture`, `/create-epics`, `/review-all-gdds` | on use |
| `docs/gdd/systems-index.md` | System decomposition + status table. The `SYSTEMS-TABLE` region is regenerated from the registry. | `/map-systems`, `tools/generate_systems_index.py` | `/help`, `/project-stage-detect`, `/create-epics` | scaffold |
| `docs/gdd/game-concept.md` | The concept doc — pitch, loop, audience. | `/brainstorming`, you | `/map-systems`, `/design-review` | scaffold |
| `docs/gdd/game-pillars.md` | The design pillars every review checks against. | you | `/design-review`, `/gate-check` | scaffold |
| `docs/art-bible.md` | Visual identity spec that gates asset production. | `/art-bible` | `/asset-spec`, `/team-art` | scaffold |
| `docs/adr/NNN-<slug>.md` | Architecture decision records. Permanent. | `/architecture-decision` | `/code-review`, `/dev-story`, `/architecture-review`, `/gate-check` | on use |
| `docs/adr/TEMPLATE.md` | The ADR skeleton each new record copies. | — (shipped template) | `/architecture-decision` | scaffold |
| `docs/specs/YYYY-MM-DD-<topic>-design.md` | Live feature specs. | `/brainstorming` | `/writing-plans`, `/design-review`, `/scope-check` | on use |
| `docs/plans/YYYY-MM-DD-<topic>-plan.md` | Live implementation plans. | `/writing-plans` | `/executing-plans`, `/scope-check` | on use |
| `docs/z-old/specs/` · `docs/z-old/plans/` | Archive for FINAL specs and SHIPPED plans. | the spec/plan lifecycle | history lookups | scaffold |
| `docs/devlog.md` | The single canonical change log — retrospectives route in here too. | `/update`, `/retrospective` | `/help`, `/consistency-check` | scaffold |
| `docs/implementation-status.md` | Data/pipeline reference; points at the data files. | `/update` | anyone asking "which file holds that number?" | scaffold |
| `docs/open-flags.md` | Unresolved designer questions raised by the checks. | `/consistency-check`, `/red-flag-scan` | `/help`, `/gate-check` | scaffold |
| `docs/engine-reference/<engine>/` | Project-owned notes on what your **pinned** engine version actually does. | `/setup-engine` step 2, then you | the engine specialists, `/create-architecture`, `/create-control-manifest` | on use, **optional** |
| `docs/adoption-plan-*.md` | Migration plan for a brownfield project. | `/adopt` | `/help`, `/start` | on use, optional |
| `docs/content-audit-*.md` | Planned-vs-built content report. | `/content-audit` | `/gate-check` | on use, optional |
| `docs/ux/*.md` · `docs/levels/` · `docs/narrative/` · `docs/assets/specs/*.md` | Filled-in copies of the shipped templates for those disciplines. | the matching `/team-*` skill | `/asset-spec`, the discipline agents | on use, optional |

> **Existence is not evidence — judge a scaffolded artifact on its content.** The
> installer seeds this whole stack, so on a brand-new project every `scaffold` row
> above already exists and is blank. "Does the file exist?" was a usable phase
> signal when the installer created nothing; it is a constant now. Three rules
> follow from that, and every shipped skill obeys them:
>
> 1. **A file carrying the `scaffold-seed: unwritten` marker is absent.** That is
>    the mechanical test, and it is the one to reach for first — see
>    § *Seeded is not written* above.
> 2. **Glob ADRs as `docs/adr/[0-9]*.md`, never `docs/adr/*.md`.** A real ADR is
>    `NNN-<slug>.md`; the leading digit separates a decision from the scaffolded
>    `TEMPLATE.md` beside it. A bare `*.md` glob counts the skeleton as a decision,
>    which is how a fresh install starts reporting it has reached technical-setup.
>    `.claude/docs/workflow-catalog.yaml` uses the digit form too.
> 3. **Read the value, not the filename.** `stage.txt` is seeded `not-started` and
>    `review-mode.txt` is seeded `lean` — those are defaults nobody chose. A
>    template whose prompts are still in `[brackets]` has not been written. The
>    strongest "this project is in flight" signal is a non-empty `systems[]` in
>    `data/_schemas/system_registry.json`.

## Architecture layer — `docs/architecture/`

| Path | What it is | Written by | Read by | Source |
|---|---|---|---|---|
| `docs/architecture/architecture.md` | The master technical blueprint. | `/create-architecture` | `/dev-story`, `/code-review`, `/architecture-review` | on use |
| `docs/architecture/control-manifest.md` | Flat "must / must never" rules sheet for programmers. | `/create-control-manifest` | `/dev-story`, `/code-review` | on use |
| `docs/architecture/tr-registry.yaml` | Requirement-coverage registry (TR ids → ADRs). | `/architecture-review`, `/architecture-decision` | `/gate-check`, `/propagate-design-change` | on use |
| `docs/architecture/architecture-review-*.md` | One dated review report per run. | `/architecture-review` | the architecture phase gate | on use, optional |
| `docs/architecture/change-impact-*.md` | Which ADRs a GDD revision just made stale. | `/propagate-design-change` | you | on use, optional |

> ADRs do **not** live here. `docs/architecture/` holds the blueprint, the manifest and the
> registry; decisions live in `docs/adr/`. Two homes for one artifact is how a stack drifts.

## Data layer — `data/`

| Path | What it is | Written by | Read by | Source |
|---|---|---|---|---|
| `data/_schemas/system_registry.json` | **The built-state source of truth.** Is it built? Ask here first. | `/map-systems`, `/design-system`, `/architecture-decision`, `/update` | almost every skill, and every session open | scaffold |
| `data/_schemas/dev_diary.json` | Session-by-session work record. | `/session-close`, `/update` | `/consistency-check` | scaffold |
| `data/<category>/*.json` | Your editable game content. One file per thing. | you and the design skills | the game, `/content-audit` | on use |

## Production layer — `production/`

| Path | What it is | Written by | Read by | Source |
|---|---|---|---|---|
| `production/session-state/active.md` | Last session, next steps, carry-forward. | `/session-close`, `/update` | every session open, `/help` | scaffold |
| `production/session-logs/` | One log per closed session; playtest notes land here too. | `/session-close`, `/qa-plan` | `/retrospective`, `/gate-check` | scaffold |
| `production/stage.txt` | The current project phase. Authoritative. Seeded `not-started`, which is **not** a phase — it means no gate has been cleared. | `/gate-check` | `/help`, `/project-stage-detect` | scaffold |
| `production/review-mode.txt` | `full` \| `lean` \| `solo` — how strict reviews are right now. Seeded `lean`, a default nobody chose. | `/start`, you | `/gate-check`, the director gates | scaffold |
| `production/flow-ledger.yaml` | Mechanical workflow state. | `tools/workflow_state_check.py`, `/update` | the session-start hook, `/help` | scaffold |
| `production/sprint-status.yaml` | Machine-readable sprint state. | `/sprint-plan`, `/retrospective` | `/help`, `/gate-check` | scaffold |
| `production/workstreams/<domain>.md` | Per-domain progress + open questions. One file per domain, created when that domain opens. | the `/team-*` skills | `/help`, `/sprint-plan` | on use |
| `production/sprints/` | One plan per sprint. | `/sprint-plan` | `/bug-triage`, `/retrospective` | scaffold (empty) |
| `production/epics/<epic>/` | Epics and their story files. | `/create-epics`, `/create-stories` | `/dev-story`, `/scope-check` | scaffold (empty) |
| `production/qa/bugs/BUG-NNN-<slug>.md` | One file per bug. | `/bug-report` | `/bug-triage`, `/sprint-plan` | scaffold (empty) |
| `production/qa/evidence/` | Test evidence attached to stories before they close. | `/dev-story`, `/qa-plan` | `/gate-check` | scaffold (empty) |
| `production/milestones/<milestone>.md` | One file per milestone, from the shipped milestone-definition template. | the producer agent, you | the session-start hook, `/sprint-plan` | on use, optional |
| `production/security/security-audit-*.md` | Dated security audit reports. | `/security-audit` | `/day-one-patch`, the release gate | on use, optional |
| `production/releases/` | Patch records, rollback plans, per-version patch notes, incident records. | `/day-one-patch`, the community-manager agent | `/team-release` | on use, optional |
| `production/community/dev-blogs/` · `feedback-digests/` · `guidelines.md` · `crisis-log.md` | Community output. | the community-manager agent | `/team-marketing` | on use, optional |

## Runners — `tools/`

| Path | What it is | Source |
|---|---|---|
| `tools/consistency_check.py` | Cross-document consistency gate. `/consistency-check`, `/update` and `/session-close` run it. | shipped |
| `tools/workflow_state_check.py` | Mechanical flow state from the ledger + artifact evidence. The session-start hook runs it. | shipped |
| `tools/generate_systems_index.py` | Regenerates the `SYSTEMS-TABLE` region of the systems index from the registry. | shipped |
| `tools/generate_skills_index.py` | Regenerates the `SKILLS-TABLE` region of the skills index from `SKILL.md` frontmatter. | shipped |
| `tools/doc_stack_check.py` + `tools/doc_stack.manifest.json` | Proves no doc commands a path that nothing creates, and no doc names a slash-command that no skill ships. | shipped |
| `tools/<step>_<feature>_check.gd` | Your per-step headless harnesses. A naming convention, not a shipped file. | on use |
| `tools/generate_session_context.sh` | Optional project-owned session context script. The hook runs it only if you wrote one. | project-owned, optional |

## The installed framework — `.claude/`

Everything under `.claude/` is **shipped**: it comes out of the bundle and is replaced on
upgrade. Do not hand-edit it — edit the framework repo and reinstall.

| Path | What it is |
|---|---|
| `.claude/skills/<name>/SKILL.md` | Every workflow skill you invoke. |
| `.claude/agents/*.md` | The specialist roster the dispatch rule reads. |
| `.claude/docs/` | This reference library: `skills-index.md`, `agents-index.md`, `workflow-catalog.yaml`, `director-gates.md`, `doc-stack.md` (this file), `engine-notes/`. |
| `.claude/docs/templates/` | Document templates the authoring skills fill in. |
| `.claude/docs/technical-preferences.md` | Your engine profile, written by `/setup-engine`. |
| `.claude/rules/` | Per-domain coding rules the agents load. |
| `.claude/hooks/` | Session-start, skill-gate and validation hooks. |
| `.claude/settings.json` | Wires the hooks. Seeded once; never overwritten. |
| `CLAUDE.md` | The one file every fresh session reads cold. Seeded once; yours to edit. |

---

## Retired conventions

Seven path conventions were retired when the layout was unified: an old top-level design
tree, a separate art folder, an entity registry outside the data layer, a live-ops folder
of its own, ADRs filed under the architecture folder with an `adr-` prefix, and game data
nested inside the asset tree. Each is listed with its replacement in
`tools/doc_stack.manifest.json` under `killed_conventions`, and `tools/doc_stack_check.py`
fails the check if any shipped doc still cites one. If you meet one in the wild, it is a
bug — fix the doc.

---

## When an artifact is not there

Most of this stack is **on use** — absent until a skill writes it. That is normal, and a
lean project may deliberately never create half of it. Every read-gate skill and every
engine-reading agent therefore carries the same clause, word for word:

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

The same rule holds for the tools the framework itself ships: a runner, a template, or a
`/command` a doc names must exist, or the doc must not name it. `tools/doc_stack_check.py`
enforces both halves — paths and slash-commands — so a skill can no longer advertise a gate
that a fresh install has nothing to fire.

Audit it with:

```bash
grep -rl "If an artifact named here is absent:" .claude/skills .claude/agents | wc -l
```

In a default install that returns **80** — 59 of the 69 skills, and 21 of the 35 agents. The
numbers are lower than the totals on purpose, and the gap is the interesting part:

- **10 skills are excluded deliberately.** They are pure technique — they read no project
  artifact, so there is nothing for them to degrade over.
- **14 agents are excluded for the same reason** — they take their context from the
  dispatching skill rather than reading the doc stack themselves.
- **2 further clause-bearing agents ship only with an engine pack** (`--engine godot`
  installs the godot-extras specialists), so a bundle-side grep over `skills/ agents/`
  in this repo returns **82**, not 80. Both numbers are correct; they count different sets.

Two rules follow from it, and they are the whole point:

1. **Never fabricate.** A missing GDD is reported as missing. It is not summarised from
   imagination so a checklist can go green.
2. **Never block on an optional artifact.** A close, a gate or a review may not fail because
   a file the project never chose to create is not there. Say it is absent, and continue.
