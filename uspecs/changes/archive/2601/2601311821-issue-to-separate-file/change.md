---
registered_at: 2026-01-31T17:21:36Z
change_id: 2601311821-issue-to-separate-file
baseline: 9da09f938b72f61418b16aaa48c5426600444e4c
archived_at: 2026-01-31T18:10:23Z
---

# Change request: Fetch issue to separate file

## Why

When engineer creates a change request with an issue reference, the issue content is currently embedded directly into change.md. Extracting issue content to a separate issue.md file improves separation of concerns - the original issue details remain intact in their own file while change.md focuses on describing the change itself.

## What

When creating a change request with an issue reference:

- Fetch issue content to a separate `issue.md` file in the Change Folder
- Reference the issue.md from change.md instead of embedding content
- Keep overall change.md structure unchanged (frontmatter, Why, What sections)
