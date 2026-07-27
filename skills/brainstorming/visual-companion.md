# Visual Companion Guide

Browser-based visual brainstorming companion for showing mockups, diagrams, and options.

## When to Use

Decide per-question, not per-session. The test: **would the user understand this better by seeing it than reading it?**

**Use the browser** when the content itself is visual:

- **UI mockups** — wireframes, layouts, navigation structures, component designs
- **Architecture diagrams** — system components, data flow, relationship maps
- **Side-by-side visual comparisons** — comparing two layouts, two color schemes, two design directions
- **Design polish** — when the question is about look and feel, spacing, visual hierarchy
- **Spatial relationships** — state machines, flowcharts, entity relationships rendered as diagrams

**Use the terminal** when the content is text or tabular:

- **Requirements and scope questions** — "what does X mean?", "which features are in scope?"
- **Conceptual A/B/C choices** — picking between approaches described in words
- **Tradeoff lists** — pros/cons, comparison tables
- **Technical decisions** — API design, data modeling, architectural approach selection
- **Clarifying questions** — anything where the answer is words, not a visual preference

A question *about* a UI topic is not automatically a visual question. "What kind of wizard do you want?" is conceptual — use the terminal. "Which of these wizard layouts feels right?" is visual — use the browser.

## Availability — read this before you offer it

**The browser companion is not part of this bundle.** It is provided by the
optional `obra/superpowers` plugin, which ships the local server, its
`start-server.sh` / `stop-server.sh` runners, the page frame and its CSS
classes, and the event format you read selections back from. Nothing in
ShiningPlague Studio starts a server.

So, in order:

1. **Check first.** If the `superpowers` plugin is installed, its own
   brainstorming skill carries the current operating guide — server startup,
   the write/read loop, the CSS classes, the event format. Follow *that* guide;
   it is versioned with the server and this page is not.
2. **If it is not installed, do not offer the companion.** Say one line —
   "the browser companion needs the optional superpowers plugin, which isn't
   installed, so I'll keep this in the terminal" — and continue. Never send the
   user chasing a script this bundle does not ship.
3. **Either way, the judgment above still applies.** Visual-vs-terminal is a
   decision about the *question*, not about the tooling.

## The terminal fallback (always available)

Everything the companion does for a text question, the terminal already does
better. For a genuinely visual question with no companion available:

- **Describe the layout in structure, not prose** — a small ASCII or box sketch
  beats a paragraph, and costs nothing.
- **Name the differences, not the designs** — "A puts the nav on the left and
  the action bar at the bottom; B inverts that" is the actual decision.
- **Offer 2-3 options with one distinguishing line each**, then ask which
  direction to develop. Use `AskUserQuestion` to capture the pick.
- **Write the chosen direction into the spec** at `docs/specs/` so the visual
  decision survives the conversation.

If the project needs a persistent visual artifact, the shipping path is a UX
spec authored by the `ux-designer` agent under `docs/ux/`, not a transient
browser session.
