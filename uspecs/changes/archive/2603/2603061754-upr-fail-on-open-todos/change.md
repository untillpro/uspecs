---
registered_at: 2026-03-06T17:22:23Z
change_id: 2603061722-upr-fail-on-open-todos
baseline: ef926fac77063bb965a9f3ec3c789a6963be4a79
archived_at: 2026-03-06T17:54:41Z
---

# Change request: upr fails on open todo items

## Why

The `upr` action creates a pull request, but currently does not verify that all todo items in the change folder are completed. Submitting a PR with open todos indicates the change is not actually ready for review.

## What

Specs changes:

- `upr.feature`: add "change folder has uncompleted todo items" to the "Validation rejects invalid state" examples

Script changes:

- `uspecs.sh`: rename `pr mergedef` to `pr preflight`; add `--change-folder <path>` option and uncompleted todo items check
- `actn-upr.md`: update call to use `pr preflight` and pass Active Change Folder path via `--change-folder`
