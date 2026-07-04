#!/usr/bin/env bash
#
# ShiningPlague Game Studio — installer (POSIX bash)
#
# Two modes:
#   1. User-level skills install (default): copies skills/* into ~/.claude/skills/,
#      SKIPPING any skill that already exists at user level (so your personal
#      skills are never clobbered). Pass --force to overwrite.
#   2. Project install (--project <path>): copies the studio framework
#      (agents/ hooks/ rules/ templates/ + CLAUDE.md.template) into <path>/.claude/.
#
# Nothing destructive happens without --force. Existing files are reported, not
# silently overwritten.
#
set -euo pipefail

# --- resolve repo dir (parent of this scripts/ dir) --------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

USER_SKILLS_DIR="${HOME}/.claude/skills"

FORCE=0
PROJECT_DIR=""

usage() {
  cat <<'USAGE'
ShiningPlague Game Studio installer

Usage:
  install.sh [--force]
      Install skills/* into ~/.claude/skills/. Existing user-level skills are
      SKIPPED (with a warning) unless --force is given.

  install.sh --project <path> [--force]
      Install the studio framework (agents/ hooks/ rules/ templates/ and
      CLAUDE.md.template) into <path>/.claude/. Also copies CLAUDE.md.template
      to <path>/CLAUDE.md if that file does not already exist. Existing files
      are skipped unless --force.

Options:
  --project <path>   Target project directory for a project install.
  --force            Overwrite existing files instead of skipping them.
  -h, --help         Show this help.
USAGE
}

# --- parse args --------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --project)
      if [ $# -lt 2 ]; then
        echo "ERROR: --project requires a path argument." >&2
        exit 2
      fi
      PROJECT_DIR="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

warn() { printf 'WARN:  %s\n' "$1" >&2; }
info() { printf '       %s\n' "$1"; }
step() { printf '==> %s\n' "$1"; }

# --- project install ---------------------------------------------------------
if [ -n "${PROJECT_DIR}" ]; then
  if [ ! -d "${PROJECT_DIR}" ]; then
    echo "ERROR: project path does not exist: ${PROJECT_DIR}" >&2
    exit 1
  fi
  PROJECT_DIR="$(cd "${PROJECT_DIR}" && pwd)"
  DEST_CLAUDE="${PROJECT_DIR}/.claude"
  step "Project install into: ${DEST_CLAUDE}"
  mkdir -p "${DEST_CLAUDE}"

  for sub in agents hooks rules templates; do
    src="${REPO_DIR}/${sub}"
    if [ ! -d "${src}" ]; then
      warn "skip ${sub}/ — not present in repo"
      continue
    fi
    dest="${DEST_CLAUDE}/${sub}"
    if [ -e "${dest}" ] && [ "${FORCE}" -ne 1 ]; then
      warn "skip ${sub}/ — already exists at ${dest} (use --force to overwrite)"
      continue
    fi
    step "copy ${sub}/ -> ${dest}"
    mkdir -p "${dest}"
    cp -R "${src}/." "${dest}/"
  done

  # CLAUDE.md.template -> .claude/CLAUDE.md.template (reference copy)
  tmpl_src="${REPO_DIR}/CLAUDE.md.template"
  if [ -f "${tmpl_src}" ]; then
    tmpl_dest="${DEST_CLAUDE}/CLAUDE.md.template"
    if [ -e "${tmpl_dest}" ] && [ "${FORCE}" -ne 1 ]; then
      warn "skip CLAUDE.md.template -> ${tmpl_dest} (already exists)"
    else
      step "copy CLAUDE.md.template -> ${tmpl_dest}"
      cp "${tmpl_src}" "${tmpl_dest}"
    fi

    # Seed project CLAUDE.md only if absent (never clobber a real one)
    proj_claude="${PROJECT_DIR}/CLAUDE.md"
    if [ -e "${proj_claude}" ]; then
      warn "skip ${proj_claude} — already exists (template left at ${tmpl_dest})"
    else
      step "seed CLAUDE.md -> ${proj_claude}"
      cp "${tmpl_src}" "${proj_claude}"
      info "Fill the {{PLACEHOLDERS}} in ${proj_claude}."
    fi
  else
    warn "CLAUDE.md.template not found in repo — nothing to seed"
  fi

  step "Project install complete."
  info "Next: install user-level skills too — run: ${SCRIPT_DIR}/install.sh"
  exit 0
fi

# --- default: user-level skills install --------------------------------------
SKILLS_SRC="${REPO_DIR}/skills"
if [ ! -d "${SKILLS_SRC}" ]; then
  echo "ERROR: skills/ directory not found at ${SKILLS_SRC}" >&2
  exit 1
fi

step "Installing skills into: ${USER_SKILLS_DIR}"
mkdir -p "${USER_SKILLS_DIR}"

installed=0
skipped=0
for skill_path in "${SKILLS_SRC}"/*/; do
  [ -d "${skill_path}" ] || continue
  name="$(basename "${skill_path}")"
  dest="${USER_SKILLS_DIR}/${name}"
  if [ -e "${dest}" ] && [ "${FORCE}" -ne 1 ]; then
    warn "skip '${name}' — already exists at user level (use --force to overwrite)"
    skipped=$((skipped + 1))
    continue
  fi
  if [ -e "${dest}" ]; then
    rm -rf "${dest}"
  fi
  cp -R "${skill_path%/}" "${dest}"
  info "installed '${name}'"
  installed=$((installed + 1))
done

step "Skills done: ${installed} installed, ${skipped} skipped."

cat <<EOF

Next steps
----------
1. Install the framework into a game project:
     ${SCRIPT_DIR}/install.sh --project /path/to/your/project
   (copies agents/ hooks/ rules/ templates/ + CLAUDE.md.template into .claude/)

2. Or manually copy CLAUDE.md.template to your project root as CLAUDE.md and
   fill the {{PLACEHOLDERS}}.

3. Install the plugins the skills reference:
     /plugin install superpowers
     /plugin install anthropic-skills   (for the engine skills, e.g. godot)

EOF
