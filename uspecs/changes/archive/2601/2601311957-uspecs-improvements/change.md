---
registered_at: 2026-01-31T19:39:22Z
change_id: 2601311200-uspecs-improvements
baseline: bb8ebeb9b28d8074190be68affd62fe06d2dfe07
archived_at: 2026-01-31T19:57:03Z
---

# Change request: Improve uspecs.sh and usync action

## Why

The uspecs.sh script incorrectly adds `../` prefix to all relative paths during archive, even when the path is not actually relative. The usync action analyzes files within the Change Request folder itself, which is unnecessary.

## What

Improvements to uspecs tooling:

- uspecs.sh `convert_links_to_relative` should only add `../../` prefix when the link target is a relative path (not starting with `../` already or absolute)
- usync action should explicitly exclude files in the Change Request folder from analysis
