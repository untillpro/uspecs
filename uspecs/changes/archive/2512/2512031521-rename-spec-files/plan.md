# Implementation plan: Rename spec files

Change: `[change.md](change.md)`

## Files modification

Template renames (move):

- [x] move: `[.uspecs/templates/change-derive-project.md](../../../.uspecs/templates/change-derive-project.md)`
  - to: `[.uspecs/templates/change-pd.md](../../../.uspecs/templates/change-pd.md)`
  - Also create change-td.md (split into two templates)

- [x] move: `[.uspecs/templates/change-metadata.md](../../../.uspecs/templates/change-metadata.md)`
  - to: `[.uspecs/templates/change-common-metadata.md](../../../.uspecs/templates/change-common-metadata.md)`

- [x] move: `[.uspecs/templates/change-plan.md](../../../.uspecs/templates/change-plan.md)`
  - to: `[.uspecs/templates/plan.md](../../../.uspecs/templates/plan.md)`

- [x] move: `[.uspecs/templates/change-specs-impact.md](../../../.uspecs/templates/change-specs-impact.md)`
  - to: `[.uspecs/templates/specs-impact.md](../../../.uspecs/templates/specs-impact.md)`

- [x] move: `[.uspecs/templates/feature-impl-details.md](../../../.uspecs/templates/feature-impl-details.md)`
  - to: `[.uspecs/templates/td.md](../../../.uspecs/templates/td.md)`

- [x] move: `[.uspecs/templates/project-context.md](../../../.uspecs/templates/project-context.md)`
  - to: `[.uspecs/templates/fd-rules.md](../../../.uspecs/templates/fd-rules.md)`

- [x] move: `[.uspecs/templates/project-design.md](../../../.uspecs/templates/project-design.md)`
  - to: `[.uspecs/templates/td-rules.md](../../../.uspecs/templates/td-rules.md)`

- [x] move: `[.uspecs/templates/project-specs.md](../../../.uspecs/templates/project-specs.md)`
  - to: `[.uspecs/templates/specs-rules.md](../../../.uspecs/templates/specs-rules.md)`

New templates:

- [x] create: `[.uspecs/templates/change-td.md](../../../.uspecs/templates/change-td.md)`
  - Template for "Configure technical design rules" scenario
  - Split from change-derive-project.md

- [x] create: `[.uspecs/templates/uxui-rules.md](../../../.uspecs/templates/uxui-rules.md)`
  - UX/UI guidelines structure template

Update references in actions:

- [x] update: `[.uspecs/actions/register.md](../../../.uspecs/actions/register.md)`
  - line 15: specs/specs.md -> specs/specs-rules.md
  - line 16: project-specs.md -> specs-rules.md
  - line 22-26: update routing table (replace derive project with config-td and config-pd)
  - line 33: specs/specs.md -> specs/specs-rules.md
  - line 34: specs/specs.md -> specs/specs-rules.md, update validation for new scenarios

- [x] update: `[.uspecs/actions/analyze-spec-impact.md](../../../.uspecs/actions/analyze-spec-impact.md)`
  - line 12: specs/specs.md -> specs/specs-rules.md
  - line 13: project-specs.md -> specs-rules.md
  - line 33: derive-project -> config-pd
  - line 44: impl-details.md -> td.md
  - line 48: change-specs-impact.md -> specs-impact.md
  - (lines 40-42: already use new names)

- [x] update: `[.uspecs/actions/apply.md](../../../.uspecs/actions/apply.md)`
  - line 11: specs/specs.md -> specs/specs-rules.md
  - line 12: project-specs.md -> specs-rules.md

- [x] update: `[.uspecs/actions/archive.md](../../../.uspecs/actions/archive.md)`
  - line 15: specs/specs.md -> specs/specs-rules.md
  - line 16: project-specs.md -> specs-rules.md
  - line 46-52: update examples (specs.md, context.md references)

- [x] update: `[.uspecs/actions/plan.md](../../../.uspecs/actions/plan.md)`
  - line 12: specs/specs.md -> specs/specs-rules.md
  - line 13: project-specs.md -> specs-rules.md
  - line 19: specs/design.md -> specs/td-rules.md
  - line 44: specs/context.md -> specs/fd-rules.md
  - line 52, 57, 62, 65: specs/design.md -> specs/td-rules.md
  - line 55-58: update derive-project section for new config-td/config-pd scenarios
  - line 75: impl-details.md -> td.md (in feature folder)
  - line 81: change-plan.md -> plan.md

