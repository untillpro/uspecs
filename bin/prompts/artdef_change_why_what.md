# Change request heading, Why and What sections

## data

Basic example:

```markdown
# Change request: {title}

## Why

[1-3 sentences describing the reason or purpose behind the change request]

## What

Introductory sentence:

- Item 1
- Item 2
```

Rules:

- `{title}`: short noun phrase, sentence case, no trailing period, <= 80 characters, no file paths or symbol names
- Insert the `Refs:` block from `@artdef_change_refs` between the H1 and `## Why` (?fetchable_maybe)
- Under `--fetchable`, populate `## Why` and `## What` by distilling the fetched issue in the change's terms; do not restate the issue body verbatim (?fetchable_maybe)
- `## What` content (default format, applies to all types except `fix`):
  - 2-6 bullets, optionally preceded by one lead-in sentence
  - each bullet is a behavior claim, not an implementation step
  - no exhaustive lists of file or symbol changes
- Tailor the `## What` items to the `type:` frontmatter value:
  - `feat`: behavior claims only; no file paths, no symbol names; name the affected domain/context in prose so reviewers can judge blast radius
  - `fix`: use the separate format for the `## What` section, see below (the default bullet format does not apply)
  - `refactor`, `perf`, `style`: explicit "no behavior change" claim, and name the externally observable behavior that must be preserved (API surface, output, performance contract, etc.)
  - `docs`: what the reader gains and which artifact category is touched
  - `build`, `ci`, `chore`: what capability or guarantee changes for contributors, not which files
  - `test`: which behavior gains coverage and at which level
  - `revert`: the commit being reverted and which behavior returns

## What section format for fix

For `type: fix`, the `## What` section replaces the default bullet format with three blocks in this order:

```markdown
[symptom]

[flow]

[corrected behavior claim]
```

- symptom: one sentence stating the observable wrong outcome
- flow: a fenced `text` block containing a vertical ASCII flowchart from the external trigger through the internal causal chain to the symptom, with the fault marked as a step
  - steps may use conceptual labels (e.g. "the body builder", "the validator", "the rule") and/or concrete identifiers (file names, function/method names, config keys, etc.)
  - prefer concrete identifiers when the fault is already located in code; use conceptual labels when it is not
  - example:

    ```text
    user submits form
          |
          v
    request validator
          |
          v
    body builder         <-- fault: drops trailing field
          |
          v
    downstream API rejects request   (symptom)
    ```

- corrected behavior claim: one sentence stating what the system does after the fix
