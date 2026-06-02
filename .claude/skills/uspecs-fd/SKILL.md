---
name: uspecs-fd
description: Use this skill when authoring or reviewing a Functional Design Specification - any `*.feature` or `*--reqs.md` file under `uspecs/specs/`.
user-invocable: false
---

Functional Design Specifications describe the user-facing behavior to be implemented.

Artifacts:

- Scenario File (uspecs/specs/{domain}/{context}/{feature}.feature): feature scenarios in Gherkin format
- Requirements File (uspecs/specs/{domain}/{context}/{feature}--reqs.md): requirements that do not fit into Gherkin scenarios

## Scenarios File rules

- Create very concise scenarios
- Focus on user-facing behavior (what the user observes), not internal implementation steps
- Prefer Scenario Outlines with Examples tables over multiple similar Scenarios
- Use data tables in steps for inline structured data
- Write Scenarios as concrete examples of rules, not generic descriptions
  - Use named domain objects and representative literal values, e.g. `User Login "jsmith"` and Login Alias `"j.smith"`
  - Use generic wording only when the exact value is irrelevant to the behavior
  - Avoid vague outcomes such as "is accepted"; assert externally observable state instead
  - Use placeholders only in Scenario Outlines with an Examples table
- If appropriate group scenarios under `Rule: {aspect}`
  - Default to generic names: `Basic flow` (happy path), `Alternative flows`, `Exception flows`
  - Use an aspect-specific name (e.g. `Variable expansion`, `Escape sequences`, `Option parsing`) if all scenarios in the rule share one clearly named behavior and the specific name is more informative than the generic one

See [echo.feature](./echo.feature) as an example.

Example style for entity-state behavior:

```gherkin
Scenario: Admin replaces an existing Login Alias
  Given User Login "jsmith" has active Login Alias "j.smith"
  When Admin sets Login Alias "john.smith" for User Login "jsmith"
  Then User Login "jsmith" has active Login Alias "john.smith"
  And Login Alias "j.smith" is no longer active
```

## Requirements File rules

- Use Requirements File for content too large or too structured for Gherkin steps (e.g. lookup tables, option catalogs, error code catalogs, field/schema definitions, state transition tables, permission matrices, validation rule sets)

See [echo--reqs.md](./echo--reqs.md) as an example.
