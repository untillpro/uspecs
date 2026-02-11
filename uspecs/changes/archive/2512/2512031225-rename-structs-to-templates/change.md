# Change: Rename structs folder to templates

- Type: refactoring
- Baseline: 4ca07a8

## Problem

The folder `.uspecs/structs` contains template files, but the name "structs" does not clearly communicate this purpose. The name "templates" would be more descriptive.

## Proposal

Rename `.uspecs/structs` to `.uspecs/templates` and update all references throughout the codebase.

## Inferred requirements

- Rename folder `.uspecs/structs` to `.uspecs/templates`
- Update all references in action files (register.md, plan.md, apply.md, etc.)
- Update all references in struct/template files themselves
- Update any documentation that references the old path
