# Product OS Artifact Contract

schema_version: 1.0

All Product OS artifacts must follow:

- ASCII text encoding.
- Initiative scope path: `product-intel/initiatives/<initiative_id>/...`
- Stage artifacts should include stable metadata where applicable:
  - `Initiative:`
  - `Status:`
  - `Last Updated:` (recommended)
- Human review fields for gateable docs: `Status:`.

Required stage outputs:

1. `discover`
- Initiative-scoped:
  - `reports/discovery-insights.md`
  - `reports/discovery-brief.md`
- Workspace-scoped:
  - `normalized/feedback_registry.csv`
  - `reports/initiative-candidates.csv`
  - Registry triage states must use: `Mapped`, `Candidate`, `Duplicate`, `Ignored`, `Promoted`.

1. `prioritize`
- `reports/prioritization-matrix.csv`
- `reports/roadmap-plan.md`
- `reports/prioritization-decision-log.md`

1. `define`
- `reports/requirements-prd.md`
- `reports/execution-plan.md`
- Must include: `Problem Statement`, `Success Metrics`, `Requirements`, `Out Of Scope`.

1. `build_ready`
- `reports/delivery-readiness.md` with `Status: Ready` before approval
- `reports/test-case-mapping.md`
- Must include: `Acceptance Criteria`, `Test Plan`, `Dependencies`, `Risks And Mitigations`.

1. `release_ready`
- `reports/launch-readiness.md`
- `reports/release-checklist.md`
- Must include: `Rollout Plan`, `Monitoring And Alerts`, `Rollback Plan`, `Go/No-Go Checklist`.

1. `learn_ready`
- `reports/learning-review.md`
  - `reports/iteration-backlog.md`
  - Must include: `Outcomes vs Success Metrics`, `Insights`, `Follow-Up Actions`.

Cross-stage required:

- `logs/decisions.md`
- `agent-packs/<stage>/task.md`
- `agent-packs/<stage>/context.json`
