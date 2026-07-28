<!-- scaffold-seed: unwritten — delete this line once you write real content -->
# Crisis Communication Log

> Last updated: [YYYY-MM-DD]
> Entries: 0

**What this is.** The running history of what you told players during every
incident, and when. Append-only. It exists so the next outage is handled by
somebody reading the last one instead of improvising, and so a post-mortem can
answer "how long before we said anything?" with a timestamp rather than a memory.

**Written by** the community-manager agent — one `##` entry per incident, updated
live while the incident runs and closed out afterwards.
**Read by** the community-manager before drafting the next incident's first post,
the producer during a post-mortem, and `/team-release` when reviewing how a launch
went.

**How this relates to the other two incident artifacts — they are not the same file:**

| File | What it holds |
|---|---|
| **This log** | The COMMUNICATION history — what was said publicly, on which channel, at which minute, across every incident. One file, many incidents. |
| `production/releases/incident-*.md` | The per-incident RECORD — technical cause, timeline, fix, follow-up actions. One file per incident, from `.claude/docs/templates/incident-response.md`. |
| `production/community/guidelines.md` | The community rules and the moderation ladder. Not incident-specific. |

Link them: every entry below names its incident record, and the incident record
points back here.

---

## The standing response contract

*Decided once, in calm, so nobody has to decide it at 2am. These are the numbers
the community-manager agent works to.*

| Commitment | Target |
|---|---|
| First acknowledgement after detection | [30 minutes] |
| Status updates while unresolved | [every 30–60 minutes] |
| Channels every update goes to | [Discord #status, @studio on X, Steam news, in-game banner] |
| Who approves a compensation offer | [producer] |
| Who may speak for the studio during an incident | [community-manager only] |

**Say what is true and specific.** "Login servers are down" beats "we're
experiencing issues". Give an ETA, and update it when it slips rather than letting
it pass in silence.

---

## Entries

*Newest first. Never edit a past entry's timeline — append a correction line to it
instead. A rewritten timeline is worth nothing in a post-mortem.*

_(none yet)_

Shape of one entry:

## [YYYY-MM-DD] — [Short incident name]

- **Severity:** [S1-Critical / S2-Major / S3-Moderate / S4-Minor]
- **Detected:** [HH:MM UTC] — [how: monitoring / player reports / internal]
- **Resolved:** [HH:MM UTC]
- **Incident record:** `production/releases/incident-[slug].md`
- **Player impact:** [who was affected, how many, what they lost]

### Communication timeline

| Time (UTC) | Channel | What we said | Link |
|---|---|---|---|
| [HH:MM] | [Discord #status] | [First acknowledgement — one line of what we posted] | [link] |
| [HH:MM] | [X / Steam news] | [Status update] | [link] |
| [HH:MM] | [all channels] | [Resolved notice] | [link] |

### Compensation

[What was offered, to whom, approved by whom — or "none, and why not".]

### What we would do differently

[One or two lines. This is the sentence the next incident's first responder reads.]
