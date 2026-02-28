# Product OS Toolkit Manual

Version: `1.1.0` (see `VERSION` and `CHANGELOG.md`).

## 1. Purpose

Product OS Toolkit is a portable system for AI-enabled product management across the full PDLC:

1. Discovery
1. Prioritization
1. Definition
1. Delivery Readiness
1. Launch Readiness
1. Learning

It supports non-technical PM workflows with:

- stage-based approvals,
- initiative-level context,
- daily operating cadence,
- agent-compatible execution (Codex, Claude Code, generic).

## 2. Core Structure

Toolkit root:

- `scripts/`
- `specs/`
- `providers/`
- `skills/`
- `templates/`
- `README.md`
- `TOOLKIT-MANUAL.md`

After bootstrap in a target repo:

- `.product-os/config.json`
- `scripts/product_os.ps1`
- `scripts/product_os.cmd`
- `scripts/product_os.sh`
- `<workspace_root>/` (default `product-intel/`)

Inside workspace:

- `raw/` (input feedback sources)
- `normalized/` (registry)
- `reports/` (portfolio-level status)
- `daily/` (daily operating files)
- `initiatives/<initiative_id>/` (all initiative artifacts)

## 3. Canonical Specs

Read these for contracts:

1. `specs/ARTIFACT_CONTRACT.md`
1. `specs/STAGE_GATE_CONTRACT.md`
1. `specs/AGENT_COMPATIBILITY.md`

These define required artifacts, approval behavior, and provider-agnostic agent context.

## 4. Commands

Core:

- `init <initiative_id>`
- `runstage <stage> <initiative_id>`
- `approvestage <stage> <initiative_id>`
- `approve G1|G2|G3 <initiative_id>`
- `status <initiative_id>`
- `validate <initiative_id>`
- `agentpack <stage> <initiative_id>`

Daily:

- `planday`
- `startsession <initiative_id> <stage>`
- `closesession <session_id>`
- `endday`

PM-friendly stage aliases:

- `discovery` -> `discover`
- `prioritization` -> `prioritize`
- `definition` -> `define`
- `delivery_ready` -> `build_ready`
- `launch_ready` -> `release_ready`
- `learning` -> `learn_ready`

## 5. Stage Workflow

Per initiative:

1. `runstage discovery <initiative>`
1. review docs
1. `approvestage discovery <initiative>`
1. `runstage prioritization <initiative>`
1. review docs
1. `approvestage prioritization <initiative>`
1. `runstage definition <initiative>`
1. review docs
1. `approvestage definition <initiative>`
1. `runstage delivery_ready <initiative>`
1. update readiness doc to `Status: Ready`
1. `approvestage delivery_ready <initiative>`
1. `runstage launch_ready <initiative>`
1. `approvestage launch_ready <initiative>`
1. `runstage learning <initiative>`
1. `approvestage learning <initiative>`

Initiative start behavior:

- `init <initiative_id>` creates starter discovery docs automatically:
  - `reports/discovery-brief.md`
  - `reports/discovery-insights.md`

Optional gates:

- `approve G1` after delivery_ready
- `approve G2` after launch_ready
- `approve G3` after learning

## 6. Initiative Artifact Set

Reports:

- `reports/discovery-insights.md`
- `reports/discovery-brief.md`
- `reports/prioritization-matrix.csv`
- `reports/roadmap-plan.md`
- `reports/prioritization-decision-log.md`
- `reports/requirements-prd.md`
- `reports/execution-plan.md`
- `reports/delivery-readiness.md`
- `reports/test-case-mapping.md`
- `reports/launch-readiness.md`
- `reports/release-checklist.md`
- `reports/learning-review.md`
- `reports/iteration-backlog.md`

Context:

- `context/current-state.md`
- `context/change-log.md`
- `context/session-brief.md`
- `context/initiative-meta.md`

Approvals:

- `approvals/STAGE-*.approved`
- `approvals/G1.approved` etc.

Logs/agent:

- `logs/decisions.md`
- `agent-packs/<stage>/task.md`
- `agent-packs/<stage>/context.json`

