# Implementation plan: Rename config-pd to config-fd and add multi-context support

Change: `[change.md](change.md)`

## Files modification

- [x] move: ``[actions/config-pd.md](../../../.uspecs/actions/config-pd.md)``
  - to: `[actions/config-fd.md](../../../.uspecs/actions/config-fd.md)`
  - Update title to "Configure functional design rules"
  - Update description to "Configure functional design rules for an existing project"
  - Update validation to only check specs/fd-rules.md exists
  - Remove uxui-rules.md validation
  - Remove register-base.md call and change-fd.md template reference
  - Implement direct fd-rules.md generation with questions about actors and services
  - Ask about most unclear/ambiguous issues first
  - Automatically analyze codebase to infer dev actors (git config, CI files, etc.)
  - Generate fd-rules.md immediately after questions
  - Show link to generated fd-rules.md for user review

- [x] move: ``[templates/change-pd.md](../../../.uspecs/templates/change-pd.md)``
  - to: `[templates/change-fd.md](../../../.uspecs/templates/change-fd.md)`
  - Repurpose as template for fd-rules.md structure (not for change.md)
  - Update title to "Structure for specs/fd-rules.md (multi-context)"
  - Remove metadata, Scope, Paths, Known context sections
  - Add multi-context structure with Production context and Development context
  - Each context includes: Actors, Services provided, Services consumed subsections

- [x] update: ``[templates/fd-rules.md](../../../.uspecs/templates/fd-rules.md)``
  - Add multi-context structure example with Production context and Development context
  - Update format section to show context-based structure
  - Add rules for inferring dev actors from codebase
  - Update example to demonstrate multi-context usage

- [x] update: `[AGENTS.md](../../../AGENTS.md)`
  - Line 24: change "configure product design rules" to "configure functional design rules"
  - Line 24: change "config-pd.md" to "config-fd.md"

- [x] update: `[actions/analyze-spec-impact.md](../../../.uspecs/actions/analyze-spec-impact.md)`
  - Line 33: change "config-pd" to "config-fd"
  - Line 50: change "config-pd" to "config-fd"

- [x] update: `[actions/plan.md](../../../.uspecs/actions/plan.md)`
  - Line 55: change "For config-pd changes" to "For config-fd changes"
  - Line 57: change "specs/fd-rules.md and specs/uxui-rules.md" to "specs/fd-rules.md"
  - Line 58: change "config-pd" to "config-fd"

- [x] update: `[templates/change-common-metadata.md](../../../.uspecs/templates/change-common-metadata.md)`
  - Line 16: remove "config-pd" from Type values list (config-fd generates fd-rules.md directly without change registration)

- [x] update: `[docs/overview.md](../../../docs/overview.md)`
  - Line 17: change "Configure product design rules" to "Configure functional design rules"
  - Line 18: change "configure product design rules" to "configure functional design rules"
  - Line 20: change "change-pd.md" to "change-fd.md"
  - Update description to reflect direct fd-rules.md generation without change.md
  