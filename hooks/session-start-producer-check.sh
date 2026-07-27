#!/usr/bin/env bash
# SessionStart hook — reads dev_diary.json's most recent `next` field +
# greps for keywords mapping to specialist-agent dispatch territory.
# Injects a system-reminder pointing at the right specialist + the
# CLAUDE.md MANDATORY DISPATCH rule, so Claude lands a fresh chat with
# explicit dispatch guidance for what's queued.
#
# Closes an observed gap where queued PM/audit work was done inline
# because no chat-start prompt surfaced "this is producer territory"
# ahead of time.

set -e

# Find the most recent dev_diary entry's `next` field. dev_diary.json
# structure: entries.YYYY-MM-DD.next
DIARY="data/_schemas/dev_diary.json"
if [ ! -f "$DIARY" ]; then
  exit 0
fi

# Extract last entry's `next` value. Use jq if available; fall back to
# Python which is always available on this project (consistency_check.py
# uses it).
NEXT_VAL=""
if command -v jq >/dev/null 2>&1; then
  NEXT_VAL="$(jq -r '.entries | to_entries | sort_by(.key) | last.value.next // ""' "$DIARY" 2>/dev/null)"
elif command -v python >/dev/null 2>&1; then
  NEXT_VAL="$(python -c "
import json, sys
try:
    r = json.load(open('$DIARY', encoding='utf-8'))
    entries = r.get('entries', {})
    if entries:
        last_key = sorted(entries.keys())[-1]
        print(entries[last_key].get('next', '') or '')
except Exception:
    pass
" 2>/dev/null)"
fi

# Lowercase for case-insensitive match.
NEXT_LOWER="$(printf '%s' "$NEXT_VAL" | tr '[:upper:]' '[:lower:]')"

# Empty `next` field → no dispatch guidance to inject.
if [ -z "$NEXT_LOWER" ]; then
  exit 0
fi

# Build dispatch reminders based on keywords in the `next` field.
# Maps mirror the CLAUDE.md MANDATORY DISPATCH table + .claude/docs/agents-index.md.
REMINDERS=""

add_dispatch() {
  if [ -n "$REMINDERS" ]; then
    REMINDERS="${REMINDERS}\n"
  fi
  REMINDERS="${REMINDERS}$1"
}

case "$NEXT_LOWER" in
  *"audit"*|*"registry"*|*"consistency"*|*"sprint"*|*"milestone"*|*"scope"*|*"tech debt"*|*"retrospective"*|*"bug triage"*|*"project management"*|*"doc sync"*|*"docs sync"*|*"stock check"*|*"restructure"*|*"cleanup"*|*"reorganis"*|*"reorganiz"*)
    add_dispatch "[chat-start 🔒 MANDATORY DISPATCH] dev_diary.next field flags PM/audit territory. **DISPATCH \`producer\` agent FIRST** for any non-trivial scoped work — Agent({subagent_type: 'producer', prompt: '...'}). See CLAUDE.md MANDATORY DISPATCH rule + .claude/docs/agents-index.md Intent table. Today's primary work is producer-owned." ;;
esac

case "$NEXT_LOWER" in
  *"narrative"*|*"story arc"*|*"dialogue"*|*"lore"*|*"act 1"*|*"act 2"*|*"act 3"*|*"quest"*|*"scene"*)
    add_dispatch "[chat-start 🔒 MANDATORY DISPATCH] dev_diary.next field flags narrative territory. **DISPATCH \`narrative-director\` (or \`/team-narrative\` for full vertical) FIRST.** Templates: narrative-character-sheet.md, faction-design.md, player-journey.md." ;;
esac

case "$NEXT_LOWER" in
  *"combat"*|*"damage"*|*"ability"*|*"abilities"*|*"trait"*|*"effect"*|*"status"*|*"enemy"*|*"enemies"*|*"boss"*)
    add_dispatch "[chat-start 🔒 MANDATORY DISPATCH] dev_diary.next field flags combat-vertical territory. **DISPATCH \`gameplay-programmer\` + \`systems-designer\` (or \`/team-combat\` for full vertical) FIRST** for non-trivial scoped work. /team-combat orchestrates gameplay-programmer + systems-designer + qa-tester." ;;
esac

