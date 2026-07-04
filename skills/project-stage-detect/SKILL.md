---
name: project-stage-detect
description: "Use when checking what development phase the project is in, what artifacts exist vs are missing, or when the designer asks 'where are we?' Reads production/stage.txt, scans artifact globs from workflow-catalog.yaml, and reports phase + gaps. ShiningPlague-adopted (Sons of Gilgamesh): SoG-specific artifact checks per phase, workstream phase map, gap summary with priority gap surfacing."
metadata:
  origin: Donchitos
  origin_url: https://github.com/Donchitos/Claude-Code-Game-Studios
  adopted_by: ShiningPlague (Sons of Gilgamesh)
  adopted_date: 2026-05-15
  vanilla_backup: docs/vanilla-backups/2026-05-15/project-stage-detect/SKILL.md
  enhancements:
    - Per-phase SoG artifact checks (Concept/Systems-Design/Technical-Setup/Production)
    - Workstream phase map (where each workstream is relative to project)
    - Gap summary with priority gap surfacing
    - SoG-specific known states (3 ADRs combat-only, 0/21 per-system GDDs, etc.)
---

# Project Stage Detect

> 🌱 **ShiningPlague-adopted (2026-05-15).** Originally Donchitos (barebones stub). Sons of Gilgamesh project adopted and enhanced. Upstream was a pointer-only file; SoG version is the full implementation — per-phase artifact checks, workstream phase map, gap summary. Vanilla backup: `docs/vanilla-backups/2026-05-15/project-stage-detect/`.

Auto-detect current development phase and report gap analysis.

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
- Game concept doc: `design/gdd/game-concept.md` or `docs/GDD*.md`
- Game pillars: `design/gdd/game-pillars.md` (MISSING for SoG)
- Art bible: check for art-bible artifact (MISSING for SoG)

**Systems Design phase:**
- Systems index: `design/gdd/systems-index.md` (EXISTS — 58 entries)
- Per-system GDDs: `design/gdd/*.md` or `docs/gdd/*.md` (0 of 21 for SoG)
- Cross-GDD review: review-all-gdds artifact

**Technical Setup phase:**
- ADRs: `docs/adr/*.md` (3 exist, combat-only)
- Master architecture: `docs/architecture/architecture.md` (MISSING)
- Control manifest: `docs/architecture/control-manifest.md` (EXISTS — 55 rules)
- Engine reference: `docs/engine-reference/` (EXISTS)

**Production phase:**
- Source files: `src/` (EXISTS)
- Sprint status: `production/sprint-status.yaml` (MISSING)

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

## SoG Paths
- Stage: `production/stage.txt` (= production)
- Catalog: `.claude/docs/workflow-catalog.yaml`
- Workstreams: `production/workstreams/*.md`
- Registry: `data/_schemas/system_registry.json`
