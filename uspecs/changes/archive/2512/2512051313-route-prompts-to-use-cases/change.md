# Change: Route prompts to use cases

- Type: behavior
- Baseline: 868f35f

## Problem

The register action currently contains routing logic for different use cases. This coupling makes it harder to maintain and extend.

## Proposal

Create separate action files for each use case instead of routing in register.md:

- actions/register-base.md
  - Common flow: read specs-rules.md, create change folder, get baseline, create change.md
  - Accepts template parameter from calling action
  - Internal use only, not triggered directly
- actions/init-project.md
  - Triggered by "initialize project [name] [description]"
  - Project name inferred from current folder if not provided
  - Fail fast if specs/ folder exists
  - Calls register-base with change-init.md template
- actions/config-td.md
  - Triggered by "configure technical design rules"
  - Why: partially initialize rules, it is possible to work without product design rules
  - Fail fast if specs/td-rules.md exists
  - Calls register-base with change-td.md template
- actions/config-pd.md
  - Triggered by "configure product design rules"
  - Fail fast if specs/fd-rules.md or specs/uxui-rules.md exists
  - Calls register-base with change-pd.md template
- actions/register.md
  - Triggered by "new change [description]"
  - No validation
  - Calls register-base with change-standard.md template

AGENTS.md triggering instructions route directly to each action.

## Inferred requirements

- register-base.md contains common logic (DRY)
- Each action validates its own preconditions then delegates to register-base
- Appropriate error messages must be returned when preconditions fail
- Update AGENTS.md with new triggering instructions
