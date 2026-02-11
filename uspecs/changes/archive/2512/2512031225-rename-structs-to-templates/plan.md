# Implementation plan: Rename structs folder to templates

Change: [change.md](change.md)

## Files modification

- [x] move: `[.uspecs/structs](../../../.uspecs/structs)`
  - to: `[.uspecs/templates](../../../.uspecs/templates)`

- [x] update: `[.uspecs/actions/register.md](../../../.uspecs/actions/register.md)`
  - line 16, 24, 25, 26: replace `.uspecs/structs/` with `.uspecs/templates/`

- [x] update: `[.uspecs/actions/plan.md](../../../.uspecs/actions/plan.md)`
  - line 13, 81: replace `.uspecs/structs/` with `.uspecs/templates/`

- [x] update: `[.uspecs/actions/apply.md](../../../.uspecs/actions/apply.md)`
  - line 12: replace `.uspecs/structs/` with `.uspecs/templates/`

- [x] update: `[.uspecs/actions/analyze-spec-impact.md](../../../.uspecs/actions/analyze-spec-impact.md)`
  - line 13, 54: replace `.uspecs/structs/` with `.uspecs/templates/`

- [x] update: `[.uspecs/actions/archive.md](../../../.uspecs/actions/archive.md)`
  - line 16: replace `.uspecs/structs/` with `.uspecs/templates/`

- [x] update: `[.uspecs/templates/project-specs.md](../../../.uspecs/templates/project-specs.md)`
  - line 29, 30, 31, 32, 33: replace `.uspecs/structs/` with `.uspecs/templates/`

- [x] update: `[.uspecs/templates/change-specs-impact.md](../../../.uspecs/templates/change-specs-impact.md)`
  - line 44: replace `.uspecs/structs/` with `.uspecs/templates/`

- [x] update: `[overview.md](../../../overview.md)`
  - line 24, 36, 74: replace `.uspecs/structs/` with `.uspecs/templates/`

- [x] update: `[changes/active/251202-derive-uspecs/spec-impact.md](../../../changes/active/251202-derive-uspecs/spec-impact.md)`
  - line 8: replace `.uspecs/structs/` with `.uspecs/templates/`

## Skipped (historical records)

Archive files are not updated - they document what happened at that time:

- `changes/archive/251203-reorganize-rules-to-structs/change.md`
- `changes/archive/251203-reorganize-rules-to-structs/plan.md`
  