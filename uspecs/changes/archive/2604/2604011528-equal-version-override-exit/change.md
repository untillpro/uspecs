---
registered_at: 2026-04-01T14:28:36Z
change_id: 2604011428-equal-version-override-exit
baseline: d3cad4b541319b25aa2c004d589e23d8f61e5df4
archived_at: 2026-04-01T15:28:50Z
---


# Change request: Exit with message when install --override versions match

## Why

When install --override is invoked and the installed version equals the incoming version, the script silently reinstalls the same version. This is unnecessary work. The script should exit early with a message suggesting to remove uspecs.yml to force reinstall.

## What

When install --override is invoked in `cmd_apply`, if the installed version matches the incoming version (same logic as the "Already up to date" check in update/upgrade), exit with a message suggesting to remove uspecs.yml to force reinstall.
