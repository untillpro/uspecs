---
registered_at: 2026-03-11T08:52:25Z
change_id: 2603110852-default-branch-creation
baseline: 12f67cb6c33ac7d63a1590d22f6612443904d6ad
---

# Change request: Default branch creation for uchange

## Why

Creating a git branch is almost always desired when starting a new change. Requiring `--branch` each time is unnecessary friction. Making branch creation the default, with an explicit `--no-branch` opt-out, better matches the expected workflow.

## What

Update `uchange` so branch creation is on by default:

- Make branch creation the default behavior in `uspecs.sh` `cmd_change_new`
- Add `--no-branch` option to skip branch creation when not desired
- Keep `--branch` as an explicit override (reserved for future per-project default configuration)
- Update usage comments in `uspecs.sh` to reflect new defaults
- Update `actn-uchange.md` parameters and flow to document the new behavior
