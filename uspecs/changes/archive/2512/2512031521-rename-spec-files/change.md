# Change: Rename spec files

- Type: behavior
- Baseline: a0e7ab0

## Problem

Current spec file names (context.md, spec.md, design.md) are generic and do not clearly indicate their purpose as rule files.

## Proposal

Rename template files and split derive-project into separate technical and product design configuration scenarios.

## Definitions

- fd: functional design
- td: technical design
- pd: product design (fd + uxui)
- Product design rules: Functional design and UX/UI guidelines for the product

## Templates

Keep as is:

- change-init.md
- change-standard.md (alias: change-default.md)
- feature-gherkin.md (alias: gherkin.md)

Rename:

- change-derive-project.md -> change-pd.md + change-td.md
- change-metadata.md -> change-common-metadata.md
- change-plan.md -> plan.md
- change-specs-impact.md -> specs-impact.md
- feature-impl-details.md -> td.md
- project-context.md -> fd-rules.md
- project-design.md -> td-rules.md
- project-specs.md -> specs-rules.md

New:

- uxui-rules.md

## Scenarios

- Initialize project
  - Triggered by user request "initialize project [name] [description]"
  - Fail fast if /specs exists
  - Uses change-init.md template
- Configure technical design rules
  - Triggered by user request like "configure technical design rules"
  - Why: partially initialize rules, it is possible to work without product design rules
  - Fail fast if /specs/td-rules.md exists
  - Uses change-td.md template (see below)
- Configure product design rules
  - Triggered by user request like "configure product design rules"
  - Fail fast if /specs/fd-rules.md or /specs/uxui-rules.md exists
  - Uses change-pd.md template (see below)

## change-init.md

Agent guesses whole project properties from existing codebase and prepares change.md with these guesses.

change.md will include todo items to create new spec files:

- /specs/specs-rules.md (copied)
- /specs/td-rules.md (inferred)
- /specs/fd-rules.md (inferred)
- /specs/uxui-rules.md (inferred)

## change-td.md

Template to generate change.md for configuring technical design rules.

Agent guesses td-rules.md from existing codebase and prepares change.md with these guesses.

change.md will include todo items to create new spec files:

- /specs/specs-rules.md (if not exist, will be copied)
- /specs/td-rules.md (derived from the change.md and codebase)

## change-pd.md

Template to generate change.md for configuring product design rules.

Agent guesses fd-rules.md and uxui-rules.md from existing codebase and prepares change.md with these guesses.

change.md will include todo items to create new spec files:

- /specs/specs-rules.md (if not exist, will be copied)
- /specs/fd-rules.md (derived from the change.md and codebase)
- /specs/uxui-rules.md (derived from the change.md and codebase)

## Obsolete scenarios

These existing scenarios are replaced by the new scenarios above:

- "initialize project" -> replaced by "Initialize project" (new behavior)
- "derive project" -> replaced by "Configure technical design rules" + "Configure product design rules"
