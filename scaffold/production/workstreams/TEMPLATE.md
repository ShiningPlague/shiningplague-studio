<!-- scaffold-seed: unwritten — delete this line once you write real content -->
# Workstream: [Name]

> **What this file is.** One domain's running state — combat, narrative, art,
> audio, UI/UX, economy, level/world, QA, release, security, infrastructure,
> game-design, marketing. A workstream phase is ORTHOGONAL to the project phase:
> a workstream can be deep in production while the project is still in concept.
>
> **Copy this file** to `production/workstreams/<name>.md` when work in that
> domain begins. `<name>` must match the workstream key in
> `.claude/docs/workflow-catalog.yaml` (e.g. `combat.md`, `narrative.md`).
>
> **Written by** the `/team-*` skills and whoever is working the domain.
> **Read by** `.claude/hooks/session-start.sh` (prints every workstream's phase at session
> open — it skips this TEMPLATE.md by name), `/help` (step 4), `/update`.
>
> **Do not rename the two bold fields below.** The session-start hook greps for
> `Current Phase:` and `Last Updated:` literally.

**Current Phase:** not-started
**Last Updated:** YYYY-MM-DD
**Owner:** [lead agent for this domain, e.g. `gameplay-programmer`]

---

## Purpose

[One paragraph. What this workstream is responsible for, and where its boundary
sits against the neighbouring domains.]

## In Progress

- [What is actually being worked right now — one line each, with the artifact path]

## Done

- [Shipped work, newest first, with the commit or evidence path]

## Blocked

- [What cannot move, and the exact thing that would unblock it]

## Open Questions

- [Decisions this workstream owes the designer. These surface at session open.]

## Key Artifacts

| Artifact | Path |
|---|---|
| GDD | `docs/gdd/<system>.md` |
| ADRs | `docs/adr/NNN-<slug>.md` |
| Data | `data/<category>/` |
| Evidence | `production/qa/evidence/` |

## Handoff Notes

[What the next session needs to know to pick this up cold. Assume no memory.]
