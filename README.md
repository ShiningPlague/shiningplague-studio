# ShiningPlague Game Studio

*A multi-agent game-development studio for Claude Code — you talk about your game in plain words, and a coordinated team of workflow skills and specialist agents does the rest.*

---

## What is this

ShiningPlague Game Studio is a set of files you install into your game project that turns [Claude Code](https://docs.anthropic.com/en/docs/claude-code) from a single improvising assistant into a coordinated studio. You say what you want in normal language — "design my combat system", "something's broken", "what should I do next" — and the studio routes it to the right specialist and the right workflow. You never need to memorize commands or process: the studio proposes the process, and you say yes, no, or "just do it the simple way".

## Setup (paste this into Claude Code)

Never used Claude Code skills or agents before? You don't need to have. Open [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in your game folder — brand-new and empty is fine — and paste this one message. No typing into files or terminals; you just answer three questions.

```text
Set up the ShiningPlague Studio in this project:
1. git clone https://github.com/ShiningPlague/shiningplague-studio.git .sp-studio-tmp
2. bash .sp-studio-tmp/scripts/install.sh .
3. run: python tools/consistency_check.py   — it should exit 0
4. delete the .sp-studio-tmp folder
5. Read the new CLAUDE.md, then ask me (one question at a time) for: project name, engine + version, and a one-sentence description of my game — and fill those into CLAUDE.md for me.
6. Tell me the studio is ready and suggest my first move.
```

Setup is **100% project-local**: everything lands inside your game folder (`.claude/` + `tools/` + a seeded `CLAUDE.md` + the document stack the skills read — `docs/`, `data/`, `production/`), and nothing ever touches your personal `~/.claude`. Each game gets its own install, and edits you make stay in that project. Re-running the installer later updates the `.claude/` layer in place — your `CLAUDE.md`, `.claude/settings.json` and every seeded document are never overwritten.

### Check it landed

Two commands, both pure-stdlib Python 3, both runnable the second the installer finishes:

```bash
python tools/consistency_check.py     # is this project's doc stack coherent?
python tools/doc_stack_check.py       # does every path the docs command actually exist?
```

`consistency_check.py` is the gate the close ritual runs — 12 checks over your registry, your docs and your ADRs. On a brand-new install it exits **0** and reports `4 PASS, 0 FAIL` with 8 checks that have nothing to look at yet saying so plainly. `doc_stack_check.py` is the regression guard: it reads every path and every `/command` the shipped docs name and fails if any of them is a phantom. Run bare from your project root it detects that it is looking at an install and checks that the install landed complete; run bare from a studio clone it checks the bundle instead. Neither one writes to your game.

<details>
<summary><strong>Manual install</strong> (if you'd rather run it yourself)</summary>

```bash
git clone https://github.com/ShiningPlague/shiningplague-studio.git
bash shiningplague-studio/scripts/install.sh /path/to/your/game
```

Windows PowerShell: `./shiningplague-studio/scripts/install.ps1 C:\path\to\your\game`. **The target does not have to exist** — both installers create it (and say so) when it is absent, so `install.sh ./my-new-game` is a valid first command. Run with no argument from inside your game folder (empty/new folders work too) and it installs there; it refuses to install into the studio repo itself. Optional engine agent packs: `--engine unity|unreal|godot-extras|multiplayer` (bash) / `-Engine unity` (PowerShell). Full copy map + no-script hand-copy steps: [scripts/README.md](scripts/README.md).

</details>

## What it feels like

> **You:** I want to design my combat system.
> **Studio:** That's creative work, so I'm starting the `brainstorming` workflow — we explore before we build. First question: when a fight starts, what should the player be *feeling*?
> *…a guided back-and-forth later, a design spec exists at `docs/specs/2026-07-20-combat-design.md`…*
> **Studio:** Spec drafted. I'd hand this to the `game-designer` agent for a design review next — want that, or is it small enough to lock in as-is?
> **You:** Do the review.
> **Studio:** *[dispatches `game-designer`, reads its report]* Two gaps flagged: no failure state, and attacks have no resource cost. Want to resolve those now or park them in the spec's open questions?

That's the whole interaction model. Every workflow in the studio works like this — plain conversation on your side, structured process on Claude's side.

## What's inside

| | Count | What they are |
|---|---|---|
| **Skills** | 69 | Guided workflows — brainstorming, writing a design doc, planning a sprint, reviewing code, closing a session. Each one walks Claude through a repeatable process instead of improvising. |
| **Agents** | 35 (+14 in engine packs) | Specialist subagents the skills dispatch — game designer, gameplay programmer, narrative director, QA lead, and more. Each runs in its own context and reports back. |
| **Hooks** | 13 | Session-lifecycle automation — start-of-session briefings, keyword detection that suggests the right skill, validation checks. |
| **Rules** | 11 | Path-scoped coding standards that apply automatically to the files they govern. |
| **Templates** | 41 | Document scaffolds — GDDs, ADRs, specs, plans, sprint files, workstream state. |
| **Tools** | 5 | Zero-LLM Python runners: two checkers you can run right now (`consistency_check.py`, `doc_stack_check.py`), the workflow-state detector ([docs/flow-ledger.md](docs/flow-ledger.md)), and two index generators. |
| **Scaffold** | 36 paths | The document stack the skills read, seeded into your project on install — and never overwritten on re-run. |

Every count above is reproduced by a command recorded beside it in [manifest.yaml](manifest.yaml), and CI re-runs both checkers on every push.

Under the hood these organize into pipelines that move work through phases — **Concept → Design → Architecture → Production → Release** — but you don't need to know any of that on day one. Say what you want; the studio knows where it fits.

## What you get

The installer lands two things: the framework under `.claude/` + `tools/`, and the document stack your project actually writes into. This is the canonical layout — every skill reads and writes these paths, and `CLAUDE.md`'s reading map is the authority they all follow.

```
your-game/
├── CLAUDE.md                      # seeded from template; the file every session reads first
├── .claude/
│   ├── skills/                    # 69 guided workflows
│   ├── agents/                    # 35 specialists (+ engine packs)
│   ├── hooks/                     # 13 session-lifecycle hooks
│   ├── rules/                     # 11 path-scoped coding standards
│   ├── docs/                      # the framework's reference library (+ docs/templates/)
│   └── settings.json              # hook wiring — never overwritten
├── tools/                         # 5 zero-LLM Python runners
│
├── docs/                          # ── seeded, never overwritten ──
│   ├── GDD.md                     # master game design document
│   ├── gdd/                       # systems-index, game-concept, game-pillars (+ per-system GDDs ✎)
│   ├── art-bible.md
│   ├── adr/                       # TEMPLATE.md — the NNN-<slug>.md records themselves are ✎
│   ├── architecture/              # ✎ empty dir; /create-architecture, /create-control-manifest
│   │                              #   and /architecture-review write into it
│   ├── specs/ · plans/            # ✎ empty dirs; /brainstorming and /writing-plans fill them
│   ├── z-old/{specs,plans}/       # where they retire to
│   └── devlog.md · implementation-status.md · open-flags.md
├── data/
│   └── _schemas/
│       ├── system_registry.json   # THE built-state source of truth (seeded valid + empty)
│       └── dev_diary.json
└── production/
    ├── session-state/active.md    # session handover — how the next chat resumes
    ├── session-logs/ · workstreams/ · sprints/ · epics/
    ├── qa/{bugs,evidence}/
    └── stage.txt · review-mode.txt · sprint-status.yaml · flow-ledger.yaml
```

**✎ = created on use, not seeded.** A fresh install has the *directory*, not the file: `docs/architecture/architecture.md` does not exist until you run `/create-architecture`, and that is the correct day-one state. Everything else in the tree above is a real file the moment the installer finishes. `CLAUDE.md`'s reading map holds the same line — rows for on-use artifacts point at the directory and name the skill that fills it, so no session ever hunts for a file that was never written.

The seeded files are skeletons, and each one carries a `scaffold-seed: unwritten` marker line that you delete when you write real content. That is what lets `tools/workflow_state_check.py` tell a blank seed from your work instead of reporting steps you never took ([docs/doc-stack.md](docs/doc-stack.md) § *Seeded is not written*).

Already have your own document stack? `--no-scaffold` (bash) / `-NoScaffold` (PowerShell) installs the `.claude/` layer alone.

## Your first session

After installing, open Claude Code in your project and try any of these:

- **"start"** — guided onboarding. Detects whether your project is brand new or already in flight and routes you accordingly.
- **"I want to make a cozy farming game — help me figure out the concept"** — kicks off a guided brainstorm from nothing.
- **"Brainstorm my inventory system"** — same, scoped to one feature.
- **"Where are we? What should I do next?"** — the studio reads your project state and recommends one concrete next action.
- **"Wrap up"** — closes the session properly so the next chat picks up exactly where you left off.

## Going deeper

- **[docs/START-HERE.md](docs/START-HERE.md)** — the 15-minute orientation: how skills fire, how agents get dispatched, when to use the pipeline and when to skip it. **Read this one first.**
- [docs/doc-stack.md](docs/doc-stack.md) — the doc-stack contract: every artifact in the layout above, who writes it, who reads it, and whether it ships, is scaffolded, or is written on first use. The page to open when the answer is "where does X live?".
- [docs/flow-ledger.md](docs/flow-ledger.md) — the mechanical workflow-state checker (`tools/workflow_state_check.py`): a small zero-LLM script that cross-checks claimed progress against the files that actually exist.
- `tools/consistency_check.py` — the doc-stack gate the close ritual runs (`python tools/consistency_check.py`). 12 mechanical checks: the registry parses and its references resolve, every path `CLAUDE.md` promises exists, ADRs are numbered and statused, specs sit where their status says, no markdown link is broken, every wired hook is on disk. A brand-new install passes it clean — checks that have nothing to look at yet say so and move on.
- `tools/doc_stack_check.py` — the regression guard (`python tools/doc_stack_check.py`; it detects whether it is looking at a studio clone or an installed project, and `--project <dir>` forces the latter). Classifies every path and every `/command` the shipped docs name; any phantom fails the run. New paths get declared in `tools/doc_stack.manifest.json`, never in the script. Wired into CI on push and pull request.
- [docs/skills-protocol-extended.md](docs/skills-protocol-extended.md) — advanced: the full-discipline skills protocol.
- [docs/agent-coordination-map.md](docs/agent-coordination-map.md) — advanced: the complete org chart, delegation rules, and escalation paths.
- [docs/director-gates.md](docs/director-gates.md) — advanced: the phase-gate review reference.

## Engine-agnostic

This studio is **not engine-specific**. The core skills and agents are engine-neutral, and the roster ships specialist packs for **Godot, Unity, and Unreal** (see `agents/engine-packs/`).

It grew inside a Godot project, so where an example needs to be concrete it defaults to Godot idioms (a headless validation harness, `.tscn`/`.gd` checks). Treat those as **reference implementations** — the shape of the check is the point; swap in your engine's equivalent.

## Prerequisites & optional enhancers

**No prerequisites — the studio is fully self-contained.** Every skill, agent, hook, rule, and template it references ships in this bundle. Two Claude Code plugins pair well with it but are **never required**: **`obra/superpowers`** (the upstream vanilla discipline skills — brainstorming, TDD, systematic debugging, verification — for comparison or fallback) and **`anthropic-skills`** (deep per-engine skills like `godot` and `unity-development`, plus document/media skills the workflows can lean on). Install either via the plugin marketplace (`/plugin install superpowers`, `/plugin install anthropic-skills`) whenever you want the extra depth.

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
├── scaffold/               # Seed document stack → <project>/docs/, data/, production/
│                           #   (never overwrites; skip with --no-scaffold)
├── scripts/                # install.sh / install.ps1 (project-local installers)
├── .github/workflows/      # CI — both checkers, on push + pull request
├── CLAUDE.md.template      # Project instruction file → <project>/CLAUDE.md (seeded if absent)
├── manifest.yaml           # Inventory + lineage + install targets + scaffold contract
├── CHANGELOG.md
├── CREDITS.md
└── LICENSE
```

## Honest status

This is an **early public release**, hardened on one real production project. The framework is game-neutral and self-contained, but expect to tune reference implementations (engine checks, example paths) to your own project rather than dropping it in untouched.

**Upgrading from 0.4.x?** Re-run the installer — that is the whole upgrade, and nothing you already have is overwritten. The details, and what 0.5.0 actually repaired, are in [CHANGELOG.md](CHANGELOG.md).

Contributions and forks welcome.

## Lineage & credit

ShiningPlague was born out of adapting **[Donchitos' Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)** (MIT © Kirill Ivanov) together with the **[obra/superpowers](https://github.com/obra/superpowers)** skill methodology, then hardening the result on a real project — a Godot narrative-RPG.

Donchitos provided the original agent roster, template set, and pipeline architecture — the backbone this studio stands on. The obra/superpowers work provided the skill-authoring methodology and the discipline skills (brainstorming, test-driven development, systematic debugging, verification-before-completion, writing-skills). ShiningPlague evolves those foundations with a formalized skills protocol, session and goal tracking, director gates, and a decluttered, verified skill set shaped by day-to-day production use.

If you build with this, the credit runs upstream: Donchitos and obra did the hard early work, and Anthropic built Claude Code and the anthropic-skills the studio can lean on. See [CREDITS.md](CREDITS.md) for the full attribution detail.

## License

MIT. The license preserves Donchitos' original copyright and adds ShiningPlague's adaptations. See [LICENSE](LICENSE) and [CREDITS.md](CREDITS.md).
