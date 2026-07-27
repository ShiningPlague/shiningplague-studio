# scaffold/ — the artifact layer a fresh install needs

**This file is the only thing in `scaffold/` that is NOT installed.** Everything
else in this directory is copied into the target project by the installer's
scaffold step (`scripts/install.sh` / `scripts/install.ps1`).

## Why this exists

The `.claude/` layer (skills, agents, hooks, rules, docs) is *instructions*.
Those instructions constantly command paths outside `.claude/`:

> "read `data/_schemas/system_registry.json` first"
> "check `production/review-mode.txt`"
> "append to `docs/devlog.md`"
> "resume from `production/session-state/active.md`"

Before this directory existed, a fresh install created **none** of them. Every
one of those instructions was commanding air: the first session opened, followed
the reading map, and hit a missing file.

`scaffold/` is the seed of that artifact layer — real starter files, each with a
header saying what it is, who writes it, and which skill reads it. Empty of
content, complete in shape.

## Two sources, one step

The scaffold step seeds from two places, so no document is duplicated in this
repo:

| Seeded path (in the project) | Source |
|---|---|
| everything under `scaffold/` | this directory, copied 1:1 |
| `docs/GDD.md` | `templates/game-design-document.md` |
| `docs/gdd/game-concept.md` | `templates/game-concept.md` |
| `docs/gdd/game-pillars.md` | `templates/game-pillars.md` |
| `docs/gdd/systems-index.md` | `templates/systems-index.md` |
| `docs/art-bible.md` | `templates/art-bible.md` |
| `docs/adr/TEMPLATE.md` | `templates/architecture-decision-record.md` |

The right-hand column is authored once, in `templates/`, and installs to
`.claude/docs/templates/` as well. The scaffold step copies it a second time to
the working path the skills actually open. Fix the template, and the seed a new
project receives is fixed with it.

## The rules this layer obeys

1. **Never clobber.** A file that already exists in the target is left exactly as
   it is and counted as skipped. Re-running the installer on a live project can
   never overwrite a real registry, a real devlog, or a real handover file.
2. **Never a zero-byte placeholder.** Every seed either carries usable structure
   or a `.gitkeep` whose only job is to make an empty directory survive git.
3. **Generic.** No game's content, ever. Placeholders read `your-system`,
   `example-enemy`, `<system>`.
4. **Declared.** Every path this step creates is listed in the
   `SCAFFOLD-BEGIN … SCAFFOLD-END` region of both installers, and cross-checked
   against the `scaffold` block of `tools/doc_stack.manifest.json` by
   `tools/doc_stack_check.py`. A promise made there and not kept here is a build
   failure, not a comment.

## Opting out

`install.sh --no-scaffold` (or `install.ps1 -NoScaffold`) installs the `.claude/`
layer alone. Use it when a project already has its own document stack and you
only want the skills.
