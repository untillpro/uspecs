---
registered_at: 2026-02-23T17:44:50Z
change_id: 2602231744-uarchive-d-commit
baseline: 40d3debe97160c060c864b693d2931b24f26a0e3
archived_at: 2026-02-24T10:34:44Z
---

# Change request: uarchive -d flag: commit, remove branch and refs

## Why

When archiving a completed change, the associated git branch and refs remain behind, cluttering the repository. A `-d` flag would allow Engineers to clean up git state as part of the archive operation.

## What

Add `-d` flag to the `uarchive` command that, after moving the folder to archive, performs git cleanup:

- Makes a git commit with message `archive <folder-from> <folder-to>`
- Removes the associated branch
- Removes associated refs
