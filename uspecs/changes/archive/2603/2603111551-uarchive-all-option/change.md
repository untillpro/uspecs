---
registered_at: 2026-03-11T14:58:38Z
change_id: 2603111458-uarchive-all-option
baseline: 94763247cd777b84839face89d4daaa63491ba96
archived_at: 2026-03-11T15:51:31Z
---

# Change request: uarchive --all option

## Why

When a branch contains multiple change folders, archiving them one by one is tedious. A batch option is needed to archive all modified change folders at once.

## What

Add `--all` option to `uarchive` action that:

- Requires no Active Change Folder argument
- Finds all change folders in `changes_folder` that have modifications compared to `pr_remote/default_branch`
- Archives each modified folder (simple archive, no git branch cleanup)
- Reports count of archived, unchanged, and failed folders
