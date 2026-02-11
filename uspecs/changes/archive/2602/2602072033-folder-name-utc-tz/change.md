---
registered_at: 2026-02-07T20:24:18Z
change_id: 2602072023-folder-name-utc-tz
baseline: fae01132a4cbe4fc2cd943ac90d6dc38358f8373
archived_at: 2026-02-07T20:33:20Z
---

# Change request: Change Folder name must use UTC time zone

## Why

Currently the Change Folder naming convention specifies "Must use current local date", which leads to inconsistent folder names depending on the engineer's local time zone. Using UTC ensures consistent, unambiguous timestamps across all contributors.

## What

Update the Change Folder naming convention to require UTC time zone:

- Replace "Must use current local date" with "Must use current date and time in UTC" in `uspecs/u/conf.md`
