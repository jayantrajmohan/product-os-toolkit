# Changelog

All notable changes to Product OS Toolkit are documented in this file.

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

