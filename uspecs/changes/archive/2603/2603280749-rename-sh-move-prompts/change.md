---
registered_at: 2026-03-28T07:12:39Z
change_id: 2603280712-rename-sh-move-prompts
baseline: 6a8f44011ed3db876cec4791832979cbfe9f33f9
archived_at: 2026-03-28T07:49:16Z
---

# Change request: Rename uspecs.sh and move prompts.md

## Why

The script name `uspecs.sh` does not reflect its purpose clearly. Renaming it to `softeng.sh` better communicates what it does. The prompts file belongs at the `uspecs/u/` level rather than nested inside `uspecs/u/scripts/`.

## What

File renames and moves:

- Rename `uspecs/u/scripts/uspecs.sh` to `uspecs/u/scripts/softeng.sh`
- Move `uspecs/u/scripts/prompts.md` to `uspecs/u/prompts.md`
- Update all references to the old paths across the codebase
