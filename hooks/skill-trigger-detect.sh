#!/usr/bin/env bash
# UserPromptSubmit hook — scans the user's prompt for skill-name keywords and
# injects a system-reminder pointing at the matching skill. Mechanically
# enforces the Skills Protocol from CLAUDE.md so silent skipping becomes
# structurally impossible.
#
# Reads the hook input JSON from stdin. We don't parse — just grep the
# entire payload for keyword strings. Robust against schema changes and
# missing jq.
#
# Outputs JSON with hookSpecificOutput.additionalContext when a keyword
# matches; otherwise outputs nothing (silent pass-through, no overhead).

set -e

# Slurp stdin (the hook input JSON containing the user's prompt). Lowercase
# for case-insensitive match.
INPUT="$(cat | tr '[:upper:]' '[:lower:]')"

# Build the reminder list — one line per matched skill. Order: 🔒 MUST-USE
# first (highest priority), then 🟢 propose-first.
REMINDERS=""

add_reminder() {
  if [ -n "$REMINDERS" ]; then
    REMINDERS="${REMINDERS}\n"
  fi
  REMINDERS="${REMINDERS}$1"
}

# 🔒 MUST-USE — auto-fire on trigger, no announce-and-wait
# "bug"/"error" need word boundaries — bare substrings over-match ("debug", "terror").
DEBUG_MATCH=0
case "$INPUT" in
  *"crash"*|*"hang"*|*"doesn't work"*|*"does not work"*|*"not working"*|*"failed"*|*"broken"*) DEBUG_MATCH=1 ;;
esac
if [ "$DEBUG_MATCH" -eq 0 ] && printf '%s' "$INPUT" | grep -qiE '\b(bugs?|errors?)\b'; then
  DEBUG_MATCH=1
fi
if [ "$DEBUG_MATCH" -eq 1 ]; then
  add_reminder "[skill-trigger 🔒] Bug/error language detected in prompt — fire /systematic-debugging via Skill tool BEFORE proposing any fix. Phase 1 evidence-gathering first."
fi
case "$INPUT" in
  *"verify"*|*"is it done"*|*"did that work"*|*"shipped?"*|*"is it fixed"*|*"is it complete"*|*"can you confirm"*)
    add_reminder "[skill-trigger 🔒] Verification language detected — fire /verification-before-completion via Skill tool. Run actual verification commands; do NOT claim done without command-output reference." ;;
esac
case "$INPUT" in
  *"brainstorm"*|*"new feature"*|*"design a"*|*"how should we build"*)
    add_reminder "[skill-trigger 🔒] Brainstorm/design language detected — fire /brainstorming via Skill tool BEFORE writing any code. Spec-first workflow per CLAUDE.md." ;;
esac

# 🟢 propose-first — announce and wait for confirmation
case "$INPUT" in
  *"consistency check"*|*"audit the doc"*|*"verify the doc"*|*"check for drift"*)
    add_reminder "[skill-trigger 🟢] Consistency check requested — propose firing /consistency-check via Skill tool. Don't improvise an ad-hoc script." ;;
esac
case "$INPUT" in
  *"design review"*|*"review the spec"*|*"review the design"*)
    add_reminder "[skill-trigger 🟢] Design review requested — propose firing /design-review via Skill tool." ;;
esac
case "$INPUT" in
  *"simplify"*|*"clean this up"*|*"refactor"*|*"make this simpler"*)
    add_reminder "[skill-trigger 🟢] Simplification requested — propose firing /simplify via Skill tool." ;;
esac
case "$INPUT" in
  *"code review"*|*"review the code"*|*"review my code"*|*"review src"*)
    add_reminder "[skill-trigger 🟢] Code review requested — propose firing /code-review via Skill tool." ;;
esac
case "$INPUT" in
  *"architecture decision"*|*"adr"*|*"lock the decision"*|*"architectural call"*)
    add_reminder "[skill-trigger 🟢] Architecture decision context — propose firing /architecture-decision via Skill tool. ADRs are the deliverable." ;;
