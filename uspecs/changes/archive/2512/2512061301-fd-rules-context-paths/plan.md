# Implementation plan: Add context paths to fd-rules

Change: `[change.md](change.md)`

## Files modification

- [x] update: `[templates/fd-rules.md](../../../.uspecs/templates/fd-rules.md)`
  - Add Showcase context section after Development context
  - Update Rules section: change "Two contexts" to "Three fixed contexts: Production context, Development context, and Showcase context"
  - Update example to include Showcase context with Visitor actor and repository attraction services

- [x] update: `[templates/specs-rules.md](../../../.uspecs/templates/specs-rules.md)`
  - Update Project structure section to show context-based feature folder organization
  - Change from flat `specs/feature-name/` to `specs/{context}/feature-name/`
  - Add examples: `specs/prod/`, `specs/dev/`, `specs/showcase/`
  - Update Feature folder structure section to clarify context folders contain feature folders

- [x] update: `[actions/plan.md](../../../.uspecs/actions/plan.md)`

- [x] update: `[actions/analyze-spec-impact.md](../../../.uspecs/actions/analyze-spec-impact.md)`
  - Add guidance for determining feature context based on actors referenced in Gherkin scenarios
  - When creating new features, agent should analyze actors and assign to appropriate context
  - Match actor names to contexts defined in fd-rules.md

- [x] update: `[templates/specs-impact.md](../../../.uspecs/templates/specs-impact.md)`
  - Update example feature paths to include context folder: `prod/authentication/register.feature`

- [x] update: `[templates/plan.md](../../../.uspecs/templates/plan.md)`
  - Update Implementation details rule and examples to include context folders: `specs/{context}/{feature}/td.md`

- [x] update: `[templates/td.md](../../../.uspecs/templates/td.md)`
  - Update heading comment from `{feature-id}/td.md` to `{context}/{feature-id}/td.md`
  - Update relative path examples to account for extra context folder level
  - Change `../../src/` to `../../../src/` (one more level up)
  