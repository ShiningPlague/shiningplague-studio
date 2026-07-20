# Skills Protocol — Extended Detail

> **Advanced reference — you do not need this on day one.**
> This is the full-discipline mode of the skills protocol — the strict
> version of the light default in your project's CLAUDE.md. If you're new,
> start with [docs/START-HERE.md](START-HERE.md) and adopt this when it helps.

> 🌱 **ShiningPlague-adopted:** Originally Donchitos framework reference doc. Extended with studio additions — canonical-flow driving examples (moved out of CLAUDE.md), chain-propose full transition table, conditional auto-promotion rules, subagent tier overrides, dev branches policy. Original Donchitos content preserved; studio additions explicitly labeled.

Slim canonical version: [CLAUDE.md § Skills Protocol](../../CLAUDE.md). This file holds rarely-needed detail extracted from CLAUDE.md to keep the entry-point file lean.

---

## Conditional auto-promotion (🟢 → 🔒 with conditions)

Some skills are 🟢 propose-first by default but auto-fire 🔒 when a specific condition is met — hard-won rule: selective promotion with explicit conditions beats both always-ask and always-fire.

| Skill | Default | Auto-fires (🔒) when... |
|---|---|---|
| `executing-plans` | 🟢 | An active plan exists at chat start AND `next_session_priorities[0]` references that plan as the next action |
| `regression-suite` | 🟢 | A bug fix just landed in the current session (capture-as-test enforcement) |
| `design-review` | 🟢 | Spec at `docs/specs/<latest>.md` is >200 lines AND not yet flipped to FINAL |
| `retrospective` | 🟢 | Step T10 docs-sync just shipped (auto-fire as part of step retrospective ritual) |

For these, no announce-and-wait — fire on condition match. Voice still announces *"This is a `<skill>` task — invoking"* (same as standard 🔒) but doesn't wait for permission.

---

## Chain-propose rule — full transition table

Hard-won rule: the designer will not remember to manually fire follow-on skills — the studio lead must always propose the next step in the chain (or auto-fire it where marked).

At the END of every skill that closes a phase, I MUST propose the natural follow-on:

| When this skill closes... | I MUST propose... | Why not auto-fire? |
|---|---|---|
| `brainstorming` finishes a spec | `design-review` 🟢 | Some specs are too small to need a full review — designer call |
| `design-review` passes | `architecture-decision` 🟢 | Some specs don't need a new ADR (small additions to existing) |
| `architecture-decision` writes an ADR | `writing-plans` 🟢 | Sometimes the ADR alone is the deliverable (no impl needed yet) |
| `writing-plans` outputs a plan | `executing-plans` 🟢 OR `subagent-driven-development` 🟢 | Designer may want plan review first |
| Plan execution completes | `verification-before-completion` 🔒 | Auto-fires regardless |
| `verification-before-completion` passes | `code-review` 🟢 + `simplify` 🟢 (BOTH proposed) | Designer chooses which |
| `code-review` flags issues + designer approves fixes | `simplify` 🟢 (on the approved sections only) | Auto-fixing skips approval gate |
| `code-review` flags performance issues | performance-analyst dispatch 🟢 | |
| `code-review` flags security concerns | `security-audit` 🟢 | |
| Step ships end-to-end | `gate-check` 🟢 + `finishing-a-development-branch` 🟢 + `regression-suite` 🟢 (coverage-gap pass) + `retrospective` 🔒 (retrospective ritual) | |
| Bug fix lands | `regression-suite` 🟢 (capture as regression test) | |
| `systematic-debugging` finds root cause | `test-driven-development` 🔒 (write failing test BEFORE the fix) | Auto-fire |
| Spec changes after ADR was written | `propagate-design-change` 🟢 | |
| Doc drift detected by `consistency-check` | `architecture-review` 🟢 if ADR-related, `scope-check` 🟢 if planned-but-unbuilt | |
| `red-flag-scan` audit identifies high-priority items | `writing-plans` 🟢 (batch fix) + `architecture-decision` 🟢 if structural + `scope-check` 🟢 if blocking + `simplify` 🟢 for low-effort items | Tech-debt is identification only — fix workstream is its own ship cycle |

**Forgetting to propose any of these = same failure mode as silently skipping a skill.** The hook at `.claude/hooks/skill-trigger-detect.sh` catches keyword triggers from user prompts; this rule covers transitions inside Claude's own work.

---

## Subagent model-tier rules (project-local override)

Hard-won rule: when dispatching subagents via the `Agent` tool, **prioritise quality over cost**. The generic "use the cheapest model that fits" guidance is OVERRIDDEN here — low-tier subagents have shipped critical bugs on code tasks that only surfaced under stronger-model review.

| Task type | Model |
|---|---|
| GDScript code (autoloads, scene scripts, system rewrites), debugging, architecture work | **Opus** (latest) |
| Code-quality review | **Opus** (latest) |
| Writing plans, ADRs, specs (by subagent) | **Opus** (latest) |
| Giving instructions to other subagents | **Opus** (latest) |
| Pure data authoring (JSON writes with exact specs) | **Sonnet** |
| Data migrations / Python scripts | **Sonnet** |
| Spec compliance review (checklist matching) | **Sonnet** |
| Docs sync / devlog writes | **Sonnet** |
| **Haiku** | phased out — do not use unless triaging a trivial one-shot structural check |

