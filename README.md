# ShiningPlague Game Studio

*A complete multi-agent game-development studio for Claude Code — 67 workflow skills, 49 specialist agents, gated pipelines, and hooks that turn Claude Code into a coordinated dev team.*

---

## What it is

ShiningPlague Game Studio is a portable framework that gives [Claude Code](https://docs.anthropic.com/en/docs/claude-code) the structure of a real game studio. It ships five kinds of building block:

- **Skills** — guided workflows you invoke (brainstorming, writing a GDD, planning a sprint, running a code review, closing a session). A skill walks Claude through a repeatable process instead of improvising one.
- **Agents** — specialist subagents that skills dispatch (game designer, systems designer, gameplay programmer, narrative director, QA lead, and more). Each runs in its own context with a scoped toolset and returns a report.
- **Hooks** — automated reminders and checks wired into the session lifecycle (session-start briefings, keyword→skill trigger detection, consistency gates).
- **Rules** — path-scoped coding standards that apply automatically to the files they govern.
- **Templates** — design and production document scaffolds (GDDs, ADRs, specs, plans, sprint files, workstream state).

These are organized into **director-gated pipelines** that move work through phases — **Concept → Design → Architecture → Production → Release** — with director agents reviewing readiness between phases.

## Lineage & credit

ShiningPlague was born out of adapting **[Donchitos' Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)** (MIT © Kirill Ivanov) together with the **[obra/superpowers](https://github.com/obra/superpowers)** skill methodology, then hardening the result on a real project — a Godot narrative-RPG.

Donchitos provided the original agent roster, template set, and pipeline architecture — the backbone this studio stands on. The obra/superpowers work provided the skill-authoring methodology and the discipline skills (brainstorming, test-driven development, systematic debugging, verification-before-completion, writing-skills). ShiningPlague evolves those foundations with a formalized skills protocol, session and goal tracking, director gates, and a decluttered, verified skill set shaped by day-to-day production use.

If you build with this, the credit runs upstream: Donchitos and obra did the hard early work, and Anthropic built Claude Code and the anthropic-skills the studio can lean on. See [CREDITS.md](CREDITS.md) for the full attribution detail.

## Prerequisites

**None. The studio is fully self-contained.** Every skill, agent, hook, rule, and template it references ships in this bundle — clone, install, go.

### Optional enhancers

Two Claude Code plugins pair well with the studio but are **never required** — every studio workflow runs without them:

- **`obra/superpowers`** — the upstream home of the discipline-skill methodology. Adds the vanilla `superpowers:*` skill set (brainstorming, TDD, systematic debugging, verification, plan writing) alongside the studio's adapted versions, so you can compare or fall back to the originals.
- **`anthropic-skills`** — Anthropic's skill collection. Adds deep per-engine expertise (the `godot` and `unity-development` skills), plus general-purpose document/media skills the workflows can dispatch to when present.

Install either via the Claude Code plugin marketplace (`/plugin install superpowers`, `/plugin install anthropic-skills`) whenever you want the extra depth.

## Engine-agnostic

This studio is **not engine-specific**. The core skills and agents are engine-neutral, and the roster ships specialist packs for **Godot, Unity, and Unreal** (see `agents/engine-packs/`).

It grew inside a Godot project, so where an example needs to be concrete it defaults to Godot idioms (a headless validation harness, `.tscn`/`.gd` checks). Treat those as **reference implementations** — the shape of the check is the point; swap in your engine's equivalent.

## Install (quickstart)

Built for **Claude Code**. Installation is **100% project-local** — everything lands inside your game project, nothing touches your personal `~/.claude`.

```bash
git clone https://github.com/ShiningPlague/shiningplague-studio.git
cd shiningplague-studio

# macOS / Linux / Git Bash
./scripts/install.sh /path/to/your/game

# Windows (PowerShell)
./scripts/install.ps1 C:\path\to\your\game
```

The installer copies `skills/`, `agents/` (top-level roster), `hooks/`, `rules/`, `docs/` + `templates/` into `<project>/.claude/`, puts `tools/` at `<project>/tools/`, seeds `<project>/CLAUDE.md` from the template (only if the project has none), and wires the hooks by writing `<project>/.claude/settings.json` (only if absent — otherwise it tells you to merge the hooks block manually).

Optional engine packs: `--engine unity|unreal|godot-extras|multiplayer` (bash) / `-Engine unity` (PowerShell) adds that specialist pack to `.claude/agents/`.

Re-running the installer updates the install in place and prints a diff count so locally modified files don't get silently replaced. `CLAUDE.md` and `settings.json` are never overwritten.

**Isolation model:** every install is per-project — the studio files are copied into that project, and any edits you make to skills, agents, hooks, or rules stay in that project. A new game means a fresh install, and nothing ever touches your personal `~/.claude`.

### Manual install (fallback)

If you'd rather not run a script, copy everything project-local by hand:

1. Copy `skills/` into `<project>/.claude/skills/`.
2. Copy `agents/*.md` (top level; add any `agents/engine-packs/<pack>/` you want) into `<project>/.claude/agents/`.
3. Copy `hooks/` into `<project>/.claude/hooks/` and `rules/` into `<project>/.claude/rules/`.
4. Copy `docs/` into `<project>/.claude/docs/` and `templates/` into `<project>/.claude/docs/templates/`.
5. Copy `tools/` into `<project>/tools/`.
6. Copy `CLAUDE.md.template` to your project root as `CLAUDE.md` (skip if one exists) and fill the `{{PLACEHOLDER}}` fields.
7. Copy `templates/settings.template.json` to `<project>/.claude/settings.json` to wire the hooks (or merge its `hooks` block into your existing settings.json).

Every install is per-project and edits stay in that project — a new game gets a fresh install. Nothing goes into (or reads from) your personal `~/.claude`.

## Repo structure

```
shiningplague-studio/
├── skills/                 # Guided workflows → <project>/.claude/skills/
├── agents/                 # Specialist subagents → <project>/.claude/agents/
│   └── engine-packs/       # Optional Godot / Unity / Unreal / multiplayer packs
├── hooks/                  # Session-lifecycle hooks → <project>/.claude/hooks/
├── rules/                  # Path-scoped coding standards → <project>/.claude/rules/
├── templates/              # Doc scaffolds + settings.template.json → <project>/.claude/docs/templates/
├── docs/                   # Framework documentation → <project>/.claude/docs/
├── tools/                  # Project runtime tools → <project>/tools/
├── scripts/                # install.sh / install.ps1 (project-local installers)
├── CLAUDE.md.template      # Project instruction file → <project>/CLAUDE.md (seeded if absent)
├── manifest.yaml           # Inventory + lineage + install targets
├── CHANGELOG.md
├── CREDITS.md
└── LICENSE
```

## How it works (brief)

- **Skills are workflows you invoke.** Say what you want ("brainstorm this feature", "plan the next sprint", "review this code") and the matching skill runs its process.
- **Agents are specialists that skills dispatch.** A skill hands scoped work to the right agent — the game designer writes the GDD, the gameplay programmer implements, the QA lead builds the test plan — and synthesizes their reports back.
- **Eight MUST-USE discipline skills** auto-fire on trigger and keep the work honest: `using-superpowers` (chat start), `brainstorming` (before any creative work), `test-driven-development` (before implementation code), `systematic-debugging` (on any bug), `verification-before-completion` (before any "done" claim), the engine skill (when touching engine files), `writing-skills` (when editing a skill), and `session-close` (at session end).
- **Two pipeline paths.** The **small path** (brainstorm → ADR → plan → execute) handles single-system work in a week or two. The **large path** adds the full ceremony — GDD → system decomposition → architecture → control manifest → epics → stories → implementation → QA → gate — for multi-vertical work. Brainstorm first, then choose the path the scope actually needs.
- **Mechanical workflow-state detection.** A small, zero-LLM checker (`tools/workflow_state_check.py`) reads a human-authored **flow ledger** (`production/flow-ledger.yaml`) of what's done / skipped-with-reason, cross-checks every claim against the files that actually exist, and derives the honest next step — surfaced at every session start. Fresh repo? Run it once for a **bootstrap** draft to review. See [docs/flow-ledger.md](docs/flow-ledger.md).

## Honest status

This is an **early public release**, hardened on one real production project. The framework is game-neutral and self-contained, but expect to tune reference implementations (engine checks, example paths) to your own project rather than dropping it in untouched.

Contributions and forks welcome.

## License

MIT. The license preserves Donchitos' original copyright and adds ShiningPlague's adaptations. See [LICENSE](LICENSE) and [CREDITS.md](CREDITS.md).
