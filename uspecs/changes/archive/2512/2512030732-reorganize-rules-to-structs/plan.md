# Implementation plan: Reorganize rules to structs

Change: `[change.md](change.md)`

## Files modification

### Move rule files to structs folder (remove -struct postfix)

- [x] move: `[change-derive-project-struct.md](../../../.uspecs/rules/change-derive-project-struct.md)`
  - to: `[change-derive-project.md](../../../.uspecs/structs/change-derive-project.md)`

- [x] move: `[change-init-struct.md](../../../.uspecs/rules/change-init-struct.md)`
  - to: `[change-init.md](../../../.uspecs/structs/change-init.md)`

- [x] move: `[change-metadata-struct.md](../../../.uspecs/rules/change-metadata-struct.md)`
  - to: `[change-metadata.md](../../../.uspecs/structs/change-metadata.md)`

- [x] move: `[change-plan-struct.md](../../../.uspecs/rules/change-plan-struct.md)`
  - to: `[change-plan.md](../../../.uspecs/structs/change-plan.md)`

- [x] move: `[change-specs-impact-struct.md](../../../.uspecs/rules/change-specs-impact-struct.md)`
  - to: `[change-specs-impact.md](../../../.uspecs/structs/change-specs-impact.md)`

- [x] move: `[change-standard-struct.md](../../../.uspecs/rules/change-standard-struct.md)`
  - to: `[change-standard.md](../../../.uspecs/structs/change-standard.md)`

- [x] move: `[feature-gherkin-struct.md](../../../.uspecs/rules/feature-gherkin-struct.md)`
  - to: `[feature-gherkin.md](../../../.uspecs/structs/feature-gherkin.md)`

- [x] move: `[feature-impl-details-struct.md](../../../.uspecs/rules/feature-impl-details-struct.md)`
  - to: `[feature-impl-details.md](../../../.uspecs/structs/feature-impl-details.md)`

- [x] move: `[project-context-struct.md](../../../.uspecs/rules/project-context-struct.md)`
  - to: `[project-context.md](../../../.uspecs/structs/project-context.md)`

- [x] move: `[project-design-struct.md](../../../.uspecs/rules/project-design-struct.md)`
  - to: `[project-design.md](../../../.uspecs/structs/project-design.md)`

- [x] move: `[project-specs-struct.md](../../../.uspecs/rules/project-specs-struct.md)`
  - to: `[project-specs.md](../../../.uspecs/structs/project-specs.md)`

### Update references in action files

- [x] update: `[analyze-spec-impact.md](../../../.uspecs/actions/analyze-spec-impact.md)`
  - `.uspecs/rules/project-specs-struct.md` -> `.uspecs/structs/project-specs.md`
  - `.uspecs/rules/change-specs-impact-struct.md` -> `.uspecs/structs/change-specs-impact.md`

- [x] update: `[apply.md](../../../.uspecs/actions/apply.md)`
  - `.uspecs/rules/project-specs-struct.md` -> `.uspecs/structs/project-specs.md`

- [x] update: `[plan.md](../../../.uspecs/actions/plan.md)`
  - `.uspecs/rules/project-specs-struct.md` -> `.uspecs/structs/project-specs.md`
  - `.uspecs/rules/change-plan-struct.md` -> `.uspecs/structs/change-plan.md`

- [x] update: `[register.md](../../../.uspecs/actions/register.md)`
  - `.uspecs/rules/project-specs-struct.md` -> `.uspecs/structs/project-specs.md`
  - `.uspecs/rules/change-init-struct.md` -> `.uspecs/structs/change-init.md`
  - `.uspecs/rules/change-derive-project-struct.md` -> `.uspecs/structs/change-derive-project.md`
  - `.uspecs/rules/change-standard-struct.md` -> `.uspecs/structs/change-standard.md`

### Update cross-references in struct files (after move)

- [x] update: `[change-derive-project.md](../../../.uspecs/structs/change-derive-project.md)`
  - `.uspecs/rules/change-metadata-struct.md` -> `.uspecs/structs/change-metadata.md`

- [x] update: `[change-init.md](../../../.uspecs/structs/change-init.md)`
  - `.uspecs/rules/change-metadata-struct.md` -> `.uspecs/structs/change-metadata.md`

- [x] update: `[change-metadata.md](../../../.uspecs/structs/change-metadata.md)`
  - `change-*-struct.md` -> `change-*.md` in description text

- [x] update: `[change-specs-impact.md](../../../.uspecs/structs/change-specs-impact.md)`
  - `.uspecs/rules/project-specs-struct.md` -> `.uspecs/structs/project-specs.md`

- [x] update: `[change-standard.md](../../../.uspecs/structs/change-standard.md)`
  - `.uspecs/rules/change-metadata-struct.md` -> `.uspecs/structs/change-metadata.md`

- [x] update: `[project-specs.md](../../../.uspecs/structs/project-specs.md)`
  - `.uspecs/rules/project-specs-struct.md` -> `.uspecs/structs/project-specs.md`
  - `.uspecs/rules/project-context-struct.md` -> `.uspecs/structs/project-context.md`
  - `.uspecs/rules/project-design-struct.md` -> `.uspecs/structs/project-design.md`
  - `.uspecs/rules/feature-gherkin-struct.md` -> `.uspecs/structs/feature-gherkin.md`
  - `.uspecs/rules/feature-impl-details-struct.md` -> `.uspecs/structs/feature-impl-details.md`

### Update references in other files

- [x] update: `[overview.md](../../../overview.md)`
  - `.uspecs/rules/*-struct.md` -> `.uspecs/structs/*.md`
  - `.uspecs/rules/project-specs-struct.md` -> `.uspecs/structs/project-specs.md`
  - `.uspecs/rules/feature-impl-details-struct.md` -> `.uspecs/structs/feature-impl-details.md`

- [x] update: `[spec-impact.md](../../../changes/active/251202-derive-uspecs/spec-impact.md)`
  - `.uspecs/rules/project-specs-struct.md` -> `.uspecs/structs/project-specs.md`
