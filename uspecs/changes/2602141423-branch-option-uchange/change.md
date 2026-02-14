---
registered_at: 2026-02-14T14:24:06Z
change_id: 2602141423-branch-option-uchange
baseline: dbd0d23aa0ac15cfbe8023218c0b9157c63962b3
---

# Change request: Add --branch option to uchange command

## Why

When creating a change request, engineers often need to create a corresponding git branch to implement the change. Currently, this requires a separate manual step after running uchange. Adding a --branch option would streamline the workflow by automatically creating the branch with proper naming conventions.

## What

Add --branch option to the uchange command that creates a git branch when specified:

- When --branch option is provided during change request creation, automatically create a git branch
- Branch naming rules are defined in conf.md
- Branch creation happens after the Change Folder and Change File are created
- If branch creation fails, report the error but don't fail the entire change creation process
