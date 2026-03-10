# Implementation plan: Replace grep wrapper with git_path() and eliminate duplication

## Construction

### Shared library

- [x] update: [u/scripts/_lib/utils.sh](../../../../u/scripts/_lib/utils.sh)
  - add: `git_path()` function
  - add: `error()` function (consolidated from `uspecs.sh` and `pr.sh`)
  - remove: `checkcmds()` function (unused; git_path() fails naturally when git is absent)
  - remove: `_GREP_BIN` variable and `_grep()` function

### Standalone installer

- [x] update: [u/scripts/conf.sh](../../../../u/scripts/conf.sh)
  - add: `git_path()` function (intentional duplication -- runs standalone before _lib is available)
  - remove: `checkcmds()` function and its call `checkcmds curl`
  - remove: `_GREP_BIN` variable and `_grep()` function
  - replace: all `_grep` calls with plain `grep`
  - add: `git_path` call in `main()` before the command dispatch
  - add: `-y` flag to `cmd_install`, `cmd_update_or_upgrade`, `cmd_apply`; pass through call chain
  - remove: `USPECS_YES` env var; `confirm_action()` now accepts `yes_flag` param directly
  - add: `--local` flag to `cmd_install`; skips GitHub download, uses running `conf.sh`
  - add: `get_local_version()` and `get_local_commit_info()` for `--local` mode

### Main entry point

- [x] update: [u/scripts/uspecs.sh](../../../../u/scripts/uspecs.sh)
  - remove: `error()` function (moves to _lib/utils.sh)
  - replace: all `_grep` calls with plain `grep`
  - add: `git_path` call in `main()` before the command dispatch

### PR automation

- [x] update: [u/scripts/_lib/pr.sh](../../../../u/scripts/_lib/pr.sh)
  - remove: `error()` function (moves to _lib/utils.sh)
  - replace: all `_grep` calls with plain `grep`

### Testing

- [x] reorganize: tests into `tests/sys/` and `tests/e2e/` subdirectories
  - move: existing system tests and helpers into `tests/sys/`
  - fix: `REPO_ROOT` and `STUBS_DIR` paths in `tests/sys/helpers.bash` after move
- [x] create: [tests/alltests.sh](../../../../../tests/alltests.sh)
  - add: bash runner that calls `bats --recursive` on the tests directory
- [x] create: [tests/e2e/conf-install.bats](../../../../../tests/e2e/conf-install.bats)
  - add: E2E tests for `conf.sh install` using BATS framework
  - add: alpha install test using `--local` flag (no GitHub download lag)
  - add: `--pr` prerequisite test (dirty working directory)
  - add: already-installed failure test
