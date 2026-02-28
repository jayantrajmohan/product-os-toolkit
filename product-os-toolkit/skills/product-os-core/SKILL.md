---
name: product-os-core
description: Run end-to-end Product OS workflows for AI-enabled product management across discovery, prioritization, definition, build readiness, release readiness, and learning stages. Use when managing product requirements, ingesting qualitative feedback, producing PDLC artifacts, enforcing stage approvals, and preparing LLM-agent execution packs for Codex, Claude Code, or generic agents.
---

# Product OS Core

Execute this stage workflow:

1. `init` for a new initiative.
1. `runstage discovery` (alias: `discover`).
1. Human review, then `approvestage discovery`.
1. `runstage prioritization` (alias: `prioritize`).
1. Human review, then `approvestage prioritization`.
1. `runstage definition` (alias: `define`).
1. Human review, then `approvestage definition`.
1. `runstage delivery_ready` (alias: `build_ready`).
1. Ensure `delivery-readiness.md` has `Status: Ready`, then `approvestage delivery_ready`.
1. `runstage launch_ready` (alias: `release_ready`), then `approvestage launch_ready`.
1. `runstage learning` (alias: `learn_ready`), then `approvestage learning`.

Read these references when needed:

- `references/stage-guide.md` for stage outcomes.
- `references/artifact-checks.md` for minimum quality checks.
- `references/provider-usage.md` for Codex/Claude/generic compatibility.

Always keep edits initiative-scoped under:

- `product-intel/initiatives/<initiative_id>/`
