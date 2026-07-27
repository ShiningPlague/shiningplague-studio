# Changelog

All notable changes to the ShiningPlague Game Studio framework are recorded here.
The format follows [Keep a Changelog](https://keepachangelog.com/); versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **`/story-readiness` and `/story-done` — the two story gates 19 shipped files
  already commanded.** The story pipeline was documented end to end
  (`/create-stories` → `/story-readiness` → `/dev-story` → `/code-review` →
  `/story-done`), a director gate named one of them, the control manifest
  stamped a version for one to compare against, and the test-evidence template
  made the other its sign-off gate — but neither skill existed, so a stranger's
  pipeline dead-ended twice at a command nothing could fire. Both now ship, with
  the contracts the surrounding docs already specified.
- **A slash-command cross-check in `tools/doc_stack_check.py`.** `/story-done` is
  not a path, so no missing-path rule could ever catch it; five declared
  commands survived a clean phantom-path sweep for exactly that reason. Every
  `/command` a shipped doc names is now checked against `skills/<name>/SKILL.md`
  and fails the run if no such skill ships. Exemptions live in the manifest's
  new `slash_commands.ignore` block — six entries, each with a stated reason
  (Claude Code built-ins and two literal placeholders in the `/help` output
  template). Inspect with `--list PHANTOM-COMMAND | IGNORED-COMMAND`.
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
- **`tools/consistency_check.py` — the runner four skills already commanded.**
  `consistency-check` advertised it in its own description ("Runner at
  tools/consistency_check.py"), and `/update`, `/red-flag-scan` and
  `/session-close` executed it as a gate — but it had never shipped, so on a real
  project the close ritual crashed on a missing file. It exists now: pure Python
  3 stdlib, cross-platform, 12 checks. The registry parses and carries the keys
  the skills read; entries have the required keys, a status from the vocabulary
  and unique ids; every registry path and id reference resolves; what is on disk
  (data dirs, autoloads, addons, project tools) is in the registry; every path
  `CLAUDE.md`'s reading map promises exists; the registry's own doc ledger
  resolves; specs and plans sit where their status says; ADR numbering, Status
  lines and `ADR-NNN` references hold up; the registry, `implementation-status.md`
  and `stage.txt` agree; no relative markdown link is broken; `active.md` is not
  lagging the newest commit; and every wired hook plus every `SKILL.md`
  frontmatter is intact. FAIL fails the run, WARN never does, and a check with
  nothing to look at yet says "not applicable" and keeps going — so a
  brand-new install exits 0 with a clean report instead of a traceback.
  Flags: `--quiet`, `--no-bump`, `--fix-safe` (creates absent empty directories
  and nothing else — never touches prose or data), `--stale-days N`, `--root DIR`.
- **`scaffold/` — the project document stack the skills read.** The installer used to
  create the `.claude/` layer and nothing else, so every instruction that pointed
  outside it ("open `data/_schemas/system_registry.json` first", "check
  `production/review-mode.txt`", "append to `docs/devlog.md`", "resume from
  `production/session-state/active.md`") was commanding a file no fresh install had.
  Both installers now seed 36 paths — a valid empty registry with documented schema
  notes, a dev diary, the handover file, stage + review-mode + sprint-status +
  flow-ledger, devlog / implementation-status / open-flags, the ADR and workstream
  templates in place, and the spec / plan / gdd / architecture / epic / sprint / qa
  directories. Six of them are copies of shipped `templates/` documents, so no
  document is authored twice in this repo.
- `--no-scaffold` (bash) / `-NoScaffold` (PowerShell) — install the `.claude/` layer
  alone, for projects that already have their own document stack.

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
- **The repo's stale self-install is gone.** A single tracked file,
  `.claude/docs/workflow-catalog.yaml`, was a partial dogfood copy that had
  drifted against its source (still globbing the retired `production/playtests/`
  a release after the source was fixed). `scripts/install.sh` refuses to install
  into this repo at all, so that copy could only ever drift. Removed, and
  `/.claude/` is now gitignored with the reason.

### Changed
- The scaffold step **never overwrites**: an existing file is left untouched and
  counted as skipped, so a live project's real registry, devlog and session state
  survive any number of re-runs. Running the installer twice is a byte-for-byte
  no-op the second time (`seeded 0 · skipped 29`).
- `tools/doc_stack_check.py` now sees a kept promise: installer scaffold coverage
  went from 0/34 covered to 36/36, and the "unscaffolded promises" failure class
  dropped to zero. Against a fresh install, commanded-but-missing paths fell from
  46 to 2 (the two remaining are runners, not documents).

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
