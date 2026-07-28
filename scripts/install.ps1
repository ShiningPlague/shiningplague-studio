#Requires -Version 5.1
<#
.SYNOPSIS
    ShiningPlague Game Studio -- installer (PowerShell). 100% project-local.

.DESCRIPTION
    Installs the studio INTO a game project. Everything lands inside the
    target project:

      skills\            -> <target>\.claude\skills\
      agents\*.md        -> <target>\.claude\agents\        (top level only)
      hooks\             -> <target>\.claude\hooks\
      rules\             -> <target>\.claude\rules\
      docs\              -> <target>\.claude\docs\
      templates\         -> <target>\.claude\docs\templates\
      tools\             -> <target>\tools\
      scaffold\          -> <target>\ (docs\, data\, production\ — only files absent)
      CLAUDE.md.template -> <target>\CLAUDE.md              (only if absent)
      templates\settings.template.json -> <target>\.claude\settings.json (only if absent)

    ISOLATION GUARANTEE: this script never writes to ~\.claude or any other
    user-level path. Installs are per-project; edits you make stay in that
    project; a new game gets its own fresh install.

    Idempotent: re-running updates the install in place. Existing files that
    differ from the bundle are overwritten, with a diff count printed so local
    modifications don't vanish silently. CLAUDE.md, settings.json and EVERY
    scaffolded artifact are never overwritten — a project's real registry,
    devlog and session state survive any number of re-runs.

.PARAMETER Target
    The game project directory to install into. It does NOT have to exist — an
    absent target is created (with a printed note), so
    ./install.ps1 .\my-new-game is a valid first command. If omitted, the
    current directory is used when it looks like a project root (contains .git,
    .claude, CLAUDE.md, project.godot, package.json, a *.uproject, or Unity's
    Assets\ + ProjectSettings\) OR when it is an empty/new folder. Otherwise
    the parameter is required. Guard: the installer refuses to install into
    the studio repo itself (a folder with manifest.yaml + skills\).

.PARAMETER Engine
    Optional engine agent pack(s) from agents\engine-packs\ to also install
    into <target>\.claude\agents\. Valid: unity, unreal, godot-extras,
    multiplayer.

.PARAMETER NoScaffold
    Install the .claude\ layer only. Skips seeding the project document stack
    (docs\, data\, production\) that the skills read. The bash equivalent is
    --no-scaffold. Use it when the project already has its own stack.

.EXAMPLE
    ./install.ps1 C:\games\mygame
    Install the studio into C:\games\mygame (project-local).

.EXAMPLE
    ./install.ps1 C:\games\mygame -Engine unity
    Install the studio plus the Unity specialist agent pack.

.EXAMPLE
    ./install.ps1 C:\games\mygame -NoScaffold
    Install the .claude\ layer without seeding the project document stack.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target,

    [ValidateSet('unity', 'unreal', 'godot-extras', 'multiplayer')]
    [string[]]$Engine = @(),

    [switch]$NoScaffold
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# --- resolve repo dir (parent of this scripts\ dir) --------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir   = Split-Path -Parent $ScriptDir

function Write-Step { param([string]$m) Write-Host "==> $m" }
function Write-Info { param([string]$m) Write-Host "    $m" }
function Write-Warn { param([string]$m) Write-Warning $m }

# --- project-marker detection ------------------------------------------------
function Test-LooksLikeProject {
    param([string]$Dir)
    if (Test-Path (Join-Path $Dir '.git'))            { return $true }
    if (Test-Path (Join-Path $Dir '.claude'))         { return $true }
    if (Test-Path (Join-Path $Dir 'CLAUDE.md'))       { return $true }
    if (Test-Path (Join-Path $Dir 'project.godot'))   { return $true }
    if (Test-Path (Join-Path $Dir 'package.json'))    { return $true }
    if (Test-Path (Join-Path $Dir 'Cargo.toml'))      { return $true }
    if (Test-Path (Join-Path $Dir 'go.mod'))          { return $true }
    if (Test-Path (Join-Path $Dir 'pyproject.toml'))  { return $true }
    if ((Test-Path (Join-Path $Dir 'Assets')) -and (Test-Path (Join-Path $Dir 'ProjectSettings'))) { return $true }
    if (Get-ChildItem -LiteralPath $Dir -Filter '*.uproject' -File -ErrorAction SilentlyContinue) { return $true }
    if (Get-ChildItem -LiteralPath $Dir -Filter '*.sln' -File -ErrorAction SilentlyContinue)      { return $true }
    return $false
}

