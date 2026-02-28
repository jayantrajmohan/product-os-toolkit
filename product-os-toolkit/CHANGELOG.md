# Changelog

All notable changes to Product OS Toolkit are documented in this file.

## [1.2.1] - 2026-02-28

Reports navigation usability patch.

### Added
- Initiative reports index now renders clickable markdown links in:
  - `product-intel/initiatives/<initiative_id>/reports/README.md`
- Index refresh is wired into standard workflow actions (`init`, `runstage`, `approvestage`, `approve`, `run`, `status`, `closesession`).

## [1.2.0] - 2026-02-28

Canonical single-artifact mode by stage.

### Changed
- Toolkit now writes and validates one canonical report file per artifact type.
- Legacy alias outputs are no longer generated during stage runs.

### Canonical files enforced
- Discovery: `discovery-insights.md`, `discovery-brief.md`
- Prioritization: `prioritization-matrix.csv`, `roadmap-plan.md`, `prioritization-decision-log.md`
- Definition: `requirements-prd.md`, `execution-plan.md`
- Delivery readiness: `delivery-readiness.md`, `test-case-mapping.md`
- Launch readiness: `launch-readiness.md`, `release-checklist.md`

## [1.1.2] - 2026-02-28

Prioritization data preservation patch.

### Fixed
- When scoped registry rows are zero, `runstage prioritization` no longer overwrites non-empty prioritization outputs.
- Existing non-empty `reports/prioritization-matrix.csv` is preserved.
- Prevents accidental loss of curated prioritization artifacts during reruns.

## [1.1.1] - 2026-02-28

Prioritization artifact consistency patch.

### Fixed
- `runstage prioritization` now always writes both:
  - `reports/prioritization.csv` (compat alias)
  - `reports/prioritization-matrix.csv` (PM-friendly canonical)
- This applies even when prioritization has zero scoped rows.

## [1.1.0] - 2026-02-28

Intake and initiative-start reliability update.

### Added
- Automatic candidate backlog file:
  - `product-intel/reports/initiative-candidates.csv`
- Discovery starter artifact creation on initiative init:
  - `reports/discovery-brief.md`
  - `reports/discovery-insights.md`
- Feedback triage normalization for raw intake with explicit states:
  - `Mapped`, `Candidate`, `Duplicate`, `Ignored`, `Promoted`

### Changed
- Discovery stage now rebuilds candidate backlog after ingestion.
- Ingestion maps feedback to existing initiatives when initiative ID or initiative-name text signals are present.
- Engine version updated to `2.1.0`.

## [1.0.0] - 2026-02-28

Initial ship-ready baseline for portable AI-enabled PM operations.

### Added
- End-to-end PDLC stage workflow with approvals and gate checks.
- Daily operating flow (`planday`, `startsession`, `closesession`, `endday`).
- Initiative context system (`current-state`, `change-log`, `session-brief`, `initiative-meta`).
- PM-friendly stage aliases and naming conventions.
- Stage support artifacts and templates:
  - discovery brief
  - prioritization decision log
  - execution plan
  - test case mapping
  - release checklist
  - iteration backlog
- Skills:
  - `product-os-core`
  - `product-os-daily-ops`
  - `product-os-intake`
  - `product-os-prioritization`
  - `product-os-build-handoff`
- Provider-agnostic compatibility contracts for Codex, Claude Code, and generic agents.

### Changed
- Consolidated top-level docs to `README.md` + `TOOLKIT-MANUAL.md` as canonical entrypoints.
- Strengthened artifact/spec contracts for stage readiness consistency.

### Notes
- Compatibility aliases are intentionally retained for migration safety.
