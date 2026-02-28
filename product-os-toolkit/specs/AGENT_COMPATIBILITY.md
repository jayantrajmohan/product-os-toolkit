# Product OS Agent Compatibility Contract

schema_version: 1.0

Goal: keep Product OS execution provider-agnostic across Codex, Claude Code, and generic LLM agents.

Provider abstraction:

- Engine produces canonical artifacts and approval files.
- Provider adapters only change prompting/dispatch, never output schema.

Required provider adapters:

- `providers/codex/adapter.md`
- `providers/claude/adapter.md`
- `providers/generic/adapter.md`

Agent pack contract:

- `agent-packs/<stage>/task.md`
- `agent-packs/<stage>/context.json`
- `agent-packs/<stage>/codex.prompt.md`
- `agent-packs/<stage>/claude.prompt.md`
- `agent-packs/<stage>/generic.prompt.md`

Context contract (`context.json`):

- `initiative_id`
- `stage`
- `workspace_root`
- `reports_path`
- `approvals_path`
- `contracts` array

If a provider cannot execute automation:

- fall back to manual mode using `task.md` and explicit stage approval.
