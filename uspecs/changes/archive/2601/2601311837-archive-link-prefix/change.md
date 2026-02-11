---
registered_at: 2026-01-31T18:02:08Z
change_id: 2601311837-archive-link-prefix
baseline: 9b5919c593cae9c4d8f0ec2db9e037dde5b64ac3
archived_at: 2026-01-31T18:04:47Z
---

# Change request: Archive link prefix instead of backticks

## Why

During archive, markdown links are wrapped in backticks to indicate they are no longer functional. However, wrapping in backticks removes link functionality entirely. A better approach is to add `../` prefix to the links so they remain navigable after the folder moves to archive.

## What

Modify the archive process to prefix links with `../` instead of wrapping them in backticks:

- Rename `convert_links_to_backticks` to `convert_links_to_relative`
- Update the sed pattern to add `../` prefix to link targets instead of wrapping in backticks
- Example: `[foo](../bar.md)` becomes `[foo](../../bar.md)`
