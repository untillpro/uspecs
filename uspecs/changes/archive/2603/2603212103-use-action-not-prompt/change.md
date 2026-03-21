---
registered_at: 2026-03-21T20:47:44Z
change_id: 2603212047-use-action-not-prompt
baseline: 182ef192cba3d52975451df2572df4d947601e00
archived_at: 2026-03-21T21:03:24Z
---

# Change request: Use action command instead of prompt for upr and uaccept

## Why

The execution instructions currently use `uspecs.sh prompt {keyword}` for upr and uaccept keywords, but should use `uspecs.sh action {keyword}` instead to align with the correct command structure.

## What

Update execution instructions and script implementation:

- Change `uspecs.sh prompt {keyword}` to `uspecs.sh action {keyword}` for upr and uaccept keywords in AGENTS.md
- Rename `prompt` command to `action` in uspecs.sh script
- Update usage documentation and comments in uspecs.sh to reflect the new command name
