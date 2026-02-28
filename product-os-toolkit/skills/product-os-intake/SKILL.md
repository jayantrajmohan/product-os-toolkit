---
name: product-os-intake
description: Ingest raw qualitative inputs (calls, transcripts, chats, notes) into Product OS with normalized entries, clear signal extraction, and initiative candidates for discovery and prioritization.
---

# Product OS Intake

Use this skill when new product inputs arrive and need structured capture.

Primary objective:

1. Convert raw inputs into normalized, traceable records.
1. Preserve source links and signal quality.
1. Produce initiative candidates that flow into discovery/prioritization.

Required inputs:

- `product-intel/raw/` source files for the current intake batch.

Primary outputs:

- Update `product-intel/normalized/feedback_registry.csv`.
- Update `product-intel/reports/initiative-candidates.csv`.
- Update `product-intel/reports/pm-portfolio-dashboard.md` with latest demand/themes summary.
- If needed, create candidate initiative IDs for PM review in `product-intel/reports/initiative-index.md`.

Rules:

- Do not skip source traceability; every added normalized row must map to a raw source.
- Merge duplicates instead of creating repeated entries.
- Use triage states consistently:
  - `Mapped` for feedback linked to existing initiatives
  - `Candidate` for potential new initiatives
  - `Duplicate`, `Ignored`, `Promoted` as applicable
- Keep categorization PM-friendly and consistent with initiative metadata:
  - `initiative_type`: `new_feature`, `enhancement`, `bug_fix`, `ops_improvement`, `research`
- Keep edits workspace-scoped for intake and initiative-scoped only after PM confirms an initiative.
