---
name: safety-push
description: "Use when designer says 'safety push', 'back up to git', 'commit and push everything safe', or expresses concern about machine failure / disk loss / disaster. Quick scan + commit + push of safe modified files. One-shot disaster insurance."
user-invocable: true
allowed-tools: Bash, Read
model: haiku
metadata:
  origin: ShiningPlague
  adopted_by: ShiningPlague
  vanilla_backup: none (originally authored locally — no upstream)
  enhancements:
    - Authored locally as one-shot disaster insurance commit
    - File classification (skip secrets, large binaries, gitignored, build artifacts)
    - Branch verification before push
    - Recovery scenario documentation
    - NOT a substitute for /update or /session-close
---

# Safety Push — Disaster Insurance Commit

> 🌱 **ShiningPlague-authored.** No upstream version exists. One-shot disaster-insurance backup that gets local work to GitHub before machine failure / disk loss / OS reinstall.

One-shot: scan git status, commit safe files, push to remote. Skips secrets, large binaries, gitignored files. Pre-disaster backup that gets the local work to GitHub before the machine can die.

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## When to fire

- Designer says: "safety push", "back up", "commit and push everything", "in case my machine dies", "disaster", "what if I lose this"
- Long work session with uncommitted changes accumulating
- Before risky operations (Godot version upgrade, OS reinstall, hardware change)
- Before stepping away from the machine for an extended period

## When NOT to fire

- Mid-brainstorm with WIP files not ready for any commit
- Right after `/session-close` already pushed
- Detached HEAD state / wrong branch
- If git push is broken (network/auth issue) — fix that first

## Procedure

### Step 1: Scan git state

```bash
cd "<project-root>"
git status --short
git rev-parse --abbrev-ref HEAD       # Verify on master (or expected branch)
git log --oneline -1                   # Last commit reference
```

### Step 2: Classify files

Categorize each modified/untracked file:

| Skip if | Reason |
|---|---|
| Path matches `.env*`, `*credentials*`, `*secret*`, `*.key`, `*.pem`, `*_token*` | Auth/secrets |
| File size > 100MB | Repo bloat (git LFS territory) |
| Path matches `.gitignore` (sanity check — git won't add but verify) | Already excluded |
| Path contains `.pyc`, `__pycache__`, `node_modules`, `.tmp`, `~` prefix | Build artifacts / temp files |

Everything else: INCLUDE.

### Step 3: Stage + commit

```bash
git add <safe-file-1> <safe-file-2> ...
git commit -m "$(cat <<'EOF'
chore: SAFETY-COMMIT — pre-disaster backup

Files committed:
- <list of files>

Triggered by designer safety-push request. Not all files may be in
shipped/reviewed state; this is disaster insurance, not a feature commit.

Co-Authored-By: Claude <current model> <noreply@anthropic.com>
EOF
)"
```

### Step 4: Push

```bash
git push origin <current-branch>
```

### Step 5: Report

Tell designer:
- Commit hash + message
- Files included
- Files skipped (with reasons)
- Push destination (origin URL)

## Common mistakes

- ❌ Using `git add -A` or `git add .` without classification — risks committing `.env` files
- ❌ Pushing on a feature branch without confirming branch — could surprise the designer
- ❌ Skipping the file classification "because it's a quick safety thing" — sensitive files leak via this exact rationalization
- ❌ Auto-firing without designer request — they decide when disaster insurance is needed
- ❌ Committing files mid-edit (file is being saved as you read it) — wait 5 seconds after designer signals end of editing

## Recovery scenario

Designer's disk dies after `/safety-push` fires. On new machine:

```bash
git clone https://github.com/<owner>/<repo>.git
cd <repo>
# All work up to last safety-push commit is here.
# Open Claude Code — session-start hook reads active.md + workstream states, designer is caught up.
```

That's the value. Cheap. Fast. One command.

## Cross-skill awareness

- `/safety-push` is NOT a substitute for `/update` or `/session-close`. Those do docs sync + dev_diary + reflections. `/safety-push` just gets bits to GitHub.
- After firing, propose `/update` if the work is at a real checkpoint (not just disaster insurance).
- Do NOT fire `/safety-push` automatically as part of any other skill's chain — it's designer-invoked only.

## Reference files

- `production/session-state/active.md` — read briefly to know what designer was working on (for commit message context)
- Project's `.gitignore` — sanity check that skip patterns align
