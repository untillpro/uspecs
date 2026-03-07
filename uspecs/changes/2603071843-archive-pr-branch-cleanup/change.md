---
registered_at: 2026-03-07T18:43:42Z
change_id: 2603071843-archive-pr-branch-cleanup
baseline: 61b53f9643412314071f10a8c9db35c8bfc871f3
---

# Change request: Archive pr branch cleanup

## Why

When archiving a PR branch, the remote branch may already have been deleted (e.g. by the hosting platform after merge). The current code unconditionally errors if the remote tracking ref is absent and always pushes without checking. After cleanup, the local default branch should also be updated to reflect the latest remote state.

## What

Update `uspecs/specs/prod/softeng/uarchive.feature`:

- Clarify that option 1 push is conditional on remote branch existence
- Add step: local default branch is fast-forwarded to pr_remote/default_branch after cleanup
- Add scenario: archive on PR branch when remote branch no longer exists (commit without push, remove local branch and refs, fast-forward default branch)

Update `cmd_change_archive` in `uspecs/u/scripts/uspecs.sh`:

- Check if the remote branch exists (via `git ls-remote`) instead of requiring local tracking ref as a precondition
- If the remote branch is gone: skip the push step and proceed with local branch and tracking ref removal only
- After switching to the default branch: fetch and fast-forward it from `pr_remote/default_branch`