esac
case "$INPUT" in
  *"architecture review"*|*"trace adr"*|*"adr coverage"*)
    add_reminder "[skill-trigger 🟢] Architecture review context — propose firing /architecture-review via Skill tool." ;;
esac
case "$INPUT" in
  *"writing plan"*|*"plan the impl"*|*"break this into tasks"*|*"plan this out"*)
    add_reminder "[skill-trigger 🟢] Plan-writing context — propose firing /writing-plans via Skill tool. Spec → ADR → plan → execute chain." ;;
esac
case "$INPUT" in
  *"regression"*|*"regression test"*|*"capture as test"*|*"prevent this regressing"*)
    add_reminder "[skill-trigger 🟢] Regression context — propose firing /regression-suite via Skill tool. Maps fixed bug → regression test entry." ;;
esac
case "$INPUT" in
  *"new skill"*|*"edit skill"*|*"write skill"*|*"skill.md"*|*"author a skill"*|*"create a skill"*|*"rewrite skill"*|*"skill override"*)
    add_reminder "[skill-trigger 🔒 MANDATORY per CLAUDE.md] SKILL.md authoring context. **YOU MUST FIRE /writing-skills via Skill tool BEFORE any Write/Edit on a SKILL.md path.** Self-check: did /writing-skills fire this turn? If no, fire it FIRST. Treating this as 🟢 advisory has caused drift before — promoted to 🔒." ;;
esac
# "scope" needs a word boundary — bare substring over-matches ("telescope", "microscope").
SCOPE_MATCH=0
case "$INPUT" in
  *"deviating"*|*"beyond what we planned"*) SCOPE_MATCH=1 ;;
esac
if [ "$SCOPE_MATCH" -eq 0 ] && printf '%s' "$INPUT" | grep -qiE '\bscope\b'; then
  SCOPE_MATCH=1
fi
if [ "$SCOPE_MATCH" -eq 1 ]; then
  add_reminder "[skill-trigger 🟢] Scope context — propose firing /scope-check via Skill tool to detect deviation from current step's stated scope."
fi
case "$INPUT" in
  *"tech debt"*|*"technical debt"*|*"cruft"*|*"cleanup later"*|*"refactor someday"*)
    add_reminder "[skill-trigger 🟢] Tech-debt context — propose firing /red-flag-scan via Skill tool to log + prioritise debt items." ;;
esac

# === AGENT-TRIGGER patterns (added 2026-04-30) ============================
# Maps designer intent to specialist agent dispatch + relevant templates.
# Full mapping at docs/agents-index.md § Intent -> Agent + Templates table.
# Pattern: case-insensitive substring match on user prompt -> inject reminder
# pointing me at the right agent(s) + templates to consider dispatching.

# Vision / pivot / redesign work
case "$INPUT" in
  *"redesign"*|*"vision"*|*"pivot"*|*"direction"*|*"core pillar"*|*"game pillars"*|*"6 pillars"*)
    add_reminder "[agent-trigger] Vision/pivot context detected. Propose dispatching creative-director (Agent tool, subagent_type=creative-director) + reading templates: .claude/docs/templates/game-pillars.md (6-pillar exercise), game-concept.md (pitch), game-design-document.md (full GDD). See docs/agents-index.md for full Intent->Agent mapping." ;;
esac

# Mechanic / system design
case "$INPUT" in
  *"new mechanic"*|*"design a mechanic"*|*"design the system"*|*"mechanic design"*|*"design a new"*)
    add_reminder "[agent-trigger] Mechanic-design context. Propose dispatching game-designer + systems-designer. Templates: .claude/docs/templates/economy-model.md, difficulty-curve.md. Skills: brainstorming 🔒, design-review, architecture-decision." ;;
esac

# Balance / tuning
case "$INPUT" in
  *"balance"*|*"tune the"*|*"tuning"*|*"rebalance"*)
    add_reminder "[agent-trigger] Balance/tuning context. Dispatch systems-designer/economy-designer (balance analysis via content-audit). Template: difficulty-curve.md." ;;
