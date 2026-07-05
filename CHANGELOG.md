# Changelog

All notable changes to the ShiningPlague Game Studio framework are recorded here.
The format follows [Keep a Changelog](https://keepachangelog.com/); versions follow
[Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-07-04

### Added
- `tools/workflow_state_check.py` — mechanical (zero-LLM) workflow-state detection. Cross-checks a human-authored flow ledger against artifact evidence on disk, flags conflicts / unrecorded work / illegitimate skips, honors designer-decision (`rule_pending`) blockers, and derives the recommended next step. Includes BOOTSTRAP MODE for fresh repos (infers a draft ledger from artifact existence). Pure stdlib — PyYAML if present, built-in mini-parser fallback if not.
- `templates/flow-ledger.TEMPLATE.yaml` — flow-ledger scaffold: schema/how-to-edit header plus done-with-evidence, leapfrogged-with-reason, and custom example steps.
- Session-hook integration — `hooks/session-start.sh` now calls the checker (`--brief`) under a CANONICAL-RECOMMENDED NEXT ACTION block, with a static fallback when Python or the tool is unavailable.
- `docs/flow-ledger.md` — documents the system (catalog vs ledger vs checker, verdicts, rule-pending blockers, recommended-next derivation, bootstrap story, session-hook role).

## [0.1.0] - 2026-07-04

### Added
- Initial ShiningPlague Game Studio framework: 65 workflow skills, 35 active agents (+14 in engine packs), 13 hooks, 11 path-scoped rules, 37 document templates, director-gated pipelines, installers, and `CLAUDE.md.template`. Adopted from Donchitos' Claude-Code-Game-Studios and the obra/superpowers skill methodology; MIT-licensed with upstream attribution preserved.
