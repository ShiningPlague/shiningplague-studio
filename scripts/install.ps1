#Requires -Version 5.1
<#
.SYNOPSIS
    ShiningPlague Game Studio — installer (PowerShell).

.DESCRIPTION
    Two modes:
      1. User-level skills install (default): copies skills\* into
         ~\.claude\skills\, SKIPPING any skill that already exists at user level
         (so your personal skills are never clobbered). Use -Force to overwrite.
      2. Project install (-Project <path>): copies the studio framework
         (agents\ hooks\ rules\ templates\ + CLAUDE.md.template) into
         <path>\.claude\, and seeds <path>\CLAUDE.md if it does not exist.

    Nothing is overwritten without -Force. Existing files are reported, not
    silently replaced.

.PARAMETER Project
    Target project directory for a project install.

.PARAMETER Force
    Overwrite existing files instead of skipping them.

.EXAMPLE
    ./install.ps1
    Install skills into ~\.claude\skills\ (skipping existing ones).

.EXAMPLE
    ./install.ps1 -Project C:\games\mygame
    Install the framework into C:\games\mygame\.claude\.
#>
[CmdletBinding()]
param(
    [string]$Project,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# --- resolve repo dir (parent of this scripts\ dir) --------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir   = Split-Path -Parent $ScriptDir
$UserSkillsDir = Join-Path $HOME '.claude\skills'

function Write-Step { param([string]$m) Write-Host "==> $m" }
function Write-Info { param([string]$m) Write-Host "    $m" }
function Write-Warn { param([string]$m) Write-Warning $m }

# --- project install ---------------------------------------------------------
if ($Project) {
    if (-not (Test-Path -LiteralPath $Project -PathType Container)) {
        Write-Error "Project path does not exist: $Project"
        exit 1
    }
    $ProjectDir = (Resolve-Path -LiteralPath $Project).Path
    $DestClaude = Join-Path $ProjectDir '.claude'
    Write-Step "Project install into: $DestClaude"
    New-Item -ItemType Directory -Force -Path $DestClaude | Out-Null

    foreach ($sub in @('agents', 'hooks', 'rules', 'templates')) {
        $src = Join-Path $RepoDir $sub
        if (-not (Test-Path -LiteralPath $src -PathType Container)) {
            Write-Warn "skip $sub\ — not present in repo"
            continue
        }
        $dest = Join-Path $DestClaude $sub
        if ((Test-Path -LiteralPath $dest) -and -not $Force) {
            Write-Warn "skip $sub\ — already exists at $dest (use -Force to overwrite)"
            continue
        }
        Write-Step "copy $sub\ -> $dest"
        Copy-Item -LiteralPath $src -Destination $dest -Recurse -Force
    }

    # CLAUDE.md.template -> .claude\CLAUDE.md.template (reference copy)
    $tmplSrc = Join-Path $RepoDir 'CLAUDE.md.template'
    if (Test-Path -LiteralPath $tmplSrc -PathType Leaf) {
        $tmplDest = Join-Path $DestClaude 'CLAUDE.md.template'
        if ((Test-Path -LiteralPath $tmplDest) -and -not $Force) {
            Write-Warn "skip CLAUDE.md.template -> $tmplDest (already exists)"
        } else {
            Write-Step "copy CLAUDE.md.template -> $tmplDest"
            Copy-Item -LiteralPath $tmplSrc -Destination $tmplDest -Force
        }

        # Seed project CLAUDE.md only if absent (never clobber a real one)
        $projClaude = Join-Path $ProjectDir 'CLAUDE.md'
        if (Test-Path -LiteralPath $projClaude) {
            Write-Warn "skip $projClaude — already exists (template left at $tmplDest)"
        } else {
            Write-Step "seed CLAUDE.md -> $projClaude"
            Copy-Item -LiteralPath $tmplSrc -Destination $projClaude -Force
            Write-Info "Fill the {{PLACEHOLDERS}} in $projClaude."
        }
    } else {
        Write-Warn "CLAUDE.md.template not found in repo — nothing to seed"
    }

    Write-Step "Project install complete."
    Write-Info "Next: install user-level skills too — run: $ScriptDir\install.ps1"
    exit 0
}

# --- default: user-level skills install --------------------------------------
$SkillsSrc = Join-Path $RepoDir 'skills'
if (-not (Test-Path -LiteralPath $SkillsSrc -PathType Container)) {
    Write-Error "skills\ directory not found at $SkillsSrc"
    exit 1
}

Write-Step "Installing skills into: $UserSkillsDir"
New-Item -ItemType Directory -Force -Path $UserSkillsDir | Out-Null

$installed = 0
$skipped   = 0
Get-ChildItem -LiteralPath $SkillsSrc -Directory | ForEach-Object {
    $name = $_.Name
    $dest = Join-Path $UserSkillsDir $name
    if ((Test-Path -LiteralPath $dest) -and -not $Force) {
        Write-Warn "skip '$name' — already exists at user level (use -Force to overwrite)"
        $script:skipped++
        return
    }
    if (Test-Path -LiteralPath $dest) {
        Remove-Item -LiteralPath $dest -Recurse -Force
    }
    Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
    Write-Info "installed '$name'"
    $script:installed++
}

Write-Step "Skills done: $installed installed, $skipped skipped."

Write-Host @"

Next steps
----------
1. Install the framework into a game project:
     $ScriptDir\install.ps1 -Project C:\path\to\your\project
   (copies agents\ hooks\ rules\ templates\ + CLAUDE.md.template into .claude\)

2. Or manually copy CLAUDE.md.template to your project root as CLAUDE.md and
   fill the {{PLACEHOLDERS}}.

3. Install the plugins the skills reference:
     /plugin install superpowers
     /plugin install anthropic-skills   (for the engine skills, e.g. godot)

"@