esac

# Loot / economy / rewards
case "$INPUT" in
  *"loot table"*|*"loot tables"*|*"currency"*|*"reward"*|*"economy"*|*"sink"*|*"faucet"*)
    add_reminder "[agent-trigger] Economy context. Propose dispatching economy-designer. Template: .claude/docs/templates/economy-model.md. Dispatch systems-designer/economy-designer (balance analysis via content-audit)." ;;
esac

# Narrative / story / lore
case "$INPUT" in
  *"story arc"*|*"narrative"*|*"plot"*|*"scene structure"*|*"character arc"*)
    add_reminder "[agent-trigger] Narrative context. Propose dispatching narrative-director + writer + world-builder (or fire /team-narrative). Templates: narrative-character-sheet.md, player-journey.md." ;;
esac

# Dialogue / writing
case "$INPUT" in
  *"write dialogue"*|*"draft dialogue"*|*"dialogue line"*|*"item description"*|*"lore entry"*)
    add_reminder "[agent-trigger] Writing context. Propose dispatching writer (subagent). For longer narrative work, also propose narrative-director." ;;
esac

# Worldbuilding / factions / lore depth
case "$INPUT" in
  *"worldbuild"*|*"world building"*|*"faction"*|*"history of"*|*"lore depth"*)
    add_reminder "[agent-trigger] Worldbuilding context. Propose dispatching world-builder. Template: faction-design.md. Cross-reference docs/lorebook_v3.md for canon." ;;
esac

# Level / encounter design
case "$INPUT" in
  *"level layout"*|*"level design"*|*"encounter design"*|*"spatial design"*|*"act 1 scene"*|*"act 2 scene"*)
    add_reminder "[agent-trigger] Level/encounter context. Propose dispatching level-designer. Template: level-design-document.md." ;;
esac

# UX / UI design
case "$INPUT" in
  *"ux flow"*|*"user journey"*|*"menu structure"*|*"interaction pattern"*|*"hud design"*)
    add_reminder "[agent-trigger] UX context. Propose dispatching ux-designer (+ ui-programmer if implementation follows). Templates: ux-spec.md, hud-design.md, interaction-pattern-library.md." ;;
esac

# Accessibility
case "$INPUT" in
  *"accessibility"*|*"a11y"*|*"colourblind"*|*"colorblind"*|*"screen reader"*|*"key remap"*)
    add_reminder "[agent-trigger] Accessibility context. Propose dispatching accessibility-specialist. Template: accessibility-requirements.md. Skill: design:accessibility-review." ;;
esac

# Audio / music / SFX
case "$INPUT" in
  *"music direction"*|*"soundtrack"*|*"audio cue"*|*"sfx"*|*"sound design"*|*"audio mix"*)
    add_reminder "[agent-trigger] Audio context. Propose dispatching audio-director (direction) or sound-designer (specs). Template: sound-bible.md. Or fire /team-audio." ;;
esac

# Art direction / visual identity
case "$INPUT" in
  *"art direction"*|*"art bible"*|*"visual identity"*|*"style guide"*|*"asset pipeline"*|*"card art"*)
    add_reminder "[agent-trigger] Art-direction context. Propose dispatching art-director (or technical-artist for pipeline). Template: art-bible.md. Skill: art-bible." ;;
esac

# Sprint / milestone / production / PM heavy-lifting
# "audit"/"registry" need word boundaries — bare substrings over-match ("auditory", "auditorium").
PM_MATCH=0
case "$INPUT" in
  *"sprint plan"*|*"milestone"*|*"what's next"*|*"whats next"*|*"timeline"*|*"production schedule"*|*"consistency check"*|*"doc sync"*|*"docs sync"*|*"stock check"*|*"project state"*|*"restructure"*|*"cleanup"*|*"reorganise"*|*"reorganize"*|*"scope check"*|*"tech debt"*|*"technical debt"*|*"retrospective"*|*"bug triage"*|*"project management"*) PM_MATCH=1 ;;
