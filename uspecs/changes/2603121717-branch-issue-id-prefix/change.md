---
registered_at: 2026-03-12T17:17:37Z
change_id: 2603121717-branch-issue-id-prefix
baseline: 705d383d5a3ecfbfe0f588430de2f1da98096a9c
---

# Change request: Branch name should start with issue ID

## Why

When an issue URL is provided during change creation, the resulting git branch name should include the issue ID as a prefix. This makes it easy to associate branches with their originating issues at a glance.

## What

When an issue URL is provided, the branch name format changes from `{change-name}` to `{issue-id}-{change-name}`:

- Extract issue ID from the issue URL (e.g., `123` from GitHub issue URL, `PROJ-456` from Jira URL)
- Prefix the branch name with the extracted issue ID
- Example: for issue `#42` and change name `branch-issue-id-prefix`, branch becomes `42-branch-issue-id-prefix`
- When no issue URL is provided, branch naming remains unchanged
