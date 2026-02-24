---
registered_at: 2026-02-24T17:09:47Z
change_id: 2602241709-pr-mergedef-validate-merge
baseline: 6ffb6e458ab2169f9953f4aeebafd046d9933d61
issue_url: https://untill.atlassian.net/browse/AIR-3067
archived_at: 2026-02-24T17:32:43Z
---

# Change request: pr mergedef --validate should try to merge

## Why

The `pr mergedef --validate` command currently does not attempt an actual merge, which means it can miss real merge conflicts. Performing a trial merge during validation would catch conflicts early and give more accurate feedback about merge readiness.

See [issue.md](issue.md) for details.

## What

Extend `pr mergedef --validate` to attempt a trial merge as part of its validation:

- Try to merge the default branch into the current branch during validation
- Report merge conflicts or failures as validation errors
- Restore the working tree to its original state after the trial merge