Update references in templates:

- [x] update: `[.uspecs/templates/specs-rules.md](../../../.uspecs/templates/specs-rules.md)`
  - After rename, update internal references:
  - line 1: heading "Structure for specs/specs.md" -> "Structure for specs/specs-rules.md"
  - line 12: specs.md -> specs-rules.md
  - line 13: context.md -> fd-rules.md
  - line 23: project-specs.md -> specs-rules.md
  - line 24: project-context.md -> fd-rules.md
  - line 25: project-design.md -> td-rules.md
  - line 26: feature-gherkin.md -> gherkin.md
  - line 27: feature-impl-details.md -> td.md
  - line 34: impl-details.md -> td.md

- [x] update: `[.uspecs/templates/fd-rules.md](../../../.uspecs/templates/fd-rules.md)`
  - After rename, update heading:
  - line 1: "Structure for specs/context.md" -> "Structure for specs/fd-rules.md"

- [x] update: `[.uspecs/templates/td-rules.md](../../../.uspecs/templates/td-rules.md)`
  - After rename, update heading:
  - line 1: "Structure for specs/design.md" -> "Structure for specs/td-rules.md"

- [x] update: `[.uspecs/templates/td.md](../../../.uspecs/templates/td.md)`
  - After rename, update heading:
  - line 1: "Structure for {feature-id}/impl-details.md" -> "Structure for {feature-id}/td.md"
  - line 40: impl-details.md -> td.md

- [x] update: `[.uspecs/templates/change-init.md](../../../.uspecs/templates/change-init.md)`
  - line 3: change-metadata.md -> change-common-metadata.md

- [x] update: `[.uspecs/templates/change-pd.md](../../../.uspecs/templates/change-pd.md)`
  - After rename, update internal reference:
  - line 3: change-metadata.md -> change-common-metadata.md

- [x] update: `[.uspecs/templates/change-standard.md](../../../.uspecs/templates/change-standard.md)`
  - line 3: change-metadata.md -> change-common-metadata.md

- [x] update: `[.uspecs/templates/plan.md](../../../.uspecs/templates/plan.md)`
  - After rename, update internal references:
  - line 33: impl-details.md -> td.md
  - line 34: specs/design.md -> specs/td-rules.md
  - line 75: impl-details.md -> td.md

- [x] update: `[.uspecs/templates/specs-impact.md](../../../.uspecs/templates/specs-impact.md)`
  - After rename, update internal references:
  - line 12: specs.md -> specs-rules.md
  - line 14: context.md -> fd-rules.md
  - line 16: design.md -> td-rules.md
  - line 73: context.md -> fd-rules.md, design.md -> td-rules.md

- [x] update: `[.uspecs/templates/feature-gherkin.md](../../../.uspecs/templates/feature-gherkin.md)`
  - line 7: context.md -> fd-rules.md
  - line 69: context.md -> fd-rules.md

- [x] update: `[.uspecs/templates/change-common-metadata.md](../../../.uspecs/templates/change-common-metadata.md)`
  - After rename, update Type values:
  - line 16: remove derive-project, add config-td, config-pd

Update other documentation:

- [x] update: `[overview.md](../../../overview.md)`
  - line 23: specs/specs.md -> specs/specs-rules.md
  - line 26: specs/specs.md -> specs/specs-rules.md
  - line 36: specs/specs.md -> specs/specs-rules.md
  - line 55: specs.md -> specs-rules.md, context.md -> fd-rules.md, design.md -> td-rules.md
  - line 67: impl-details.md -> td.md
  - line 73: impl-details.md -> td.md
  - line 74: specs/specs.md -> specs/specs-rules.md
  - line 79: specs/specs.md -> specs/specs-rules.md, context.md -> fd-rules.md, design.md -> td-rules.md

- [x] update: `[AGENTS.md](../../../AGENTS.md)`
  - line 19-23: fix typo .upsecs -> .uspecs (lines 19-21)
