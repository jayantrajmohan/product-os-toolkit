# Product OS Stage Gate Contract

schema_version: 1.0

Execution order:

1. discovery (`discover`)
1. prioritization (`prioritize`)
1. definition (`define`)
1. delivery_ready (`build_ready`)
1. launch_ready (`release_ready`)
1. learning (`learn_ready`)

Rules:

- Next stage is blocked until previous stage is approved.
- Approval marker file: `initiatives/<initiative_id>/approvals/STAGE-<stage>.approved`
- Approval includes current `cycle_id`.
- Registry changes invalidate stale approvals for the affected initiative via cycle mismatch.

Gate mapping:

1. `G1` requires `build_ready` approved.
1. `G2` requires `release_ready` approved.
1. `G3` requires `learn_ready` approved.

Manual review checkpoints:

- PM/team reviews artifacts at each stage.
- Artifacts are edited, then `approvestage` is executed.
