# Implementation plan: Shared git validations library

## Functional design

- [x] create: [softeng/shared/git-validations.feature](../../../../specs/prod/softeng/shared/git-validations.feature)
  - add: Feature "Git validations" with scenarios "Project inside Git working tree" and "Git working tree is clean"

- [x] create: [softeng/shared/change-validations.feature](../../../../specs/prod/softeng/shared/change-validations.feature)
  - add: Feature "Change Folder validations" with scenarios "Exactly one Working Change Folder" and "All todo items are completed"

- [x] update: [softeng/upr.feature](../../../../specs/prod/softeng/upr.feature)
  - replace inline edge case examples with references to shared library scenarios
  - keep: feature-specific edge case (no changes detected)

- [x] update: [softeng/uaccept.feature](../../../../specs/prod/softeng/uaccept.feature)
  - replace inline edge case examples with references to shared library scenarios
  - add: missing reference to "Git validations#Git working tree is clean"
  - keep: feature-specific edge case (current branch has no upstream)

## Construction

- [x] update: [u/scripts/_lib/git.sh](../../../../u/scripts/_lib/git.sh)
  - add: `git_validate_working_tree` -- reflects scenario "Project inside Git working tree"
    - extract git repo check from `check_prerequisites`
  - add: `git_validate_clean_repo` -- reflects scenario "Git working tree is clean"
    - call `git_validate_working_tree`
    - extract clean working directory check from `check_prerequisites`
    - extract default branch check from inline code in `cmd_action_upr`/`cmd_action_uaccept`
  - keep: `check_prerequisites` unchanged (used by `git_ffdefault`, `git_mergedef`, `cmd_pr_preflight`)

- [x] update: [u/scripts/uspecs.sh](../../../../u/scripts/uspecs.sh)
  - rename: `changes_detect_wcf` -> `changes_validate_single_wcf` -- reflects scenario "Exactly one Working Change Folder"
  - add: `changes_validate_todos_completed` -- reflects scenario "All todo items are completed"
    - extract uncompleted todos check from `cmd_action_upr`
  - refactor: `cmd_action_upr` to use `git_validate_clean_repo`, `changes_validate_single_wcf`, `changes_validate_todos_completed`
  - refactor: `cmd_action_uaccept` to use `git_validate_clean_repo`, `changes_validate_single_wcf`

- [x] update: [tests/sys/uspecs.sh-prompt-upr.bats](../../../../../tests/sys/uspecs.sh-prompt-upr.bats)
  - update: edge case test comments to reference shared scenario names

- [x] update: [tests/sys/uspecs.sh-prompt-uaccept.bats](../../../../../tests/sys/uspecs.sh-prompt-uaccept.bats)
  - update: edge case test comments to reference shared scenario names
