---
name: dispatching-parallel-agents
description: Use when fanning out work to multiple subagents at once — 2 or more independent tasks with no shared files or state that could run concurrently
---

# Dispatching Parallel Agents

## Overview

Parallel dispatch trades coordination overhead for wall-clock speed. It is only safe when the tasks are genuinely independent — the moment two agents can touch the same file or one needs the other's output, parallelism turns into corruption or rework.

**Core principle:** slice by ownership, brief for isolation, verify the merge yourself.

## When to fan out

ALL of these must hold:

- **2+ tasks** that are each substantial enough to justify a dispatch.
- **Disjoint file sets** — every file is owned by exactly one agent. No exceptions, not even "one appends, one edits elsewhere in the file."
- **No ordering dependency** — no task consumes another task's output.
- **No shared mutable state** — no common registry/index/manifest that multiple agents would update.

If any condition fails: run the tasks sequentially, or re-slice until it holds.

## How to slice the work

1. **Partition by file ownership first, topic second.** List every file each task will write. If two lists intersect, merge those tasks into one agent or move the shared file to a single owner.
2. **Write explicit per-agent instructions.** Each agent starts cold — no conversation memory. The prompt must carry: absolute file paths, the exact scope (what to change AND what not to touch), relevant conventions, and what to do when an instructed target is missing (skip and record, don't improvise).
3. **Define a structured return contract.** Tell each agent exactly what to report: files created, files changed, items skipped with reasons, and what verification it ran. Vague returns make the merge unverifiable.
4. **Reserve shared files for yourself.** Any index, registry, or summary doc that aggregates the agents' work is updated by the dispatcher AFTER all agents return — never by the agents.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| Two agents editing one file | Mid-edit collisions; last-write-wins silently destroys one agent's work |
| Vague prompts ("clean up the docs") | Each agent invents its own scope; results overlap, contradict, or miss the point |
| Fire-and-forget | Agent reports are claims, not evidence — unverified fan-out ships unverified work |
| Hidden coupling | Both tasks "independently" bump the same manifest/index — a shared file you forgot to list |
| Fan-out for tiny tasks | Dispatch overhead exceeds the work; do trivial items inline |
| Re-briefing by reference ("as discussed above") | Subagents can't see the conversation; every prompt must be self-contained |

## Dispatch brief shape

Every agent prompt should carry these five parts (order matters — scope before task):

```
CONTEXT: <one paragraph: what the repo/area is, why this work is happening>
OWNED FILES: <absolute paths this agent may create/edit — and nothing else>
TASK: <numbered, concrete steps; exact target content where it is load-bearing>
CONSTRAINTS: <conventions to follow, files/dirs that are off-limits, skip protocol>
RETURN: <the exact report shape: created / changed / skipped+reason / verification run>
```

If you cannot fill OWNED FILES with a list that is disjoint from every other agent's list, the slicing is wrong — stop and re-partition before dispatching.

## The verify-after-parallel rule

After ALL agents return, the dispatcher MUST verify the merged result before claiming completion:

1. **Read the seams.** Open each changed file at the boundaries where agents' outputs meet (cross-references, links, names one agent introduced that another consumes).
2. **Run the project's checks** (consistency/lint/build/headless harness — whatever the repo provides) over the combined state, not per-agent.
3. **Reconcile skips.** Every "skipped" item in a return contract gets a decision: re-dispatch, do inline, or accept and record.
4. **Only then** report done — citing the verification output, not the agents' self-reports.

An agent saying "done and verified" is input to your verification, never a substitute for it.

## Quick reference

- Independent? → fan out. Shared file or ordering? → sequential.
- One file, one owner. Shared aggregates belong to the dispatcher.
- Cold-start prompts: absolute paths + scope + conventions + skip protocol.
- Return contract: created / changed / skipped-with-reason / verification-run.
- Verify the merge yourself; self-reports are claims.
