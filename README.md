# ShiningPlague Game Studio

*A complete multi-agent game-development studio for Claude Code — 65 workflow skills, 49 specialist agents, gated pipelines, and hooks that turn Claude Code into a coordinated dev team.*

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

ShiningPlague was born out of adapting **[Donchitos' Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)** (MIT © Kirill Ivanov) together with the **[obra/superpowers](https://github.com/obra/superpowers)** skill methodology, then hardening the result on a real project — *Sons of Gilgamesh*, a Godot 4.6 narrative RPG.

Donchitos provided the original agent roster, template set, and pipeline architecture — the backbone this studio stands on. The obra/superpowers work provided the skill-authoring methodology and the discipline skills (brainstorming, test-driven development, systematic debugging, verification-before-completion, writing-skills). ShiningPlague evolves those foundations with a formalized skills protocol, session and goal tracking, director gates, and a decluttered, verified skill set shaped by day-to-day production use.

If you build with this, the credit runs upstream: Donchitos and obra did the hard early work, and Anthropic built Claude Code and the anthropic-skills the studio leans on. See [CREDITS.md](CREDITS.md) for the full attribution detail.

## Engine-agnostic

This studio is **not Godot-specific**. The core skills and agents are engine-neutral, and the roster ships specialist packs for **Godot, Unity, and Unreal** (see `agents/engine-packs/`).

It grew inside a Godot project, so some skill and hook bodies reference *Sons of Gilgamesh* as a concrete worked example. Treat those as **reference implementations** — patterns to adapt to your own engine and project, not requirements. Where a body says "run the Godot headless harness," the shape of the check is the point; swap in your engine's equivalent.

## Install (quickstart)

Built for **Claude Code**.

```bash
git clone https://github.com/ShiningPlague/shiningplague-studio.git
cd shiningplague-studio

# macOS / Linux
./scripts/install.sh

# Windows (PowerShell)
./scripts/install.ps1
```

The installer copies `skills/` into your user-level `~/.claude/skills/` (so skills are portable across projects) and scaffolds the studio files into a project's `.claude/`.

**Prerequisite plugins** — install these via the Claude Code plugin marketplace before running the studio, as several discipline skills defer to them:

- `obra/superpowers` — discipline skills + skill-authoring methodology
- `anthropic-skills` — Anthropic's skill collection (includes the Godot skill)

### Manual install (fallback)

1. Copy `skills/*` into `~/.claude/skills/`.
2. Copy `agents/`, `hooks/`, and `rules/` into your project's `.claude/` directory.
3. Copy `CLAUDE.md.template` to your project root as `CLAUDE.md` and fill in the `{{PLACEHOLDER}}` fields.

## Repo structure

```
shiningplague-studio/
├── skills/               # Guided workflows (invoke via the Skill tool) → ~/.claude/skills/
├── agents/               # Specialist subagents
│   └── engine-packs/     # Godot / Unity / Unreal specialist agents
├── hooks/                # Session-lifecycle hooks (reminders, gates, triggers)
├── rules/                # Path-scoped coding standards
├── templates/            # GDD / ADR / spec / plan / sprint doc scaffolds
├── docs/                 # Framework documentation
├── scripts/              # install.sh / install.ps1
├── CLAUDE.md.template     # Project instruction file to copy + fill
├── manifest.yaml          # Inventory + lineage + install targets
├── CREDITS.md
└── LICENSE
```

## How it works (brief)

- **Skills are workflows you invoke.** Say what you want ("brainstorm this feature", "plan the next sprint", "review this code") and the matching skill runs its process.
- **Agents are specialists that skills dispatch.** A skill hands scoped work to the right agent — the game designer writes the GDD, the gameplay programmer implements, the QA lead builds the test plan — and synthesizes their reports back.
- **Eight MUST-USE discipline skills** auto-fire on trigger and keep the work honest: `using-superpowers` (chat start), `brainstorming` (before any creative work), `test-driven-development` (before implementation code), `systematic-debugging` (on any bug), `verification-before-completion` (before any "done" claim), `anthropic-skills:godot` (when touching engine files), `writing-skills` (when editing a skill), and `session-close` (at session end).
- **Two pipeline paths.** The **small path** (brainstorm → ADR → plan → execute) handles single-system work in a week or two. The **large path** adds the full ceremony — GDD → system decomposition → architecture → control manifest → epics → stories → implementation → QA → gate — for multi-vertical work. Brainstorm first, then choose the path the scope actually needs.

## Honest status

This is a **first public release**. Skill and hook bodies contain *Sons of Gilgamesh* examples as worked references; full project-parameterization (extracting those into `{{PLACEHOLDER}}` fields) is in progress. Some paths and counts reflect the project it grew inside. It works, and it's been used in real production — but expect to adapt reference implementations to your own project rather than dropping it in untouched.

Contributions and forks welcome.

## License

MIT. The license preserves Donchitos' original copyright and adds ShiningPlague's adaptations. See [LICENSE](LICENSE) and [CREDITS.md](CREDITS.md).
