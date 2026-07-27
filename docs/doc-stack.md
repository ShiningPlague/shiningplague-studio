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
| `production/stage.txt` | The current project phase. Authoritative. | `/gate-check` | `/help`, `/project-stage-detect` | scaffold |
| `production/review-mode.txt` | `full` \| `lean` \| `solo` — how strict reviews are right now. | `/start`, you | `/gate-check`, the director gates | scaffold |
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
| `tools/doc_stack_check.py` + `tools/doc_stack.manifest.json` | Proves no doc commands a path that nothing creates. | shipped |
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

Audit it with:

```bash
grep -rl "If an artifact named here is absent:" .claude/skills .claude/agents
```

Two rules follow from it, and they are the whole point:

1. **Never fabricate.** A missing GDD is reported as missing. It is not summarised from
   imagination so a checklist can go green.
2. **Never block on an optional artifact.** A close, a gate or a review may not fail because
   a file the project never chose to create is not there. Say it is absent, and continue.
