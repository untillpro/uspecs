# Decisions: Add optional grouping to Construction section

## When to group vs. keep flat

Use grouping when the Construction section has items spanning 3+ distinct categories (confidence: high).

Rationale: Below 3 categories, grouping adds overhead without improving readability. At 3+ categories the flat list becomes hard to scan and grouping provides clear visual separation.

Alternatives:

- Group when 5+ items total (confidence: medium)
  - Focuses on list length rather than conceptual diversity; a long list within one category does not benefit from grouping
- Always group (confidence: low)
  - Adds noise for small changes with 1-2 items

## What constitutes a "category"

Group by dependency order between components - items that must change together or in sequence form a category (confidence: high).

Rationale: Categories should reflect the dependency chain of the change. Foundational changes come first, dependent changes after. For example: `### Schema changes` -> `### Function signature changes` -> `### Caller updates` -> `### Tests`. This gives a natural top-down ordering and conveys which changes are prerequisites for others.

Alternatives:

- Group by artifact type like `### Source code`, `### Tests`, `### Configuration` (confidence: medium)
  - Flat classification that does not convey dependency relationships between items
- Group by module/package (confidence: low)
  - Works for large monorepos but breaks down for cross-cutting changes

## Whether grouping headers should be prescribed or free-form

Use free-form `###` headers chosen by AI Agent (confidence: high).

Rationale: Prescribed categories would be too rigid - the right grouping depends on the specific change. AI Agent knows best how to organize items for readability based on the change context.

Alternatives:

- Prescribe a fixed set of categories (confidence: low)
  - Too rigid; many changes would not fit the prescribed categories
- Provide a recommended list but allow custom (confidence: medium)
  - Adds complexity to the spec for marginal benefit

## Whether grouping applies only to Construction or also to other sections

Apply only to Construction section (confidence: high).

Rationale: Functional design and Technical design sections are typically short (1-3 items) and already scoped by their nature. Construction is the section that grows large with diverse file types.

Alternatives:

- Apply to all three sections (confidence: low)
  - Functional design and Technical design rarely have enough items to benefit
- Apply to Construction and Technical design (confidence: low)
  - Technical design is already structured by architecture hierarchy

## Whether to make grouping a rule or a guideline

Frame as optional guideline with a soft threshold (confidence: high).

Rationale: Making it a strict rule would add enforcement burden. A guideline like "consider grouping when items span 3+ categories" gives AI Agent discretion while nudging toward better organization.

Alternatives:

- Strict rule with mandatory grouping above threshold (confidence: low)
  - Over-prescriptive for a formatting concern
- No mention of threshold at all (confidence: medium)
  - Without any guidance, grouping would be used inconsistently
