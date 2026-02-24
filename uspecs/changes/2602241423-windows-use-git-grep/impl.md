# Implementation plan: On Windows use grep from git install

## Construction

- [x] update: [u/scripts/_lib/utils.sh](../../u/scripts/_lib/utils.sh)
  - add: `_GREP_BIN` module-level variable and `_grep` wrapper function that resolves git's bundled grep on Windows (`$OSTYPE` msys*/cygwin*) and fails fast if not found; falls through to system grep on non-Windows

- [x] update: [u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - replace: 3 `grep` calls with `_grep` (lines 70, 134, 349)

- [x] update: [u/scripts/_lib/pr.sh](../../u/scripts/_lib/pr.sh)
  - replace: 3 `grep` calls with `_grep` (lines 78, 96, 142)
  - add: `change_branch_head` output in `cmd_mergedef` validate mode

- [x] update: [u/scripts/conf.sh](../../u/scripts/conf.sh)
  - replace: 10 `grep` calls with `_grep` (lines 101, 113, 115, 128, 130, 370 (two calls), 669, 670, 671)

## Specifications

- [x] update: [specs/prod/softeng/upr.feature](../../specs/prod/softeng/upr.feature)
  - update: scenario step to specify AI Agent reports both PR URL and change branch commit hash

- [x] update: [u/actn-upr.md](../../u/actn-upr.md)
  - update: flow to parse `change_branch_head` from validation output
  - update: final report step to include `change_branch_head` and branch restore command
  