**Donchitos agent frontmatter note:** the subagent definitions at `.claude/agents/*.md` are normalised to `model: opus` in their YAML frontmatter. Dispatching any specialist via the `Agent` tool picks Opus by default — no override needed for the project-standard case. Passing `model: "opus"` explicitly is fine (belt-and-suspenders, costs nothing). For a cheaper model (data authoring, docs sync per the tier table above), pass `model: "sonnet"` explicitly — that override takes precedence over the frontmatter.

---

## Dev branches policy

We work on `master` directly for solo-dev efficiency under the launch-and-iterate constraint. Feature branches add ceremony that usually doesn't pay off for one developer + AI. Use a feature branch (via `using-git-worktrees` 🟢) when:
- Doing a risky experiment that might be thrown away
- Multiple parallel features in flight (rare for solo dev)
- A refactor that needs a clean review point before merge

Default = master; reach for a branch only when one of the three conditions above holds.

---

## Donchitos framework reconciliation

Full Donchitos Claude-Code-Game-Studios framework is installed (`.claude/agents/`, `.claude/docs/`, `.claude/hooks/`, `.claude/rules/`, and the studio skills at project-local `.claude/skills/` — repo-canonical under the two-home separation; user level holds only personal skills). **Our project conventions remain authoritative when they conflict.** Quick lookups:

- **Workflow shape** → your project's workflow conventions win for the small path; Donchitos pipeline (`workflow-catalog.yaml`) is the large path
- **Directory structure** → our `docs/specs/`, `docs/adr/`, `data/`, `src/systems/` tree wins (not `design/gdd/`, `docs/architecture/`, `src/gameplay/`)
- **Coding standards** → `.claude/rules/gameplay-code.md` (our customised); Donchitos defaults for unspecified topics
- **Templates** → optional starting points; our ADR template + project-local brainstorming SKILL override win for those skills
- **Donchitos slash commands** (`/create-epics`, `/create-stories`, `/dev-story`) → use ONLY for the large path (multi-vertical, multi-week work). NOT for small ship cycles.
- **Donchitos audit skills** (`/consistency-check`, `/review-all-gdds`, `/architecture-review`) → opt-in per task; project-local SKILL.md overrides the consistency-check

---

## Expected Outcomes checkpoint (MUST be in every spec)

Every spec written via `brainstorming` MUST carry an `## Expected outcomes at ship` section near the top — before Architecture details — answering: *"When this ships, what can the designer do / edit / test? What does the player see differently?"* This becomes the Phase 6 ship checklist. Mandatory template in the project-local `.claude/skills/brainstorming/SKILL.md` (ShiningPlague-adopted, repo-canonical under the two-home separation — this is the version that fires). Never create a user-level twin: Anthropic precedence (user > project) would silently shadow the project version.

---

## Canonical Donchitos Flow Driving — designer/studio-lead dialogue examples (studio addition)

The rule itself stays in [CLAUDE.md § Canonical Donchitos Flow Driving](../../CLAUDE.md). These worked examples illustrate the rule for new agents who need pattern reference.

**Designer:** *"I want to work on the narrative system."*
**Studio lead (driving):** *"Narrative workstream is in Concept phase. Project canonical phase = Concept. Foundational gap: `design/gdd/game-concept.md` is pointer-only. My recommendation: FIRE `/design-system game-concept` first (project-foundational), THEN `/design-system narrative` next chat (per-system GDD). Proceed with game-concept now? Or override and go straight to narrative — we'll backfill the concept doc later (acceptable but logged)."*

**Designer:** *"Let's discuss the economy."*
**Studio lead (driving):** *"Economy workstream has built code but no per-system GDD. Project still in Concept canonical phase. Quickest path: (a) discuss informally here to clarify intent (no formal output), then (b) FIRE `/design-system game-concept` first (project-foundational), then (c) `/design-system economy` in a later chat. Or override and start formal Economy GDD now — we'll backfill the concept doc later."*

**Designer:** *"I'm just chatting today."*
**Studio lead (driving):** *"Chat mode — META × Discussion. Staying aware: 5 open adoption TODOs unresolved (see active.md). When ready to act, canonical next step is `/design-system game-concept`. Tagging this chat as Discussion to prevent drift into work."*

### Anti-patterns (FAILURE MODES — DO NOT do these)

❌ Studio lead says: *"Here's the workstream menu, pick one."* (passive)
✅ Studio lead says: *"Canonical recommendation: FIRE `/design-system game-concept` — Concept-phase gap is the highest-impact missing artifact. Other workstream options exist (A/B/C below) but require this foundational doc first."*

❌ Studio lead asks: *"What do you want to work on today?"* (without first surfacing canonical recommendation)
✅ Studio lead states: *"Based on current canonical state (Concept phase, game-concept.md pointer-only), my recommendation is X. Want to proceed, or override with different work?"*
