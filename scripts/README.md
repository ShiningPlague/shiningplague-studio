# Install scripts

Two equivalent installers for the ShiningPlague Game Studio framework — one for
POSIX shells, one for PowerShell. Pick whichever matches your platform.

| Script | Platform |
|---|---|
| `install.sh`  | macOS / Linux / Git Bash / WSL |
| `install.ps1` | Windows PowerShell 5.1+ / PowerShell 7+ |

## What they do

Installation is **100% project-local**. Everything lands inside the target game
project — nothing is ever written to `~/.claude` or any other user-level path.

```sh
./install.sh /path/to/your/game
```
```powershell
./install.ps1 C:\path\to\your\game
```

**The target does not have to exist.** Both installers create an absent target
directory (parents included) and print a note saying so — installing into a folder
you have not made yet is the normal first move, and refusing it made the studio's
very first command an error message.

The target argument is optional. With no target, the current directory is used
when it looks like a project root (contains `.git`, `.claude`, `CLAUDE.md`,
`project.godot`, `package.json`, a `*.uproject`, or Unity's `Assets/` +
`ProjectSettings/`) **or** when it is an empty/new folder (ignoring a
`.sp-studio-tmp` / `shiningplague-studio` clone and OS cruft). Otherwise the
target argument is required. One guard: the installer refuses to install into
the studio repo itself (any folder with `manifest.yaml` + `skills/`) — `cd`
into your game project and run it from there.

What gets copied where:

| Bundle | Destination |
|---|---|
| `skills/` | `<target>/.claude/skills/` |
| `agents/*.md` (top level only) | `<target>/.claude/agents/` |
| `hooks/` | `<target>/.claude/hooks/` |
| `rules/` | `<target>/.claude/rules/` |
| `docs/` | `<target>/.claude/docs/` |
| `templates/` | `<target>/.claude/docs/templates/` |
| `tools/` | `<target>/tools/` |
| `scaffold/` | `<target>/` — the project document stack (`docs/`, `data/`, `production/`); **only files that are absent** |
| `CLAUDE.md.template` | `<target>/CLAUDE.md` — **only if no CLAUDE.md exists** |
| `templates/settings.template.json` | `<target>/.claude/settings.json` — **only if absent** (wires the hooks; if a settings.json exists you get a "merge the hooks block manually" notice instead) |

### The scaffold step (the project document stack)

The `.claude/` layer is *instructions*, and those instructions constantly command
paths **outside** `.claude/`: *"open `data/_schemas/system_registry.json` first"*,
*"check `production/review-mode.txt`"*, *"append to `docs/devlog.md`"*, *"resume
from `production/session-state/active.md`"*. The scaffold step is what makes those
paths exist on day one, so a first session that follows the reading map does not
hit a missing file.

It seeds **36 paths** — real starter files, never zero-byte placeholders, each
carrying a header saying what it is, who writes it and which skill reads it, plus
a `scaffold-seed: unwritten` marker line you delete when you write real content.
That marker is what lets the tools tell a blank seed from your work: without it
`tools/workflow_state_check.py` read three untouched skeletons as evidence and told
a brand-new user to log three steps they had never taken (contract:
`docs/doc-stack.md` § *Seeded is not written*).

| Group | What lands |
|---|---|
| Built state | `data/_schemas/system_registry.json` (valid, empty, documented schema), `data/_schemas/dev_diary.json` |
| Session state | `production/session-state/active.md` (the handover file), `production/stage.txt` (`not-started` — not a phase name; no gate cleared yet), `production/review-mode.txt` (`lean`), `production/flow-ledger.yaml`, `production/sprint-status.yaml` |
| Doc stack | `docs/devlog.md`, `docs/implementation-status.md`, `docs/open-flags.md` |
| Templates in place | `docs/adr/TEMPLATE.md`, `production/workstreams/TEMPLATE.md`, `docs/GDD.md`, `docs/gdd/{game-concept,game-pillars,systems-index}.md`, `docs/art-bible.md` |
| Working directories | `docs/{specs,plans,gdd,architecture,z-old/specs,z-old/plans}/`, `production/{session-logs,workstreams,sprints,epics,qa/bugs,qa/evidence}/` |