esac
if [ "$PM_MATCH" -eq 0 ] && printf '%s' "$INPUT" | grep -qiE '\b(audits?|registry)\b'; then
  PM_MATCH=1
fi
if [ "$PM_MATCH" -eq 1 ]; then
  add_reminder "[agent-trigger 🔒 MANDATORY DISPATCH per CLAUDE.md] PM / audit / registry / coordination context. **YOU MUST PROPOSE DISPATCHING \`producer\` FIRST.** Doing it inline = silent skill skipping failure mode. Templates: sprint-plan.md, milestone-definition.md, risk-register-entry.md. Skills: sprint-plan, retrospective, scope-check, estimate, red-flag-scan, content-audit, bug-triage. See docs/agents-index.md Intent table."
fi

# Tools-programmer dispatch triggers (registry / consistency check tooling = tools-programmer territory)
case "$INPUT" in
  *"build a script"*|*"build the script"*|*"automation script"*|*"check_"*|*"consistency_check"*|*"registry coverage"*|*"hook extension"*|*"extend the hook"*|*"helper script"*|*"validation script"*)
    add_reminder "[agent-trigger 🔒 MANDATORY DISPATCH per CLAUDE.md] Tools / automation context. **YOU MUST PROPOSE DISPATCHING \`tools-programmer\` FIRST** for non-trivial Python/GDScript automation. Inline only for trivial one-liner edits. See docs/agents-index.md." ;;
esac

# Architecture / engine-level
case "$INPUT" in
  *"engine choice"*|*"rendering pipeline"*|*"performance budget"*|*"architectural call"*|*"core framework"*)
    add_reminder "[agent-trigger] Architecture context. Propose dispatching technical-director (or engine-programmer for implementation). Template: architecture-decision-record.md, technical-design-document.md. Skill: architecture-decision, architecture-review." ;;
esac

# Performance
case "$INPUT" in
  *"frame time"*|*"fps drop"*|*"perf bottleneck"*|*"memory leak"*|*"profile the"*)
    add_reminder "[agent-trigger] Performance context. Dispatch performance-analyst (+ engine-programmer if optimisation)." ;;
esac

# QA / testing strategy
case "$INPUT" in
  *"qa plan"*|*"test strategy"*|*"playtest"*|*"bug triage"*|*"test cases"*)
    add_reminder "[agent-trigger] QA context. Propose dispatching qa-lead (strategy) or qa-tester (test cases). Templates: test-plan.md, test-evidence.md. Skills: qa-plan, bug-triage, regression-suite." ;;
esac

# Release / launch
case "$INPUT" in
  *"release coordination"*|*"launch prep"*|*"patch notes"*|*"day one patch"*|*"day-one patch"*|*"release pipeline"*)
    add_reminder "[agent-trigger] Release context. Propose dispatching release-manager (+ producer for coord, qa-lead for gate). Templates: release-checklist-template.md, release-notes.md. Skills: day-one-patch, gate-check (dispatch release-manager)." ;;
esac

# Localisation
case "$INPUT" in
  *"localis"*|*"localiz"*|*"i18n"*|*"translation"*|*"string extraction"*)
    add_reminder "[agent-trigger] Localisation context. Propose dispatching localization-lead." ;;
esac

# Prototyping
case "$INPUT" in
  *"prototype this"*|*"throwaway prototype"*|*"concept validation"*|*"vertical slice"*|*"prove the concept"*)
    add_reminder "[agent-trigger] Prototyping context. Propose dispatching prototyper. Template: concept-doc-from-prototype.md." ;;
esac

# Incident / post-mortem
case "$INPUT" in
  *"incident"*|*"post-mortem"*|*"postmortem"*|*"outage"*|*"production issue"*)
    add_reminder "[agent-trigger] Incident context. Propose dispatching release-manager + qa-lead. Templates: incident-response.md, post-mortem.md. Skill: retrospective." ;;
esac

