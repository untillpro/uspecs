---
registered_at: 2026-02-24T17:37:49Z
change_id: 2602241737-uarchive-hash-restore
baseline: 6ffb6e458ab2169f9953f4aeebafd046d9933d61
issue_url: https://untill.atlassian.net/browse/AIR-3068
---

# Change request: Uarchive report deleted branch hash and restore

## Why

When `uarchive` deletes the git branch, the branch hash is not reported, making it impossible to recover if deleted by mistake. Reporting the hash and providing a restore path improves developer safety in the uspecs workflow.

See [issue.md](issue.md) for details.

## What

Update `uarchive` to report the deleted branch hash and support restore:

- After deleting the branch during archive, print its hash
- Add an option to restore the branch from the reported hash (ref. PR branch)

Update functional design if necessary
