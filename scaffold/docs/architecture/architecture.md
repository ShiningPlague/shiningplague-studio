<!-- scaffold-seed: unwritten — delete this line once you write real content -->
# [Project] — Master Architecture

**What this is.** The master technical blueprint: how every system in the design
becomes modules, layers, data flows and API contracts. It sits between design and
implementation, and it must exist before sprint planning starts.

**Written by** `/create-architecture` — it fills this file section by section, in
the order below, writing each section as soon as you approve it.
**Read by** `/dev-story` (what layer am I in, what may I call), `/code-review`
(does this change respect the boundaries), `/architecture-review` (is the
blueprint still true).

**Not here:** individual decisions. Those are ADRs at `docs/adr/NNN-<slug>.md`.
This file is the whole-system picture that gives those ADRs their context.

**How to fill it:** run `/create-architecture`. Every heading below is one phase
of that skill; the italic line under each says what belongs there. Delete the
italic prompts as you replace them.

---

## Document Status

*Fill once, update on every revision.*

- **Version:** 0 (unwritten)
- **Last Updated:** [YYYY-MM-DD]
- **Engine:** [engine + version, exactly as pinned in `.claude/docs/technical-preferences.md`]
- **GDDs Covered:** [list the design docs this blueprint was built from]
- **ADRs Referenced:** [list the ADR numbers this blueprint assumes]
- **Technical Director Sign-Off:** [date] — APPROVED / APPROVED WITH CONDITIONS
- **Lead Programmer Feasibility:** FEASIBLE / CONCERNS ACCEPTED / REVISED

---

## Engine Knowledge Gap Summary

*Which engine domains this project depends on that the assistant cannot answer from
training data alone — so every claim about them gets verified against
`docs/engine-reference/<engine>/` instead of guessed. Group by HIGH / MEDIUM / LOW
risk and name the systems that touch each.*

| Risk | Domain | What changed / why it is risky | Systems that touch it |
|---|---|---|---|
| HIGH | [e.g. physics] | [API reshaped after the model's training cutoff] | [system] |

---

## System Layer Map

*Every system from `docs/gdd/systems-index.md`, placed in exactly one layer. A
system in two layers is a system that has not been decided yet.*

```
┌─────────────────────────────────────────────┐
│  PRESENTATION   │  UI, HUD, menus, VFX, audio
├─────────────────────────────────────────────┤
│  FEATURE        │  secondary systems, AI, quests
├─────────────────────────────────────────────┤
│  CORE           │  the main loop, physics, input, movement
├─────────────────────────────────────────────┤
│  FOUNDATION     │  engine integration, save/load, scene mgmt, event bus
├─────────────────────────────────────────────┤
│  PLATFORM       │  OS, hardware, engine API surface
└─────────────────────────────────────────────┘
```

| Layer | System | Module boundary | Owns exclusively |
|---|---|---|---|
| Core | [system] | [one sentence: where this module starts and stops] | [the state nothing else may write] |

---

## Module Ownership

*Per module: what it owns, what it lets others touch, what it needs from others.
"Owns" is the load-bearing column — two modules owning one piece of state is the
bug this table exists to prevent.*

| Module | Layer | Owns | Exposes | Consumes | Engine APIs used |
|---|---|---|---|---|---|
| [module] | [layer] | [state it alone writes] | [what others may read/call] | [what it reads from others] | [class/node/signal + risk] |

*Then an ASCII dependency diagram — arrows point from consumer to producer.*

---

## Data Flow

*How data actually moves at runtime. Four flows at minimum; add any the design needs.*

### Frame update path
*Input → core systems → state → rendering. Name the data, the producer and the consumer at each hop.*

### Event / signal path
*How systems talk without knowing about each other. Name the bus or signal convention.*

### Save / load path
*What is serialised, which module owns serialisation, what the format is, what happens on a version mismatch.*

### Initialisation order
*Which modules must boot before which. Flag any cycle — a cycle here is a bug found early and cheap.*

*Flag every flow that crosses a thread boundary.*

---

## API Boundaries

*The contracts programmers implement against. One block per boundary, in
pseudocode or your engine's language.*

```
# [Module] — public surface
#   entry points : [functions / signals / properties others may use]
#   callers must : [invariant the caller is responsible for]
#   we guarantee : [what the module promises in return]
```

Example shape (generic):

```
# EventBus — public surface
#   entry points : emit(topic, payload), subscribe(topic, handler)
#   callers must : never assume delivery order between topics
#   we guarantee : every subscriber of a topic sees every emit on that topic, once
```

---

## ADR Audit

*Does every existing decision still hold against the blueprint above, and does
every technical requirement have a decision covering it?*

### ADR quality

| ADR | Engine compatibility section? | Engine version recorded? | Conflicts with a layer/ownership call? | Still valid? |
|---|---|---|---|---|
| ADR-NNNN | [yes/no] | [yes/no] | [none / describe] | [yes/no] |

### Requirement coverage

*Summary only — the live registry is `docs/architecture/tr-registry.yaml`, and it wins.*

| Req ID | Requirement | ADR coverage | Status |
|---|---|---|---|
| TR-[system]-001 | [one line] | ADR-NNNN | covered / partial / GAP |

---

## Required ADRs

*Decisions this blueprint exposed as missing, grouped by when they block work.
Foundation first — those are the ones that cost the most to change later.*

**Must have before coding starts (Foundation & Core):**
- [ ] [decision title] — blocks [system]

**Should have before the relevant system is built:**
- [ ] [decision title] — blocks [system]

**Can defer to implementation:**
- [ ] [decision title]

---

## Architecture Principles

*3–5 principles derived from the concept, the GDDs and the technical preferences.
Each one must be falsifiable — a principle no code could ever violate is decoration.*

1. **[Principle]** — [what it forbids in practice, in one line].

---

## Open Questions

*Decisions deliberately deferred. Each must be resolved before its layer is built —
say which layer, so the deferral has a deadline.*

| Question | Blocks which layer | Owner | Resolve by |
|---|---|---|---|
| [question] | [layer] | [role] | [milestone or gate] |
