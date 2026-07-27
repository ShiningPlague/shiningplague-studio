---
name: project-stage-detect
description: "Use when checking what development phase the project is in, what artifacts exist vs are missing, or when the designer asks 'where are we?' Reads production/stage.txt, scans artifact globs from workflow-catalog.yaml, and reports phase + gaps. ShiningPlague-adopted: per-phase project artifact checks, workstream phase map, gap summary with priority gap surfacing."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague
  enhancements:
    - Per-phase project artifact checks (Concept/Systems-Design/Technical-Setup/Production)
    - Workstream phase map (where each workstream is relative to project)
    - Gap summary with priority gap surfacing
---

# Project Stage Detect

> 🌱 **ShiningPlague-adopted.** Originally Donchitos (barebones stub); battle-tested on a shipped Godot project. Upstream was a pointer-only file; the studio version is the full implementation — per-phase artifact checks, workstream phase map, gap summary.

Auto-detect current development phase and report gap analysis.

> **If an artifact named here is absent:** say so plainly in one line, skip that step, and
> continue. Never invent the file to satisfy a checklist, and never fail a close because an
> optional artifact was never created.

## Procedure

### 1. Read Authoritative Phase
Read `production/stage.txt`. Map to workflow-catalog phase key:
- "Concept" → concept
- "Systems Design" → systems-design
- "Technical Setup" → technical-setup
- "Pre-Production" → pre-production
- "Production" → production
- "Polish" → polish
- "Release" → release

### 2. Read Workflow Catalog
Read `.claude/docs/workflow-catalog.yaml`. For each phase up to and including current, check each step's `artifact.glob` for existence.

### 3. Check Per-Phase Artifacts

**Concept phase:**
- Game concept doc: `docs/gdd/game-concept.md` or `{{GDD_PATH}}`
- Game pillars: `docs/gdd/game-pillars.md`
- Art bible: check for art-bible artifact

**Systems Design phase:**
- Systems index: `docs/gdd/systems-index.md`
- Per-system GDDs: `docs/gdd/*.md`
- Cross-GDD review: review-all-gdds artifact

**Technical Setup phase:**
- ADRs: `docs/adr/*.md`
- Master architecture: `docs/architecture/architecture.md`
- Control manifest: `docs/architecture/control-manifest.md`
- Engine reference: `docs/engine-reference/`

**Production phase:**
- Source files: `src/`
- Sprint status: `production/sprint-status.yaml`

Report each as EXISTS / MISSING / partial from the live scan — never from cached claims.

### 4. Check Workstream States
Read `production/workstreams/*.md` for per-workstream phase positions.
Report which workstreams are ahead/behind the declared project phase.

### 5. Output Report

```
## Project Phase: [phase]

### Phase Artifacts
✓ [artifact] — exists
✗ [artifact] — MISSING (required for [phase])
~ [artifact] — partial (exists but incomplete)

### Workstream Phase Map
- Combat: Production
- Narrative: Concept
- Game Design: Production (gaps in Concept/Systems Design)

### Gaps Summary
[N] missing required artifacts across [phases]
Priority gap: [highest-impact missing item]

### Recommendation
[what to do next to close the most important gap]
```

## Project Paths
- Stage: `production/stage.txt`
- Catalog: `.claude/docs/workflow-catalog.yaml`
- Workstreams: `production/workstreams/*.md`
- Registry: `data/_schemas/system_registry.json`
