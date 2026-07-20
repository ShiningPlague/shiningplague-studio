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
| `CLAUDE.md.template` | `<target>/CLAUDE.md` — **only if no CLAUDE.md exists** |
| `templates/settings.template.json` | `<target>/.claude/settings.json` — **only if absent** (wires the hooks; if a settings.json exists you get a "merge the hooks block manually" notice instead) |

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
  unchanged counts.
- **Local-modification warning.** Any existing file that differed from the
  bundle is counted and listed after the update — if you had local edits under
  `.claude/`, recover them from your project's git history.
- **`CLAUDE.md` and `.claude/settings.json` are never overwritten**, ever.
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
6. `CLAUDE.md.template` → `<project>/CLAUDE.md` (skip if one exists) and fill
   the `{{PLACEHOLDERS}}`
7. `templates/settings.template.json` → `<project>/.claude/settings.json`
   (or merge its `hooks` block into your existing settings.json)

No prerequisites — the studio is fully self-contained. The `obra/superpowers`
and `anthropic-skills` plugins are optional enhancers, never required.
