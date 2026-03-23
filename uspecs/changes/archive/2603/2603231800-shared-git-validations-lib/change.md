---
registered_at: 2026-03-23T14:39:45Z
change_id: 2603231439-shared-git-validations-lib
baseline: 4545ca54fa16ecf6b436ed1dbdb8d0516ad08ae4
archived_at: 2026-03-23T18:00:49Z
---

# Change request: Shared git validations library

## Why

The upr and uaccept features have common edge case examples (no git repository, working tree has uncommitted changes, current branch is the default branch) that are duplicated across both feature files. This duplication makes maintenance harder and increases the risk of inconsistency.

## What

Create shared feature libraries for common validation edge cases:

- shared/git-validations.feature: "Project inside Git working tree", "Git working tree is clean"
- shared/change-validations.feature: "Exactly one Working Change Folder", "All todo items are completed"

Update existing features to reference shared libraries instead of duplicating examples:

- upr.feature: reference shared git and Change Folder validation scenarios
- uaccept.feature: reference shared git and Change Folder validation scenarios

Align implementation with shared scenarios - each scenario has a corresponding validation function:

- `git_validate_working_tree`, `git_validate_clean_repo` in `_lib/git.sh`
- `changes_validate_single_wcf`, `changes_validate_todos_completed` in `uspecs.sh`