The last two rows in the "Templates in place" group are copies of the shipped
`templates/` documents (`architecture-decision-record.md`, `game-design-document.md`,
`game-concept.md`, `game-pillars.md`, `systems-index.md`, `art-bible.md`), so no
document is authored twice in this repo: fix the template, and every future
project's seed is fixed with it.

**Never clobber.** A scaffolded file that already exists is left exactly as it is
and counted as skipped — different discipline from the `.claude/` layer, which is
updated in place. Re-running the installer on a two-year-old project cannot touch
its real registry, devlog or handover file.

```sh
./install.sh /path/to/your/game --no-scaffold      # .claude/ layer only
```
```powershell
./install.ps1 C:\path\to\your\game -NoScaffold     # same thing
```

Use it when the project already has its own document stack. The skills that read
the registry, the stage, the review mode or the handover file will find nothing
until you create those paths yourself.

Every path the step creates is listed in the `SCAFFOLD-BEGIN … SCAFFOLD-END`
region of **both** installers and cross-checked against
`tools/doc_stack.manifest.json` by `tools/doc_stack_check.py` — a promise made
there and not kept in the installer fails the check.

### Engine packs (optional)

```sh
./install.sh /path/to/your/game --engine unity
```
```powershell
./install.ps1 C:\path\to\your\game -Engine unity
```

Copies `agents/engine-packs/<pack>/` into `<target>/.claude/agents/`.
Valid packs: `unity`, `unreal`, `godot-extras`, `multiplayer`. The flag may be
repeated (bash) or given a list (PowerShell).

## Idempotency & safety

- **Re-run = update in place.** New bundle files are added, changed ones are
  updated, identical ones are left alone. The summary prints new / updated /
  unchanged counts for the `.claude/` layer and seeded / skipped counts for the
  document stack.
- **Running the installer twice is a no-op the second time.** Second run on an
  unchanged project: `new 0 · updated 0 · unchanged 183 · seeded 0 · skipped 29`,
  and the file tree is byte-for-byte identical.
- **Local-modification warning.** Any existing file that differed from the
  bundle is counted and listed after the update — if you had local edits under
  `.claude/`, recover them from your project's git history.
- **`CLAUDE.md`, `.claude/settings.json` and every scaffolded artifact are never
  overwritten**, ever.
- **Isolation guarantee:** the installers never write to `~/.claude` or any
  user-level path. Every install is per-project; edits you make stay in that
  project; a new game = a fresh install.

Run `./install.sh --help` or `Get-Help ./install.ps1` for full usage.

## Manual install fallback

If you'd rather not run a script, copy everything project-local by hand:

1. `skills/` → `<project>/.claude/skills/`
2. `agents/*.md` (plus any engine pack you want) → `<project>/.claude/agents/`
3. `hooks/` → `<project>/.claude/hooks/` ; `rules/` → `<project>/.claude/rules/`
4. `docs/` → `<project>/.claude/docs/` ; `templates/` → `<project>/.claude/docs/templates/`
5. `tools/` → `<project>/tools/`
6. `scaffold/` → `<project>/` (everything except `scaffold/README.md`, which
   documents the folder and is not part of a game project) — **copy only files
   that do not already exist**. Then copy six templates into the working paths
   the skills open: `templates/game-design-document.md` → `docs/GDD.md`,
   `game-concept.md` → `docs/gdd/game-concept.md`, `game-pillars.md` →
   `docs/gdd/game-pillars.md`, `systems-index.md` → `docs/gdd/systems-index.md`,
   `art-bible.md` → `docs/art-bible.md`, `architecture-decision-record.md` →
   `docs/adr/TEMPLATE.md`
7. `CLAUDE.md.template` → `<project>/CLAUDE.md` (skip if one exists) and fill
   the `{{PLACEHOLDERS}}`
8. `templates/settings.template.json` → `<project>/.claude/settings.json`
   (or merge its `hooks` block into your existing settings.json)

No prerequisites — the studio is fully self-contained. The `obra/superpowers`
and `anthropic-skills` plugins are optional enhancers, never required.
