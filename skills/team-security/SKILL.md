---
name: team-security
description: "Use when auditing save data integrity, checking for cheat vectors, reviewing data validation, or hardening the game against exploits. Routes to the correct workflow pattern and executes step-by-step."
metadata:
  origin: ShiningPlague
  adopted_by: ShiningPlague
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as team-orchestrator for security workstream
    - security-engineer + lead-programmer dispatch
    - Director gate (TD-CODE-REVIEW)
    - Project threat-model placeholder block
---

# Team Security

> 🌱 **ShiningPlague-authored.** No upstream version exists. Team-orchestrator skill for the security workstream.

**Execution protocol:** `.claude/docs/templates/team-orchestrator.md`
**Workstream state:** `production/workstreams/security.md`
**Domain code:** SC

## Step 0: Load State + Select Activity

1. Read `production/workstreams/security.md` — what's done, in-progress, next
2. Ask or infer: which ACTIVITY? (Design / Build / Content / Playtest / Review / Ship)
3. Follow the matching execution chain from `team-orchestrator.md`

## Agent Routing — WHO to dispatch at each step

| Step in chain | Agent to dispatch | What they do |
|---|---|---|
| Design: threat model | `security-engineer` | Vulnerability audit, threat vectors, mitigation spec |
| Design: GDD authoring | `security-engineer` | Security requirements per system |
| Build: implementation | `gameplay-programmer` | Save encryption, validation code, input sanitization |
| Build: code review | `lead-programmer` | Secure coding patterns review |
| Playtest: penetration | `security-engineer` | Save tampering tests, data manipulation checks |
| Review: code review | `lead-programmer` | Gate TD-CODE-REVIEW |

## Gates to Fire

| Gate | When | Director |
|---|---|---|
| TD-CODE-REVIEW | After security-related code changes | lead-programmer |

## Project-Specific Context

Fill in your threat model (examples):

- Network surface (e.g. single-player offline — no network security needed)
- Primary vectors (e.g. save file tampering, data file manipulation)
- Intentional exposure (e.g. human-editable JSON at `data/` exposed on purpose for modding)
- Security focus (e.g. save integrity; anti-cheat only if leaderboards ship)