function Test-EmptyOrNew {
    # True if the dir is a brand-new project folder -- no entries besides the
    # temp studio clone and OS cruft.
    param([string]$Dir)
    $ignorable = @('.sp-studio-tmp', 'shiningplague-studio', '.DS_Store', 'Thumbs.db', 'desktop.ini')
    $entries = Get-ChildItem -LiteralPath $Dir -Force -ErrorAction SilentlyContinue
    foreach ($e in $entries) {
        if ($ignorable -notcontains $e.Name) { return $false }
    }
    return $true
}

function Test-StudioRepo {
    # True if the dir looks like the studio repo itself (any clone of it).
    param([string]$Dir)
    return ((Test-Path (Join-Path $Dir 'manifest.yaml') -PathType Leaf) -and
            (Test-Path (Join-Path $Dir 'skills') -PathType Container))
}

if (-not $Target) {
    $cwd = (Get-Location).Path
    if (Test-StudioRepo $cwd) {
        Write-Error ("The current directory is the ShiningPlague Studio repo itself (manifest.yaml + skills\). " +
            "cd into your GAME project folder and run the installer from there: " +
            "cd C:\path\to\your\game; & C:\path\to\shiningplague-studio\scripts\install.ps1")
        exit 1
    } elseif (Test-LooksLikeProject $cwd) {
        $Target = $cwd
        Write-Step "No target given -- current directory looks like a project root, using it."
    } elseif (Test-EmptyOrNew $cwd) {
        $Target = $cwd
        Write-Step "No target given -- current directory is an empty/new folder, using it as the project root."
    } else {
        Write-Error ("No target directory given, and the current directory is neither an empty/new folder " +
            "nor a recognizable project root (.git / .claude / CLAUDE.md / project.godot / package.json / " +
            "*.uproject / Unity dirs). Pass the game project directory explicitly: ./install.ps1 C:\path\to\your\game")
        exit 2
    }
}

# A stranger pastes the quick-start into a folder that does not exist yet -- that
# is the NORMAL first move ("install the studio into .\my-game"), and refusing it
# made the studio's very first command an error message. Create it and say so.
# Behaviourally identical to install.sh's mkdir -p.
if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
    if (Test-Path -LiteralPath $Target) {
        Write-Error "Target exists but is not a directory: $Target"
        exit 1
    }
    try {
        New-Item -ItemType Directory -Force -Path $Target -ErrorAction Stop | Out-Null
    } catch {
        Write-Error ("Target directory does not exist and could not be created: $Target. " +
            "Create it yourself, then re-run the installer: New-Item -ItemType Directory -Force -Path '$Target'")
        exit 1
    }
    Write-Step "Target directory did not exist -- created it: $Target"
}
$TargetDir = (Resolve-Path -LiteralPath $Target).Path