# AI / NPC behaviour
case "$INPUT" in
  *"ai behaviour"*|*"ai behavior"*|*"npc behavior"*|*"npc behaviour"*|*"behaviour tree"*|*"behavior tree"*|*"pathfinding"*|*"enemy logic"*)
    add_reminder "[agent-trigger] AI/NPC context. Propose dispatching ai-programmer. Skills: anthropic-skills:godot 🔒, test-driven-development 🔒." ;;
esac

# Shader / VFX
case "$INPUT" in
  *"shader"*|*"particle"*|*"post-processing"*|*"vfx"*)
    add_reminder "[agent-trigger] Shader/VFX context. Propose dispatching godot-shader-specialist (+ technical-artist for art pipeline)." ;;
esac

# === WORKSTREAM-TRIGGER patterns (added 2026-05-11) =======================
# Maps designer intent to workstream + team orchestrator dispatch.
# Each workstream has a dedicated state file at production/workstreams/<name>.md
# and a team-* orchestrator. Remind the assistant to load workstream state on match.

# Combat workstream
case "$INPUT" in
  *"combat"*|*"battle"*|*"fight"*|*"timeline"*|*"card system"*|*"deck"*|*"damage"*|*"trait"*|*"status effect"*)
    add_reminder "[workstream-trigger] Combat workstream detected. Load production/workstreams/combat.md if exists. Propose dispatching /team-combat (gameplay-programmer + systems-designer + qa-tester)." ;;
esac

# Narrative workstream
case "$INPUT" in
  *"narrative layer"*|*"story"*|*"act 1"*|*"act 2"*|*"act 3"*|*"companion"*|*"dm narration"*|*"scene structure"*)
    add_reminder "[workstream-trigger] Narrative workstream detected. Load production/workstreams/narrative.md if exists. Propose dispatching /team-narrative (narrative-director + writer + world-builder)." ;;
esac

# UI/UX workstream
# "ui"/"ux" need word boundaries — bare substrings over-match ("building", "guide", "flux").
UIWS_MATCH=0
case "$INPUT" in
  *"hud"*|*"menu"*|*"dashboard"*|*"dock"*|*"editor dock"*|*"interface"*|*"screen layout"*) UIWS_MATCH=1 ;;
esac
if [ "$UIWS_MATCH" -eq 0 ] && printf '%s' "$INPUT" | grep -qiE '\b(ui|ux)\b'; then
  UIWS_MATCH=1
fi
if [ "$UIWS_MATCH" -eq 1 ]; then
  add_reminder "[workstream-trigger] UI/UX workstream detected. Load production/workstreams/ui-ux.md if exists. Propose dispatching /team-ui (ui-programmer + ux-designer)."
fi

# Economy workstream
case "$INPUT" in
  *"economy"*|*"loot"*|*"reward"*|*"progression"*|*"resource"*|*"supplies"*|*"resolve"*|*"currency"*)
    add_reminder "[workstream-trigger] Economy workstream detected. Load production/workstreams/economy.md if exists. Propose dispatching /team-economy (economy-designer + systems-designer)." ;;
esac

# Level/World workstream
case "$INPUT" in
  *"level design"*|*"world map"*|*"location"*|*"biome"*|*"encounter layout"*|*"travel system"*|*"map screen"*)
    add_reminder "[workstream-trigger] Level/World workstream detected. Load production/workstreams/level-world.md if exists. Propose dispatching /team-level (level-designer + world-builder)." ;;
esac

# Art workstream
case "$INPUT" in
  *"art style"*|*"illustration"*|*"visual identity"*|*"asset"*|*"sprite"*|*"card art"*|*"character art"*)
    add_reminder "[workstream-trigger] Art workstream detected. Load production/workstreams/art.md if exists. Propose dispatching /team-art (art-director + technical-artist)." ;;
esac

# Audio workstream
case "$INPUT" in
  *"music"*|*"soundtrack"*|*"audio"*|*"sfx"*|*"sound"*|*"ambient"*)
    add_reminder "[workstream-trigger] Audio workstream detected. Load production/workstreams/audio.md if exists. Propose dispatching /team-audio (audio-director + sound-designer)." ;;
esac

