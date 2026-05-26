# What section default format

## data

```markdown
## What

Introductory sentence:

- Item 1
- Item 2
```

Rules:

- 2-6 bullets, optionally preceded by one lead-in sentence
- Each bullet is a behavior claim, not an implementation step
- No exhaustive lists of file or symbol changes
- Tailor the `## What` items to the `type:` frontmatter value:
  - `feat`: behavior claims only; no file paths, no symbol names; name the affected domain/context in prose so reviewers can judge blast radius
  - `refactor`, `perf`, `style`: explicit "no behavior change" claim, and name the externally observable behavior that must be preserved (API surface, output, performance contract, etc.)
  - `docs`: what the reader gains and which artifact category is touched
  - `build`, `ci`, `chore`: what capability or guarantee changes for contributors, not which files
  - `test`: which behavior gains coverage and at which level
  - `revert`: the commit being reverted and which behavior returns
