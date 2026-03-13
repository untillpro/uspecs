---
registered_at: 2026-02-23T17:44:50Z
change_id: 2602231744-uarchive-d-commit
baseline: 40d3debe97160c060c864b693d2931b24f26a0e3
archived_at: 2026-02-24T12:06:26Z
---

# Change request: uarchive git cleanup on PR branch

## Why

When archiving a completed change on a PR branch, the associated git branch and refs remain behind, cluttering the repository. Engineers should be offered git cleanup as part of the archive operation without needing to remember an explicit flag.

## What

When `uarchive` is invoked on a branch ending with `--pr`, AI Agent detects this automatically and asks for confirmation before performing git cleanup:

- Makes a git commit with message `archive <folder-from> to <folder-to>`
- Pushes the commit
- Removes the associated branch and refs