# Infrastructure workstream
# "hook" needs a word boundary — bare substring over-matches ("hooked", "hookah").
INFRA_MATCH=0
case "$INPUT" in
  *"framework"*|*"donchitos"*|*"skill override"*|*"studio setup"*|*"pipeline"*|*"autoload"*|*"addon"*) INFRA_MATCH=1 ;;
esac
if [ "$INFRA_MATCH" -eq 0 ] && printf '%s' "$INPUT" | grep -qiE '\bhooks?\b'; then
  INFRA_MATCH=1
fi
if [ "$INFRA_MATCH" -eq 1 ]; then
  add_reminder "[workstream-trigger] Infrastructure workstream detected. Load production/workstreams/infrastructure.md if exists. Propose dispatching /team-infra (tools-programmer + devops-engineer)."
fi

# Game Design workstream (meta — crosses all domains)
case "$INPUT" in
  *"game design"*|*"core loop"*|*"pillar"*|*"mda"*|*"player experience"*|*"gdd"*|*"design the game"*)
    add_reminder "[workstream-trigger] Game Design workstream detected. Load production/workstreams/game-design.md if exists. This is creative-director-led — propose dispatching creative-director + game-designer." ;;
esac

# QA workstream
case "$INPUT" in
  *"qa pass"*|*"test plan"*|*"regression"*|*"smoke test"*|*"quality"*|*"playtest report"*)
    add_reminder "[workstream-trigger] QA workstream detected. Load production/workstreams/qa.md if exists. Producer-led — propose dispatching qa-lead + qa-tester." ;;
esac

# Session close trigger
case "$INPUT" in
  *"wrap up"*|*"close session"*|*"we're done"*|*"that's it"*|*"good session"*|*"let's close"*|*"call it"*)
    add_reminder "[session-trigger] Session close language detected. Initiate close protocol: director bookend re-dispatch, consistency gate, /update ritual, session reflection. See docs/specs/2026-05-11-workstream-formalization-design.md § Section 5." ;;
esac

# === DRIFT-RECOVERY reminder (fires on EVERY prompt if no other trigger matched) ===
# If no skill/agent/workstream trigger matched, the designer's message might be
# conversational or off-topic. Remind Claude to check: are we in a workstream?
# If yes, surface the current step and ask whether to continue or switch.
if [ -z "$REMINDERS" ]; then
  # Check if a workstream is active by reading active.md for workstream context
  STATE_FILE="production/session-state/active.md"
  if [ -f "$STATE_FILE" ]; then
    # Only fire if active.md mentions an active workstream
    ACTIVE_WS=$(grep -m1 "Workstream:" "$STATE_FILE" 2>/dev/null | head -1)
    if [ -n "$ACTIVE_WS" ]; then
      add_reminder "[drift-check] No skill or workstream trigger matched this prompt. Check: are we mid-workflow? If a team-* orchestrator is running an execution chain, remind the designer where we are in the chain and ask: continue current step, or switch workstream? If no active workflow, this is fine — conversation mode."
    fi
  fi
fi

# === END WORKSTREAM-TRIGGER patterns =======================================

# === END AGENT-TRIGGER patterns ===========================================

# If nothing matched, exit silently (zero-overhead path)
if [ -z "$REMINDERS" ]; then
  exit 0
fi

# Output the reminder as additionalContext. The harness injects this as a
# system-reminder in the model's context for this turn.
# Use printf so \n in REMINDERS becomes real newlines, then jq -Rsa to
# JSON-encode the whole multi-line string safely.
CONTEXT="$(printf "%b" "$REMINDERS")"

# JSON-encode the context. Try jq first (cleanest); fall back to manual
# escape if jq is missing.
if command -v jq >/dev/null 2>&1; then
  printf '%s' "$CONTEXT" | jq -Rsa '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: .}}'
else
  # Manual escape — replace " with \", newlines with \n, backslashes with \\
  ESCAPED="$(printf '%s' "$CONTEXT" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n' '\f' | sed 's/\f/\\n/g')"
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$ESCAPED"
fi
