# Change request heading, Why and What sections

## data

```markdown
# Change request: {title-derived-from-change-description}

## Why

[1-3 sentences describing the reason, cause, purpose, or belief behind the change request]

## What

[What is being delivered, without implementation details, do not build exhaustive lists of changes here - just a summary of the main change items]

Introductory sentence:

- Item 1
- Item 2

...
```

Rules:

- Tailor the `## What` items to the `type:` frontmatter value:
  - `feat`: behavior claims only; no file paths, no symbol names; name the affected domain/context in prose so reviewers can judge blast radius
  - `fix`:
    - symptom (observable wrong outcome)
    - flow: external trigger through the internal causal chain to the symptom, with the fault marked as a step
      - steps may use conceptual labels (e.g. "the body builder", "the validator", "the rule") and/or concrete identifiers (file names, function/method names, config keys, etc.)
      - concrete identifiers are optional; the whole flow can be conceptual (e.g. for bugs in workflows, rules, or behavior not yet located in code)
    - corrected behavior claim
  - `refactor`, `perf`, `style`: explicit "no behavior change" claim plus the invariant being preserved
  - `docs`: what the reader gains and which artifact category is touched
  - `build`, `ci`, `chore`: what capability or guarantee changes for contributors, not which files
  - `test`: which behavior gains coverage and at which level
  - `revert`: the commit being reverted and which behavior returns
- When `breaking: true` in frontmatter (any type), include an explicit bullet describing what previously worked stops working or changes shape
