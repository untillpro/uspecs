---
registered_at: 2026-02-04T15:33:54Z
change_id: 2602041633-update-from-home-safety
baseline: 616610d3ef7b42197a1725af9db0706301aaba2a
archived_at: 2026-02-04T15:56:39Z
---

# Change request: Add safety checks and version tracking to update-from-home.sh

## Why

The update-from-home.sh script currently runs without verifying the target repository state, which could lead to conflicts or loss of uncommitted work. Additionally, there is no way to track which version of uspecs was synced.

## What

Enhance update-from-home.sh with safety and tracking features:

- Add pre-flight check for uncommitted git changes in target directory
  - Use `git status --porcelain` to detect uncommitted changes
  - Exit with error if uncommitted changes exist

- Add version info saving after successful sync
  - Save to `uspecs/version.txt`
  - Format: `YYYYMMDDhhmmss-<commit12>` (always use commit, not tags)
