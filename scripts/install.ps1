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
      CLAUDE.md.template -> <target>\CLAUDE.md              (only if absent)
      templates\settings.template.json -> <target>\.claude\settings.json (only if absent)

    ISOLATION GUARANTEE: this script never writes to ~\.claude or any other
    user-level path. Installs are per-project; edits you make stay in that
    project; a new game gets its own fresh install.

    Idempotent: re-running updates the install in place. Existing files that
    differ from the bundle are overwritten, with a diff count printed so local
    modifications don't vanish silently. CLAUDE.md and settings.json are never
    overwritten.

.PARAMETER Target
    The game project directory to install into. If omitted, the current
    directory is used when it looks like a project root (contains .git,
    .claude, CLAUDE.md, project.godot, package.json, a *.uproject, or Unity's
    Assets\ + ProjectSettings\) OR when it is an empty/new folder. Otherwise
    the parameter is required. Guard: the installer refuses to install into
    the studio repo itself (a folder with manifest.yaml + skills\).

.PARAMETER Engine
    Optional engine agent pack(s) from agents\engine-packs\ to also install
    into <target>\.claude\agents\. Valid: unity, unreal, godot-extras,
    multiplayer.

.EXAMPLE
    ./install.ps1 C:\games\mygame
    Install the studio into C:\games\mygame (project-local).

.EXAMPLE
    ./install.ps1 C:\games\mygame -Engine unity
    Install the studio plus the Unity specialist agent pack.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target,

    [ValidateSet('unity', 'unreal', 'godot-extras', 'multiplayer')]
    [string[]]$Engine = @()
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

if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
    Write-Error "Target directory does not exist: $Target"
    exit 1
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
    $srcFull = (Resolve-Path -LiteralPath $Src).Path
    Get-ChildItem -LiteralPath $srcFull -Recurse -File | Sort-Object FullName | ForEach-Object {
        $rel = $_.FullName.Substring($srcFull.Length).TrimStart('\','/')
        Copy-StudioFile -Src $_.FullName -Dest (Join-Path $Dest $rel)
    }
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
Write-Info "new files:        $($script:CountNew)"
Write-Info "updated in place: $($script:CountUpdated)"
Write-Info "unchanged:        $($script:CountUnchanged)"
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