# Refuse to install into the studio repo itself (this clone or any other).
if (($TargetDir.TrimEnd('\','/') -eq $RepoDir.TrimEnd('\','/')) -or (Test-StudioRepo $TargetDir)) {
    Write-Error ("Target is the ShiningPlague Studio repo itself (manifest.yaml + skills\ present). " +
        "Pass your game project directory instead, or cd into it and re-run.")
    exit 1
}

# --- copy engine: merge-update with diff counting ----------------------------
$script:CountNew       = 0
$script:CountUpdated   = 0
$script:CountUnchanged = 0
$script:UpdatedList    = New-Object System.Collections.Generic.List[string]
$script:SkippedItems   = New-Object System.Collections.Generic.List[string]

function Test-SameContent {
    param([string]$A, [string]$B)
    $ha = (Get-FileHash -LiteralPath $A -Algorithm SHA256).Hash
    $hb = (Get-FileHash -LiteralPath $B -Algorithm SHA256).Hash
    return $ha -eq $hb
}

function Copy-StudioFile {
    param([string]$Src, [string]$Dest)
    $destDir = Split-Path -Parent $Dest
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    }
    if (-not (Test-Path -LiteralPath $Dest)) {
        Copy-Item -LiteralPath $Src -Destination $Dest -Force
        $script:CountNew++
    } elseif (Test-SameContent $Src $Dest) {
        $script:CountUnchanged++
    } else {
        Copy-Item -LiteralPath $Src -Destination $Dest -Force
        $script:CountUpdated++
        $script:UpdatedList.Add($Dest)
    }
}

function Copy-StudioTree {
    param([string]$Src, [string]$Dest)
    if (-not (Test-Path -LiteralPath $Src -PathType Container)) {
        Write-Warn "skip $(Split-Path -Leaf $Src)\ -- not present in bundle"
        return
    }
    # Build artefacts are excluded: running a tools\ runner inside a studio clone
    # leaves __pycache__\*.pyc behind, and without this the installer would post
    # one developer's stale bytecode into every project it touches (and the
    # install file count would depend on whether the clone had ever been run).
    $srcFull = (Resolve-Path -LiteralPath $Src).Path
    Get-ChildItem -LiteralPath $srcFull -Recurse -File | Sort-Object FullName | ForEach-Object {
        $rel = $_.FullName.Substring($srcFull.Length).TrimStart('\','/')
        if ($rel -match '(^|[\\/])__pycache__[\\/]') { return }
        if ($_.Name -like '*.pyc') { return }
        if ($_.Name -in @('.DS_Store','Thumbs.db')) { return }
        Copy-StudioFile -Src $_.FullName -Dest (Join-Path $Dest $rel)
    }
}

# --- seed engine: create-if-absent, NEVER overwrite --------------------------
# Different discipline from Copy-StudioFile on purpose. The .claude\ layer is
# OURS and is updated in place; the document stack is the PROJECT'S and is only
# ever seeded. A second install must not touch a registry that now has 40
# systems in it, a devlog with a year of history, or a half-written handover.
$script:SeedNew      = 0
$script:SeedSkipped  = 0
$script:SeedMissing  = New-Object System.Collections.Generic.List[string]

function Copy-StudioSeed {
    param([string]$Src, [string]$Dest)
    if (Test-Path -LiteralPath $Dest) {
        $script:SeedSkipped++
        return
    }
    if (-not (Test-Path -LiteralPath $Src -PathType Leaf)) {
        $script:SeedMissing.Add("$Src (source not in bundle)")
        return
    }
    $destDir = Split-Path -Parent $Dest
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    }
    Copy-Item -LiteralPath $Src -Destination $Dest -Force
    $script:SeedNew++
}

# --- install -----------------------------------------------------------------
$DestClaude = Join-Path $TargetDir '.claude'
Write-Step "Installing ShiningPlague Game Studio into: $TargetDir"
Write-Info "(project-local only -- nothing is written to ~\.claude)"
New-Item -ItemType Directory -Force -Path $DestClaude | Out-Null

Write-Step "skills\    -> .claude\skills\"
Copy-StudioTree (Join-Path $RepoDir 'skills') (Join-Path $DestClaude 'skills')

Write-Step "agents\*.md (top level) -> .claude\agents\"
$agentsSrc = Join-Path $RepoDir 'agents'
if (Test-Path -LiteralPath $agentsSrc -PathType Container) {
    Get-ChildItem -LiteralPath $agentsSrc -Filter '*.md' -File | ForEach-Object {
        Copy-StudioFile -Src $_.FullName -Dest (Join-Path $DestClaude "agents\$($_.Name)")
    }
} else {
    Write-Warn "skip agents\ -- not present in bundle"
}

Write-Step "hooks\     -> .claude\hooks\"
Copy-StudioTree (Join-Path $RepoDir 'hooks') (Join-Path $DestClaude 'hooks')

Write-Step "rules\     -> .claude\rules\"
Copy-StudioTree (Join-Path $RepoDir 'rules') (Join-Path $DestClaude 'rules')

Write-Step "docs\      -> .claude\docs\"
Copy-StudioTree (Join-Path $RepoDir 'docs') (Join-Path $DestClaude 'docs')

Write-Step "templates\ -> .claude\docs\templates\"
Copy-StudioTree (Join-Path $RepoDir 'templates') (Join-Path $DestClaude 'docs\templates')

Write-Step "tools\     -> tools\"
Copy-StudioTree (Join-Path $RepoDir 'tools') (Join-Path $TargetDir 'tools')

# --- engine packs (optional) -------------------------------------------------
foreach ($pack in $Engine) {
    $packDir = Join-Path $RepoDir "agents\engine-packs\$pack"
    if (-not (Test-Path -LiteralPath $packDir -PathType Container) -and $pack -eq 'multiplayer') {
        # transitional alias: 'multiplayer' pack previously shipped as 'multiplayer'
        $alias = Join-Path $RepoDir 'agents\engine-packs\other'
        if (Test-Path -LiteralPath $alias -PathType Container) { $packDir = $alias }
    }
    if (-not (Test-Path -LiteralPath $packDir -PathType Container)) {
        Write-Warn "engine pack '$pack' not found in bundle -- skipped"
        $script:SkippedItems.Add("engine pack '$pack' (not in bundle)")
        continue
    }
    Write-Step "engine pack '$pack' -> .claude\agents\"
    Get-ChildItem -LiteralPath $packDir -Filter '*.md' -File | ForEach-Object {
        Copy-StudioFile -Src $_.FullName -Dest (Join-Path $DestClaude "agents\$($_.Name)")
    }
}

# --- project document stack (never overwrite) --------------------------------
# The .claude\ layer is instructions; those instructions command paths OUTSIDE
# .claude\ ("open data/_schemas/system_registry.json first", "check
# production/review-mode.txt", "append to docs/devlog.md"). This step is what
# makes those paths exist on day one.
#
# Every path created here is listed below AND in the `scaffold` block of
# tools/doc_stack.manifest.json. tools/doc_stack_check.py reads the region
# between the two markers and fails the build on any promise made there that is
# not kept here. Keep the list and the manifest in step.
#
# SCAFFOLD-BEGIN
$ScaffoldPaths = @(
    'docs/',
    'docs/GDD.md',
    'docs/gdd/',
    'docs/gdd/systems-index.md',
    'docs/gdd/game-concept.md',
    'docs/gdd/game-pillars.md',
    'docs/art-bible.md',
    'docs/accessibility-requirements.md',
    'docs/adr/',
    'docs/adr/TEMPLATE.md',
    'docs/architecture/',
    'docs/architecture/architecture.md',
    'docs/architecture/control-manifest.md',
    'docs/architecture/tr-registry.yaml',
    'docs/assets/',
    'docs/assets/asset-manifest.md',
    'docs/specs/',
    'docs/plans/',
    'docs/z-old/specs/',
    'docs/z-old/plans/',
    'docs/devlog.md',
    'docs/implementation-status.md',
    'docs/open-flags.md',
    'data/',
    'data/_schemas/',
    'data/_schemas/system_registry.json',
    'data/_schemas/dev_diary.json',
    'production/',
    'production/session-state/',
    'production/session-state/active.md',
    'production/session-state/active-goals.json',
    'production/session-logs/',
    'production/workstreams/',
    'production/workstreams/TEMPLATE.md',
    'production/sprints/',
    'production/epics/',
    'production/qa/',
    'production/qa/bugs/',
    'production/qa/evidence/',
    'production/stage.txt',
    'production/review-mode.txt',
    'production/sprint-status.yaml',
    'production/flow-ledger.yaml',
    'tests/',
    'tests/regression-suite.md'
)

# Seeds that are just a copy of a shipped template, so no document in this repo
# is written twice: fix the template, and every future project's seed is fixed.
$ScaffoldFromTemplate = [ordered]@{
    'game-design-document.md'          = 'docs/GDD.md'
    'game-concept.md'                  = 'docs/gdd/game-concept.md'
    'game-pillars.md'                  = 'docs/gdd/game-pillars.md'
    'systems-index.md'                 = 'docs/gdd/systems-index.md'
    'art-bible.md'                     = 'docs/art-bible.md'
    'architecture-decision-record.md'  = 'docs/adr/TEMPLATE.md'
}

if (-not $NoScaffold) {
    Write-Step "scaffold\  -> docs\ data\ production\  (seeds only what is absent)"
    $scaffoldSrc = Join-Path $RepoDir 'scaffold'
    if (Test-Path -LiteralPath $scaffoldSrc -PathType Container) {
        $scaffoldFull = (Resolve-Path -LiteralPath $scaffoldSrc).Path
        Get-ChildItem -LiteralPath $scaffoldFull -Recurse -File -Force | Sort-Object FullName | ForEach-Object {
            $rel = $_.FullName.Substring($scaffoldFull.Length).TrimStart('\','/')
            # scaffold\README.md documents this directory for repo readers; it is
            # not part of a game project and must never land in one.
            if ($rel -ne 'README.md') {
                Copy-StudioSeed -Src $_.FullName -Dest (Join-Path $TargetDir $rel)
            }
        }
    } else {
        Write-Warn "skip scaffold\ -- not present in bundle"
        $script:SkippedItems.Add('scaffold\ (not in bundle)')
    }

    foreach ($tmplName in $ScaffoldFromTemplate.Keys) {
        Copy-StudioSeed -Src (Join-Path $RepoDir "templates\$tmplName") `
                        -Dest (Join-Path $TargetDir $ScaffoldFromTemplate[$tmplName])
    }

    # A list nothing enforces is a comment. Verify every promised path landed.
    $scaffoldAbsent = New-Object System.Collections.Generic.List[string]
    foreach ($p in $ScaffoldPaths) {
        if (-not (Test-Path -LiteralPath (Join-Path $TargetDir $p))) { $scaffoldAbsent.Add($p) }
    }

    Write-Info "seeded new:      $($script:SeedNew)"
    Write-Info "already present: $($script:SeedSkipped) (left untouched)"
    if ($scaffoldAbsent.Count -gt 0) {
        Write-Warn "these promised paths are NOT present after seeding:"
        $scaffoldAbsent | ForEach-Object { Write-Host "         $_" }
    }
    if ($script:SeedMissing.Count -gt 0) {
        Write-Warn "seed sources missing from the bundle:"
        $script:SeedMissing | ForEach-Object { Write-Host "         $_" }
    }
} else {
    Write-Step "scaffold   -> SKIPPED (-NoScaffold)"
    Write-Info "the .claude\ layer is installed, but docs\, data\ and production\ are not seeded."
    Write-Info "skills that read the registry, the stage, the review mode or the handover"
    Write-Info "file will find nothing until you create those paths yourself."
}
# SCAFFOLD-END

# --- CLAUDE.md seed (never overwrite) ----------------------------------------
$tmplSrc    = Join-Path $RepoDir 'CLAUDE.md.template'
$projClaude = Join-Path $TargetDir 'CLAUDE.md'
if (Test-Path -LiteralPath $tmplSrc -PathType Leaf) {
    if (Test-Path -LiteralPath $projClaude) {
        Write-Info "CLAUDE.md already exists -- left untouched."
    } else {
        Write-Step "seed CLAUDE.md -> $projClaude"
        Copy-Item -LiteralPath $tmplSrc -Destination $projClaude -Force
        $script:CountNew++
        Write-Info "Fill the {{PLACEHOLDERS}} in $projClaude."
    }
} else {
    Write-Warn "CLAUDE.md.template not found in bundle -- nothing to seed"
    $script:SkippedItems.Add('CLAUDE.md.template (not in bundle)')
}

# --- settings.json hook wiring (never overwrite) -----------------------------
$settingsSrc  = Join-Path $RepoDir 'templates\settings.template.json'
$settingsDest = Join-Path $DestClaude 'settings.json'
if (Test-Path -LiteralPath $settingsSrc -PathType Leaf) {
    if (Test-Path -LiteralPath $settingsDest) {
        Write-Warn ".claude\settings.json already exists -- NOT overwritten."
        Write-Info "To wire the studio hooks, merge the `"hooks`" block from"
        Write-Info "  .claude\docs\templates\settings.template.json"
        Write-Info "into your existing .claude\settings.json manually."
    } else {
        Write-Step "wire hooks: settings.template.json -> .claude\settings.json"
        Copy-Item -LiteralPath $settingsSrc -Destination $settingsDest -Force
        $script:CountNew++
    }
} else {
    Write-Warn "templates\settings.template.json not found in bundle -- hooks not wired"
    $script:SkippedItems.Add('settings.template.json (not in bundle)')
}

# --- summary -----------------------------------------------------------------
Write-Host ""
Write-Step "Install complete: $TargetDir"
Write-Info ".claude layer -- new files:        $($script:CountNew)"
Write-Info ".claude layer -- updated in place: $($script:CountUpdated)"
Write-Info ".claude layer -- unchanged:        $($script:CountUnchanged)"
if (-not $NoScaffold) {
    Write-Info "doc stack     -- seeded:           $($script:SeedNew)"
    Write-Info "doc stack     -- skipped (exists): $($script:SeedSkipped)"
} else {
    Write-Info "doc stack     -- not seeded (-NoScaffold)"
}
if ($script:CountUpdated -gt 0) {
    Write-Host ""
    Write-Warn "$($script:CountUpdated) existing file(s) differed from the bundle and were UPDATED IN PLACE."
    Write-Warn "If any of those carried local modifications, recover them from your project's git history:"
    $script:UpdatedList | ForEach-Object { Write-Host "         $_" }
}
if ($script:SkippedItems.Count -gt 0) {
    Write-Host ""
    Write-Warn "Skipped (instructed target not found in bundle):"
    $script:SkippedItems | ForEach-Object { Write-Host "         $_" }
}

Write-Host @"

Next steps
----------
1. Open the project in Claude Code -- hooks are wired via .claude\settings.json.
2. Fill the {{PLACEHOLDERS}} in CLAUDE.md (if it was just seeded).
3. Optional enhancers (never required): the obra/superpowers and
   anthropic-skills plugins, via the Claude Code plugin marketplace.

Isolation model: this install is per-project. Edits you make to skills, agents,
hooks, or rules stay in THIS project. A new game = a fresh install. Nothing was
written to ~\.claude.
"@
