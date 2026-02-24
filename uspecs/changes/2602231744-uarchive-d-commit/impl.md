# Implementation plan: uarchive -d flag: commit, remove branch and refs

## Functional design

- [x] update: [softeng/uarchive.feature](../../specs/prod/softeng/uarchive.feature)
  - add: Scenario for -d flag: archive, commit and push, remove branch and refs

## Construction

- [x] update: [u/actn-uarchive.md](../../u/actn-uarchive.md)
  - add: -d flag parameter and flow: commit and push with message `archive <folder-from> <folder-to>`, remove branch and refs
- [x] update: [u/scripts/_lib/utils.sh](../../u/scripts/_lib/utils.sh)
  - add: `get_pr_info` helper to parse pr.sh output into associative array
- [x] update: [u/scripts/conf.sh](../../u/scripts/conf.sh)
  - refactor: `show_operation_plan` to use `get_pr_info`
- [x] update: [u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - fix: archive folder check pattern `*archive*` -> `archive/*`
  - add: -d flag to `cmd_change_archive`: git commit and push, delete branch and refs
  - add: validation for -d: clean tree, not default branch, remote ref exists, no divergence, must be PR branch
  - fix: branch deletion uses current branch instead of folder-derived name
