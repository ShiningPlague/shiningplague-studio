---
name: team-security
description: "Use when auditing save data integrity, checking for cheat vectors, reviewing data validation, or hardening the game against exploits. Routes to the correct workflow pattern and executes step-by-step."
metadata:
  origin: ShiningPlague (Sons of Gilgamesh)
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as team-orchestrator for security workstream
    - security-engineer + lead-programmer dispatch
    - Director gate (TD-CODE-REVIEW)
    - SoG security context (single-player offline, save tampering vectors only)
---

# Team Security

> 🌱 **ShiningPlague-authored (2026-05-15).** Originally authored for the Sons of Gilgamesh project — no upstream version exists. Team-orchestrator skill for the security workstream. Promoted to user-level 2026-05-15 for portability.

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

## SoG-Specific Context

- Single-player offline game — no network security needed
- Primary vectors: save file tampering, JSON data manipulation
- All game data in human-editable JSON at `data/` — intentionally exposed for modding
- Security focus: save integrity + anti-cheat for leaderboards (if added)
