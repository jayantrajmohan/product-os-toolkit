# Product OS Commands Cheat Sheet

Use this in any repo, for any initiative, at any stage.

## Daily Start

1. Check current state:
- `.\scripts\product_os.cmd status <initiative_id>`

2. Build day queue:
- `.\scripts\product_os.cmd planday`

3. Open context:
- `product-intel/initiatives/<initiative_id>/context/session-brief.md`
- `product-intel/initiatives/<initiative_id>/reports/README.md`

## Session Lifecycle

1. Start session:
- `.\scripts\product_os.cmd startsession <initiative_id> <stage>`

2. Get session id:
- `product-intel/daily/session-register.md`

3. Close session:
- `.\scripts\product_os.cmd closesession <session_id>`

4. End day:
- `.\scripts\product_os.cmd endday`

## Stage Execution Pattern

For any stage:

1. Run stage:
- `.\scripts\product_os.cmd runstage <stage> <initiative_id>`

2. Review/update artifacts:
- `product-intel/initiatives/<initiative_id>/reports/README.md`

3. Approve stage:
- `.\scripts\product_os.cmd approvestage <stage> <initiative_id>`

## Stage Names

Canonical:
- `discovery`
- `prioritization`
- `definition`
- `delivery_ready`
- `launch_ready`
- `learning`

Also supported:
- `discover`, `prioritize`, `define`, `build_ready`, `release_ready`, `learn_ready`

## Typical Flows

## New Initiative

1. `.\scripts\product_os.cmd init <initiative_id>`
2. `.\scripts\product_os.cmd runstage discovery <initiative_id>`
3. `.\scripts\product_os.cmd approvestage discovery <initiative_id>`
4. Continue stage pattern

## Existing Initiative (Resume)

1. `.\scripts\product_os.cmd status <initiative_id>`
2. `.\scripts\product_os.cmd startsession <initiative_id> <current_stage>`
3. Continue from current stage artifacts

## If You Forget Everything

Run:
- `.\scripts\product_os.cmd status <initiative_id>`

Then open:
- `product-intel/initiatives/<initiative_id>/context/session-brief.md`
- `product-intel/initiatives/<initiative_id>/reports/README.md`
