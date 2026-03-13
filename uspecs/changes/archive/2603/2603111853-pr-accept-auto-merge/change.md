---
registered_at: 2026-03-11T17:37:55Z
change_id: 2603111737-pr-accept-auto-merge
baseline: 9fb2490f79442cc5a940a63c6e97d3a6e4e19d5b
archived_at: 2026-03-11T18:53:14Z
---

# Change request: PR accept comment triggers archiveall and squash merge

## Why

Accepting a PR currently requires manual steps: archiving all active changes and merging the PR with squash. Automating this via an "uaccept" comment reduces friction and ensures the process is always executed consistently.

## What

When a Developer with Write access posts a comment containing exactly "uaccept" on a PR, the system automatically:

- Reacts to the comment with +1
- Executes the `uspecs change archiveall` command to archive all active change requests
- Merges the PR using squash with auto-merge and deletes the remote branch
- Posts a summary comment instructing the Developer to run `uarchive` locally

Additionally, `uspecs change archive -d` is optimized: when the remote branch is already gone (e.g. deleted by the workflow), it skips the local archive step and just refreshes the default branch and cleans up the local PR branch.
