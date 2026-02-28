# Product OS Toolkit

Portable Product OS for AI-enabled PMs using Codex, Claude Code, or generic LLM agents.

Read [TOOLKIT-MANUAL.md](./TOOLKIT-MANUAL.md) for full end-to-end documentation.
For session-by-session operation, use the "Session Run Playbook" section in the manual.
For quick command usage across any initiative/stage/session, use [COMMANDS-CHEATSHEET.md](./COMMANDS-CHEATSHEET.md).
Current version: `1.2.1` (see [VERSION](./VERSION) and [CHANGELOG.md](./CHANGELOG.md)).

## Included
- `scripts/product_os_engine.ps1`: stage orchestrator, approvals, validation, agent-pack generation.
- `scripts/bootstrap_product_os.ps1`: one-command installer in any repo.
- `specs/`: artifact, stage-gate, and agent-compatibility contracts.
- `providers/`: provider adapter guidance for Codex/Claude/generic.
- `skills/`: reusable Product OS skill packages:
  - `product-os-core` (end-to-end stage workflow)
  - `product-os-daily-ops` (daily PM operating cadence)
  - `product-os-intake` (raw feedback to normalized signals)
  - `product-os-prioritization` (portfolio and initiative ranking)
  - `product-os-build-handoff` (definition to delivery handoff quality)
- `templates/`: core stage document templates.

## Stage Workflow
1. `discovery` (`discover`)
1. `prioritization` (`prioritize`)
1. `definition` (`define`)
1. `delivery_ready` (`build_ready`)
1. `launch_ready` (`release_ready`)
1. `learning` (`learn_ready`)

Each stage requires human approval (`approvestage`) before progressing.

## Install In Any Repo
1. Copy `product-os-toolkit/` to target repo root.
1. Run:
   - `powershell -ExecutionPolicy Bypass -File .\product-os-toolkit\scripts\bootstrap_product_os.ps1`
1. Use:
   - `.\scripts\product_os.cmd init <initiative_id>`
   - `.\scripts\product_os.cmd runstage discovery <initiative_id>`
   - `.\scripts\product_os.cmd approvestage discovery <initiative_id>`
   - `.\scripts\product_os.cmd status <initiative_id>`

## Commands
- `init`
- `runstage <stage>`
- `approvestage <stage>`
- `approve G1|G2|G3`
- `agentpack <stage>`
- `planday`
- `startsession <initiative> <stage>`
- `closesession <session_id>`
- `endday`
- `validate`
- `status`

Note: direct engine execution requires `-RepoRoot`; wrappers pass this automatically.

## Output Structure
- `product-intel/normalized/feedback_registry.csv`
- `product-intel/reports/portfolio-status.md`
- `product-intel/reports/pm-portfolio-dashboard.md`
- `product-intel/reports/initiative-index.md`
- `product-intel/reports/initiative-candidates.csv`
- `product-intel/daily/today-plan.md`
- `product-intel/daily/session-register.md`
- `product-intel/daily/end-of-day-rollup.md`
- `product-intel/daily/sessions/*.md`
- `product-intel/initiatives/<initiative_id>/reports/*`
- `product-intel/initiatives/<initiative_id>/approvals/*`
- `product-intel/initiatives/<initiative_id>/agent-packs/<stage>/*`
- `product-intel/initiatives/<initiative_id>/context/current-state.md`
- `product-intel/initiatives/<initiative_id>/context/change-log.md`
- `product-intel/initiatives/<initiative_id>/context/session-brief.md`
- `product-intel/initiatives/<initiative_id>/context/initiative-meta.md`

## Compatibility
Provider-specific prompting is separated from artifact contracts so output structure is identical across Codex, Claude Code, and generic agents.

Artifact naming policy:
- One canonical file per artifact type (no duplicate alias files).
