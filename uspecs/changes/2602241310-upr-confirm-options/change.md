---
registered_at: 2026-02-24T13:10:07Z
change_id: 2602241310-upr-confirm-options
baseline: d9596c65bdadfe584c994a9bb4c5ad2d0d748d1b
---

# Change request: Use numbered options in upr confirmation

## Why

The `upr` action currently asks a plain "Confirm?" prompt, requiring a yes/no answer. This is inconsistent with `uarchive`, which presents numbered options. A numbered option list is clearer and consistent with the established pattern.

## What

Update `actn-upr.md` to replace the plain confirmation prompt with a numbered option list:

- Option 1: Create PR (proceed with squash-merge, branch deletion, and PR creation)
- Option 2: Cancel
