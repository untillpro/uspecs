# Domain architecture: devops

## Actions and skills

- Actions like `uchange`, `upr` are defined in AGENTS.md

## Development conventions

### Shared skill content

cross knowledge skills is authored once under `.claude/skills/uspecs-concepts/shared/` and referenced from consuming skills with sibling-relative links of the form `../uspecs-concepts/shared/<name>.md`.

Rationale: A single source of truth avoids the drift that arises when the same rules or path lists are copied into multiple skills.

Implementation: During marketplace generation each such reference is inlined with the referenced file's content, so published skills are self-contained. The `uspecs-concepts/shared/` source is excluded from the published output. Only the `../uspecs-concepts/shared/` link form is inlined; all other links are left untouched.

## Key data models

### Version format

- Semantic versioning: X.Y.Z-aN
  - X: major version
  - Y: minor version
  - Z: patch version
  - aN: pre-release identifier (optional, alpha build number)
- Examples: 1.0.0-a0 (development), 1.0.12 (release)
