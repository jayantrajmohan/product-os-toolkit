---
name: product-os-prioritization
description: Run portfolio-level and initiative-level prioritization using Product OS contracts so PMs can rank work, document rationale, and sequence execution.
---

# Product OS Prioritization

Use this skill when multiple demands compete for capacity.

Primary objective:

1. Rank initiatives at portfolio level.
1. Produce explicit rationale and tradeoffs.
1. Feed approved priorities into stage execution.

Portfolio outputs:

- `product-intel/reports/pm-portfolio-dashboard.md`
- `product-intel/reports/portfolio-status.md`
- `product-intel/reports/initiative-index.md`

Initiative outputs (during prioritization stage):

- `product-intel/initiatives/<initiative_id>/reports/prioritization-matrix.csv`
- `product-intel/initiatives/<initiative_id>/reports/roadmap-plan.md`
- `product-intel/initiatives/<initiative_id>/reports/prioritization-decision-log.md`

Rules:

- Use consistent scoring dimensions across all active initiatives in the same cycle.
- Record assumptions and confidence levels in the decision log.
- Keep top-priority ordering aligned between portfolio docs and initiative docs.
- Do not advance stage without explicit PM approval (`approvestage prioritization <initiative_id>`).

