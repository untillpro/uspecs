---
registered_at: 2026-03-26T14:48:24Z
change_id: 2603261448-skip-branch-off-default
baseline: de35a3ed744b937672baa1bf3a814aecf234178e
archived_at: 2026-03-26T16:17:22Z
---

# Change request: Skip branch creation when not on default branch

## Why

When Engineer runs uchange while already on a non-default branch (e.g. a feature branch), creating a new branch is unnecessary and confusing. The new change should be created in the context of the current branch.

## What

uchange skips branch creation when the current branch is not the default branch:

- `cmd_change_new()` in `uspecs.sh`: after resolving `is_new_branch`, check if current branch is the default branch. If not on default branch, set `is_new_branch=""` unless `--branch` was explicitly passed
- `actn-uchange.md`: update documentation to reflect the new default behavior -- branch is created only when on default branch; `--branch` forces creation regardless
- `uspecs/u/conf.md`: update Branch naming section to mention this behavior
