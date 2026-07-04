# Install scripts

Two equivalent installers for the ShiningPlague Game Studio framework — one for
POSIX shells, one for PowerShell. Pick whichever matches your platform.

| Script | Platform |
|---|---|
| `install.sh`  | macOS / Linux / Git Bash / WSL |
| `install.ps1` | Windows PowerShell 5.1+ / PowerShell 7+ |

## What they do

Both scripts run in one of two modes.

### 1. User-level skills install (default — no arguments)

```sh
./install.sh
```
```powershell
./install.ps1
```

Copies each skill under `skills/` into `~/.claude/skills/` (`$HOME\.claude\skills\`
on Windows), where personal skills live and take precedence.

### 2. Project install

```sh
./install.sh --project /path/to/your/project
```
```powershell
./install.ps1 -Project C:\path\to\your\project
```

Copies the framework — `agents/`, `hooks/`, `rules/`, `templates/`, and
`CLAUDE.md.template` — into `<project>/.claude/`, and seeds `<project>/CLAUDE.md`
from the template **only if the project has no `CLAUDE.md` yet**.

## Safety behaviour

- **Existing user-level skills are never overwritten.** If a skill directory of
  the same name already exists in `~/.claude/skills/`, the installer **skips it
  and prints a warning** — your personal customizations are safe.
- **Existing project files are never overwritten** either — framework folders and
  an existing `CLAUDE.md` are skipped with a warning.
- To intentionally overwrite, pass `--force` (bash) / `-Force` (PowerShell). This
  is the only way anything gets replaced; there are no other destructive ops.

Run `./install.sh --help` or `Get-Help ./install.ps1` for full usage.

## Manual install fallback

If you'd rather not run a script:

1. Copy each directory under `skills/` into `~/.claude/skills/` — but skip any
   name that already exists there.
2. Copy `agents/`, `hooks/`, `rules/`, `templates/` into your project's `.claude/`.
3. Copy `CLAUDE.md.template` to your project root as `CLAUDE.md` and fill the
   `{{PLACEHOLDERS}}`.
4. Install the referenced plugins:
   ```
   /plugin install superpowers
   /plugin install anthropic-skills
   ```
