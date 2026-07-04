# Credits & Attribution

ShiningPlague Game Studio stands on the work of several projects. This file records that debt in detail. Attribution is preserved both here and, per-artifact, in a `metadata.origin` marker inside individual skills and agents (see the tiers below).

## Donchitos — Claude-Code-Game-Studios

- **Repository:** https://github.com/Donchitos/Claude-Code-Game-Studios
- **License:** MIT © Kirill Ivanov (Donchitos)
- **What it provided:** the original agent roster, the template set, and the multi-phase pipeline architecture that this studio is built on. The director-gated Concept → Design → Architecture → Production → Release structure, the epic/story decomposition flow, and the majority of the document scaffolds trace directly to this project. ShiningPlague adapted and extended these; the backbone is Donchitos'.

## obra/superpowers

- **Repository:** https://github.com/obra/superpowers
- **What it provided:** the skill-authoring methodology and the discipline skills that keep the studio honest — **brainstorming**, **test-driven-development**, **systematic-debugging**, **verification-before-completion**, **writing-skills**, and related workflow-discipline skills. Where ShiningPlague ships adapted versions, the original methodology and structure are obra's. Vanilla versions of these skills remain reachable via the `superpowers` plugin namespace.

## Anthropic

- **Claude Code** — the agent harness this studio runs inside. https://docs.anthropic.com/en/docs/claude-code
- **anthropic-skills** — Anthropic's skill collection, including the **godot** skill the studio's engine work leans on, plus general-purpose skills the workflows dispatch to.

## Origin tiers

Every skill and agent in this studio carries a `metadata.origin` marker recording where it came from and how much it changed:

| Tier | Meaning |
|---|---|
| **SP-authored** | Written for ShiningPlague from scratch (no upstream equivalent). |
| **SP-adopted-modified** | Adopted from Donchitos or obra/superpowers and materially changed for this studio. |
| **SP-adopted-in-place** | Adopted with little or no change — upstream structure kept as-is. |
| **vanilla** | Unmodified upstream artifact, carried for reference; no ShiningPlague marker beyond the origin note. |

If you fork or extend this studio, please keep these markers intact and preserve the copyright notices in [LICENSE](LICENSE). The upstream authors did the hard early work, and their names should travel with it.
