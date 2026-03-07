# Implementation plan: Archive pr branch cleanup

## Functional design

- [x] update: [softeng/uarchive.feature](../../specs/prod/softeng/uarchive.feature)
  - update: option 1 - split commit+push into two steps; push is conditional on remote branch existence
  - add: option 1 - Engineer is switched to default branch
  - add: option 1 - local default branch is fast-forwarded to pr_remote/default_branch
  - add: edge case scenario - archive on PR branch when remote branch no longer exists

## Construction

- [x] update: [u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - update: `cmd_change_archive` precondition (c) - replace local tracking ref check with `git ls-remote` to detect if remote branch actually exists; store result in `remote_exists`
  - update: `cmd_change_archive` precondition (d) - skip divergence check when `remote_exists` is empty
  - update: `cmd_change_archive` execution - make push conditional on `remote_exists`
  - add: `cmd_change_archive` execution - after switching to default branch, fetch and `--ff-only` merge `pr_remote/default_branch`
  - update: `cmd_change_archive` - extract `pr_remote` from `pr_info` for use in fast-forward step

- [x] update: [tests/uspecs.sh-change-archive.bats](../../../tests/uspecs.sh-change-archive.bats)
  - add: setup helper - create temp git repo with a remote, a PR branch, and a fake change folder
  - add: `assert_cleanup_complete` helper - asserts PR branch deleted, tracking ref gone, current branch is default, default branch equals remote tip
  - add: test - remote branch exists: commit is pushed; call `assert_cleanup_complete`
  - add: test - remote branch does not exist: push is skipped; call `assert_cleanup_complete`
