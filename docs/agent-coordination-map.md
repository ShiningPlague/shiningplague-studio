# Agent Coordination and Delegation Map

> 🌱 **ShiningPlague-adopted (2026-05-15):** Originally Donchitos framework reference doc. Extended with Sons of Gilgamesh additions — Three dispatch patterns detail (moved from CLAUDE.md 2026-05-15), session protocol section, workstream dispatch flow. Original Donchitos hierarchy + delegation rules + escalation paths + workflow patterns preserved verbatim; SoG additions explicitly labeled.

## Organizational Hierarchy

```
                           [Human Developer]
                                 |
                 +---------------+---------------+
                 |               |               |
         creative-director  technical-director  producer
                 |               |               |
        +--------+--------+     |        (coordinates all)
        |        |        |     |
  game-designer art-dir  narr-dir  lead-programmer  qa-lead  audio-dir
        |        |        |         |                |        |
     +--+--+     |     +--+--+  +--+--+--+--+--+   |        |
     |  |  |     |     |     |  |  |  |  |  |  |   |        |
    sys lvl eco  ta   wrt  wrld gp ep  ai net tl ui qa-t    snd
                                 |
                             +---+---+
                             |       |
                          perf-a   devops   analytics

  Additional Leads (report to producer/directors):
    release-manager         -- Release pipeline, versioning, deployment
    localization-lead       -- i18n, string tables, translation pipeline
    prototyper              -- Rapid throwaway prototypes, concept validation
    security-engineer       -- Anti-cheat, exploits, data privacy, network security
    accessibility-specialist -- WCAG, colorblind, remapping, text scaling
    live-ops-designer       -- Seasons, events, battle passes, retention, live economy
    community-manager       -- Patch notes, player feedback, crisis comms

  Engine Specialists (use the SET matching your engine):
    unreal-specialist  -- UE5 lead: Blueprint/C++, GAS overview, UE subsystems
      ue-gas-specialist         -- GAS: abilities, effects, attributes, tags, prediction
      ue-blueprint-specialist   -- Blueprint: BP/C++ boundary, graph standards, optimization
      ue-replication-specialist -- Networking: replication, RPCs, prediction, bandwidth
      ue-umg-specialist         -- UI: UMG, CommonUI, widget hierarchy, data binding

    unity-specialist   -- Unity lead: MonoBehaviour/DOTS, Addressables, URP/HDRP
      unity-dots-specialist         -- DOTS/ECS: Jobs, Burst, hybrid renderer
      unity-shader-specialist       -- Shaders: Shader Graph, VFX Graph, SRP customization
      unity-addressables-specialist -- Assets: async loading, bundles, memory, CDN
      unity-ui-specialist           -- UI: UI Toolkit, UGUI, UXML/USS, data binding

    godot-specialist   -- Godot 4 lead: GDScript, node/scene, signals, resources
      godot-gdscript-specialist    -- GDScript: static typing, patterns, signals, performance
      godot-shader-specialist      -- Shaders: Godot shading language, visual shaders, VFX
      godot-gdextension-specialist -- Native: C++/Rust bindings, GDExtension, build systems
```

### Legend
```
sys  = systems-designer       gp  = gameplay-programmer
lvl  = level-designer         ep  = engine-programmer
eco  = economy-designer       ai  = ai-programmer
ta   = technical-artist       net = network-programmer
wrt  = writer                 tl  = tools-programmer
wrld = world-builder          ui  = ui-programmer
snd  = sound-designer         qa-t = qa-tester
narr-dir = narrative-director perf-a = performance-analyst
art-dir = art-director
```

## Delegation Rules

### Who Can Delegate to Whom

