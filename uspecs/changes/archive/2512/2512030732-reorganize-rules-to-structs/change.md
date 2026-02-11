# Change: Reorganize rules to structs

- Type: refactoring
- Baseline: 9870494

## Problem

The current naming convention for rule files uses a `-struct` postfix (e.g., `change-standard-struct.md`), which is redundant when files are already located in a rules folder.

## Proposal

Move rule files from `.uspecs/rules/` to `.uspecs/structs/` and remove the `-struct` postfix from filenames. For example, `.uspecs/rules/change-standard-struct.md` becomes `.uspecs/structs/change-standard.md`.

## Inferred requirements

- Move all rule files from `.uspecs/rules/` to `.uspecs/structs/`
- Remove `-struct` postfix from filenames during move
- Update all references to these files throughout the codebase
- Ensure no broken links after reorganization
