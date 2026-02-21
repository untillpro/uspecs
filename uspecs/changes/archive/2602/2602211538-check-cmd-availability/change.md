---
registered_at: 2026-02-21T15:23:10Z
change_id: 2602211523-check-cmd-availability
baseline: 9b1cedc7b2df02891d278276a6aa2cfe6bc8ebd4
archived_at: 2026-02-21T15:37:48Z
archived_at: 2026-02-21T15:38:08Z
---

# Change request: Check command availability in all scripts

## Why

conf.sh and uspecs.sh scripts silently fail or produce cryptic errors when required external commands (e.g., `grep`, `git`, `curl`) are not available in the environment. A fail-fast check at startup ensures clear, early feedback when dependencies are missing.

## What

Add availability checks for required external commands:

- At the start of each script (or in a shared init), verify that all required commands are present using `command -v` or equivalent
- If any required command is missing, print a clear error message naming the missing command and exit with a non-zero status immediately

## How

- add _lib/utils.sh with `checkcmds command1...` function
- Source utils.sh in conf.sh and uspecs.sh to check for required commands at the beginning of each script
