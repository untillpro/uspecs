---
uspecs.registered_at: 2026-01-20T11:54:52Z
uspecs.change_id: 260120-fetch-issue-to-change
uspecs.baseline: 29c77062d8d50c87f87c673dec76bf143e32c715
uspecs.archived_at: 2026-01-24T19:58:27Z
---

# Change request: Fetch issue content when creating change

## Why

When a Developer creates a change request based on an issue (bug report, feature request, etc.), they currently need to manually copy issue details into the change.md file. This is inefficient and error-prone. The issue content contains valuable context that should be automatically captured and referenced from the change folder.

## What

When creating a change request with an issue reference, the system will automatically:

- If possible, fetch the issue content and include it in the change.md file
- Store the issue URL in the frontmatter metadata (uspecs.issue_url)
