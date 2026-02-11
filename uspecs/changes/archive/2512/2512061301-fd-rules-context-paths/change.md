# Change: Add context paths to fd-rules

- Type: behavior
- Baseline: a8f651a739f64794770bf5f77892a9b7d51f63a8

## Problem

The fd-rules.md template defines Production context and Development context but does not specify where feature specifications for each context should be stored in the file system.

## Proposal

Add configurable context paths to fd-rules.md showing where feature folders are located for each context.

Design decisions:

- Three fixed contexts:
  - Production context (prod): User - end-user facing features and functionality
  - Development context (dev): Developer - development concerns (testing, CI/CD, build tools)
  - Showcase context (showcase): Visitor - attracting repository visitors (project site, docs, demos)
- Context section names in fd-rules.md define both the context and its path
  - "Production context" section maps to /specs/prod path
  - "Development context" section maps to /specs/dev path
  - "Showcase context" section maps to /specs/showcase path
- Context folders are roots for feature folders
  - Structure: specs/{context-folder}/feature-name/
  - Example: specs/prod/authentication/, specs/dev/ci-pipeline/
- Features are assigned to contexts based on which actors they reference in Gherkin scenarios
  - Agent should guess the context by analyzing actors in "As a..." lines
  - Match actor names to contexts defined in fd-rules.md
  - Each feature belongs to exactly one context (no multi-context features)
- Additional contexts can be inferred from existing codebase folder structure
- Backward compatibility: not needed (new feature, existing projects can keep current structure)
- Templates requiring updates: fd-rules.md, specs-rules.md
