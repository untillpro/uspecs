---
registered_at: 2026-03-27T16:19:55Z
change_id: 2603271619-fix-umergepr-upstream
baseline: 6a8f44011ed3db876cec4791832979cbfe9f33f9
---


# Change request: Fix umergepr upstream remote handling

## Why

When working with fork-based workflows (upstream remote), umergepr has two problems:

- `gh pr merge` fails with "base branch was modified since the last push" because the PR branch is not updated with the latest base before the merge attempt
- After successful merge, syncing local default branch to upstream/main fails with `fatal: Not possible to fast-forward, aborting.` -- `gh pr merge` in fork setups can leave local main diverged from upstream/main, making `--ff-only` impossible even though local main was ff-able before umergepr

## What

Fix umergepr merge failure when base branch has been modified:

- After pushing the archive commit, call `gh pr update-branch` to sync the PR branch with the latest base branch before attempting `gh pr merge`

Fix umergepr post-merge sync failure with upstream remote:

- After fetch, check if fast-forward is possible using `git merge-base --is-ancestor`
- If diverged, log details (local HEAD, remote HEAD, merge-base, local-only commits) and skip fast-forward
- If fast-forward succeeds, push to origin (suppress errors, just log)

Add explicit fork branch cleanup in umergepr:

- `gh pr merge --delete-branch` skips remote deletion for cross-repo PRs by design
- After merge, check if branch exists on origin via `git ls-remote` and delete with `git push origin --delete`

Add `quiet` helper to suppress git/gh output noise:

- Added `quiet()` to utils.sh -- captures both stdout and stderr, suppresses on success, dumps to respective streams on failure
- Wrapped all git/gh commands in upr and umergepr with `quiet` (except browser-opening and diagnostic commands)
- Added progress echo statements to replace suppressed git output with cleaner messages
