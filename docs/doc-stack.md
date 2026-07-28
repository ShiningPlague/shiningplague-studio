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

**Some seeds cannot carry a comment line, and are handled by value instead:**

| Seed | Why no marker | The seeded-default signal |
|---|---|---|
| `production/stage.txt` | Read with `cat`; a comment line would corrupt every reader. | Seeded **`not-started`** — deliberately not a phase name. `/gate-check` writes a real phase on the first PASS. |
| `data/_schemas/system_registry.json`, `dev_diary.json`, `production/session-state/active-goals.json` | JSON has no comments. | Seeded structurally empty — `"systems": []`, `"entries": {}`, `"primary_goal": null`. Emptiness is already machine-visible, which is exactly what a marker would have added. |
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
| `docs/sound-bible.md` | Audio identity spec — sonic pillars, music direction, SFX palette, mix targets. The art bible's counterpart. | `/team-audio` (audio-director + sound-designer) | the sound-designer when speccing cues, `docs/ux/interaction-pattern-library.md` | scaffold |
| `docs/accessibility-requirements.md` | Project-wide accessibility tier + the feature matrix across every system. Per-screen notes stay in the UX specs; this is what they point at. | the ux-designer + producer | the UX / HUD / interaction templates in `.claude/docs/templates/`, the technical-setup gate | scaffold |
| `docs/assets/asset-manifest.md` | Master index of every asset the game needs, and its state. | `/asset-spec` | `/asset-spec` (picks the next unspecced target), `/content-audit`, the production gate | scaffold |
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
| `docs/consistency-failures.md` | Append-only reflexion log: what went wrong, and the generalised lesson. **Append-only, never auto-created** — an empty file would claim a clean history nobody earned, so absence is the honest day-one state. | `/consistency-check`, `/architecture-review` | the same two on their next run | on use, optional |
| `docs/ux/` | UX layer — the pattern library plus one spec per key screen. | `/team-ui`, the ux-designer | the ui-programmer, the pre-production gate | scaffold |
| `docs/ux/interaction-pattern-library.md` | Cross-screen interaction rules decided once: button states, dialogs, gestures, input maps. A screen spec cites a pattern instead of re-inventing it. | `/team-ui` (ux-designer) | every `docs/ux/*.md` spec, the ui-programmer, `docs/accessibility-requirements.md` | scaffold |
| `docs/ux/ux-spec-<screen>.md` | One spec per key screen, from the shipped `ux-spec.md` template. | the ux-designer | the ui-programmer, `/asset-spec` | on use |
| `docs/levels/<level>.md` | Level design docs, from the shipped `level-design-document.md` template. | `/team-level`, the level-designer | `/asset-spec level:<name>` | on use, optional |
| `docs/narrative/<character>.md` | Character sheets and narrative docs, from the shipped `narrative-character-sheet.md` template. | `/team-narrative`, the writer | `/asset-spec character:<name>` | on use, optional |
| `docs/world-lore.md` · `docs/story-outline.md` | The narrative pack's lore home and act/chapter outline — the **default** filenames behind `{{LORE_DOC}}` and `{{ACT_REFERENCE}}`. Point the placeholders elsewhere and these names move with them, which is why they are not seeded. | the world-builder / narrative team | `/team-narrative`, the writer | on use, optional |
| `docs/assets/specs/<target>-assets.md` | One asset spec per specced system / level / character. | `/asset-spec` | the art-director, the asset pipeline | on use, optional |
| `docs/live-ops/` | Live-ops planning — calendar, seasons, economy rules, ethics policy. | the live-ops-designer (multiplayer pack) | `/team-release`, the producer | on use, optional |

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
| `docs/architecture/architecture.md` | The master technical blueprint. | `/create-architecture` | `/dev-story`, `/code-review`, `/architecture-review` | scaffold |
| `docs/architecture/control-manifest.md` | Flat "must / must never" rules sheet for programmers. | `/create-control-manifest` | `/dev-story`, `/code-review`, `/story-readiness` | scaffold |
| `docs/architecture/tr-registry.yaml` | **Requirement-coverage registry (TR ids → ADRs).** The only place a TR id is minted, and the only authority on requirement text, coverage status, conflicts and superseded requirements. | `/architecture-review`, `/architecture-decision` | `/dev-story`, `/gate-check`, `/propagate-design-change`, `/create-stories` | scaffold |
| `docs/architecture/requirements-traceability.md` | The full RTM — **GDD → ADR → Story → Test**. A regenerated *snapshot* of the registry above plus the two columns it has no fields for: the implementing story and its test evidence. Derived: the registry wins any disagreement. | `/architecture-review rtm` | the release gate, `/qa-plan`, `/regression-suite` | scaffold |
| `docs/architecture/architecture-review-*.md` | One dated review report per run. | `/architecture-review` | the architecture phase gate | on use, optional |
| `docs/architecture/change-impact-*.md` | Which ADRs a GDD revision just made stale. | `/propagate-design-change` | you | on use, optional |

