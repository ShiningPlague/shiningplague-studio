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
#   scaffold/          -> <target>/ (docs/, data/, production/ — only files absent)
#   CLAUDE.md.template -> <target>/CLAUDE.md              (only if absent)
#   templates/settings.template.json -> <target>/.claude/settings.json (only if absent)
#
# ISOLATION GUARANTEE: this script never writes to ~/.claude or any other
# user-level path. Installs are per-project; edits you make stay in that
# project; a new game gets its own fresh install.
#
# Idempotent: re-running updates the install in place. Files that already
# exist and differ from the bundle are overwritten, with a diff count printed
# so local modifications don't vanish silently. CLAUDE.md, settings.json and
# EVERY scaffolded artifact are never overwritten — a project's real registry,
# devlog and session state survive any number of re-runs.
#
set -euo pipefail

# --- resolve repo dir (parent of this scripts/ dir) --------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TARGET_DIR=""
ENGINE_PACKS=()
DO_SCAFFOLD=1

usage() {
  cat <<'USAGE'
ShiningPlague Game Studio installer — project-local, zero-prerequisite.

Usage:
  install.sh [TARGET_DIR] [--engine unity|unreal|godot-extras|multiplayer]...
             [--no-scaffold]

  TARGET_DIR   The game project to install into. It does NOT have to exist —
               an absent target is created (with a printed note), so
               `install.sh ./my-new-game` is a valid first command. If omitted,
               the current directory is used when it looks like a project root
               (contains .git, .claude, CLAUDE.md, project.godot, package.json,
               a *.uproject, or Unity's Assets/+ProjectSettings/) OR when it is
               an empty/new folder. Otherwise the argument is required.
               Guard: the installer refuses to install into the studio repo
               itself (a folder with manifest.yaml + skills/).

Options:
  --engine <pack>   Also install an engine agent pack from agents/engine-packs/
                    into <target>/.claude/agents/. May be given more than once.
                    Packs: unity, unreal, godot-extras, multiplayer.
  --no-scaffold     Install the .claude/ layer only. Skips seeding the project
                    document stack (docs/, data/, production/) that the skills
                    read. Use it when the project already has its own.
  -h, --help        Show this help.

Everything installs INSIDE the target project (.claude/ + tools/ + the seeded
document stack). Nothing is written to ~/.claude or any user-level path.
Re-running updates the .claude/ layer in place; CLAUDE.md, .claude/settings.json
and every scaffolded artifact are never overwritten.
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
    --no-scaffold) DO_SCAFFOLD=0; shift ;;
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

is_empty_or_new() {
  # $1 = dir. True if it is a brand-new project folder — no entries besides
  # the temp studio clone and OS cruft.
  local d="$1" entry name
  for entry in "${d}"/* "${d}"/.[!.]* "${d}"/..?*; do
    [ -e "${entry}" ] || continue
    name="$(basename "${entry}")"
    case "${name}" in
      .sp-studio-tmp|shiningplague-studio|.DS_Store|Thumbs.db|desktop.ini) : ;;
      *) return 1 ;;
    esac
  done
  return 0
}

is_studio_repo() {
  # $1 = dir. True if it looks like the studio repo itself (any clone of it).
  [ -f "$1/manifest.yaml" ] && [ -d "$1/skills" ]
}

if [ -z "${TARGET_DIR}" ]; then
  if is_studio_repo "$(pwd)"; then
    echo "ERROR: the current directory is the ShiningPlague Studio repo itself (manifest.yaml + skills/)." >&2
    echo "       cd into your GAME project folder and run the installer from there:" >&2
    echo "         cd /path/to/your/game && bash /path/to/shiningplague-studio/scripts/install.sh" >&2
    exit 1
  elif looks_like_project "$(pwd)"; then
    TARGET_DIR="$(pwd)"
    step "No target given — current directory looks like a project root, using it."
  elif is_empty_or_new "$(pwd)"; then
    TARGET_DIR="$(pwd)"
    step "No target given — current directory is an empty/new folder, using it as the project root."
  else
    echo "ERROR: no target directory given, and the current directory is neither an empty/new folder" >&2
    echo "       nor a recognizable project root (.git / .claude / CLAUDE.md / project.godot /" >&2
    echo "       package.json / *.uproject / Unity dirs)." >&2
    echo "       Pass the game project directory explicitly: install.sh /path/to/your/game" >&2
    exit 2
  fi
fi

# A stranger pastes the quick-start into a folder that does not exist yet -- that
# is the NORMAL first move ("install the studio into ./my-game"), and refusing it
# made the studio's very first command an error message. Create it and say so.
if [ ! -d "${TARGET_DIR}" ]; then
  if [ -e "${TARGET_DIR}" ]; then
    echo "ERROR: target exists but is not a directory: ${TARGET_DIR}" >&2
    exit 1
  fi
  if ! mkdir -p "${TARGET_DIR}" 2>/dev/null; then
    echo "ERROR: target directory does not exist and could not be created: ${TARGET_DIR}" >&2
    echo "       Create it yourself, then re-run the installer:" >&2
    echo "         mkdir -p \"${TARGET_DIR}\"" >&2
    exit 1
  fi
  step "Target directory did not exist — created it: ${TARGET_DIR}"
fi
TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"

# Refuse to install into the studio repo itself (this clone or any other).
if [ "${TARGET_DIR}" = "${REPO_DIR}" ] || is_studio_repo "${TARGET_DIR}"; then
  echo "ERROR: target is the ShiningPlague Studio repo itself (manifest.yaml + skills/ present)." >&2
  echo "       Pass your game project directory instead, or cd into it and re-run:" >&2
  echo "         cd /path/to/your/game && bash /path/to/shiningplague-studio/scripts/install.sh" >&2
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
  if [ "${pack}" = "multiplayer" ] && [ -d "${REPO_DIR}/agents/engine-packs/multiplayer" ]; then
    echo "${REPO_DIR}/agents/engine-packs/multiplayer"; return 0
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
  # $1 = src dir, $2 = dest dir — merge-copy every file, preserving structure.
  # Build artefacts are excluded: running a tools/ runner inside a studio clone
  # leaves __pycache__/*.pyc behind, and without this the installer would post
  # one developer's stale bytecode into every project it touches (and the
  # install file count would depend on whether the clone had ever been run).
  local src="$1" dest="$2" f rel
  [ -d "${src}" ] || { warn "skip $(basename "${src}")/ — not present in bundle"; return 0; }
  while IFS= read -r f; do
    rel="${f#"${src}"/}"
    copy_file "${f}" "${dest}/${rel}"
  done < <(find "${src}" -type f \
             -not -path '*/__pycache__/*' \
             -not -name '*.pyc' \
             -not -name '.DS_Store' \
             -not -name 'Thumbs.db' | sort)
}

# --- seed engine: create-if-absent, NEVER overwrite --------------------------
# Different discipline from copy_file on purpose. The .claude/ layer is OURS and
# is updated in place; the document stack is the PROJECT'S and is only ever
# seeded. A second install must not touch a registry that now has 40 systems in
# it, a devlog with a year of history, or a half-written handover file.
SEED_NEW=0
SEED_SKIPPED=0
SEED_MISSING=""

seed_file() {
  # $1 = src file, $2 = dest file
  local src="$1" dest="$2"
  if [ -e "${dest}" ]; then
    SEED_SKIPPED=$((SEED_SKIPPED + 1))
    return 0
  fi
  if [ ! -f "${src}" ]; then
    SEED_MISSING="${SEED_MISSING}${src#"${REPO_DIR}"/} (source not in bundle)"$'\n'
    return 0
  fi
  mkdir -p "$(dirname "${dest}")"
  cp "${src}" "${dest}"
  SEED_NEW=$((SEED_NEW + 1))
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

# --- project document stack (never overwrite) --------------------------------
# The .claude/ layer is instructions; those instructions command paths OUTSIDE
# .claude/ ("open data/_schemas/system_registry.json first", "check
# production/review-mode.txt", "append to docs/devlog.md"). This step is what
# makes those paths exist on day one.
#
# Every path created here is listed below AND in the `scaffold` block of
# tools/doc_stack.manifest.json. tools/doc_stack_check.py reads the region
# between the two markers and fails the build on any promise made there that is
# not kept here. Keep the list and the manifest in step.
#
# SCAFFOLD-BEGIN
SCAFFOLD_PATHS="
docs/
docs/GDD.md
docs/gdd/
docs/gdd/systems-index.md
docs/gdd/game-concept.md
docs/gdd/game-pillars.md
docs/art-bible.md
docs/adr/
docs/adr/TEMPLATE.md
docs/architecture/
docs/specs/
docs/plans/
docs/z-old/specs/
docs/z-old/plans/
docs/devlog.md
docs/implementation-status.md
docs/open-flags.md
data/
data/_schemas/
data/_schemas/system_registry.json
data/_schemas/dev_diary.json
production/
production/session-state/
production/session-state/active.md
production/session-logs/
production/workstreams/
production/workstreams/TEMPLATE.md
production/sprints/
production/epics/
production/qa/
production/qa/bugs/
production/qa/evidence/
production/stage.txt
production/review-mode.txt
production/sprint-status.yaml
production/flow-ledger.yaml
"

# Seeds that are just a copy of a shipped template, so no document in this repo
# is written twice: fix the template, and every future project's seed is fixed.
SCAFFOLD_FROM_TEMPLATE="
game-design-document.md|docs/GDD.md
game-concept.md|docs/gdd/game-concept.md
game-pillars.md|docs/gdd/game-pillars.md
systems-index.md|docs/gdd/systems-index.md
art-bible.md|docs/art-bible.md
architecture-decision-record.md|docs/adr/TEMPLATE.md
"

if [ "${DO_SCAFFOLD}" -eq 1 ]; then
  step "scaffold/  -> docs/ data/ production/  (seeds only what is absent)"
  scaffold_src="${REPO_DIR}/scaffold"
  if [ -d "${scaffold_src}" ]; then
    while IFS= read -r f; do
      rel="${f#"${scaffold_src}"/}"
      # scaffold/README.md documents this directory for repo readers; it is not
      # part of a game project and must never land in one.
      [ "${rel}" = "README.md" ] && continue
      seed_file "${f}" "${TARGET_DIR}/${rel}"
    done < <(find "${scaffold_src}" -type f | sort)
  else
    warn "skip scaffold/ — not present in bundle"
    SKIPPED_ITEMS="${SKIPPED_ITEMS}scaffold/ (not in bundle)"$'\n'
  fi

  while IFS= read -r pair; do
    [ -n "${pair}" ] || continue
    seed_file "${REPO_DIR}/templates/${pair%%|*}" "${TARGET_DIR}/${pair##*|}"
  done <<EOF
${SCAFFOLD_FROM_TEMPLATE}
EOF

  # A list nothing enforces is a comment. Verify every promised path landed.
  scaffold_absent=""
  while IFS= read -r p; do
    [ -n "${p}" ] || continue
    [ -e "${TARGET_DIR}/${p}" ] || scaffold_absent="${scaffold_absent}${p}"$'\n'
  done <<EOF
${SCAFFOLD_PATHS}
EOF

  info "seeded new:      ${SEED_NEW}"
  info "already present: ${SEED_SKIPPED} (left untouched)"
  if [ -n "${scaffold_absent}" ]; then
    warn "these promised paths are NOT present after seeding:"
    printf '%s' "${scaffold_absent}" | sed 's/^/         /'
  fi
  if [ -n "${SEED_MISSING}" ]; then
    warn "seed sources missing from the bundle:"
    printf '%s' "${SEED_MISSING}" | sed 's/^/         /'
  fi
else
  step "scaffold   -> SKIPPED (--no-scaffold)"
  info "the .claude/ layer is installed, but docs/, data/ and production/ are not seeded."
  info "skills that read the registry, the stage, the review mode or the handover"
  info "file will find nothing until you create those paths yourself."
fi
# SCAFFOLD-END

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
info ".claude layer — new files:       ${COUNT_NEW}"
info ".claude layer — updated in place: ${COUNT_UPDATED}"
info ".claude layer — unchanged:       ${COUNT_UNCHANGED}"
if [ "${DO_SCAFFOLD}" -eq 1 ]; then
  info "doc stack     — seeded:          ${SEED_NEW}"
  info "doc stack     — skipped (exists): ${SEED_SKIPPED}"
else
  info "doc stack     — not seeded (--no-scaffold)"
fi
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
