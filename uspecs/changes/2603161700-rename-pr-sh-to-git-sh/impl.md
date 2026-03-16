# Implementation plan: Rename pr.sh to git.sh and switch to sourcing

## Construction

- [x] rename: `[u/scripts/_lib/pr.sh](../../u/scripts/_lib/pr.sh)` -> [u/scripts/_lib/git.sh](../../u/scripts/_lib/git.sh)
  - use git mv to preserve history
  - update: file header - update file name and description, keep Concepts section, remove Usage block (dispatch interface is gone)
  - remove: `cmd_info` function
  - remove: dispatch block (lines 412-430)
  - add: `git_pr_info` function with doc comment (new; calls `determine_pr_remote`/`default_branch_name` directly)
  - rename: `cmd_prbranch` -> `git_prbranch`, move doc from header Usage block to above function
  - rename: `cmd_ffdefault` -> `git_ffdefault`, move doc from header Usage block to above function
  - rename: `cmd_pr` -> `git_pr`, move doc from header Usage block to above function
  - rename: `cmd_mergedef` -> `git_mergedef`, move doc from header Usage block to above function
  - rename: `cmd_diff` -> `git_diff`, move doc from header Usage block to above function
  - rename: `cmd_changepr` -> `git_changepr`, move doc from header Usage block to above function
  - update: line 362 (inside `git_changepr`) - `cmd_prbranch "$pr_branch"` -> `git_prbranch "$pr_branch"`

- [x] update: [u/scripts/_lib/utils.sh](../../u/scripts/_lib/utils.sh)
  - remove: `get_pr_info` function and TODO comment about circular dependency

- [x] update: [u/scripts/uspecs.sh](../../u/scripts/uspecs.sh)
  - add: `source git.sh` after existing `source utils.sh`
  - update: line 342 - `"$lib_dir/pr.sh" mergedef` -> `git_mergedef`
  - update: line 361 - remove `pr_sh` variable, call `git_pr_info pr_info "$project_dir"`
  - update: line 489 - remove `pr_sh` variable, call `git_pr_info pr_info`
  - update: line 491 - error message text "pr.sh info" -> "git remote info"
  - update: line 709 - `"$lib_dir/pr.sh" changepr` -> `git_changepr`
  - update: line 725 - `"$lib_dir/pr.sh" diff specs` -> `git_diff specs`
  - update: comment at line 37 referencing `_lib/pr.sh`

- [x] update: [u/scripts/conf.sh](../../u/scripts/conf.sh)
  - add: source `git.sh` at top level (after `_TEMP_FILES=()`, before function definitions, so conf.sh's own functions override duplicates from git.sh)
  - remove: `get_pr_info` function and comment at lines 43-47 (provided by git.sh)
  - remove: `git_path` function (provided by utils.sh, sourced by git.sh)
  - remove: `error` function (provided by utils.sh, sourced by git.sh)
  - remove: `is_tty` function (provided by utils.sh, sourced by git.sh)
  - remove: `is_git_repo` function (provided by utils.sh, sourced by git.sh)
  - remove: `sed_inplace` function (provided by utils.sh, sourced by git.sh)
  - update: line 373 - `get_pr_info "$script_dir/_lib/pr.sh" pr_info "$project_dir" 2>/dev/null` -> `git_pr_info pr_info "$project_dir" 2>/dev/null`
  - update: line 676 - `bash "$script_dir/_lib/pr.sh" ffdefault` -> `git_ffdefault`
  - update: line 717 - `bash "$script_dir/_lib/pr.sh" prbranch` -> `git_prbranch`
  - update: line 764 - `bash "$script_dir/_lib/pr.sh" pr` -> `git_pr`

- [x] update: [u/actn-upr.md](../../u/actn-upr.md)
  - update: line 12 - generalize "never call `_lib/pr.sh` directly" to "never invoke scripts from the `_lib` folder directly" (already applied)
