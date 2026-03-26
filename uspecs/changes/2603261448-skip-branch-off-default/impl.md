# Implementation plan: Skip branch creation when not on default branch

## Functional design

- [x] update: [softeng/uchange.feature](../../specs/prod/softeng/uchange.feature)
  - update: "No options" scenario to clarify branch is created only when on default branch
  - add: Scenario for uchange invoked from non-default branch (branch creation skipped)
  - add: Scenario for --branch option forcing branch creation from non-default branch

## Construction

- [x] update: [uspecs.sh](../../u/scripts/uspecs.sh)
  - update: `cmd_change_new()` -- after resolving `is_new_branch`, check if current branch is the default branch; if not, set `is_new_branch=""` unless `--branch` was explicitly passed
- [x] update: [actn-uchange.md](../../u/actn-uchange.md)
  - update: Output section and Flow to reflect that branch is created only when on default branch (unless --branch)
- [x] update: [conf.md](../../u/conf.md)
  - update: Branch naming subsection to note branch is created only when on default branch
- [x] update: [uspecs.sh-change-new.bats](../../../tests/sys/uspecs.sh-change-new.bats)
  - add: Test for no options on non-default branch (branch not created)
  - add: Test for --branch option on non-default branch (branch created)
