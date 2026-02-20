---
registered_at: 2026-02-20T11:40:50Z
change_id: 2602201140-uimpl-follow-all-change-files
baseline: 7be921889effc3350ef4d7a44ff592ea1862cea2
archived_at: 2026-02-20T11:46:26Z
---

# Change request: Uimpl follow all change folder files

## Why

The `uimpl` action does not explicitly instruct the AI to read all files in the Active Change Folder before proceeding. Without reading context files like `issue.md`, `decs.md`, and `how.md`, the AI may miss important context and produce incomplete or misaligned implementation plans.

## What

Update `actn-uimpl.md` to explicitly instruct the AI to read all files present in the Active Change Folder as the first step before executing any implementation logic.
