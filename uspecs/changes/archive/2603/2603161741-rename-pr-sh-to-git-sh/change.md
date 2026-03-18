---
registered_at: 2026-03-16T17:00:10Z
change_id: 2603161700-rename-pr-sh-to-git-sh
baseline: dbe2f52ce7562d845e2ecda5111f9b9fff4c6056
archived_at: 2026-03-16T17:41:07Z
---

# Summary

Rename `_lib/pr.sh` to `_lib/git.sh` and change usage from execution (`bash pr.sh command`) to sourcing (`source git.sh`) with direct function calls.

## Rationale

- The file covers git branch and PR automation - `git.sh` is a better name
- Sourcing makes functions available in the caller's scope, avoiding subprocess overhead and simplifying the calling pattern
- Resolves the circular dependency between `utils.sh` and `pr.sh` noted in the TODO comment

## Changes

- Rename `_lib/pr.sh` to `_lib/git.sh`, update header comments, remove dispatch block
- Update `_lib/utils.sh`: remove `get_pr_info` (moved to `git.sh` as `git_pr_info`; circular dependency resolved)
- Update `uspecs.sh`: source `git.sh`, call functions directly instead of executing
- Update `conf.sh`: source `git.sh`, call functions directly instead of executing
- Update `actn-upr.md`: reference `_lib/git.sh` instead of `_lib/pr.sh`
