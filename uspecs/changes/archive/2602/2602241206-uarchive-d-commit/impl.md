# Implementation plan: uarchive git cleanup on PR branch

## Functional design

- [x] update: [softeng/uarchive.feature](../../../../../../specs/prod/softeng/uarchive.feature)
  - restructure: Background with `Active Change Folder is unambiguous`, plain `Scenario` for basic archive
  - add: `Scenario` for PR branch auto-detection with confirmation and git cleanup
- [x] update: [softeng/upr.feature](../../../../../../specs/prod/softeng/upr.feature)
  - fix: Examples table column alignment

## Construction

- [x] update: [u/actn-uarchive.md](../../../../../../u/actn-uarchive.md)
  - replace: -d flag with `status ispr` check; agent asks Engineer to confirm git cleanup when on PR branch
- [x] update: [u/actn-upr.md](../../../../../../u/actn-upr.md)
  - fix: pr create passes body via stdin instead of --body argument
- [x] update: [u/scripts/_lib/pr.sh](../../../../../../u/scripts/_lib/pr.sh)
  - fix: `gh_create_pr` reads body from stdin via `--body-file -` instead of argument
  - fix: `git fetch` and `git merge` calls get `2>&1` to suppress PowerShell stderr errors
  - fix: `cmd_changepr` reads body from stdin when `--body` is not provided
  - fix: `cmd_changepr` fails fast with error when stdin is a TTY and `--body` is omitted
  - fix: source `utils.sh` so `is_tty` is available
- [x] update: [u/scripts/_lib/utils.sh](../../../../../../u/scripts/_lib/utils.sh)
  - add: `get_pr_info` helper to parse pr.sh info output into associative array
  - add: `is_tty` helper - returns 0 if stdin is a terminal
- [x] update: [u/scripts/conf.sh](../../../../../../u/scripts/conf.sh)
  - refactor: `show_operation_plan` to use `get_pr_info`
- [x] update: [u/scripts/uspecs.sh](../../../../../../u/scripts/uspecs.sh)
  - add: `is_git_repo` helper replacing repeated inline git rev-parse subshell pattern
  - fix: `get_baseline` accepts and uses `project_dir` parameter
  - fix: `move_folder` uses `project_dir` (or `$PWD`) for git repo check
  - add: `cmd_status_ispr`: prints `yes` when in a git repo on a branch ending with `--pr`
  - fix: `cmd_change_new` runs git commands from `project_dir`
  - add: `cmd_change_archive` -d flag: argument parsing, validations (clean tree, not default branch, remote ref exists, no divergence, must be PR branch), git commit and push, checkout default branch, delete branch and refs
  - fix: `cmd_change_archive` archive folder check pattern `*archive*` -> `archive/*`
  - add: `status ispr` dispatch
