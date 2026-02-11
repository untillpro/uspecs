---
registered_at: 2026-01-31T19:19:40Z
change_id: 2601311939-archive-subfolders
baseline: fd91a951ae1e02398b03f844e87be6e3f3fc8837
archived_at: 2026-01-31T19:26:51Z
---

# Change request: Archive subfolder structure

## Why

Archive folder is becoming cluttered with many change folders. Organizing archives by year-month subfolder improves navigation and readability.

## What

Update archive structure to use year-month subfolders:

- Current: `archive/yymmddHHMM-change-name/`
- New: `archive/yymm/yymmddHHMM-change-name/`

Modify `uspecs.sh` archive command to:

- Create year-month subfolder (yymm format) within archive
- Move archived change folder into the year-month subfolder
- Update link conversion to add extra `../` level (archives are now two levels deep)