| From | Can Delegate To |
|------|----------------|
| creative-director | game-designer, art-director, audio-director, narrative-director |
| technical-director | lead-programmer, devops-engineer, performance-analyst, technical-artist (technical decisions) |
| producer | Any agent (task assignment within their domain only) |
| game-designer | systems-designer, level-designer, economy-designer |
| lead-programmer | gameplay-programmer, engine-programmer, ai-programmer, network-programmer, tools-programmer, ui-programmer |
| art-director | technical-artist, ux-designer |
| audio-director | sound-designer |
| narrative-director | writer, world-builder |
| qa-lead | qa-tester |
| release-manager | devops-engineer (release builds), qa-lead (release testing) |
| localization-lead | writer (string review), ui-programmer (text fitting) |
| prototyper | (works independently, reports findings to producer and relevant leads) |
| security-engineer | network-programmer (security review), lead-programmer (secure patterns) |
| accessibility-specialist | ux-designer (accessible patterns), ui-programmer (implementation), qa-tester (a11y testing) |
| [engine]-specialist | engine sub-specialists (delegates subsystem-specific work) |
| [engine] sub-specialists | (advises all programmers on engine subsystem patterns and optimization) |
| live-ops-designer | economy-designer (live economy), community-manager (event comms), analytics-engineer (engagement metrics) |
| community-manager | (works with producer for approval, release-manager for patch note timing) |

### Escalation Paths

| Situation | Escalate To |
|-----------|------------|
| Two designers disagree on a mechanic | game-designer |
| Game design vs narrative conflict | creative-director |
| Game design vs technical feasibility | producer (facilitates), then creative-director + technical-director |
| Art vs audio tonal conflict | creative-director |
| Code architecture disagreement | technical-director |
| Cross-system code conflict | lead-programmer, then technical-director |
| Schedule conflict between departments | producer |
| Scope exceeds capacity | producer, then creative-director for cuts |
| Quality gate disagreement | qa-lead, then technical-director |
| Performance budget violation | performance-analyst flags, technical-director decides |

## Common Workflow Patterns

### Pattern 1: New Feature (Full Pipeline)

```
1. creative-director  -- Approves feature concept aligns with vision
2. game-designer      -- Creates design document with full spec
3. producer           -- Schedules work, identifies dependencies
4. lead-programmer    -- Designs code architecture, creates interface sketch
5. [specialist-programmer] -- Implements the feature
6. technical-artist   -- Implements visual effects (if needed)
7. writer             -- Creates text content (if needed)
8. sound-designer     -- Creates audio event list (if needed)
9. qa-tester          -- Writes test cases
10. qa-lead           -- Reviews and approves test coverage
11. lead-programmer   -- Code review
12. qa-tester         -- Executes tests
13. producer          -- Marks task complete
```

### Pattern 2: Bug Fix

```
1. qa-tester          -- Files bug report with /bug-report
2. qa-lead            -- Triages severity and priority
3. producer           -- Assigns to sprint (if not S1)
4. lead-programmer    -- Identifies root cause, assigns to programmer
5. [specialist-programmer] -- Fixes the bug
6. lead-programmer    -- Code review
7. qa-tester          -- Verifies fix and runs regression
8. qa-lead            -- Closes bug
```

### Pattern 3: Balance Adjustment

```
1. analytics-engineer -- Identifies imbalance from data (or player reports)
2. game-designer      -- Evaluates the issue against design intent
3. economy-designer   -- Models the adjustment
4. game-designer      -- Approves the new values
5. [data file update] -- Change configuration values
6. qa-tester          -- Regression test affected systems
7. analytics-engineer -- Monitor post-change metrics
```

### Pattern 4: New Area/Level

```
1. narrative-director -- Defines narrative purpose and beats for the area
2. world-builder      -- Creates lore and environmental context
3. level-designer     -- Designs layout, encounters, pacing
4. game-designer      -- Reviews mechanical design of encounters
5. art-director       -- Defines visual direction for the area
6. audio-director     -- Defines audio direction for the area
7. [implementation by relevant programmers and artists]
8. writer             -- Creates area-specific text content
9. qa-tester          -- Tests the complete area
```

### Pattern 5: Sprint Cycle

