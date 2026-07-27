# Changelog

All notable changes to the ShiningPlague Game Studio framework are recorded here.
The format follows [Keep a Changelog](https://keepachangelog.com/); versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
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