# "ui"/"ux" need word boundaries — bare substrings over-match ("building", "guide", "flux").
UI_MATCH=0
case "$NEXT_LOWER" in
  *"hud"*|*"menu"*|*"layout"*|*"dashboard"*|*"dock"*) UI_MATCH=1 ;;
esac
if [ "$UI_MATCH" -eq 0 ] && echo "$NEXT_LOWER" | grep -qiE '\b(ui|ux)\b'; then
  UI_MATCH=1
fi
if [ "$UI_MATCH" -eq 1 ]; then
  add_dispatch "[chat-start 🔒 MANDATORY DISPATCH] dev_diary.next field flags UI/UX territory. **DISPATCH \`ux-designer\` + \`ui-programmer\` (or \`/team-ui\` for full vertical) FIRST.** Templates: ux-spec.md, hud-design.md, interaction-pattern-library.md."
fi

case "$NEXT_LOWER" in
  *"tools"*|*"automation"*|*"python script"*|*"helper script"*|*"check_"*|*"editor extension"*|*"in-engine tool"*)
    add_dispatch "[chat-start 🔒 MANDATORY DISPATCH] dev_diary.next field flags tools/automation territory. **DISPATCH \`tools-programmer\` FIRST** for non-trivial scoped work." ;;
esac

# "art"/"asset" need word boundaries — bare substrings over-match ("start", "part").
ART_MATCH=0
case "$NEXT_LOWER" in
  *"illustration"*|*"card art"*|*"visual identity"*|*"style guide"*) ART_MATCH=1 ;;
esac
if [ "$ART_MATCH" -eq 0 ] && echo "$NEXT_LOWER" | grep -qiE '\b(art|assets?)\b'; then
  ART_MATCH=1
fi
if [ "$ART_MATCH" -eq 1 ]; then
  add_dispatch "[chat-start 🔒 MANDATORY DISPATCH] dev_diary.next field flags art-direction territory. **DISPATCH \`art-director\` (or \`technical-artist\` for pipeline) FIRST.** Template: art-bible.md."
fi

case "$NEXT_LOWER" in
  *"audio"*|*"music"*|*"sound"*|*"sfx"*|*"mix"*)
    add_dispatch "[chat-start 🔒 MANDATORY DISPATCH] dev_diary.next field flags audio territory. **DISPATCH \`audio-director\` (or \`/team-audio\`) FIRST.** Template: sound-bible.md." ;;
esac

case "$NEXT_LOWER" in
  *"vision"*|*"pivot"*|*"redesign"*|*"pillar"*|*"direction"*)
    add_dispatch "[chat-start 🔒 MANDATORY DISPATCH] dev_diary.next field flags vision/direction territory. **DISPATCH \`creative-director\` FIRST** (highest creative authority). Templates: game-pillars.md, game-concept.md." ;;
esac

case "$NEXT_LOWER" in
  *"release"*|*"patch notes"*|*"changelog"*|*"day-one"*|*"day one"*|*"launch"*)
    add_dispatch "[chat-start 🔒 MANDATORY DISPATCH] dev_diary.next field flags release territory. **DISPATCH \`release-manager\` FIRST.** Templates: release-checklist-template.md, release-notes.md." ;;
esac

case "$NEXT_LOWER" in
  *"security"*|*"anti-cheat"*|*"save tampering"*|*"exploit"*|*"vulnerability"*)
    add_dispatch "[chat-start 🔒 MANDATORY DISPATCH] dev_diary.next field flags security territory. **DISPATCH \`security-engineer\` FIRST.** Skill: security-audit." ;;
esac

if [ -z "$REMINDERS" ]; then
  exit 0
fi

# Output as additionalContext.
CONTEXT="$(printf "%b" "$REMINDERS")"
CONTEXT="$(printf 'dev_diary.json next field for the most recent entry contains keywords matching specialist-dispatch territory:\n\n%s\n\nNext = %s\n\nPer CLAUDE.md MANDATORY DISPATCH rule + .claude/docs/agents-index.md, dispatch the relevant specialist BEFORE doing the work inline. Doing it inline = silent skill skipping failure mode.' "$CONTEXT" "$NEXT_VAL")"

if command -v jq >/dev/null 2>&1; then
  printf '%s' "$CONTEXT" | jq -Rsa '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: .}}'
else
  ESCAPED="$(printf '%s' "$CONTEXT" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n' '\f' | sed 's/\f/\\n/g')"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$ESCAPED"
fi

exit 0
