<!-- scaffold-seed: unwritten — delete this line once you write real content -->
# Accessibility Requirements — [Project]

> **Status**: Draft | Committed | Audited | Certified
> **Owner**: [ux-designer / producer]
> **Last Updated**: [YYYY-MM-DD]
> **Target Tier**: [Basic / Standard / Comprehensive / Exemplary]
> **Platform(s)**: [list every platform you ship on — each sets its own floor]
> **Standards targeted**: [e.g. WCAG 2.1 AA; the platform holders' own guidelines]
> **Consultant**: [name + organisation, or "none engaged"]

**What this is.** The project-wide accessibility commitments: the tier you are
committing to, the feature matrix across every system, the test plan, and the
audit history. Per-screen annotations do **not** live here — those belong in the
UX specs at `docs/ux/`. This file is what those specs point at.

**If a feature conflicts with a commitment made here, this file wins.** Change the
feature, not the commitment, unless the producer approves a formal revision.

**Written by** the ux-designer and producer during technical setup; updated after
every `/gate-check` pass, after every audit, and whenever a new system appears in
`docs/gdd/systems-index.md`.
**Read by** the UX templates (`ux-spec.md`, `hud-design.md`,
`interaction-pattern-library.md`), the technical-setup phase gate, and QA.

**How to fill it.** Commit to a tier first — everything below hangs off that one
choice. Then walk the four sensory sections and set each row's Status. The long
form of every row below, with the reasoning and the research behind it, is in the
shipped template at `.claude/docs/templates/accessibility-requirements.md`; ask a
session to pull rows from it as you commit to them.

**Status vocabulary:** `Not started` · `In progress` · `Implemented` · `Verified` · `Out of scope`

---

## 1. Tier commitment

*Accessibility is not binary. Pick a tier so the team shares a vocabulary and the
scope stops moving in both directions ("we'll add it later" / "we must do everything").*

| Tier | Core commitment | Typical effort |
|---|---|---|
| **Basic** | Critical text is readable at standard resolution. No feature needs colour discrimination alone. Independent volume sliders. No photosensitivity risk. | Low — mostly design constraints |
| **Standard** | Basic, plus: full input remapping, subtitles with speaker ID, adjustable text size, at least one colourblind mode, no un-extendable timed input. | Medium — dedicated implementation work |
| **Comprehensive** | Standard, plus: screen-reader support for menus, mono audio, difficulty assists, HUD repositioning, reduced-motion mode, visual indicators for all gameplay-critical audio. | High — platform API work + UI architecture |
| **Exemplary** | Comprehensive, plus: full subtitle customisation, high-contrast mode, cognitive-load assists, haptic alternatives for audio-only cues, external audit. | Very high — dedicated budget + specialist |

### This project commits to: **[tier]**

*Rationale — 3 to 5 sentences. Do not restate the tier; justify it. Genre and its
characteristic barriers, target player, platform requirements, team capacity, and
what dropping one tier would cost in concrete terms.*

[rationale]

**In scope beyond the tier baseline:**
- [feature] — [why it was elevated]

**Explicitly out of scope:**
- [feature] — [why, and which players that affects] — see § 9

---

## 2. Visual

*Largest population of players who use accessibility features. Retrofitting minimum
text sizes or colour decisions after assets lock is expensive — decide now.*

| Feature | Tier | Scope | Status | Implementation notes |
|---|---|---|---|---|
| Minimum text size — menus | Standard | All menu screens | Not started | [px floor at your reference resolution; scale proportionally above it] |
| Minimum text size — subtitles | Standard | All captioned content | Not started | [the constraint is a player across a room, not at a desk] |
| Text contrast | Standard | All UI text | Not started | [ratio floor for body text and for large text; verify on final colour values] |
| Colourblind modes | Standard | All colour-coded gameplay | Not started | [which modes; what shifts for each — see the audit table below] |
| Colour-as-only-indicator audit | Basic | All UI + gameplay | Not started | [every entry in § 2.1 needs a non-colour backup before ship] |
| UI scaling | Standard | All UI | Not started | [range and default; test layout at both extremes] |
| High contrast mode | Comprehensive | Menus min., HUD preferred | Not started | [opaque backgrounds, outlined interactives] |
| Brightness / gamma | Basic | Global | Not started | [include a calibration reference image] |
| Flash / strobe safety | Basic | Cutscenes, VFX | Not started | [pre-launch warning + audit flash rate against a published threshold] |
| Reduced motion mode | Standard | Transitions, shake, VFX | Not started | [what it removes; what it cannot remove and why] |
| Subtitles on/off | Basic | All voiced content | Not started | [default state, and where it is offered at first launch] |
| Subtitle speaker ID | Standard | All voiced content | Not started | [name before line; colour coding only if it survives § 2.1] |

### 2.1 Colour-as-only-indicator audit

*Every place colour is currently the sole differentiator. Each needs a non-colour
backup that works in all committed colourblind modes.*

| Location | Colour signal | What it communicates | Non-colour backup | Status |
|---|---|---|---|---|
| [health bar] | [red = low] | [near death] | [numeric value + pulse] | Not started |

---

## 3. Motor

*Games are more motor-demanding than most software. Most of the rows below are
cheap if planned now and very expensive to add after ship.*

| Feature | Tier | Scope | Status | Implementation notes |
|---|---|---|---|---|
| Full input remapping | Standard | Every input, every device | Not started | [rebindable per device; warn on conflict; persist to profile] |
| Live input-method switching | Standard | Desktop | Not started | [prompts must update to the active device without a restart] |
| Hold-to-toggle alternatives | Standard | Every hold input | Not started | [list every hold input in the game here] |
| Rapid-input alternatives | Standard | Any repeated-press action | Not started | [anything sustained above ~3 presses/sec needs a single-press path] |
| Timing-window adjustment | Standard | Timed prompts, rhythm inputs | Not started | [multiplier range and default; test at both extremes] |
| Aim / targeting assist | Standard | Ranged combat | Not started | [separate sliders, not one on/off] |
| One-hand path | [tier] | [audit multi-input actions] | Not started | [which actions have a one-hand path and which do not] |
| HUD repositioning | Comprehensive | All HUD elements | Not started | [matters for players with reduced peripheral coverage] |

---

## 4. Cognitive

*Affects a larger combined population than most teams assume, and every player
under stress. The three classic failures: no pause, one-shot tutorials, and too
many simultaneous states to track.*

| Feature | Tier | Scope | Status | Implementation notes |
|---|---|---|---|---|
| Granular difficulty options | Standard | All difficulty parameters | Not started | [separate sliders beat one Easy/Normal/Hard label; justify anything fixed] |
| Pause anywhere | Basic | Every gameplay state | Not started | [document every state where pause is blocked — each is a risk] |
| Tutorial persistence | Standard | All tutorials + help text | Not started | [retrievable from a help menu after dismissal] |
| Objective clarity | Standard | Quest / objective systems | Not started | [current objective reachable in ≤2 inputs, full text on demand] |
| Reading time for UI | Standard | Auto-dismissing dialogs | Not started | [no actionable text dismisses in under ~5s; prefer no auto-dismiss] |
| Cognitive load per system | Comprehensive | Per system | Not started | [max simultaneous things tracked; flag anything above 4 for review] |
| Navigation assists | Standard | World navigation | Not started | [fast travel, waypoints, persistent objective marker — or say why not] |

---

## 5. Auditory

*Guiding principle: every sound that changes what the player should do next needs a
visual equivalent. That is a design rule before it is an accessibility rule — it
also covers everyone playing with the sound off.*

| Feature | Tier | Scope | Status | Implementation notes |
|---|---|---|---|---|
| Subtitles for all speech | Basic | All voiced content | Not started | [100% coverage — narration, incidental and distant dialogue included] |
| Captions for critical SFX | Comprehensive | The list in § 5.1 | Not started | [only sounds the player cannot infer visually] |
| Mono audio option | Comprehensive | Global output | Not started | [fold channels preserving balance; essential for single-sided deafness] |
| Independent volume sliders | Basic | Music / SFX / voice / UI | Not started | [four minimum; persist to profile; expose in the pause menu too] |
| Directional audio indicators | Comprehensive | Off-screen events | Not started | [screen-edge indicator; opacity tracks proximity] |
| High-frequency cue backup | Standard | All critical audio cues | Not started | [hearing aids often filter high frequencies — give a low-frequency or visual twin] |

### 5.1 Gameplay-critical SFX audit

*Every sound that communicates state the player must act on. Each needs a confirmed
visual backup or a caption.*

| Sound | What it communicates | Visual backup | Caption required | Status |
|---|---|---|---|---|
| [cue] | [what the player should do] | [what they see instead] | [yes/no] | Not started |

---

## 6. Platform accessibility APIs

*Using the native APIs lets OS-level assistive tools work inside the game. Platform
requirements set a floor, not a ceiling — check them before committing to a tier.*

| Platform | API / standard | Features planned | Status | Notes |
|---|---|---|---|---|
| [platform] | [API or guideline set] | [what you will integrate] | Not started | [certification requirement, if any] |

---

## 7. Per-feature accessibility matrix

*Accessibility is a property of every system, not a settings menu. One row per
system in `docs/gdd/systems-index.md`. A system with an unaddressed concern here
cannot be marked approved there.*

| System | Visual concerns | Motor concerns | Cognitive concerns | Auditory concerns | Addressed | Notes |
|---|---|---|---|---|---|---|
| [system] | [concern] | [concern] | [concern] | [concern] | Not started | |

---

## 8. Test plan

*Standard QA asks whether a feature works. Accessibility testing asks whether it
works for the players who need it. Those are different tests. Plan three kinds:
automated, manual-internal (simulators), and testing with players who actually use
these features.*

| Feature | Method | Cases | Pass criteria | Owner | Status |
|---|---|---|---|---|---|
| [feature] | [automated / manual / user testing] | [what gets tested] | [the measurable bar] | [role] | Not started |

---

## 9. Known intentional limitations

*Undocumented omissions become surprises at certification. A documented limitation
with a rationale is a decision; an undocumented one is an oversight. Every row here
is a risk — name who it affects.*

| Feature | Tier it belongs to | Why not included | Who this affects | Mitigation |
|---|---|---|---|---|
| [feature] | [tier] | [honest reason] | [which players] | [partial measure, or "none"] |

---

## 10. Audit history

*Accessibility is not certified once. Platform requirements change, new features add
new barriers. A history shows due diligence and catches regressions between audits.*

| Date | Auditor | Type | Scope | Findings | Status |
|---|---|---|---|---|---|
| [YYYY-MM-DD] | [internal / external] | [review / user testing] | [what was covered] | [summary] | [open / addressed] |

---

## 11. Open questions

| Question | Owner | Needed by | Resolution |
|---|---|---|---|
| [question] | [role] | [gate or milestone] | Unresolved |
