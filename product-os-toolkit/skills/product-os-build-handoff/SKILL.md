---
name: product-os-build-handoff
description: Prepare high-quality build handoff context from definition through delivery readiness so coding agents can implement with minimal ambiguity and strong testability.
---

# Product OS Build Handoff

Use this skill before and during implementation handoff to engineering agents.

Primary objective:

1. Convert product intent into executable build context.
1. Ensure acceptance criteria and tests are unambiguous.
1. Keep handoff traceable to stage artifacts and approvals.

Definition artifacts to validate/update:

- `product-intel/initiatives/<initiative_id>/reports/requirements-prd.md`
- `product-intel/initiatives/<initiative_id>/reports/execution-plan.md`

Delivery readiness artifacts to validate/update:

- `product-intel/initiatives/<initiative_id>/reports/delivery-readiness.md`
- `product-intel/initiatives/<initiative_id>/reports/test-case-mapping.md`

Agent handoff artifacts:

- `product-intel/initiatives/<initiative_id>/agent-packs/<stage>/task.md`
- `product-intel/initiatives/<initiative_id>/agent-packs/<stage>/context.json`

Rules:

- Every requirement must map to acceptance criteria and at least one test case.
- `delivery_ready` approval requires `Status: Ready` in readiness docs.
- Capture unresolved decisions and dependency risks before handoff.
- Keep scope explicit (`In Scope`, `Out Of Scope`) to prevent build drift.