> ADRs do **not** live here. `docs/architecture/` holds the blueprint, the manifest, the
> registry and the RTM snapshot; decisions live in `docs/adr/`. Two homes for one artifact
> is how a stack drifts — which is why a sixth name, `architecture-traceability.md`, was
> **deleted** in 0.5.0 rather than seeded. Every section of it (coverage summary, TR matrix,
> layer gaps, cross-ADR conflicts, superseded requirements) mapped one-to-one onto
> `tr-registry.yaml`: it was the registry under a second spelling, and two skills were
> writing the same fact into two files that could disagree. There is one registry.

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
| `production/session-state/active-goals.json` | This session's declared goal + the outcomes that prove it shipped. | `/goal-set`, `/goal-add-minor`, `/goal-check` | `/goal-check` — step 0 of `/session-close`, and it can pause the close | scaffold |
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
| `production/releases/day-one-patch-*.md` | One record per day-one patch: scope, fixes, QA gate. | `/day-one-patch` | `/team-release`, the release gate | on use, optional |
| `production/releases/rollback-plan-*.md` | The rollback plan a patch may not ship without. | `/day-one-patch` | `/team-release`, the release-manager | on use, optional |
| `production/releases/<version>/patch-notes.md` | Player-facing patch notes for one version. | the community-manager agent | `/team-release`, `/team-marketing` | on use, optional |
| `production/releases/incident-*.md` | Per-incident **technical** record — cause, timeline, fix, follow-ups — from the shipped `incident-response.md` template. | the release-manager, the producer | the post-mortem, `production/community/crisis-log.md` | on use, optional |
| `production/community/guidelines.md` | Published community rules + the private enforcement ladder and moderator roster. | the community-manager agent | anyone moderating, `/team-marketing` | scaffold |
| `production/community/crisis-log.md` | Append-only history of what was said publicly during every incident, and when. The **communication** side of an incident; the technical record is `production/releases/incident-*.md`. | the community-manager agent | the community-manager before the next incident, the producer at post-mortem | scaffold |
| `production/community/dev-blogs/<post>.md` | One dev blog post per file. | the community-manager agent | `/team-marketing` | on use, optional |
| `production/community/feedback-digests/<week>.md` | Weekly player-feedback digest for the team. | the community-manager agent | `/sprint-plan`, `/bug-triage`, the producer | on use, optional |
| `prototypes/<name>/REPORT.md` | Throwaway prototype folders and what each one proved. Top-level, not under `production/` — a prototype is code, and it is deliberately outside the doc stack. | the prototyper agent | `/gate-check` (the concept gate), you | on use, optional |

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

## Test layer — `tests/`

`tests/` is **yours** — the template ships no test code into a game project, and
your tests may live wherever your engine puts them. Exactly one document is seeded
there, because a skill reads it by that exact name:

| Path | What it is | Written by | Read by | Source |
|---|---|---|---|---|
| `tests/regression-suite.md` | Curated index of the tests that must stay green: critical-path coverage, per-bug regressions, known gaps, quarantined tests. Holds no test code. | `/regression-suite` | `/regression-suite` on the next run, the release gate | scaffold |

## The installed framework — `.claude/`

Everything under `.claude/` is **shipped**: it comes out of the bundle and is replaced on
upgrade. Do not hand-edit it — edit the framework repo and reinstall.

| Path | What it is |
|---|---|
| `.claude/skills/<name>/SKILL.md` | Every workflow skill you invoke. |
| `.claude/agents/*.md` | The specialist roster the dispatch rule reads. |
| `.claude/docs/` | This reference library: `skills-index.md`, `agents-index.md`, `workflow-catalog.yaml`, `director-gates.md`, `doc-stack.md` (this file). |
| `.claude/docs/engine-notes/` | Engine gotchas and coding standards shipped with the bundle — general to the engine, not to your pinned version. (Your version-specific notes go in `docs/engine-reference/`.) |
| `.claude/docs/templates/` | Document templates the authoring skills fill in. |
| `.claude/docs/technical-preferences.md` | Your engine profile, written by `/setup-engine`. **Not shipped and not seeded** — it records what one project chose, so a blank one would be a wrong answer rather than no answer. |
| `.claude/rules/` | Per-domain coding rules the agents load. |
| `.claude/hooks/` | Session-start, skill-gate and validation hooks. |
| `.claude/settings.json` | Wires the hooks. Seeded once; never overwritten. |
| `.claude/settings.local.json` | Per-machine settings overlay **Claude Code itself** writes. Never shipped, never seeded, usually gitignored. |
| `.claude/agents-optional/` | Parking folder you create by hand when trimming the active agent roster. Nothing in the framework writes it. |
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
