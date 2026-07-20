# Agent Coordination Rules

1. **Vertical Delegation**: Leadership agents delegate to department leads, who
   delegate to specialists. Never skip a tier for complex decisions.
2. **Horizontal Consultation**: Agents at the same tier may consult each other
   but must not make binding decisions outside their domain.
3. **Conflict Resolution**: When two agents disagree, escalate to the shared
   parent. If no shared parent, escalate to `creative-director` for design
   conflicts or `technical-director` for technical conflicts.
4. **Change Propagation**: When a design change affects multiple domains, the
   `producer` agent coordinates the propagation.
5. **No Unilateral Cross-Domain Changes**: An agent must never modify files
   outside its designated directories without explicit delegation.

Model tiers: all active agents run model: opus — see .claude/docs/agents-index.md.

## Subagents vs Agent Teams

This project uses two distinct multi-agent patterns:

### Subagents (current, always active)
Spawned via `Task` within a single Claude Code session. Used by all `team-*` skills
and orchestration skills. Subagents share the session's permission context, run
sequentially or in parallel within the session, and return results to the parent.

**When to spawn in parallel**: If two subagents' inputs are independent (neither
needs the other's output to begin), spawn both Task calls simultaneously rather
than waiting. Example: `/review-all-gdds` Phase 1 (consistency) and Phase 2
(design theory) are independent — spawn both at the same time.

### Agent Teams (experimental — opt-in)
Multiple independent Claude Code *sessions* running simultaneously, coordinated
via a shared task list. Each session has its own context window and token budget.
Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable.

**Use agent teams when**:
- Work spans multiple subsystems that will not touch the same files
- Each workstream would take >30 minutes and benefits from true parallelism
- A senior agent (technical-director, producer) needs to coordinate 3+ specialist
  sessions working on different epics simultaneously

**Do not use agent teams when**:
- One session's output is required as input for another (use sequential subagents)
- The task fits in a single session's context (use subagents instead)
- Cost is a concern — each team member burns tokens independently

**Current status**: Not yet used in this project. Document usage here when first adopted.

## Workstream Ownership Rules

Each workstream has an OWNER — a team orchestrator skill that dispatches agents
and manages workstream state. See `workflow-catalog.yaml § workstreams` for the
full mapping.

### Dispatch rules

1. When the designer's intent maps to a workstream, the studio lead proposes the team
   orchestrator. The orchestrator owns the workstream state file and selects the
   workflow pattern from `agent-coordination-map.md`.
2. The orchestrator dispatches agents from its roster per the selected pattern's
   step sequence. It does NOT invent new agents or skip pattern steps.
3. Cross-workstream dependencies are surfaced by the producer (reads ALL
   workstream state files). Individual orchestrators only read their own.
4. Sub-workstreams (dialogue, quests, lore, entry-flow) are routed through their
   parent workstream's orchestrator unless explicitly separated.

### Ownership boundaries

- An orchestrator may only modify files in its domain (e.g. team-combat writes
  to `src/systems/combat*`, `data/cards/`, `production/workstreams/combat.md`)
- Cross-domain file changes require explicit delegation from the other domain's
  orchestrator or a director-level decision
- Workstream state files are owned by their orchestrator — other agents may READ
  them (especially producer) but only the owner WRITES them

## Parallel Task Protocol

When an orchestration skill spawns multiple independent agents:

1. Issue all independent Task calls before waiting for any result
2. Collect all results before proceeding to dependent phases
3. If any agent is BLOCKED, surface it immediately — do not silently skip
4. Always produce a partial report if some agents complete and others block
