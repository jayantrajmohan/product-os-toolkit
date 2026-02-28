---
name: product-os-daily-ops
description: Run daily Product OS operations for non-technical PM workflows across multiple initiatives. Use when generating day plans, opening focused agent sessions, closing sessions, consolidating end-of-day outcomes, and keeping initiative context files current for low-token restart in new chat sessions.
---

# Product OS Daily Ops

Use this daily sequence:

1. `planday`
1. `startsession <initiative_id> <stage>`
1. Perform stage work and update initiative artifacts.
1. `closesession <session_id>`
1. `endday`

Always update these as canonical context:

- `product-intel/daily/today-plan.md`
- `product-intel/daily/session-register.md`
- `product-intel/daily/end-of-day-rollup.md`
- `product-intel/initiatives/<initiative_id>/context/current-state.md`
- `product-intel/initiatives/<initiative_id>/context/change-log.md`
- `product-intel/initiatives/<initiative_id>/context/session-brief.md`
- `product-intel/initiatives/<initiative_id>/context/initiative-meta.md`
