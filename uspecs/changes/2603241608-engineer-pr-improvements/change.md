---
registered_at: 2026-03-24T16:08:47Z
change_id: 2603241608-engineer-pr-improvements
baseline: e348ef49e1d064b2c707d2cf41948fac096d3238
---

# Change request: Engineer PR Improvements

## Why

The current PR workflow has several gaps: the Working Change Folder (WCF) is archived when it should remain active, the PR body is not populated from change.md, and the commit message includes the full path to change.md instead of just the filename.

## What

Adjust the Engineer PR flow:

- Do not archive the WCF when the engineer creates a PR
- Populate the PR body from change.md
- Use only `change.md` (without path) in the commit message
