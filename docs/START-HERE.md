# Start Here — a 15-minute orientation

> **For Claude, not homework:** this doc (like everything in docs/) is the assistant's reference library. Users never need to read it — Claude reads it and steers the conversation: advising, filling templates, firing skills, dispatching agents, and offering the recommended next step.


You installed the studio. Here's how it actually works, in plain terms. You don't need to read anything else before your first session.

## The one idea that matters

**You talk about your game in normal words. The studio matches what you said to a workflow and a specialist.** You never have to remember commands — although every skill *can* be invoked directly (`/brainstorming`, `/help`, `/sprint-plan`) once you know its name.

## How skills fire

A **skill** is a guided workflow — a written process Claude follows instead of improvising. There are 67 of them, and they fire in two ways:

1. **You say a thing, a workflow catches it.** "Brainstorm my combat system" starts `brainstorming`. "Something's broken" starts `systematic-debugging`. "What's next?" starts `help`. "Wrap up" starts `session-close`. Your phrasing is the trigger.
2. **A handful fire automatically** at the right moments — before creative work, before code gets written, before Claude claims anything is "done", at session end. These are the studio's quality instincts. You'll see them announced ("this is creative work, starting `brainstorming`") and you can always redirect.

If a skill starts and you didn't want it: just say so. "Skip the process, just make the change" works. The studio is a helpful colleague, not a compliance system.

## How agents get dispatched

An **agent** is a specialist (game designer, gameplay programmer, QA lead, narrative director…) that runs in its own separate context with its own tools, does one scoped job, and returns a report. Skills dispatch agents when the work fits a specialty — you'll see "dispatching `game-designer`…" and then a synthesized summary of what came back.

Why bother? Focus. A subagent reads only what its job needs, so it does that one job well without dragging your whole conversation along. You can always say "do it yourself, no dispatch" for small stuff.

## The small path — how most work flows

Most features move through five human-sized steps:

1. **Brainstorm** — talk the idea through until it's actually decided what you're building. Output: a short design spec.
2. **Decide** — write down the technical choices worth remembering, so future-you knows *why*. Output: an ADR (a one-page decision record).
3. **Plan** — break the work into concrete tasks. Output: a plan file.
4. **Build** — implement, test-first where it makes sense.
5. **Verify** — prove it works before calling it done: run the thing, cite the output.

That's it. Each step proposes the next, so you mostly just keep saying "yes" or steering. There's also a **large path** with more ceremony (full design docs, architecture, epics, stories, phase gates) for multi-week, cross-cutting work — the studio will suggest it when the scope genuinely calls for it, not before.

## When to ignore the ceremony

**Small change? Just ask for it.** "Fix the typo in the death message", "bump the potion heal to 20", "rename that file" — none of this needs a spec or a plan. The pipeline earns its keep on work that spans days, touches multiple systems, or makes decisions you'll need to remember. A good rule of thumb: if you could describe the change in one sentence and check it in one look, skip the process.

The studio is tuned to propose the lightest process that fits. If it ever feels heavier than the work deserves, say "lighter" — that's a legitimate instruction, not cheating.

## Useful things to say, anytime

| Say this… | And the studio will… |
|---|---|
| "start" | Run guided onboarding for a fresh or existing project |
| "where are we?" / "what's next?" | Read your project state, recommend one concrete next action |
| "brainstorm X" | Explore X with you before anything gets built |
| "something's wrong with X" | Investigate evidence-first before proposing fixes |
| "wrap up" | Close the session so the next chat resumes cleanly |

## Where the strict stuff lives

The studio also ships a full-discipline layer — enforcement rules, phase-gate reviews, the complete coordination hierarchy. **You do not need any of it on day one.** When you want it:

- [skills-protocol-extended.md](skills-protocol-extended.md) — the full skills protocol: auto-promotion conditions, chain rules, the strict version of everything above.
- [director-gates.md](director-gates.md) — formal director reviews between project phases, with `full` / `lean` / `solo` intensity modes.
- [agent-coordination-map.md](agent-coordination-map.md) — the complete org chart, delegation rules, and escalation paths.
- [flow-ledger.md](flow-ledger.md) — the zero-LLM checker that cross-checks claimed progress against the files that actually exist.

Your project's `CLAUDE.md` (seeded from the template at install) is the light default. Adopt the deeper layers when — and only when — they'd help.

**Next step:** open Claude Code in your project and say "start".
