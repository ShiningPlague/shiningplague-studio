# Changelog

All notable changes to the ShiningPlague Game Studio framework are recorded here.
The format follows [Keep a Changelog](https://keepachangelog.com/); versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed — the fresh-install journey, walked as a stranger

Defects found by re-walking the install as somebody who had never seen the repo.
Each one is something the *first* command a new user runs gets wrong. The last
three are one rule applied three times: **if a doc names a fixed filename, the
installer ships that file as a fillable template** — guiding the reader through
filling it is the assistant's job, and a missing file is never the reader's problem
to discover.

- **The reading map named three files a fresh install does not have — so the install
  now has them.** `CLAUDE.md`'s architecture row named
  `docs/architecture/architecture.md`, `control-manifest.md` and `tr-registry.yaml`
  in the present tense, and README's "What you get" tree listed them under the
  *seeded, never overwritten* banner, while the installer seeded the empty directory
  and nothing else. Since `CLAUDE.md` is the one file every session reads cold, a
  promise there sends the session hunting for a file that was never written.
  The first attempt at this fix reworded the docs — the row pointed at the directory
  and the three filenames went unmentioned. **That is reversed.** The rule is now the
  other direction: *the template must be there.* All three ship as fillable
  skeletons, the reading map names them outright again, and guiding the reader
  through filling one is the assistant's job, not the reader's homework. A row may
  point at a directory only when the filename genuinely cannot be known in advance —
  a dated spec, a numbered ADR — and the template's guidance block now says exactly
  that. Every backticked path in the reading map still resolves in a virgin install.
- **The scaffold fooled the tools that read it.** On a virgin install
  `tools/workflow_state_check.py` reported `game-concept`, `art-bible` and
  `map-systems` as `UNRECORDED — evidence present but NOT in ledger`, telling a
  brand-new user to log three steps they had never performed. The "evidence" was the
  three blank skeletons the installer had written seconds earlier. Root cause: since
  0.5.0 seeded the document stack, a seeded skeleton became indistinguishable from
  authored work, and *every* existence test in the bundle inherited the bug.
  One mechanism fixes all of it: every seeded document now carries a
  **`scaffold-seed: unwritten`** marker line that the author deletes when they write
  real content. `workflow_state_check.py` treats a marked file as **absent
  evidence** — for globs with or without a `pattern`, for `min_count`, for bootstrap
  inference, and for a ledger's own `evidence:` paths, so `status: done` pointing at
  an untouched skeleton is now the `CONFLICT` it always was. Directories count only
  if they hold a real file, so `.gitkeep` no longer makes `docs/adr/` a decision.
  The token is defined once (`SCAFFOLD_SEED_MARKER`) and documented once
  (`docs/doc-stack.md` § *Seeded is not written*).
- **`production/stage.txt` is seeded `not-started`, which is not a phase name.** It
  used to be seeded `concept` — a real phase — so anything testing "has the project
  reached concept?" answered yes at an empty install, and `/start` could report
  "Project already onboarded" to somebody who had just finished installing.
  `/start`, `/help`, `/adopt`, `/project-stage-detect`, `/gate-check` and
  `/day-one-patch` now read the seeded default as "no gate has been cleared" and
  fall through to content-based inference. The registry's mirrored `phase` matches.
  Two hooks had the same defect and are fixed the same way: `session-start.sh`
  announced *"a previous session left state"* on a project whose first session had
  not started, and `post-compact.sh` told Claude to restore working context from a
  blank skeleton.
- **`artifact.pattern` was declared in the catalog and read by nothing.** The
  workflow-catalog header documents it as "text pattern that must appear in the file
  (checked after glob)", and one step (`engine-setup`) declares one. It is now
  enforced — the same defect `min_count` had, in the same file. Enforcing it showed
  the declaration was also wrong: `Engine: [^[]` never matched the markdown-bold
  shape the doc is actually written in (`- **Engine:** Godot 4.6`). Widened, and it
  now does the job it was written for — a `[placeholder]` engine field no longer
  counts as a configured engine.
- **Both installers create the target directory when it is absent.** They errored
  with *"target directory does not exist"*, and the README quick-start never said it
  had to pre-exist, so a user installing into a new folder hit an error on their
  very first command. `install.sh` and `install.ps1` now `mkdir -p` the target and
  print a note, identically. CI installs into a non-existent path to keep it that way.
- **`manifest.yaml`'s `install_files` count is now guarded.** Nine directory counts
  were checked against disk on every push and this one was not, because no `find`
  reproduces it — it is what the *installer* lands. CI now tees the install log and
  asserts the printed "new files" equals the manifest number.
- **Nine more scaffold paths: every fixed-name artifact the docs promise is now
  seeded.** Fixing the three architecture files by hand would have fixed three
  symptoms of one rule, so the same question was asked of every path named in
  `doc-stack.md`, `CLAUDE.md.template`, `skills-index.md` and the phase-gate globs in
  `workflow-catalog.yaml`: *does a doc name this exact filename, and does the
  installer create it?* Four more said no, and each was a live dead end.
  `docs/accessibility-requirements.md` and `docs/assets/asset-manifest.md` are
  **phase-gate globs** — a gate that globs a literal filename can never pass on a
  fresh install. `production/session-state/active-goals.json` is read by `/goal-check`
  as step 0 of `/session-close`, and was invisible to `doc_stack_check.py` because
  `skills-index.md` names it without a directory component. `tests/regression-suite.md`
  was absolved by a `tests/**` ignore blanket — precisely the laundering the
  manifest's own rules forbid. All are seeded now, with real fillable structure:
  headings, a one-line *what goes here* under each, and a worked generic example
  where it clarifies. Scaffold goes **36 → 45 paths** (21 directories, 24 files); the
  four skills that branched on one of these files *existing* now check whether it was
  **written**. What is still created on use is only what has no knowable filename
  until it is written — dated specs and plans, numbered ADRs, per-system GDDs,
  per-target asset specs. `manifest.yaml` records the rule, not just the count.
- **Seeding nine more documents does not inflate a virgin project's progress.** The
  regression this could have caused is exactly the one 0.5.0 already fixed once: a
  blank skeleton read as authored work. Every new markdown and YAML seed carries the
  existing `scaffold-seed: unwritten` marker, the JSON one is recognised by value
  (`primary_goal: null`), and `tools/workflow_state_check.py` still reports **0
  unrecorded, 0 conflict** on a virgin install. No detector changed.

## [0.5.0] - 2026-07-28 — the install is now what the skills describe

**What was wrong.** Every version up to 0.4.0 shipped a `.claude/` layer and
nothing else. The skills inside it command paths *outside* `.claude/` — "open
`data/_schemas/system_registry.json` first", "check `production/review-mode.txt`",
"append to `docs/devlog.md`", "resume from `production/session-state/active.md`" —
and the installer created none of them. On a fresh install those were instructions
pointing at files that did not exist, so a stranger's first session opened by
inventing the document stack the framework was supposed to hand them.

Some of what was commanded was not a document but a **program**. The
`consistency-check` skill advertised its runner in its own description ("Runner at
`tools/consistency_check.py`"), and `/update`, `/red-flag-scan` and `/session-close`
executed it as a gate — but that file had never been written. The first
`/session-close` on a real project crashed on a missing file. The same was true of
`tools/generate_systems_index.py`, which `hooks/sync-systems-index.sh` ran on every
registry write, and of `docs/skills-index.md`, which claimed to be auto-generated
while nothing generated it.

And the layout **contradicted itself in three directions at once**. Documents were
addressed as `design/gdd/…`, as `docs/gdd/…` and as `docs/architecture/adr-*` in
different files; game data lived at `assets/data/` in some skills and `data/` in
others. `CLAUDE.md` — the one file every fresh session reads cold — named
`docs/gdd/`, and **44 files named `design/gdd/` against 11 that agreed with it**.
The majority of the bundle disagreed with the map every session is told to trust.
The mechanical stage detector therefore reported "missing" for artifacts that were
sitting on disk under the other name.

**What this release is.** One canonical layout, an installer that creates it, the
three missing runners, and a regression guard that fails the build if a path or a
`/command` ever goes phantom again. Verified end to end against a fresh install,
not asserted.

### Added
- **`scaffold/` — the project document stack the skills read.** Both installers now
  seed **36 paths** (19 directories, 17 files): a valid, parseable and *empty*
  registry with its schema documented inline, a dev diary, the session handover
  file, `stage.txt` / `review-mode.txt` / `sprint-status.yaml` / `flow-ledger.yaml`,
  `devlog.md` / `implementation-status.md` / `open-flags.md`, the ADR and workstream
  templates in place, and the spec / plan / gdd / architecture / epic / sprint / qa
  directories. Six seeds are copies of shipped `templates/` documents, so no
  document is authored twice in this repo. The scaffold **never overwrites** — see
  *Upgrading* below.
- `--no-scaffold` (bash) / `-NoScaffold` (PowerShell) — install the `.claude/` layer
  alone, for projects that already have their own document stack.
- **`tools/consistency_check.py` — the runner four skills already commanded.** Pure
  Python 3 stdlib, cross-platform, 12 checks. The registry parses and carries the
  keys the skills read; entries have the required keys, a status from the vocabulary
  and unique ids; every registry path and id reference resolves; what is on disk
  (data dirs, autoloads, addons, project tools) is in the registry; every path
  `CLAUDE.md`'s reading map promises exists; the registry's own doc ledger resolves;
  specs and plans sit where their status says; ADR numbering, Status lines and
  `ADR-NNN` references hold up; the registry, `implementation-status.md` and
  `stage.txt` agree; no relative markdown link is broken; `active.md` is not lagging
  the newest commit; and every wired hook plus every `SKILL.md` frontmatter is
  intact. FAIL fails the run, WARN never does, and a check with nothing to look at
  yet says "not applicable" and keeps going — so a brand-new install exits 0 with a
  clean report instead of a traceback. Flags: `--quiet`, `--no-bump`, `--fix-safe`
  (creates absent empty directories and nothing else — never touches prose or data),
  `--stale-days N`, `--root DIR`.
- **`tools/doc_stack_check.py` — the regression guard.** Reads every path and every
  `/command` cited across `skills/`, `agents/`, `docs/`, `templates/`, `rules/` and
  `CLAUDE.md.template`, and classifies each as shipped, scaffolded, created-on-use,
  templated, ignored, killed or **phantom**. Non-zero phantom fails the run. It also
  cross-checks the `SCAFFOLD-BEGIN..SCAFFOLD-END` region of *both* installers against
  the manifest's scaffold promises, so a path can never be promised in one place and
  created in neither. `--project DIR` checks an installed project instead of the
  bundle. New paths are declared in `tools/doc_stack.manifest.json`, never in the
  script.
- **A slash-command cross-check in `tools/doc_stack_check.py`.** `/story-done` is not
  a path, so no missing-path rule could ever catch it; five declared commands
  survived a clean phantom-path sweep for exactly that reason. Every `/command` a
  shipped doc names is now checked against `skills/<name>/SKILL.md` and fails the run
  if no such skill ships. Exemptions live in the manifest's `slash_commands.ignore`
  block, each with a stated reason (Claude Code built-ins and two literal
  placeholders in the `/help` output template). Inspect with
  `--list PHANTOM-COMMAND | IGNORED-COMMAND`.
- **`/story-readiness` and `/story-done` — the two story gates 19 shipped files
  already commanded.** The story pipeline was documented end to end
  (`/create-stories` → `/story-readiness` → `/dev-story` → `/code-review` →
  `/story-done`), a director gate named one of them, the control manifest
  stamped a version for one to compare against, and the test-evidence template
  made the other its sign-off gate — but neither skill existed, so a stranger's
  pipeline dead-ended twice at a command nothing could fire. Both now ship, with
  the contracts the surrounding docs already specified.
- **`tools/generate_skills_index.py`.** `docs/skills-index.md` has always claimed
  to be auto-generated; nothing generated it, so it was hand-maintained and had
  drifted — every row clipped mid-word, one of them mid-slash-command
  (`/executing-pla`), which is how a routing table starts advertising commands
  that do not exist. The table now regenerates from `SKILL.md` frontmatter into a
  marked region, clipped on a word boundary with a visible ellipsis.
- **`docs/doc-stack.md` — the doc-stack contract, in one page.** Installed to
  `.claude/docs/doc-stack.md` and linked from `CLAUDE.md`'s reading map. Every
  artifact in the canonical layout as a table: path, what it is, who writes it,
  who reads it, and whether it is shipped, scaffolded or written on first use.
  The three-lifecycle vocabulary is stated once at the top, so "optional" has a
  precise meaning instead of being a shrug. This is the page a contributor or a
  future session opens to answer "where does X live?" without reading the
  manifest.
- **A graceful-degradation clause in every read-gate skill.** 57 skills and 10
  agents now carry the same sentence, byte for byte, before their first
  procedural step:
  *"If an artifact named here is absent: say so plainly in one line, skip that
  step, and continue. Never invent the file to satisfy a checklist, and never
  fail a close because an optional artifact was never created."*
  Ten pure-technique skills that read no project artifact are deliberately
  excluded. Because the wording is identical everywhere, coverage is one grep:
  `grep -rl "If an artifact named here is absent:" .claude/skills .claude/agents`.
  This is what lets a project run a deliberately lean stack — the skills adapt
  to a missing file instead of commanding it into existence.
- **`tools/generate_systems_index.py` — the runner the sync hook already
  executed.** `hooks/sync-systems-index.sh` ran it on every registry write and
  `/design-system` told the session to run it, but it had never shipped, so the
  hook's one branch could only ever fail silently. It exists now: it regenerates
  the systems table in `docs/gdd/systems-index.md` from
  `data/_schemas/system_registry.json`, touching only the text between
  `<!-- SYSTEMS-TABLE:BEGIN -->` and `<!-- SYSTEMS-TABLE:END -->` (markers now in
  `templates/systems-index.md`). Everything else in that file is hand-authored
  and is never rewritten. Absent registry, absent index or absent markers all
  exit 3 with a plain line and change nothing — it will not guess where a table
  belongs, and it will not overwrite prose.
- **`/setup-engine` step 2 creates the engine reference library.** `docs/engine-reference/<engine>/`
  was cited by five agents, four skills and two templates and shipped by nothing —
  it cannot ship, because it records what one *pinned* engine version does. The
  skill now offers to create it (`VERSION.md` plus three companion notes and a
  `modules/` folder), and every reader is labelled optional.
- **A GitHub Actions workflow (`.github/workflows/doc-stack.yml`).** On every push
  and pull request it runs `tools/doc_stack_check.py` against the bundle, installs
  the studio into a throwaway directory, re-runs the checker against that install
  with `--project`, and runs `tools/consistency_check.py` from inside it. It also
  asserts that every runner in `tools/` is registered in `consistency_check.py`'s
  framework-tools list. The drift this release repaired cannot return silently.

### Fixed
- **Two files still commanded `coding-standards.md`, which ships nowhere.**
  `agents/qa-tester.md` and `skills/dev-story/SKILL.md` opened their test
  sections with "classify the story type per `coding-standards.md`" / "test
  requirements (from coding-standards.md)". Both were bare filenames, which the
  doc-stack checker declares out of scope and never judged. The classification
  table and the requirements list follow inline in both files, so the clause was
  dropped and the naming rule repointed at `.claude/rules/test-standards.md`,
  which does ship.
- **`production/sprints/sprint-current.md` — a filename nothing will ever write.**
  `/sprint-plan` writes `sprint-[N].md`. Two docs sent a reader to
  `sprint-current.md`; both now name "the newest `production/sprints/sprint-*.md`".
- **Eight more phantom commands, found by the new cross-check.** `/smoke-check`
  repointed to the Smoke Test Scope section `/qa-plan` actually writes;
  `/team-qa` to `/qa-plan`; `/sprint-status` to `/sprint-plan status` (a real
  mode of a real skill); `/ux-design` and `/ux-review` to the `ux-designer` and
  `accessibility-specialist` agents that ship; `/test-setup` to a qa-lead +
  devops-engineer dispatch; `/test-helpers`, `/test-evidence-review`,
  `/test-flakiness`, `/team-live-ops` and `/skill-test` removed or repointed.
- **Six phantom files hidden inside fenced code blocks.**
  `skills/subagent-driven-development/SKILL.md` dispatched three subagents via
  `./implementer-prompt.md`, `./spec-reviewer-prompt.md` and
  `./code-quality-reviewer-prompt.md`; `skills/systematic-debugging/SKILL.md`
  pointed at `root-cause-tracing.md`, `defense-in-depth.md` and
  `condition-based-waiting.md` "in this directory". None ship. The prompts and
  the techniques are now written out inline, so both skills are self-contained.
- **`skills/brainstorming/visual-companion.md` was a 289-line operating manual
  for software this bundle does not ship** — server startup, the write/read
  loop, the frame's CSS classes, `scripts/start-server.sh`,
  `scripts/stop-server.sh`. That server belongs to the optional
  `obra/superpowers` plugin. The guide now keeps the visual-vs-terminal
  judgment, states the dependency plainly, tells the session not to offer the
  companion when the plugin is absent, and gives the terminal fallback.
- **The degradation clause reached the agent layer.** 13 agents that read project
  artifacts carried no absent-file behaviour, so a dispatched creative-director
  or qa-lead had none stated. All 13 now carry the identical sentence, and the
  three collaborative-protocol templates instruct every future agent to carry it
  too. Coverage: 82 files bundle-side, 80 in a default install (the difference is
  two clause-bearing agents that ship only with `--engine godot`) — both numbers
  are now stated in `docs/doc-stack.md` so the grep result is never a surprise.
- **Manifest `why` strings cited line numbers, and line numbers rot.** Four whys
  in `tools/doc_stack.manifest.json` pointed four lines past their subject after
  the previous edit shifted the files; one landed on a blank line. All 23
  line-number citations were stripped in favour of file-and-section names, and
  the manifest's own `_readme` now forbids them — along with whys that name a
  command which does not ship (one named `/ux-design`).
- **`counts:` in `manifest.yaml` disagreed with disk.** `tools: 3` while five
  runners install, `templates: 39` while 41 files exist. Every count now carries
  the command that reproduces it.
- **`/start` would have greeted a brand-new project with "already onboarded".**
  Found by walking the first-time path end to end after the scaffold landed. The
  scaffold is what broke it: `/start` treated *the existence of*
  `production/stage.txt` as proof the project had been onboarded, and the installer
  now always seeds that file — so a stranger's very first `start` would route them
  to Path D (`/adopt`, the **brownfield** path: "audit existing project artifacts")
  on an empty folder. Three more signals had gone constant the same way:
  `review-mode.txt` always exists, so the review-mode question would never be
  asked; `docs/gdd/game-concept.md` always exists as the blank template; and
  `docs/adr/*.md` matched the seeded `docs/adr/TEMPLATE.md`, so "ADRs exist?" was
  true on day one. **Existence stopped being evidence the moment the installer
  started creating things**, and every affected reader now judges *content*:
  `stage.txt` past its seeded default, a non-empty `systems[]`, an elevator pitch
  that is no longer bracketed prompt text. (The *mechanical* version of that rule —
  the `scaffold-seed` marker, and `stage.txt` seeded `not-started` rather than
  `concept` — arrived in Unreleased above, after this release's prose rule turned
  out not to bind the tools.) ADR globs across five skills narrowed from
  `docs/adr/*.md` to `docs/adr/[0-9]*.md` — the leading digit is what separates a
  decision from the skeleton beside it, which is the form
  `.claude/docs/workflow-catalog.yaml` already used. The rule is now stated once,
  for future skills, in `docs/doc-stack.md`.
- **`python tools/doc_stack_check.py`, run from a game project, reported ~56
  failures on a perfectly good install.** MODE 1 reads the *bundle's* source layout
  (`skills/`, `agents/`, `templates/` at the root); an installed project keeps all
  of that under `.claude/`, so every scaffold promise looked unkept and every skill
  looked like a phantom command. The bare command is the obvious thing to type from
  a project root — and the README now tells people to type it — so the tool detects
  where it is rather than requiring the user to know which flag the situation calls
  for. It prints one line saying which mode it chose. `--project DIR` still forces
  MODE 2 explicitly.
- **The installer posted one developer's Python bytecode into every project.**
  `copy_tree` copied `tools/` wholesale, and running any `tools/` runner inside a
  studio clone leaves `__pycache__/*.pyc` behind — so whether a project received a
  stray `.pyc` depended on whether the clone had ever been used. Both installers now
  exclude `__pycache__/`, `*.pyc` and OS cruft, which also makes the install count
  deterministic: **191 files** every time.
- **A fresh install's very first `/consistency-check` warned about a framework
  file.** Check 4 ("what is on disk but not in the registry") exempts the runners
  the template ships, because they belong to the template rather than to the game —
  but `tools/generate_skills_index.py` shipped after that list was written and was
  never added to it. Day one therefore opened with a warning about a file the user
  did not create and cannot be expected to register. Registered, and CI now asserts
  that every runner in `tools/` is on that list, so the next runner cannot repeat
  it. A fresh install is now **4 PASS, 0 WARN, 0 FAIL**.
- **The TR registry forked on its own file extension.** `/architecture-decision`
  wrote requirement coverage into `docs/architecture/tr-registry.md` while the skill
  that creates it, the skill that reads it at the gate, and `CLAUDE.md` all use
  `tr-registry.yaml` — a silent fork in the one piece of state a gate depends on.
  The guard could not catch it because the manifest covered `docs/architecture/*`
  with a single wildcard, so *both* spellings classified clean; that wildcard is now
  seven named entries, each naming the skill that writes it.
- **`min_count` was declared on 8 catalogue steps and read by nothing.** "Minimum 3
  Foundation-layer ADRs" was mechanically enforced as ">= 1".
  `tools/workflow_state_check.py` now honours it.
- **The repo's stale self-install is gone.** A single tracked file,
  `.claude/docs/workflow-catalog.yaml`, was a partial dogfood copy that had
  drifted against its source (still globbing the retired `production/playtests/`
  a release after the source was fixed). `scripts/install.sh` refuses to install
  into this repo at all, so that copy could only ever drift. Removed, and
  `/.claude/` is now gitignored with the reason.

### Changed
- **BREAKING (for the layout, not for your files): one canonical layout.** A fresh
  session read `CLAUDE.md` and was pointed one way; the skills wrote another way;
  `docs/workflow-catalog.yaml` looked for the artifacts in a third place — so the
  mechanical stage detector reported "missing" for artifacts that existed. Measured
  on the bundle before the repair: **44 files said `design/gdd`, 11 said `docs/gdd`;
  22 said `docs/adr/`, 8 said `docs/architecture/adr-`; 5 said `assets/data/` while
  21 said `data/_schemas`.** `CLAUDE.md` is the one file every fresh session reads
  cold, so its reading map is now the law and every other reference was moved to it:

  | Was | Is |
  |---|---|
  | `design/gdd/**` | `docs/gdd/**` |
  | `design/art/art-bible.md` | `docs/art-bible.md` |
  | `design/live-ops/**`, `design/{ux,levels,narrative,assets}/**` | `docs/live-ops/**`, `docs/{ux,levels,narrative,assets}/**` |
  | `design/quick-specs/` | `docs/specs/` (a quick spec is a spec) |
  | `design/registry/entities.yaml` | removed — the entity authority **is** `data/_schemas/system_registry.json` |
  | `docs/architecture/adr-*.md` | `docs/adr/NNN-<slug>.md` |
  | `assets/data/` | `data/` |

  `docs/architecture/` survives and keeps exactly three files: `architecture.md`,
  `control-manifest.md`, `tr-registry.yaml`. There is no top-level `design/` layer
  any more, so the guard treats a bare `design/` prefix as a retired convention — a
  stray `design/whatever/` is caught the day it is written. Retired-convention
  references in the bundle and in a fresh install: **0**.
- The scaffold step **never overwrites**: an existing file is left untouched and
  counted as skipped, so a live project's real registry, devlog and session state
  survive any number of re-runs. Running the installer twice is a byte-for-byte
  no-op the second time (`seeded 0 · skipped 29`).
- `tools/doc_stack_check.py` now sees a kept promise: installer scaffold coverage
  went from 0/34 covered to 36/36, and the "unscaffolded promises" failure class
  dropped to zero. Against a fresh install, commanded-but-missing paths fell from
  46 to 0.
- `manifest.yaml` gains a `scaffold:` section — what the installer seeds, the
  never-overwrite policy, the opt-out flag, and the command that verifies it.

### Upgrading from 0.4.x

**Re-run the installer over your project.** That is the whole upgrade:

```bash
git pull                                          # in your studio clone
bash /path/to/shiningplague-studio/scripts/install.sh /path/to/your/game
```

- **Nothing you already have is overwritten by the scaffold.** Every seeded
  artifact is create-if-absent. Your registry, your devlog, your session state,
  your specs and ADRs are left exactly as they are; the installer reports them as
  `skipped (exists)`. If your project already has a full document stack, the
  scaffold step is a no-op and you can skip it outright with `--no-scaffold`.
- **The `.claude/` layer *is* updated in place** — that is where the repaired
  skills live, and it is the framework's, not yours. If you edited a skill, agent,
  hook or rule locally, the installer prints every file it overwrote and tells you
  to recover from your project's git history. **Commit your project before
  upgrading.**
- **`CLAUDE.md` and `.claude/settings.json` are never overwritten**, in this
  release as in every previous one. If you want the new reading map (it now names
  `docs/doc-stack.md`), diff yours against `CLAUDE.md.template` by hand.
- **If your project used the old paths** (`design/gdd/`, `docs/architecture/adr-*`,
  `assets/data/`), your files still work — nothing moves them. But the repaired
  skills now write to the canonical paths, so you will end up with both. Either
  move your documents to the canonical layout, or edit your `CLAUDE.md` reading map
  to name your paths; the skills follow `CLAUDE.md`.
- **Then check it**, from your project root:
  ```
  python tools/consistency_check.py
  ```
  Exit 0 means the stack is coherent. It is the same gate `/session-close` runs.

### Not changed

- **Attribution.** `LICENSE` (MIT, preserving Kirill Ivanov / Donchitos'
  copyright), `CREDITS.md` and the `lineage` block in `manifest.yaml` are
  untouched. The upstream credit to Donchitos and obra/superpowers travels with
  every copy.
- **Prerequisites: still none.** `obra/superpowers` and `anthropic-skills` remain
  optional enhancers, never required.
- **Isolation: still 100% project-local.** Nothing is written to `~/.claude` or any
  user-level path.
- **No skill was removed**, and no skill's trigger phrasing changed. The interaction
  model — you talk, the studio routes — is identical.
- **`tools/workflow_state_check.py`** keeps its interface and its flow-ledger
  contract; it gained `min_count` enforcement, nothing more.

## [0.4.0] - 2026-07-20 — first public release

### Added
- One-paste setup: README ships a message you paste into Claude Code; Claude clones, installs, cleans up, interviews you for the 3 project fill-ins, and suggests your first move. Installers now default to the current directory (guarded against running inside the studio repo itself).
- `docs/skills-index.md` + `docs/agents-index.md` — machine-readable routing tables (auto-generated from frontmatter); every reference across the bundle now resolves on a fresh install.
- `docs/START-HERE.md` — Claude's 15-minute orientation. All docs are Claude's reference library; users drive everything from the conversation.
- Adaptive mode sensing in CLAUDE.md + session-start hook: LIGHT default (act directly, no ceremony) with FULL discipline (director briefs, gates, strict pipeline) engaged when signals warrant — Claude chooses per-request.
- `production/README.md` explaining the state directory.

### Changed
- Newbie lean pass: README rewritten for first-timers; CLAUDE.md.template cut to ~150 lines with safe defaults; drill-language ("MANDATORY", "PROTOCOL FAIL") softened to recommendations across hooks; advanced docs labeled as such.
- Engine pack `other` renamed `multiplayer` (matches README/installer naming).
- Template count corrected (41).

## [0.3.0] - 2026-07-20

### Added
- **Zero prerequisites** — the studio is now fully self-contained. The two skills that
  previously required plugins are bundled: `godot-engine` (was `anthropic-skills:godot`)
  and `dispatching-parallel-agents` (was superpowers-only). All plugin-namespace
  references across skills, agents, hooks, and docs repointed to the bundled versions.
  `obra/superpowers` and `anthropic-skills` remain documented as optional enhancers,
  never required. Skill count: 67.
- `templates/settings.template.json` — Claude Code hook wiring for all 13 shipped hooks
  (SessionStart/SessionEnd, PreToolUse/PostToolUse validators, PreCompact/post-compact,
  Notification, SubagentStart/Stop logging, UserPromptSubmit skill-trigger detection).
  The installer copies it to `<project>/.claude/settings.json` when none exists;
  otherwise it prints a merge-the-hooks-block-manually notice.

### Changed
- **Fresh-start neutrality** — all game-specific references removed from the template.
  Lineage remains credited (Donchitos, obra/superpowers) but the project the studio was
  hardened on is referred to generically as "a Godot narrative-RPG project."
- **Isolated project-local installer** — `scripts/install.sh` and `scripts/install.ps1`
  rewritten. Everything installs inside the target game project (`.claude/` + `tools/`);
  nothing is ever written to `~/.claude` or any user-level path. Per-project installs
  mean edits stay in that project and a new game gets a fresh install. Idempotent
  re-runs update in place with a diff count warning on locally modified files;
  `CLAUDE.md` and `settings.json` are never overwritten. Optional
  `--engine unity|unreal|godot-extras|multiplayer` installs an agent engine pack.

### Fixed
- **46 phantom paths — the artifacts this bundle was extracted from, still cited
  as if they ship.** `tools/doc_stack_check.py` now reports zero. The repairs, by
  kind: upstream `superpowers` spec/plan folders repointed to `docs/specs/` and
  `docs/plans/`; `production/stories/` repointed to `production/epics/`;
  `production/playtests/` repointed to `production/session-logs/playtest-*.md`,
  which is where `/qa-plan` actually writes; `production/gate-checks/` and
  `production/retrospectives/` replaced with the artifacts those skills really
  produce; `docs/migration/adoption-plan-*.md` repointed to the
  `docs/adoption-plan-*.md` that `/adopt` writes; `.claude/docs/godot-gotchas.md`
  corrected to `.claude/docs/engine-notes/godot-gotchas.md`;
  `.claude/docs/coding-standards.md` and a non-existent changelog template
  dropped for the files that do ship; the `agents/*.md` and `skills/*/SKILL.md`
  self-references in the two indexes corrected to their installed `.claude/`
  paths; a project-specific bug auto-promotion script and two brainstorm server
  helper files removed as references; and `production/security/`,
  `production/releases/`, `production/community/` and `production/milestones/`
  declared in the manifest with the skill or agent that writes each one named.
- **Example content named after the projects this framework was extracted from.**
  ADR batching examples, a headless harness filename, a concrete autoload and its
  data file, and a `docs/market-research/` folder are now generic or explicitly
  labelled illustrative. A stranger reading any sentence is no longer sent to a
  file that will not be there.
- **The consistency gate failed a brand-new install.** `CLAUDE.md`'s reading map
  names `docs/architecture/architecture.md`, `control-manifest.md` and
  `tr-registry.yaml` — three files `/create-architecture` and
  `/create-control-manifest` write later. Check 5 counted all three as broken
  promises, so the first `/session-close` in a fresh project failed on artifacts
  nothing had had a reason to create yet. It now reads the `created_on_use` list
  out of `tools/doc_stack.manifest.json` (one list, not two) and reports those as
  "not written yet". A path that genuinely nothing creates still fails.
- **`/create-architecture` hard-stopped on an optional artifact.** It told the
  session to read the engine reference library "completely" and then to stop if
  it was missing. It now says so in one line, records that engine claims are
  unverified against a pinned version, and continues; the stop is reserved for
  a project with no engine configured at all.
- **Manifest version sync** — the 0.2.0 changelog entry existed but `manifest.yaml`
  still said 0.1.0; the manifest version now tracks the changelog (0.3.0).

### Upstream note
- Donchitos' Claude-Code-Game-Studios has been dormant since its v1.0.0 (2026-05-13).
  The agents in this bundle carry roughly two months of divergent hardening on top of
  that baseline; treat this repo, not upstream, as the maintained line.

## [0.2.0] - 2026-07-04

### Added
- `tools/workflow_state_check.py` — mechanical (zero-LLM) workflow-state detection. Cross-checks a human-authored flow ledger against artifact evidence on disk, flags conflicts / unrecorded work / illegitimate skips, honors designer-decision (`rule_pending`) blockers, and derives the recommended next step. Includes BOOTSTRAP MODE for fresh repos (infers a draft ledger from artifact existence). Pure stdlib — PyYAML if present, built-in mini-parser fallback if not.
- `templates/flow-ledger.TEMPLATE.yaml` — flow-ledger scaffold: schema/how-to-edit header plus done-with-evidence, leapfrogged-with-reason, and custom example steps.
- Session-hook integration — `hooks/session-start.sh` now calls the checker (`--brief`) under a CANONICAL-RECOMMENDED NEXT ACTION block, with a static fallback when Python or the tool is unavailable.
- `docs/flow-ledger.md` — documents the system (catalog vs ledger vs checker, verdicts, rule-pending blockers, recommended-next derivation, bootstrap story, session-hook role).

## [0.1.0] - 2026-07-04

### Added
- Initial ShiningPlague Game Studio framework: 65 workflow skills, 35 active agents (+14 in engine packs), 13 hooks, 11 path-scoped rules, 37 document templates, director-gated pipelines, installers, and `CLAUDE.md.template`. Adopted from Donchitos' Claude-Code-Game-Studios and the obra/superpowers skill methodology; MIT-licensed with upstream attribution preserved.