```
1. producer           -- Plans sprint with /sprint-plan new
2. [All agents]       -- Execute assigned tasks
3. producer           -- Daily status with /sprint-plan status
4. qa-lead            -- Continuous testing during sprint
5. lead-programmer    -- Continuous code review during sprint
6. producer           -- Sprint retrospective with post-sprint hook
7. producer           -- Plans next sprint incorporating learnings
```

### Pattern 6: Milestone Checkpoint

```
1. producer           -- Runs /retrospective
2. creative-director  -- Reviews creative progress
3. technical-director -- Reviews technical health
4. qa-lead            -- Reviews quality metrics
5. producer           -- Facilitates go/no-go discussion
6. [All directors]    -- Agree on scope adjustments if needed
7. producer           -- Documents decisions and updates plans
```

### Pattern 7: Release Pipeline

```text
1. producer             -- Declares release candidate, confirms milestone criteria met
2. release-manager      -- Cuts release branch, runs /gate-check
3. qa-lead              -- Runs full regression, signs off on quality
4. localization-lead    -- Verifies all strings translated, text fitting passes
5. performance-analyst  -- Confirms performance benchmarks within targets
6. devops-engineer      -- Builds release artifacts, runs deployment pipeline
7. release-manager      -- Generates changelog from git log, tags release, creates release notes
8. technical-director   -- Final sign-off on major releases
9. release-manager      -- Deploys and monitors for 48 hours
10. producer            -- Marks release complete
```

### Pattern 8: Rapid Prototype

```text
1. game-designer        -- Defines the hypothesis and success criteria
2. prototyper           -- prototyper agent scaffolds the prototype
3. prototyper           -- Builds minimal implementation (hours, not days)
4. game-designer        -- Evaluates prototype against criteria
5. prototyper           -- Documents findings report
6. creative-director    -- Go/no-go decision on proceeding to production
7. producer             -- Schedules production work if approved
```

### Pattern 9: Live Event / Season Launch

```text
1. live-ops-designer     -- Designs event/season content, rewards, schedule
2. game-designer         -- Validates gameplay mechanics for event
3. economy-designer      -- Balances event economy and reward values
4. narrative-director    -- Provides seasonal narrative theme
5. writer                -- Creates event descriptions and lore
6. producer              -- Schedules implementation work
7. [implementation by relevant programmers]
8. qa-lead               -- Test event flow end-to-end
9. community-manager     -- Drafts event announcement and patch notes
10. release-manager      -- Deploys event content
11. analytics-engineer   -- Monitors event participation and metrics
12. live-ops-designer    -- Post-event analysis and learnings
```

## Cross-Domain Communication Protocols

### Design Change Notification

When a design document changes, the game-designer must notify:
- lead-programmer (implementation impact)
- qa-lead (test plan update needed)
- producer (schedule impact assessment)
- Relevant specialist agents depending on the change

### Architecture Change Notification

When an ADR is created or modified, the technical-director must notify:
- lead-programmer (code changes needed)
- All affected specialist programmers
- qa-lead (testing strategy may change)
- producer (schedule impact)

### Asset Standard Change Notification

When the art bible or asset standards change, the art-director must notify:
- technical-artist (pipeline changes)
- All content creators working with affected assets
- devops-engineer (if build pipeline is affected)

## Session Protocol (added 2026-05-11)

The session protocol defines how every chat opens and closes. It sits above all
workflow patterns — patterns fire WITHIN sessions, the protocol wraps them.

### Opening Protocol (7 steps)

