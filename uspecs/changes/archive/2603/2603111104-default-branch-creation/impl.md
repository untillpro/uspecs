# Implementation plan: Default branch creation for uchange

## Functional design

- [x] update: [softeng/uchange.feature](../../../../specs/prod/softeng/uchange.feature)
  - update: "Create change request, no options" scenario - branch is now created by default
  - update: "--branch option" scenario - rephrase as explicit override (reserved for future per-project default)
  - add: Scenario for --no-branch option to opt out of branch creation

## Construction

- [x] update: [u/scripts/uspecs.sh](../../../../u/scripts/uspecs.sh)
  - update: usage comment - replace `[--branch]` with `[--no-branch]`
  - update: `cmd_change_new` - parse into `opt_branch`/`opt_no_branch`, validate mutual exclusivity, derive `is_new_branch` (default true, cleared by `--no-branch`)

- [x] update: [tests/sys/uspecs.sh-change-new.bats](../../../../../tests/sys/uspecs.sh-change-new.bats)
  - update: "change new creates change folder and change.md" - assert branch is also created by default
  - add: "change new --no-branch does not create branch"
  - add: "change new --branch and --no-branch fails with error"

- [x] update: [u/actn-uchange.md](../../../../u/actn-uchange.md)
  - update: parameters - replace `--branch option` with `--no-branch option (optional): skip git branch creation`
  - update: output - branch created by default unless `--no-branch`
  - update: flow - remove `--branch` parameter from base command, add `--no-branch` conditional
