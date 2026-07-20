#!/usr/bin/env bash
#
# ShiningPlague Game Studio — installer (POSIX bash)
#
# 100% PROJECT-LOCAL install. Everything lands inside the target game project:
#
#   skills/            -> <target>/.claude/skills/
#   agents/*.md        -> <target>/.claude/agents/        (top level only)
#   hooks/             -> <target>/.claude/hooks/
#   rules/             -> <target>/.claude/rules/
#   docs/              -> <target>/.claude/docs/
#   templates/         -> <target>/.claude/docs/templates/
#   tools/             -> <target>/tools/
#   CLAUDE.md.template -> <target>/CLAUDE.md              (only if absent)
#   templates/settings.template.json -> <target>/.claude/settings.json (only if absent)
#
# ISOLATION GUARANTEE: this script never writes to ~/.claude or any other
# user-level path. Installs are per-project; edits you make stay in that
# project; a new game gets its own fresh install.
#
# Idempotent: re-running updates the install in place. Files that already
# exist and differ from the bundle are overwritten, with a diff count printed
# so local modifications don't vanish silently. CLAUDE.md and settings.json
# are never overwritten.
#
set -euo pipefail

# --- resolve repo dir (parent of this scripts/ dir) --------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TARGET_DIR=""
ENGINE_PACKS=()

