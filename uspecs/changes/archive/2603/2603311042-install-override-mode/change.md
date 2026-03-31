---
registered_at: 2026-03-31T09:31:30Z
change_id: 2603310931-install-override-mode
baseline: f4d7625f295c52411124d5bbde735df313ea9ab3
archived_at: 2026-03-31T10:42:05Z
---

# Change request: Install override mode

## Why

Currently, install fails if uspecs is already installed, directing the user to use update instead. There are cases where the user wants to force a full reinstall regardless of the current version - for example, to fix a corrupted installation or to reset to a known state.

## What

Add an override mode to the install command:

- New `--override` flag for the install command that forces installation even when uspecs is already installed
- When `--override` is used, the existing installation is replaced regardless of version
- Update the "already installed" edge case to not apply when `--override` is specified
