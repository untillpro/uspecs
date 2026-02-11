# Implementation plan: Remove config-td action

Change: `[change.md](change.md)`

## Files modification

- [x] delete: `[actions/config-td.md](../../../.uspecs/actions/config-td.md)`
  - Main action file being removed

- [x] delete: `[templates/change-td.md](../../../.uspecs/templates/change-td.md)`
  - Template used by the action

- [x] update: `[AGENTS.md](../../../AGENTS.md)`
  - Line 24: remove row `| configure technical design rules         | config-td.md           |`

- [x] update: `[actions/analyze-spec-impact.md](../../../.uspecs/actions/analyze-spec-impact.md)`
  - Line 33: change to "Scope (for config-pd changes)"
  - Line 50: change to "For init-project/config-pd:"

- [x] update: `[actions/plan.md](../../../.uspecs/actions/plan.md)`
  - Lines 55-59: delete entire "For config-td changes" section (including blank line)

- [x] update: `[templates/change-common-metadata.md](../../../.uspecs/templates/change-common-metadata.md)`
  - Line 16: change to "Values: init-project, config-pd, behavior, bug, refactoring, performance, documentation, other"

- [x] update: `[docs/overview.md](../../../docs/overview.md)`
  - Lines 17-21: delete "Configure technical design rules" bullet and its sub-items
