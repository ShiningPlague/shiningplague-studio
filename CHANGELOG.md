# Changelog

All notable changes to the ShiningPlague Game Studio framework are recorded here.
The format follows [Keep a Changelog](https://keepachangelog.com/); versions follow
[Semantic Versioning](https://semver.org/).

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