Defined in CLAUDE.md § Conversation-start protocol:
1. Fire `using-superpowers`
2. Context load (active.md, dev_diary, workstream states, open-flags)
3. Director POV briefs (all 3 Tier 1 in parallel — raw perspective, not recommendations)
4. Studio-lead synthesis + /help logic (workstream-aware, surfaces gaps organically)
5. Workstream menu (or infer from designer's intent)
6. Surface critical flags
7. Match designer's message against skills index

### Work Protocol

Existing Donchitos machinery applies unchanged:
- Skills fire per triggers (🔒 auto-fire, 🟢 propose-first)
- Agents dispatch per Intent → Agent table
- Director gates fire per review mode (full/lean/solo)
- Workflow patterns (see above) apply based on work type
- Workstream state files get updated as work progresses

### Close Protocol (7 steps)

Defined in `~/.claude/skills/session-close/SKILL.md` (user-level, ShiningPlague-adopted):
1. Director bookend re-dispatch (CLOSE-CD, CLOSE-TD, CLOSE-PR from director-gates.md)
2. Studio-lead synthesis — reflection record
3. Close gate sequence (consistency-check, review-all-gdds if applicable)
4. Unified update ritual (/update)
5. Git checkpoint (draft commit, prompt for push)
6. Session reflection (reflection note + director reflections into the session log)
7. Session log auto-file (production/session-logs/)

### Workstream Dispatch Flow

```
Designer intent
  → skill-trigger-detect.sh matches workstream keywords
  → Hook surfaces workstream + team orchestrator
  → Studio lead proposes dispatching team-* orchestrator
  → Orchestrator reads production/workstreams/<name>.md (own state)
  → Selects workflow pattern from this document's patterns
  → Dispatches agents per pattern steps
  → Fires gates per director-gates.md
  → Updates workstream state when done
  → Returns report to the studio lead
```

## Three dispatch patterns — detailed (SoG addition, moved from CLAUDE.md 2026-05-15)

Agents are auto-available via the `Agent` tool — no install. Each has a defined role + restricted tool set + scoped skills + Opus-tier model + maxTurns budget. They run in isolated context and return a report.

### Pattern A — Single specialist

`Agent({subagent_type: "<agent-name>", prompt: "..."})`. For scoped specialist work.

Examples:
- `gameplay-programmer` for >50 LOC of new GDScript
- `narrative-director` for narrative architecture
- `tools-programmer` for Python automation
- `producer` for milestone planning, audits, registry coordination
- `art-director` for visual identity decisions
- `qa-tester` for test plan execution

### Pattern B — `/team-<vertical>` skill (multi-agent orchestrator)

Orchestrates multiple agents for a vertical workstream.

Examples:
- `/team-combat` (gameplay-programmer + systems-designer + qa-tester)
- `/team-narrative` (narrative-director + writer + world-builder)
- `/team-ui` (ui-programmer + ux-designer)
- `/team-audio` (audio-director + sound-designer)
- `/team-level`, `/team-polish`, `/team-release` (similar composition per vertical)

**Use these as the entry point per vertical workstream.** Never fired pre-2026-04-29 — adopt going forward.

### Pattern C — In-line execution

Just main agent. For trivial tasks (<50 LOC, one-file edits, doc tweaks). Don't over-orchestrate.

### Hook reliability layer

`.claude/hooks/skill-trigger-detect.sh` (extended 2026-04-30) injects agent-dispatch hints when the designer's prompt matches an Intent → Agent keyword. Designer says *"let's redesign our game"* → hook surfaces creative-director + game-pillars.md template. Says *"loot tables"* → economy-designer + economy-model.md. Mechanical reliability layer for agent dispatch.

---

## Anti-Patterns to Avoid

1. **Bypassing the hierarchy**: A specialist agent should never make decisions
   that belong to their lead without consultation.
2. **Cross-domain implementation**: An agent should never modify files outside
   their designated area without explicit delegation from the relevant owner.
3. **Shadow decisions**: All decisions must be documented. Verbal agreements
   without written records lead to contradictions.
4. **Monolithic tasks**: Every task assigned to an agent should be completable
   in 1-3 days. If it is larger, it must be broken down first.
5. **Assumption-based implementation**: If a spec is ambiguous, the implementer
   must ask the specifier rather than guessing. Wrong guesses are more expensive
   than a question.
