---
registered_at: 2026-03-10T17:02:48Z
change_id: 2603101702-replace-grep-git-path
baseline: fbce1b2c5864e7caf1cd1ea269bcf11db209c3f4
archived_at: 2026-03-10T19:07:08Z
---

# Change request: Replace grep wrapper with git_path() and eliminate duplication

## Why

The `_grep`/`_GREP_BIN` wrapper in `utils.sh` and `conf.sh` solves Windows PATH issues by locating grep under the Git installation, but is complex and duplicated. A simpler approach is `git_path()`, which prepends `/usr/bin` to PATH on Windows so plain `grep` and other Git-bundled tools work directly.

`error()` is also duplicated between `uspecs.sh` and `pr.sh` and can be consolidated into `utils.sh`.

## What

Replace grep-related code with `git_path()`:

- Add `git_path()` to `_lib/utils.sh` and `conf.sh` (intentional duplication -- `conf.sh` runs standalone during install)
- Remove `checkcmds` from `conf.sh` and `utils.sh` entirely (`git_path()` fails when git is not found)
- Remove `_GREP_BIN` and `_grep()` from `_lib/utils.sh` and `conf.sh`
- Replace all `_grep` calls with plain `grep` in `uspecs.sh`, `_lib/pr.sh`, and `conf.sh`

Eliminate duplication between `uspecs.sh` and `_lib/pr.sh`:

- Move `error()` from `uspecs.sh` and `_lib/pr.sh` into `_lib/utils.sh`

Call `git_path()` in `main()` of both scripts to cover all entry points:

- `uspecs.sh`: covers `cmd_change_new`, `cmd_change_archive`, `cmd_pr_preflight`, `cmd_status_ispr`, and direct `pr.sh` delegations (`pr create`, `diff specs`)
- `conf.sh`: covers `cmd_install`, `cmd_update_or_upgrade`, `cmd_im`, `cmd_apply`

Add non-interactive confirmation and local install support to `conf.sh`:

- Replace `USPECS_YES` env var with `-y` flag across `install`, `update`, `upgrade`, `apply`
- Add `--local` flag to `install` to skip GitHub download and use the local repository directly (for development and E2E testing)

Reorganize and expand the test suite:

- Split tests into `tests/sys/` (system tests) and `tests/e2e/` (end-to-end tests)
- Add `tests/alltests.sh` as a recursive BATS runner
- Add E2E tests for `conf.sh install` using `--local` flag