Workspace intake artifacts:

- `normalized/feedback_registry.csv`
- `reports/initiative-candidates.csv`
- `triage_status` values in registry:
  - `Mapped` (linked to an existing initiative)
  - `Candidate` (needs PM promotion decision)
  - `Duplicate`
  - `Ignored`
  - `Promoted`

## 7. Daily Operating System

Daily generated files:

- `daily/today-plan.md`
- `daily/session-register.md`
- `daily/end-of-day-rollup.md`
- `daily/sessions/<session_id>.md`

Recommended day loop:

1. run `planday`
1. start focused sessions with `startsession`
1. complete stage work and doc updates
1. close each session with `closesession`
1. run `endday`

This ensures next-day restart has compact, current context.

Initiative metadata drives portfolio and daily prioritization labels:

- `initiative_type` (`new_feature`, `enhancement`, `bug_fix`, `ops_improvement`, `research`)
- `product_area`
- `priority_tier`
- `owner`
- `target_outcome`

## 8. Session Run Playbook

Use this exact flow for each agent session.

1. Start session
- Run: `startsession <initiative_id> <stage>`
- Open:
  - `product-intel/initiatives/<initiative_id>/context/session-brief.md`
  - `product-intel/initiatives/<initiative_id>/context/current-state.md`

1. Execute focused work
- Run stage work (`runstage ...`) or artifact edits for the current stage.
- Keep edits initiative-scoped only.

1. Checkpoint before context grows too large
- Update:
  - `context/current-state.md` (latest status, blockers, next actions)
  - `context/change-log.md` (what changed and why)
  - stage artifact(s) touched in this session
- Recommended checkpoint frequency:
  - every 20-40 minutes, or
  - after any major decision/output.

1. Use chat compaction as helper only
- Auto-compact is allowed in-session.
- Never rely on compacted chat as source of truth.
- Always checkpoint into repo files before/after compaction.

1. Close session
- Run: `closesession <session_id>`
- This writes closure details and refreshes initiative context.

1. Start a fresh chat session (when needed)
- Provide only:
  - initiative id
  - stage
  - `session-brief.md` path
  - `current-state.md` path
- This keeps token usage low and restart quality high.

## 9. Agent Usage Model

For each stage, use:

- `agent-packs/<stage>/task.md`
- `agent-packs/<stage>/context.json`
- provider prompt files (`codex.prompt.md`, `claude.prompt.md`, `generic.prompt.md`)

Agents should read only session brief + current stage files first, then expand as needed.

## 10. Skills Included

- `skills/product-os-core/`: full stage workflow execution.
- `skills/product-os-daily-ops/`: daily planning/session/rollup operations.
- `skills/product-os-intake/`: raw-input ingestion and feedback normalization.
- `skills/product-os-prioritization/`: portfolio and initiative prioritization logic.
- `skills/product-os-build-handoff/`: implementation handoff and delivery-readiness quality.

Recommended usage by stage:

1. Discovery: `product-os-intake` + `product-os-core`
1. Prioritization: `product-os-prioritization` + `product-os-core`
1. Definition and Delivery Readiness: `product-os-build-handoff` + `product-os-core`
1. Daily operation across all stages: `product-os-daily-ops`

## 11. Bootstrap and Portability

Bootstrap from target repo root:

`powershell -ExecutionPolicy Bypass -File .\product-os-toolkit\scripts\bootstrap_product_os.ps1`

Notes:

- Engine path is validated during bootstrap.
- Engine requires explicit repo root (wrappers pass it automatically).
- This avoids running against the wrong repository.

## 12. Minimal Non-Technical PM Usage

1. Capture raw feedback in `raw/`.
1. Run `planday`.
1. Pick top initiative from `daily/today-plan.md`.
1. Run stage command + review + approve.
1. Use `startsession`/`closesession` for focused work.
1. Run `endday`.
1. Next day restart from `daily/today-plan.md` and initiative `context/session-brief.md`.

## 13. Recommended Reading Path

1. `README.md`
1. this file (`TOOLKIT-MANUAL.md`)
1. `specs/*`
