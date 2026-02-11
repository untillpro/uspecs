# Change: Rename config-pd to config-fd and add multi-context support

- Type: refactoring
- Baseline: 29688d9

## Problem

The current config-pd action name uses "pd" (product design) terminology, but the system should support multiple contexts beyond just product design, including both product users and developer users.

## Proposal

Rename config-pd action to config-fd (functional design) and extend fd-rules.md to support multiple contexts:

- prod: product users
- dev: developer users (Developer, Scripts, automation systems like GitHub Actions)

The change involves:

- Renaming the action file from config-pd.md to config-fd.md
- Repurposing the template file change-pd.md to change-fd.md as a template for fd-rules.md structure
- Updating any references to the old action name
- Extending fd-rules.md structure to support multi-context definitions with separate sections per context
- Updating triggering instructions to use the new action name (remove old trigger completely)
- Removing config-fd from change type metadata values (fd-rules generated directly from user answers)

## Multi-context structure

fd-rules.md will use separate sections per context:

```markdown
# Context

## Production context

### Actors
- User
  - type: Human
  - description: End user

### Services provided
- Authentication
  - consumer: User

### Services consumed
- Email Delivery
  - provider: EmailProvider

## Development context

### Actors
- Developer
  - type: Human
  - description: Software developer

- GitHub Actions
  - type: External System
  - description: CI/CD automation

### Services provided
- CI/CD automation
  - consumer: Developer

### Services consumed
- Git Repository
  - provider: GitHub
```

Each context section includes all three subsections: Actors, Services provided, Services consumed.

Context names are fixed: "Production context" and "Development context".

## Configuration questions

- config-fd asks questions about actors and services only (no path questions)
- Ask about most unclear/ambiguous issues first
- The action generates fd-rules.md immediately after questions and shows the link for user review
- Does not create uxui-rules.md
- Does not create specs-rules.md

## Validation

- Fail with error if specs/fd-rules.md exists

## Dev actors inference

- Automatically analyze the codebase to infer dev actors (git config, CI files, etc.) and pre-fill them in questions