usage() {
  cat <<'USAGE'
ShiningPlague Game Studio installer — project-local, zero-prerequisite.

Usage:
  install.sh [TARGET_DIR] [--engine unity|unreal|godot-extras|multiplayer]...

  TARGET_DIR   The game project to install into. If omitted, the current
               directory is used — but only when it looks like a project root
               (contains .git, .claude, CLAUDE.md, project.godot, package.json,
               a *.uproject, or Unity's Assets/+ProjectSettings/). Otherwise
               the argument is required.

Options:
  --engine <pack>   Also install an engine agent pack from agents/engine-packs/
                    into <target>/.claude/agents/. May be given more than once.
                    Packs: unity, unreal, godot-extras, multiplayer.
  -h, --help        Show this help.

Everything installs INSIDE the target project (.claude/ + tools/). Nothing is
written to ~/.claude or any user-level path. Re-running updates in place;
CLAUDE.md and .claude/settings.json are never overwritten.
USAGE
}

# --- parse args --------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --engine)
      if [ $# -lt 2 ]; then
        echo "ERROR: --engine requires a pack name (unity|unreal|godot-extras|multiplayer)." >&2
        exit 2
      fi
      ENGINE_PACKS+=("$2"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "${TARGET_DIR}" ]; then
        echo "ERROR: multiple target directories given ('${TARGET_DIR}' and '$1')." >&2
        exit 2
      fi
      TARGET_DIR="$1"; shift ;;
  esac
done

warn() { printf 'WARN:  %s\n' "$1" >&2; }
info() { printf '       %s\n' "$1"; }
step() { printf '==> %s\n' "$1"; }

# --- project-marker detection ------------------------------------------------
looks_like_project() {
  # $1 = dir. True if it contains a recognizable project marker.
  local d="$1"
  [ -d "${d}/.git" ] && return 0
  [ -d "${d}/.claude" ] && return 0
  [ -f "${d}/CLAUDE.md" ] && return 0
  [ -f "${d}/project.godot" ] && return 0
  [ -f "${d}/package.json" ] && return 0
  [ -f "${d}/Cargo.toml" ] && return 0
  [ -f "${d}/go.mod" ] && return 0
  [ -f "${d}/pyproject.toml" ] && return 0
  [ -d "${d}/Assets" ] && [ -d "${d}/ProjectSettings" ] && return 0
  # any *.uproject or *.sln at top level
  local f
  for f in "${d}"/*.uproject "${d}"/*.sln; do
    [ -e "${f}" ] && return 0
  done
  return 1
}

if [ -z "${TARGET_DIR}" ]; then
  if looks_like_project "$(pwd)"; then
    TARGET_DIR="$(pwd)"
    step "No target given — current directory looks like a project root, using it."
  else
    echo "ERROR: no target directory given and the current directory has no project marker" >&2
    echo "       (.git / .claude / CLAUDE.md / project.godot / package.json / *.uproject / Unity dirs)." >&2
    echo "       Pass the game project directory explicitly: install.sh /path/to/your/game" >&2
    exit 2
  fi
fi

if [ ! -d "${TARGET_DIR}" ]; then
  echo "ERROR: target directory does not exist: ${TARGET_DIR}" >&2
  exit 1
fi
TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"

# Refuse to install into the studio repo itself.
if [ "${TARGET_DIR}" = "${REPO_DIR}" ]; then
  echo "ERROR: target is the studio repo itself — pass your game project directory instead." >&2
  exit 1
fi

# --- validate engine packs up front ------------------------------------------
resolve_pack_dir() {
  # $1 = pack name -> echoes source dir, or empty if unavailable
  local pack="$1"
  local dir="${REPO_DIR}/agents/engine-packs/${pack}"
  if [ -d "${dir}" ]; then
    echo "${dir}"; return 0
  fi
  # transitional alias: 'multiplayer' pack previously shipped as 'other'
  if [ "${pack}" = "multiplayer" ] && [ -d "${REPO_DIR}/agents/engine-packs/other" ]; then
    echo "${REPO_DIR}/agents/engine-packs/other"; return 0
  fi
  echo ""
}

for pack in ${ENGINE_PACKS[@]+"${ENGINE_PACKS[@]}"}; do
  case "${pack}" in
    unity|unreal|godot-extras|multiplayer) : ;;
    *) echo "ERROR: unknown engine pack '${pack}' (unity|unreal|godot-extras|multiplayer)." >&2; exit 2 ;;
  esac
done

# --- copy engine: merge-update with diff counting ----------------------------
COUNT_NEW=0
COUNT_UPDATED=0
COUNT_UNCHANGED=0
UPDATED_LIST=""

copy_file() {
  # $1 = src file, $2 = dest file
  local src="$1" dest="$2"
  if [ ! -e "${dest}" ]; then
    mkdir -p "$(dirname "${dest}")"
    cp "${src}" "${dest}"
    COUNT_NEW=$((COUNT_NEW + 1))
  elif cmp -s "${src}" "${dest}"; then
    COUNT_UNCHANGED=$((COUNT_UNCHANGED + 1))
  else
    cp "${src}" "${dest}"
    COUNT_UPDATED=$((COUNT_UPDATED + 1))
    UPDATED_LIST="${UPDATED_LIST}${dest}"$'\n'
  fi
}

copy_tree() {
  # $1 = src dir, $2 = dest dir — merge-copy every file, preserving structure
  local src="$1" dest="$2" f rel
  [ -d "${src}" ] || { warn "skip $(basename "${src}")/ — not present in bundle"; return 0; }
  while IFS= read -r f; do
    rel="${f#"${src}"/}"
    copy_file "${f}" "${dest}/${rel}"
  done < <(find "${src}" -type f | sort)
}

# --- install -----------------------------------------------------------------
DEST_CLAUDE="${TARGET_DIR}/.claude"
step "Installing ShiningPlague Game Studio into: ${TARGET_DIR}"
info "(project-local only — nothing is written to ~/.claude)"
mkdir -p "${DEST_CLAUDE}"

step "skills/    -> .claude/skills/"
copy_tree "${REPO_DIR}/skills" "${DEST_CLAUDE}/skills"

step "agents/*.md (top level) -> .claude/agents/"
if [ -d "${REPO_DIR}/agents" ]; then
  for f in "${REPO_DIR}/agents"/*.md; do
    [ -f "${f}" ] || continue
    copy_file "${f}" "${DEST_CLAUDE}/agents/$(basename "${f}")"
  done
else
  warn "skip agents/ — not present in bundle"
fi

step "hooks/     -> .claude/hooks/"
copy_tree "${REPO_DIR}/hooks" "${DEST_CLAUDE}/hooks"
chmod +x "${DEST_CLAUDE}/hooks"/*.sh 2>/dev/null || true

step "rules/     -> .claude/rules/"
copy_tree "${REPO_DIR}/rules" "${DEST_CLAUDE}/rules"

step "docs/      -> .claude/docs/"
copy_tree "${REPO_DIR}/docs" "${DEST_CLAUDE}/docs"

step "templates/ -> .claude/docs/templates/"
copy_tree "${REPO_DIR}/templates" "${DEST_CLAUDE}/docs/templates"

step "tools/     -> tools/"
copy_tree "${REPO_DIR}/tools" "${TARGET_DIR}/tools"

# --- engine packs (optional) -------------------------------------------------
SKIPPED_ITEMS=""
for pack in ${ENGINE_PACKS[@]+"${ENGINE_PACKS[@]}"}; do
  src="$(resolve_pack_dir "${pack}")"
  if [ -z "${src}" ]; then
    warn "engine pack '${pack}' not found in bundle — skipped"
    SKIPPED_ITEMS="${SKIPPED_ITEMS}engine pack '${pack}' (not in bundle)"$'\n'
    continue
  fi
  step "engine pack '${pack}' -> .claude/agents/"
  for f in "${src}"/*.md; do
    [ -f "${f}" ] || continue
    copy_file "${f}" "${DEST_CLAUDE}/agents/$(basename "${f}")"
  done
done

# --- CLAUDE.md seed (never overwrite) ----------------------------------------
tmpl_src="${REPO_DIR}/CLAUDE.md.template"
proj_claude="${TARGET_DIR}/CLAUDE.md"
if [ -f "${tmpl_src}" ]; then
  if [ -e "${proj_claude}" ]; then
    info "CLAUDE.md already exists — left untouched (template at .claude/docs/templates/ if needed: CLAUDE.md.template is also bundled at repo root)"
  else
    step "seed CLAUDE.md -> ${proj_claude}"
    cp "${tmpl_src}" "${proj_claude}"
    COUNT_NEW=$((COUNT_NEW + 1))
    info "Fill the {{PLACEHOLDERS}} in ${proj_claude}."
  fi
else
  warn "CLAUDE.md.template not found in bundle — nothing to seed"
  SKIPPED_ITEMS="${SKIPPED_ITEMS}CLAUDE.md.template (not in bundle)"$'\n'
fi

# --- settings.json hook wiring (never overwrite) -----------------------------
settings_src="${REPO_DIR}/templates/settings.template.json"
settings_dest="${DEST_CLAUDE}/settings.json"
if [ -f "${settings_src}" ]; then
  if [ -e "${settings_dest}" ]; then
    warn ".claude/settings.json already exists — NOT overwritten."
    info "To wire the studio hooks, merge the \"hooks\" block from"
    info "  .claude/docs/templates/settings.template.json"
    info "into your existing .claude/settings.json manually."
  else
    step "wire hooks: settings.template.json -> .claude/settings.json"
    cp "${settings_src}" "${settings_dest}"
    COUNT_NEW=$((COUNT_NEW + 1))
  fi
else
  warn "templates/settings.template.json not found in bundle — hooks not wired"
  SKIPPED_ITEMS="${SKIPPED_ITEMS}settings.template.json (not in bundle)"$'\n'
fi

# --- summary -----------------------------------------------------------------
echo ""
step "Install complete: ${TARGET_DIR}"
info "new files:       ${COUNT_NEW}"
info "updated in place: ${COUNT_UPDATED}"
info "unchanged:       ${COUNT_UNCHANGED}"
if [ "${COUNT_UPDATED}" -gt 0 ]; then
  echo ""
  warn "${COUNT_UPDATED} existing file(s) differed from the bundle and were UPDATED IN PLACE."
  warn "If any of those carried local modifications, recover them from your project's git history:"
  printf '%s' "${UPDATED_LIST}" | sed 's/^/         /'
fi
if [ -n "${SKIPPED_ITEMS}" ]; then
  echo ""
  warn "Skipped (instructed target not found in bundle):"
  printf '%s' "${SKIPPED_ITEMS}" | sed 's/^/         /'
fi
cat <<'EOF'

Next steps
----------
1. Open the project in Claude Code — hooks are wired via .claude/settings.json.
2. Fill the {{PLACEHOLDERS}} in CLAUDE.md (if it was just seeded).
3. Optional enhancers (never required): the obra/superpowers and
   anthropic-skills plugins, via the Claude Code plugin marketplace.

Isolation model: this install is per-project. Edits you make to skills, agents,
hooks, or rules stay in THIS project. A new game = a fresh install. Nothing was
written to ~/.claude.
EOF
