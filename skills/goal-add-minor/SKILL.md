---
name: goal-add-minor
description: "Use when designer adds new scope mid-session ('let's also do X', 'add this too', 'one more thing'). Appends minor goal to active-goals.json so additions are written-not-chat-context-dependent. Survives compaction + chat deletion."
user-invocable: true
allowed-tools: Read, Edit, Bash
metadata:
  origin: ShiningPlague
  adopted_by: ShiningPlague
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally for the session-goal tracking system
    - Pairs with /goal-set + /goal-check
    - Prevents scope-creep-in-chat-context failure mode
    - Survives compaction + chat deletion via active-goals.json persistence
---

# Goal Add Minor — Append Mid-Session Goal Addition

> 🌱 **ShiningPlague-authored.** No upstream version exists. Part of the session-goal tracking system (`/goal-set` + `/goal-add-minor` + `/goal-check`).

Write a minor goal addition to `production/session-state/active-goals.json → minor_goals_added[]`. Prevents the scope-creep-in-chat-context failure mode where the assistant adds items verbally but they're never persisted.

## When to fire

- Designer says: "also do X", "let's add Y", "one more thing", "while we're at it Z"
- The assistant notices an item being added to scope verbally without being written
- After `/goal-set` is locked + designer wants to extend scope without unfreezing

## When NOT to fire

- Primary goal not yet set (fire `/goal-set` first)
- The "addition" is actually a clarification of existing goal (no scope change)
- The addition is so big it should be a NEW session goal (suggest /goal-set in new chat)

## Procedure

### Step 1: Read active-goals.json

```bash
cat production/session-state/active-goals.json
```

Verify primary_goal exists. If not, refuse — primary must be set first.

### Step 2: Validate addition

Ask designer (or infer):
- Is this a MINOR add (small, fits within session scope) or MAJOR (should be its own goal/session)?
- If MAJOR: propose new session OR rescoping primary goal.
- If MINOR: continue.

### Step 3: Append entry

Add to `minor_goals_added[]`:
```json
{
  "id": "MG-N",  // auto-increment
  "added_at": "YYYY-MM-DD",
  "text": "<one sentence>",
  "outcome": "PENDING"
}
```

Update `audit_log`:
```json
{
  "ts": "YYYY-MM-DDTHH:MM:SSZ",
  "event": "minor_goal_added",
  "note": "<id>: <text>"
}
```

### Step 4: Surface to designer

Echo back:
- "Minor goal MG-N added: <text>"
- Current count: "Primary + N minors"
- Reminder: "All will be checked at session close via /goal-check"

### Step 5: Auto-warn if scope creep

If `minor_goals_added.length > 5`:
- Warn: "Scope creep risk — N minor goals already added to session. Consider splitting into new chat OR formalizing as new session goal."
- Don't block; just surface.

## Cross-skill awareness

- Triggered by hook keyword detection ("also do", "add this", "let's also") — surface propose, not auto-fire
- `/goal-check` reads minor_goals at session close
- Defer-handoff format (Item 15b): if minor goal can't ship, structured handoff to active.md

## Failure modes

- ❌ Adding without writing — defeats persistence purpose. Use this skill, don't just remember.
- ❌ Adding major scope as "minor" — push back, propose new session
- ❌ Skipping audit_log entry — breaks traceability
