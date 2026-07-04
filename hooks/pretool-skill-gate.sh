#!/usr/bin/env bash
# PreToolUse hook — fires before every Write or Edit tool call.
# When the target file_path matches a SKILL.md path inside .claude/skills/,
# injects a LOUD additionalContext reminder forcing Claude to fire
# /writing-skills before proceeding. Also nudges about system_registry.json
# coverage when system/addon/schema files are touched.
#
# This is layer 2 of the writing-skills enforcement triple:
#   1. UserPromptSubmit hook (skill-trigger-detect.sh) — keyword detection on prose
#   2. THIS HOOK — tool-call detection on Write/Edit of SKILL.md paths
#   3. The user-level writing-skills skill (~/.claude/skills/writing-skills/) —
#      rationalisation-resistant content
#
# Stateless — cannot block (would require tracking whether /writing-skills
# fired earlier this session). Instead injects a reminder so loud Claude
# cannot honestly say it didn't see it. Behavioural enforcement; the
# discipline still relies on Claude not ignoring loud reminders.
#
# Exit 0 always. Outputs JSON additionalContext when a pattern matched.
# Silent pass-through otherwise.

set -e

INPUT="$(cat)"

# Extract tool_name and tool_input.file_path. Use jq if available, fall
# back to grep for environments where jq isn't installed.
if command -v jq >/dev/null 2>&1; then
  TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')"
  FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""')"
else
  # Best-effort fallback — grep for the fields. May fail on edge cases;
  # jq is preferred. Install with `winget install jqlang.jq` or apt-get.
  TOOL_NAME="$(printf '%s' "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)"
  FILE_PATH="$(printf '%s' "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)"
fi

# Only act on Write or Edit tool calls (empty tool_name allowed — some
# harness payloads omit it; the file_path patterns below still gate).
case "$TOOL_NAME" in
  Write|Edit|"") ;;
  *) exit 0 ;;
esac

# Normalize Windows backslashes to forward slashes so one set of glob
# patterns covers both path separator forms.
FILE_PATH="$(printf '%s' "$FILE_PATH" | tr '\\' '/')"

CONTEXT=""

# Branch 1 — file_path targets a SKILL.md inside ANY .claude/skills/ path —
# project-local (.claude/skills/...) OR user-level (~/.claude/skills/).
# Two-home ruling 2026-07-04b: studio skills live project-local at .claude/skills/
# (repo-canonical); user-level holds only personal skills. NEVER create a
# user-level twin of a project skill — precedence (user > project) shadows it.
SKILL_MATCH=0
case "$FILE_PATH" in
  # Any .claude/skills/<name>/SKILL.md (catches project-local AND the
  # home-relative user-level path via the leading wildcard)
  *.claude/skills/*/SKILL.md)
    SKILL_MATCH=1 ;;
esac

if [ "$SKILL_MATCH" -eq 1 ]; then
  CONTEXT="[pretool-gate 🔒 MANDATORY] About to ${TOOL_NAME} a SKILL.md file at: ${FILE_PATH}

CLAUDE.md MANDATORY rule (added 2026-04-30 after discipline drift):
  /writing-skills MUST fire BEFORE any Write or Edit on a .claude/skills/<name>/SKILL.md path.

Self-check before this tool call completes:
  1. Did /writing-skills fire this turn? If no, STOP. Fire it via Skill tool. Then re-attempt.
  2. What is the failing test that this SKILL.md edit addresses? Name it.
  3. Is this an upstream concern or a project-local override?

The writing-skills skill (.claude/skills/writing-skills/)
documents 2026-04-30 drift rationalisations. The rule is hard, not advisory.

If you have already fired /writing-skills this turn: proceed. Otherwise: STOP,
fire it, then re-attempt the tool call. The hook is stateless and cannot
block — but it cannot be missed either."
fi

# Branch 2 — registry nudge: system/addon/schema files often ship new
# registry-worthy artifacts. Remind about system_registry.json coverage.
case "$FILE_PATH" in
  *src/systems/*.gd|*addons/*|*data/_schemas/*.json)
    NUDGE="Registry rule: if this ships a NEW system/autoload/addon/data category, system_registry.json needs an entry (CLAUDE.md)."
    if [ -n "$CONTEXT" ]; then
      CONTEXT="${CONTEXT}

${NUDGE}"
    else
      CONTEXT="$NUDGE"
    fi
    ;;
esac

# Nothing matched — silent pass-through.
if [ -z "$CONTEXT" ]; then
  exit 0
fi

# Output JSON with hookSpecificOutput.additionalContext to inject the
# reminder into Claude's next assistant turn.
if command -v jq >/dev/null 2>&1; then
  printf '%s' "$CONTEXT" | jq -Rsa '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: .}}'
else
  ESCAPED="$(printf '%s' "$CONTEXT" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n' '\f' | sed 's/\f/\\n/g')"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$ESCAPED"
fi

exit 0
