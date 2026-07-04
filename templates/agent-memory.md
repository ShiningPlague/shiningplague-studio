# Agent Memory — [AGENT_NAME]

> Template for persistent agent memory across sessions.
> Each team orchestrator maintains a workstream state file at
> `production/workstreams/<workstream>.md` using the TEMPLATE.md in that directory.
> This template is for agent-level memory that persists independently of workstreams.

---

## Agent Identity

- **Name:** [agent name from .claude/agents/<name>.md]
- **Domain:** [what this agent owns]
- **Tier:** [1 (director) / 2 (lead) / 3 (specialist)]
- **Workstreams served:** [which workstreams this agent participates in]

## Accumulated Knowledge

### Decisions Made (cross-session)

| Date | Decision | Context | Rationale | ADR ref |
|---|---|---|---|---|
| [YYYY-MM-DD] | [what was decided] | [why it came up] | [reasoning] | [docs/adr/NNN if exists] |

### Patterns Observed

- [recurring issues, preferences, conventions this agent has noticed]
- [e.g. "Designer prefers minimal UI — avoid complex nested menus"]
- [e.g. "Combat system uses tag-based matching — never hardcode per-enemy logic"]

### Known Constraints

- [technical limitations this agent has encountered]
- [design boundaries established by pillars or ADRs]
- [budget/scope constraints communicated by producer]

## Delegation History

| Date | Delegated To | Task | Outcome |
|---|---|---|---|
| [YYYY-MM-DD] | [agent name] | [what was delegated] | [result] |

## Notes for Next Session

- [anything this agent wants to remember for next time it's dispatched]
